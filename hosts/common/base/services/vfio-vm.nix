{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.vfioVm;

  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (lib) concatMapStringsSep concatStringsSep mapAttrsToList optionalString;

  shellArg = lib.escapeShellArg;

  startScriptName = "start-${cfg.vmName}-vfio";
  restoreScriptName = "restore-${cfg.vmName}-host";
  hookName = "10-${cfg.vmName}-vfio";
  stateFile = "/run/libvirt/${cfg.vmName}-vfio-active";
  logTag = "${cfg.vmName}-vfio";

  parsePci = addr: let
    parts = builtins.match "([0-9a-fA-F]{4}):([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\\.([0-7])" addr;
  in
    if parts == null
    then throw "services.vfioVm: '${addr}' is not a valid PCI address, expected dddd:bb:ss.f"
    else {
      domain = builtins.elemAt parts 0;
      bus = builtins.elemAt parts 1;
      slot = builtins.elemAt parts 2;
      function = builtins.elemAt parts 3;
    };

  parseHex = value: let
    digits = {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      "a" = 10;
      "b" = 11;
      "c" = 12;
      "d" = 13;
      "e" = 14;
      "f" = 15;
    };
    clean = lib.removePrefix "0x" (lib.toLower value);
  in
    lib.foldl' (acc: char: acc * 16 + digits.${char}) 0 (lib.stringToCharacters clean);

  # Highest guest PCI bus any passthrough device is pinned to. Each such bus
  # needs a matching root port to hang off, so this sets the floor for
  # domain.pcieRootPorts.
  maxGuestBus =
    lib.foldl' (acc: device:
      if device.guestAddress == null
      then acc
      else lib.max acc (parseHex device.guestAddress.bus))
    0
    cfg.devices;

  ##
  ## Host device handling, shared by the libvirt hook and the manual restore
  ## command below.
  ##

  stopServiceCommands =
    concatMapStringsSep "\n" (service: ''
      log "stopping ${service}"
      systemctl stop ${shellArg service} || warn "could not stop ${service}"
    '')
    cfg.stopServices;

  restartServiceCommands =
    concatMapStringsSep "\n" (service: ''
      log "starting ${service}"
      systemctl start ${shellArg service} || {
        warn "could not start ${service}"
        failures=$((failures + 1))
      }
    '')
    cfg.restartServices;

  bindToVfioCommands =
    concatMapStringsSep "\n" (device: ''
      bind_to_vfio ${shellArg device.pci}
    '')
    cfg.devices;

  unbindCommands =
    concatMapStringsSep "\n" (device: ''
      release_from_vfio ${shellArg device.pci} || failures=$((failures + 1))
    '')
    cfg.devices;

  # Some host drivers, notably amdgpu on Navi 3x, cannot re-probe a device that
  # vfio-pci has just released: the GPU's MMIO is left in a stale state, so
  # IP discovery reads garbage and the driver hits a kernel BUG() inside
  # amdgpu_device_mm_access. Removing the device and rescanning the bus does
  # NOT help, because the kernel auto-probes amdgpu during the rescan before
  # userspace can intervene and the same BUG fires.
  #
  # A Secondary Bus Reset on the upstream PCIe bridge, via its
  # reset_subordinate attribute, is the best mitigation available from
  # userspace, and it covers the audio function on the same slot for free. It
  # is not a guaranteed fix: this is AMD's well documented and still unresolved
  # Navi 21/31 reset bug, vendor-reset carries no quirk for this ASIC, and AMD
  # have said 7900-series passthrough resets are unsupported in any
  # configuration. Treat it as harm reduction. Devices that do not need a reset
  # (USB controllers and the like) keep the default resetMethod = "none".
  resetCommands =
    concatMapStringsSep "\n" (device:
      optionalString (device.resetMethod == "sbr") ''
        reset_via_sbr ${shellArg device.pci} || failures=$((failures + 1))
      '')
    cfg.devices;

  disableD3ColdCommands =
    concatMapStringsSep "\n" (device:
      optionalString (device.resetMethod == "sbr") ''
        disable_d3cold ${shellArg device.pci}
      '')
    cfg.devices;

  restoreCommands =
    concatMapStringsSep "\n" (device: ''
      restore_device ${shellArg device.pci} ${shellArg device.hostDriver} \
        || failures=$((failures + 1))
    '')
    cfg.devices;

  # One script owns every driver transition, so the libvirt hook and the manual
  # recovery command cannot drift apart. The hook is a thin wrapper around it.
  vfioControl = pkgs.writeShellScript "${cfg.vmName}-vfio-control" ''
    set -Eeuo pipefail

    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.systemd pkgs.kmod]}:$PATH

    STATE_FILE=${shellArg stateFile}
    LOG_TAG=${shellArg logTag}

    # libvirt throws away hook stdout and stderr, so anything written there is
    # invisible after the fact - which is exactly when a failed GPU handback
    # needs to be diagnosed. Log to the journal instead: journalctl -t ${logTag}
    log() {
      printf '%s\n' "$*" | systemd-cat -t "$LOG_TAG" -p info
    }

    warn() {
      printf '%s\n' "$*" | systemd-cat -t "$LOG_TAG" -p warning
    }

    sysfs_path() {
      printf '/sys/bus/pci/devices/%s' "$1"
    }

    device_present() {
      [ -e "$(sysfs_path "$1")" ]
    }

    driver_of() {
      local link
      link="$(sysfs_path "$1")/driver"

      if [ -e "$link" ]; then
        basename "$(readlink -f "$link")"
      fi
    }

    # A device that has fallen off the bus answers config reads with all ones.
    # This is how we tell a reset that recovered the device from one that wedged
    # it further.
    config_readable() {
      local vendor
      vendor="$(cat "$(sysfs_path "$1")/vendor" 2>/dev/null || printf '0xffff')"
      [ "$vendor" != "0xffff" ]
    }

    wait_for_driver() {
      local dev="$1"
      local driver="$2"
      local attempts=${toString cfg.driverBindTimeoutDeciseconds}

      while [ "$attempts" -gt 0 ]; do
        if [ "$(driver_of "$dev")" = "$driver" ]; then
          log "$dev is bound to $driver"
          return 0
        fi
        sleep 0.1
        attempts=$((attempts - 1))
      done

      warn "timed out waiting for $dev to bind to $driver"
      return 1
    }

    unbind_device() {
      local dev="$1"
      local current
      current="$(driver_of "$dev")"

      [ -n "$current" ] || return 0

      log "unbinding $dev from $current"
      if ! printf '%s' "$dev" > "$(sysfs_path "$dev")/driver/unbind" 2>/dev/null; then
        warn "failed to unbind $dev from $current"
        return 1
      fi
    }

    disable_d3cold() {
      local dev="$1"
      local attr
      attr="$(sysfs_path "$dev")/d3cold_allowed"

      if [ -e "$attr" ]; then
        log "disabling d3cold for $dev"
        printf '0' > "$attr" 2>/dev/null || warn "could not disable d3cold for $dev"
      fi
    }

    bind_to_vfio() {
      local dev="$1"

      if ! device_present "$dev"; then
        warn "$dev is not present on the PCI bus"
        return 1
      fi

      log "claiming $dev for vfio-pci"
      printf 'vfio-pci' > "$(sysfs_path "$dev")/driver_override"
      unbind_device "$dev" || return 1

      # drivers_probe honours driver_override, so it is more reliable than
      # writing straight to the vfio-pci bind attribute.
      printf '%s' "$dev" > /sys/bus/pci/drivers_probe 2>/dev/null \
        || warn "drivers_probe rejected $dev"

      wait_for_driver "$dev" vfio-pci
    }

    release_from_vfio() {
      local dev="$1"
      local current
      current="$(driver_of "$dev")"

      if [ "$current" != "vfio-pci" ]; then
        log "$dev is on ''${current:-no driver}, not vfio-pci; nothing to release"
        return 0
      fi

      unbind_device "$dev"
    }

    reset_via_sbr() {
      local dev="$1"
      local bridge attempt

      if ! device_present "$dev"; then
        warn "cannot reset $dev: not present on the PCI bus"
        return 1
      fi

      bridge="$(basename "$(readlink -f "$(sysfs_path "$dev")/..")" 2>/dev/null || true)"
      if [ -z "$bridge" ] || ! device_present "$bridge"; then
        warn "cannot find the upstream PCIe bridge for $dev"
        return 1
      fi

      if [ ! -w "$(sysfs_path "$bridge")/reset_subordinate" ]; then
        warn "$bridge does not expose reset_subordinate; cannot reset $dev"
        return 1
      fi

      # Reset, then check whether the device actually came back before deciding
      # to hit it again. The previous version fired a fixed two resets with no
      # check, so a device that recovered on the first one got reset a second
      # time for nothing.
      for attempt in $(seq 1 ${toString cfg.sbrAttempts}); do
        log "secondary bus reset on $bridge for $dev (attempt $attempt)"
        printf '1' > "$(sysfs_path "$bridge")/reset_subordinate" 2>/dev/null \
          || warn "the reset_subordinate write failed on $bridge"

        # PCIe requires at least 100ms after a reset before config space is
        # touched again; give the GPU considerably longer than the minimum.
        sleep ${toString cfg.sbrSettleSeconds}

        if config_readable "$dev"; then
          log "$dev answers config reads again after the reset"
          return 0
        fi

        warn "$dev is still unresponsive after reset attempt $attempt"
      done

      warn "$dev did not recover after ${toString cfg.sbrAttempts} reset attempts"
      return 1
    }

    restore_device() {
      local dev="$1"
      local driver="$2"
      local current

      if ! device_present "$dev"; then
        warn "cannot restore $dev: not present on the PCI bus"
        return 1
      fi

      current="$(driver_of "$dev")"
      if [ "$current" = "$driver" ]; then
        log "$dev is already bound to $driver"
        return 0
      fi

      # A leftover vfio-pci override makes drivers_probe a no-op, so clear it
      # before asking the kernel to pick a driver again.
      printf '\n' > "$(sysfs_path "$dev")/driver_override" 2>/dev/null \
        || warn "could not clear driver_override for $dev"

      modprobe "$driver" 2>/dev/null || true

      log "reattaching $dev to $driver"
      printf '%s' "$dev" > /sys/bus/pci/drivers_probe 2>/dev/null \
        || warn "drivers_probe rejected $dev"

      if wait_for_driver "$dev" "$driver"; then
        return 0
      fi

      # Some drivers only take a device when asked directly.
      log "falling back to an explicit bind of $dev to $driver"
      printf '%s' "$dev" > "/sys/bus/pci/drivers/$driver/bind" 2>/dev/null || true
      wait_for_driver "$dev" "$driver"
    }

    start_passthrough() {
      if [ -e "$STATE_FILE" ]; then
        log "passthrough is already active"
        return 0
      fi

      # If any step below fails the host is left with no session and no GPU, so
      # unwind everything before reporting the error. set -E above is what makes
      # this trap fire for failures raised inside the helper functions; without
      # it the rollback silently never ran.
      trap 'warn "passthrough setup failed; restoring the host"; stop_passthrough force' ERR

      ${stopServiceCommands}

      log "terminating the ${cfg.user} session so the GPU is released"
      loginctl terminate-user ${shellArg cfg.user} || true
      systemctl stop ${shellArg "user@${toString cfg.userUid}.service"} || true
      sleep ${toString cfg.sessionReleaseDelaySeconds}

      log "loading vfio-pci"
      modprobe vfio-pci

      ${disableD3ColdCommands}
      ${bindToVfioCommands}

      touch "$STATE_FILE"
      trap - ERR

      log "passthrough is active"
    }

    stop_passthrough() {
      local force="''${1:-}"
      local failures=0

      # Never re-enter the rollback from inside the rollback.
      trap - ERR

      if [ ! -e "$STATE_FILE" ] && [ "$force" != "force" ]; then
        log "no passthrough state recorded; nothing to restore"
        return 0
      fi

      ${
      if cfg.hostRecovery == "reboot"
      then ''
        # This hardware cannot reset the passthrough GPU well enough for the
        # host driver to re-probe it live - amdgpu hits a kernel BUG() during IP
        # discovery. A full platform reset is the only reliable recovery, so
        # release vfio's claim and reboot rather than attempting a rebind that
        # would wedge the entire host. The GPU cold-initialises cleanly on the
        # next boot.
        set +e
        log "releasing passthrough devices from vfio-pci"
        ${unbindCommands}
        rm -f "$STATE_FILE"
        set -e

        log "hostRecovery=reboot: rebooting to reclaim the GPU via a clean cold init"
        systemctl reboot
        return 0
      ''
      else ''
        # Everything from here is best effort. One wedged device must not abort
        # the sequence: the other devices still need their drivers back, and the
        # host still needs its display manager. Problems are counted and reported
        # at the end instead of aborting.
        set +e

        log "releasing passthrough devices from vfio-pci"
        ${unbindCommands}

        sleep ${toString cfg.releaseSettleSeconds}

        log "resetting the devices that need it before their host drivers re-probe"
        ${resetCommands}

        log "reattaching passthrough devices to their host drivers"
        ${restoreCommands}

        ${restartServiceCommands}

        # vfio has let go either way, so the recorded state is stale regardless
        # of whether every device came back. The restore command below passes
        # force, so a retry still works after this is cleared.
        rm -f "$STATE_FILE"
        set -e

        if [ "$failures" -gt 0 ]; then
          warn "host restore finished with $failures problem(s); rerun ${restoreScriptName} to retry"
          return 1
        fi

        log "host restore is complete"
        return 0
      ''
      }
    }

    case "''${1:-}" in
      start)
        start_passthrough
        ;;
      stop)
        stop_passthrough "''${2:-}"
        ;;
      *)
        printf 'usage: %s start|stop [force]\n' "$0" >&2
        exit 64
        ;;
    esac
  '';

  # Guards against a hand-edited domain that no longer passes the GPU through:
  # tearing the host session down for a VM that does not want the GPU would
  # black-screen the machine for nothing.
  hasHostdevScript = pkgs.writeText "vfio-has-hostdev.py" ''
    import re
    import sys
    import xml.etree.ElementTree as ET


    def pci_num(value):
        if value is None:
            return None
        return int(value, 0)


    def parse_pci(value):
        match = re.fullmatch(r"([0-9a-fA-F]{4}):([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\.([0-7])", value)
        if not match:
            sys.exit(1)
        domain, bus, slot, function = match.groups()
        return (int(domain, 16), int(bus, 16), int(slot, 16), int(function, 16))


    target = parse_pci(sys.argv[1])

    try:
        root = ET.fromstring(sys.stdin.read())
    except (ET.ParseError, ValueError):
        sys.exit(1)

    for hostdev in root.findall(".//hostdev"):
        if hostdev.get("mode") != "subsystem" or hostdev.get("type") != "pci":
            continue

        address = hostdev.find("./source/address")
        if address is None:
            continue

        current = (
            pci_num(address.get("domain")),
            pci_num(address.get("bus")),
            pci_num(address.get("slot")),
            pci_num(address.get("function")),
        )
        if current == target:
            sys.exit(0)

    sys.exit(1)
  '';

  vfioHook = pkgs.writeShellScript "${cfg.vmName}-vfio-hook" ''
    set -euo pipefail

    VM_NAME="''${1:-}"
    OPERATION="''${2:-}"
    SUB_OPERATION="''${3:-}"
    DOMAIN_XML="$(cat)"

    [ "$VM_NAME" = ${shellArg cfg.vmName} ] || exit 0

    case "$OPERATION:$SUB_OPERATION" in
      prepare:begin)
        if ! printf '%s' "$DOMAIN_XML" \
          | ${pkgs.python3}/bin/python3 ${hasHostdevScript} ${shellArg cfg.primaryDevice}; then
          printf '%s\n' "${cfg.vmName} does not pass ${cfg.primaryDevice} through; skipping" \
            | ${pkgs.systemd}/bin/systemd-cat -t ${shellArg logTag} -p info
          exit 0
        fi

        exec ${vfioControl} start
        ;;
      release:end)
        exec ${vfioControl} stop
        ;;
    esac
  '';

  startVfio = pkgs.writeShellScriptBin startScriptName ''
    set -euo pipefail

    VIRSH="${pkgs.libvirt}/bin/virsh"

    if [ "$("$VIRSH" -c qemu:///system domstate ${shellArg cfg.vmName})" = "running" ]; then
      echo "${cfg.vmName} is already running" >&2
      exit 0
    fi

    # The prepare hook tears down the graphical session, which would take this
    # process with it if it stayed a child of the launching session.
    exec ${pkgs.systemd}/bin/systemd-run --unit=${shellArg "${cfg.vmName}-vfio-start"} \
      "$VIRSH" -c qemu:///system start ${shellArg cfg.vmName}
  '';

  # Recovery path for the case the hook could not hand the GPU back. The failure
  # mode is a host with no display, so this has to be runnable from a TTY.
  restoreHost = pkgs.writeShellScriptBin restoreScriptName ''
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "${restoreScriptName} must run as root" >&2
      exit 1
    fi

    exec ${vfioControl} stop force
  '';

  ##
  ## Declarative libvirt domain
  ##

  domainCfg = cfg.domain;

  vcpuPinXml =
    concatStringsSep "\n"
    (lib.imap0 (index: cpuset: "    <vcpupin vcpu='${toString index}' cpuset='${cpuset}'/>") domainCfg.vcpuPin);

  # QEMU's pcie-root-port is a Red Hat device (PCI 1b36:000c); a wall of 14
  # identical ones is a strong "this is QEMU" signal to anything that walks PCI
  # config space or just counts root ports. Emit only as many as the guest
  # actually needs.
  #
  # OVMF numbers guest buses in root-port order, so keeping the ports at the
  # same slot/function addresses keeps a device's guest bus number stable: the
  # port at 00:02.N gets guest bus N+1. As long as pcieRootPorts covers the
  # highest guest bus referenced by a passthrough device (bus 7 -> function 6
  # -> at least 7 ports here), Windows sees no topology change. Dropping below
  # that renumbers buses, which Windows treats as new hardware.
  pcieRootPortXml =
    concatStringsSep "\n"
    (lib.genList (
      i: let
        index = i + 1;
        slot =
          if i < 8
          then 2
          else 3;
        function =
          if i < 8
          then i
          else i - 8;
        multifunction = optionalString (function == 0) " multifunction='on'";
        port = lib.toHexString (16 + i);
      in ''
            <controller type='pci' index='${toString index}' model='pcie-root-port'>
              <model name='${domainCfg.pcieRootPortModel}'/>
              <target chassis='${toString index}' port='0x${port}'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x0${toString slot}' function='0x${toString function}'${multifunction}/>
            </controller>''
    )
    domainCfg.pcieRootPorts);

  # A COM1 serial port and its console are pure emulation with no counterpart on
  # bare-metal hardware, so they are a free VM tell. Off by default; enable
  # only when you need serial for guest debugging.
  serialConsoleXml = optionalString domainCfg.serialConsole ''
        <serial type='pty'>
          <target type='isa-serial' port='0'>
            <model name='isa-serial'/>
          </target>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>'';

  # Hyper-V enlightenments speed up a Windows guest, but they also advertise a
  # hypervisor: the vendor_id shows up at cpuid leaf 0x40000000 and Windows
  # creates Hyper-V objects, both of which VM-detection tools flag. When
  # disabled we drop the whole block (and the matching hypervclock timer) so the
  # guest looks like bare metal. The plain hypervisor cpuid bit is hidden
  # separately by the cpu <feature> below, regardless of this setting.
  hypervXml = optionalString domainCfg.hyperv ''
    <hyperv mode='custom'>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
          <vpindex state='on'/>
          <runtime state='on'/>
          <synic state='on'/>
          <stimer state='on'/>
          <reset state='on'/>
          <vendor_id state='on' value='${domainCfg.hypervVendorId}'/>
          <frequencies state='on'/>
          <tlbflush state='on'/>
          <ipi state='on'/>
          <avic state='on'/>
        </hyperv>
        '';

  hypervClockXml = optionalString domainCfg.hyperv "<timer name='hypervclock' present='yes'/>";

  smbiosXml =
    concatMapStringsSep "\n" (section: ''
      <${section.name}>
      ${concatStringsSep "\n      " (mapAttrsToList (key: value: "<entry name='${key}'>${lib.escapeXML value}</entry>") section.entries)}
      </${section.name}>'')
    domainCfg.smbios;

  diskXml =
    concatMapStringsSep "\n" (disk: let
      sourceAttr =
        if disk.type == "block"
        then "dev"
        else "file";

      driverAttrs =
        concatStringsSep "" (
          map (pair: optionalString (builtins.elemAt pair 1 != null) " ${builtins.elemAt pair 0}='${builtins.elemAt pair 1}'") [
            ["cache" disk.cache]
            ["io" disk.io]
            ["discard" disk.discard]
          ]
        );
    in ''
      <disk type='${disk.type}' device='${disk.device}'>
        <driver name='qemu' type='${disk.driverType}'${driverAttrs}/>
        <source ${sourceAttr}='${disk.source}'/>
        <target dev='${disk.target}' bus='${disk.bus}'/>${optionalString (disk.serial != null) "\n      <serial>${disk.serial}</serial>"}${optionalString disk.readonly "\n      <readonly/>"}${optionalString (disk.bootOrder != null) "\n      <boot order='${toString disk.bootOrder}'/>"}
        <address type='drive' controller='0' bus='0' target='0' unit='${toString disk.unit}'/>
      </disk>'')
    domainCfg.disks;

  # Generated from services.vfioVm.devices, so the passthrough device list has a
  # single definition rather than one in Nix and a second one in the domain XML
  # that can drift out of sync with it.
  #
  # managed='no' is load bearing. With managed='yes' libvirt rebinds the host
  # driver itself from qemuProcessStop, which runs *before* the release hook, so
  # amdgpu would re-probe the GPU before the reset below ever happens - which is
  # precisely the crash this module exists to avoid. Leaving every transition to
  # the hook keeps the ordering under our control.
  hostdevXml =
    concatMapStringsSep "\n" (device: let
      source = parsePci device.pci;
      guest = device.guestAddress;

      romXml = optionalString (device.romFile != null) ''

        <rom bar='${device.romBar}' file='${device.romFile}'/>'';

      guestXml = optionalString (guest != null) ''

        <address type='pci' domain='0x0000' bus='${guest.bus}' slot='${guest.slot}' function='${guest.function}'${optionalString guest.multifunction " multifunction='on'"}/>'';
    in ''
      <hostdev mode='subsystem' type='pci' managed='no'>
        <driver name='vfio'/>
        <source>
          <address domain='0x${source.domain}' bus='0x${source.bus}' slot='0x${source.slot}' function='0x${source.function}'/>
        </source>${romXml}${guestXml}
      </hostdev>'')
    cfg.devices;

  qemuCommandlineXml = optionalString (domainCfg.extraQemuArgs != []) ''
    <qemu:commandline>
    ${concatMapStringsSep "\n  " (arg: "<qemu:arg value='${lib.escapeXML arg}'/>") domainCfg.extraQemuArgs}
    </qemu:commandline>'';

  domainXml = pkgs.writeText "${cfg.vmName}-domain.xml" ''
    <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
      <name>${cfg.vmName}</name>
      <uuid>${domainCfg.uuid}</uuid>
      <metadata xmlns:ns0="http://libosinfo.org/xmlns/libvirt/domain/1.0">
        <ns0:libosinfo>
          <ns0:os id="${domainCfg.osinfoId}"/>
        </ns0:libosinfo>
      </metadata>
      <memory unit='KiB'>${toString domainCfg.memoryKiB}</memory>
      <currentMemory unit='KiB'>${toString domainCfg.memoryKiB}</currentMemory>
      <memoryBacking>
        <nosharepages/>
        <locked/>
      </memoryBacking>
      <vcpu placement='static'>${toString domainCfg.vcpus}</vcpu>
      <iothreads>1</iothreads>
      <cputune>
    ${vcpuPinXml}
        <emulatorpin cpuset='${domainCfg.emulatorPin}'/>
        <iothreadpin iothread='1' cpuset='${domainCfg.emulatorPin}'/>
      </cputune>
      <sysinfo type='smbios'>
      ${smbiosXml}
      </sysinfo>
      <os firmware='efi'>
        <type arch='x86_64' machine='${domainCfg.machine}'>hvm</type>
        <firmware>
          <feature enabled='no' name='enrolled-keys'/>
          <feature enabled='yes' name='secure-boot'/>
        </firmware>
        <loader readonly='yes' secure='yes' type='pflash' format='raw'>${domainCfg.loader}</loader>
        <nvram template='${domainCfg.nvramTemplate}' templateFormat='raw' format='raw'>${domainCfg.nvram}</nvram>
        <bootmenu enable='yes' timeout='5000'/>
        <smbios mode='sysinfo'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        ${hypervXml}<kvm>
          <hidden state='on'/>
        </kvm>
        <vmport state='off'/>
        <smm state='on'/>
        <ioapic driver='kvm'/>
      </features>
      <cpu mode='host-passthrough' check='none' migratable='off'>
        <topology sockets='${toString domainCfg.topology.sockets}' dies='${toString domainCfg.topology.dies}' clusters='${toString domainCfg.topology.clusters}' cores='${toString domainCfg.topology.cores}' threads='${toString domainCfg.topology.threads}'/>
        <cache mode='passthrough'/>
        <feature policy='require' name='topoext'/>
        <feature policy='require' name='invtsc'/>
        <feature policy='disable' name='hypervisor'/>
      </cpu>
      <clock offset='localtime'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
        ${hypervClockXml}
        <timer name='tsc' present='yes' mode='native'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled='${
      if domainCfg.suspendToMem
      then "yes"
      else "no"
    }'/>
        <suspend-to-disk enabled='${
      if domainCfg.suspendToDisk
      then "yes"
      else "no"
    }'/>
      </pm>
      <devices>
        <emulator>${domainCfg.emulator}</emulator>
    ${diskXml}
        <controller type='usb' index='0' model='nec-xhci' ports='15'>
          <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
        </controller>
        <controller type='pci' index='0' model='pcie-root'/>
    ${pcieRootPortXml}
        <controller type='sata' index='0'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
        </controller>
        <interface type='network'>
          <mac address='${domainCfg.network.mac}'/>
          <source network='${domainCfg.network.source}'/>
          <model type='${domainCfg.network.model}'/>
          <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
        </interface>
    ${serialConsoleXml}
        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0' persistent_state='yes'/>
        </tpm>
        <audio id='1' type='none'/>
    ${hostdevXml}
        <watchdog model='itco' action='reset'/>
        <memballoon model='none'/>
      </devices>
    ${qemuCommandlineXml}
    </domain>
  '';
in {
  options.services.vfioVm = {
    enable = mkEnableOption "single-VM libvirt VFIO passthrough";

    vmName = mkOption {
      type = types.str;
      description = "Libvirt domain name to start and handle in the VFIO hook.";
    };

    primaryDevice = mkOption {
      type = types.str;
      example = "0000:03:00.0";
      description = "Primary PCI device that must be present in the VM XML before detaching host devices.";
    };

    devices = mkOption {
      type = types.listOf (types.submodule {
        options = {
          pci = mkOption {
            type = types.str;
            example = "0000:03:00.0";
            description = "PCI address to bind to vfio-pci while the VM runs.";
          };

          hostDriver = mkOption {
            type = types.str;
            example = "amdgpu";
            description = "Host driver to bind the device back to after VM shutdown.";
          };

          resetMethod = mkOption {
            type = types.enum ["none" "sbr"];
            default = "none";
            description = ''
              Method used to reset a passthrough device before reattaching its
              host driver after VM shutdown.

              - "none": rely on the host driver to re-probe the device as-is.
              - "sbr": trigger a Secondary Bus Reset on the upstream PCIe
                bridge via its reset_subordinate sysfs attribute before
                rebinding. Required for AMD Navi 3x (RDNA 3) GPUs, whose MMIO
                is left in a stale state by vfio-pci and otherwise causes
                amdgpu IP-discovery to hit a kernel BUG() during re-probe. A
                single SBR on the GPU's bridge also resets the other functions
                on that slot (HDMI audio, for instance), so only one device per
                bridge needs to set this.
            '';
          };

          romFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "/var/lib/libvirt/vbios/gpu.rom";
            description = "Option ROM image to hand the guest for this device.";
          };

          romBar = mkOption {
            type = types.enum ["on" "off"];
            default = "on";
            description = ''
              Whether the option ROM BAR is exposed to the guest. Note that
              romBar = "off" hides the ROM entirely, which makes any romFile
              set above inert.
            '';
          };

          guestAddress = mkOption {
            default = null;
            description = ''
              Guest-side PCI address for this device. Leave null to let libvirt
              assign one, but note that a moved device looks like new hardware
              to the guest OS.
            '';
            type = types.nullOr (types.submodule {
              options = {
                bus = mkOption {
                  type = types.str;
                  example = "0x05";
                  description = "Guest PCI bus.";
                };

                slot = mkOption {
                  type = types.str;
                  default = "0x00";
                  description = "Guest PCI slot.";
                };

                function = mkOption {
                  type = types.str;
                  default = "0x0";
                  description = "Guest PCI function.";
                };

                multifunction = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether to mark this address as multifunction.";
                };
              };
            });
          };
        };
      });
      default = [];
      description = "PCI devices to detach for the VM and restore afterward.";
    };

    user = mkOption {
      type = types.str;
      default = "jack";
      description = "User whose graphical session should be terminated before detaching the GPU.";
    };

    userUid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID for the systemd user service to stop before detaching the GPU.";
    };

    stopServices = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "System services to stop before binding devices to vfio-pci.";
    };

    restartServices = mkOption {
      type = types.listOf types.str;
      default = lib.reverseList cfg.stopServices;
      defaultText = lib.literalExpression "lib.reverseList config.services.vfioVm.stopServices";
      description = ''
        System services to start again after restoring host drivers. Defaults to
        everything that was stopped, in reverse order, so the display manager
        comes back last.
      '';
    };

    sessionReleaseDelaySeconds = mkOption {
      type = types.int;
      default = 5;
      description = "Seconds to wait after terminating the user session before detaching devices.";
    };

    hostRecovery = mkOption {
      type = types.enum ["rebind" "reboot"];
      default = "rebind";
      description = ''
        How the host reclaims the passthrough devices after the VM shuts down.

        - "rebind": unbind the devices from vfio-pci, reset those that need it,
          and rebind their host drivers live. Correct for well-behaved devices.
        - "reboot": skip the live rebind and reboot the host instead. Required
          for GPUs whose reset is broken badly enough that the host driver
          cannot re-probe them after vfio releases them - AMD Navi 31 (RX 7900)
          hits a kernel BUG() in amdgpu_device_mm_access during IP discovery,
          because a bus reset recovers PCI config space but does not re-run the
          GPU's PSP. Such a device only comes back with a full platform reset,
          so the host reboots and the GPU cold-initialises cleanly, at the cost
          of one reboot per VM session. See resetMethod for the reason a plain
          reset is not enough on this ASIC.
      '';
    };

    releaseSettleSeconds = mkOption {
      type = types.int;
      default = 2;
      description = "Seconds to wait after unbinding devices from vfio-pci before resetting them.";
    };

    sbrAttempts = mkOption {
      type = types.int;
      default = 3;
      description = "How many times to retry a Secondary Bus Reset before giving up on a device.";
    };

    sbrSettleSeconds = mkOption {
      type = types.int;
      default = 2;
      description = ''
        Seconds to wait after a Secondary Bus Reset before checking whether the
        device responds again. PCIe requires at least 100ms; GPUs want far more.
      '';
    };

    driverBindTimeoutDeciseconds = mkOption {
      type = types.int;
      default = 150;
      description = "How long to wait, in tenths of a second, for a device to bind to its driver.";
    };

    desktopName = mkOption {
      type = types.str;
      default = "windows";
      description = "Desktop item file name.";
    };

    desktopDisplayName = mkOption {
      type = types.str;
      default = "Windows";
      description = "Desktop launcher display name.";
    };

    desktopComment = mkOption {
      type = types.str;
      default = "Start VM with GPU passthrough";
      description = "Desktop launcher comment.";
    };

    desktopIcon = mkOption {
      type = types.str;
      default = "windows";
      description = "Desktop launcher icon name.";
    };

    domain = {
      enable =
        mkEnableOption "declarative definition of the libvirt domain"
        // {
          description = ''
            Define the libvirt domain from this configuration on every
            activation. The domain XML then lives in version control rather than
            only in /var/lib/libvirt.

            Persistent guest state is untouched: NVRAM, the swtpm state
            directory and the disks are all referenced by path, not recreated.
            Changes made with virsh edit or virt-manager are overwritten on the
            next rebuild, so make them here instead.
          '';
        };

      uuid = mkOption {
        type = types.str;
        example = "508a7af7-d0ce-41e7-8fa8-d58005d9fabb";
        description = ''
          Domain UUID. Keep this stable: the swtpm state directory is keyed on
          it, and the guest sees it as part of its hardware identity.
        '';
      };

      osinfoId = mkOption {
        type = types.str;
        default = "http://microsoft.com/win/11";
        description = "libosinfo OS identifier recorded in the domain metadata.";
      };

      memoryKiB = mkOption {
        type = types.int;
        example = 24576000;
        description = "Guest memory in KiB.";
      };

      vcpus = mkOption {
        type = types.int;
        description = "Number of virtual CPUs.";
      };

      topology = {
        sockets = mkOption {
          type = types.int;
          default = 1;
          description = "CPU sockets presented to the guest.";
        };

        dies = mkOption {
          type = types.int;
          default = 1;
          description = "CPU dies presented to the guest.";
        };

        clusters = mkOption {
          type = types.int;
          default = 1;
          description = "CPU clusters presented to the guest.";
        };

        cores = mkOption {
          type = types.int;
          description = "CPU cores presented to the guest.";
        };

        threads = mkOption {
          type = types.int;
          default = 2;
          description = "Threads per core presented to the guest.";
        };
      };

      vcpuPin = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["1" "9" "2" "10"];
        description = ''
          Host CPU to pin each vCPU to, indexed by vCPU number. Pair sibling
          threads so the guest's SMT topology matches the host's.
        '';
      };

      emulatorPin = mkOption {
        type = types.str;
        example = "0,8";
        description = "Host CPUs the emulator and IO threads are pinned to.";
      };

      emulator = mkOption {
        type = types.str;
        default = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";
        defaultText = lib.literalExpression ''"''${pkgs.qemu_kvm}/bin/qemu-system-x86_64"'';
        description = "QEMU binary used for this domain.";
      };

      machine = mkOption {
        type = types.str;
        default = "q35";
        example = "pc-q35-10.2";
        description = ''
          QEMU machine type. Pinning an explicit version keeps the guest's
          virtual hardware stable across QEMU upgrades.
        '';
      };

      loader = mkOption {
        type = types.str;
        default = "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd";
        description = "OVMF firmware image.";
      };

      nvramTemplate = mkOption {
        type = types.str;
        default = "/run/libvirt/nix-ovmf/edk2-i386-vars.fd";
        description = "Template used to seed NVMRAM when it does not exist yet.";
      };

      nvram = mkOption {
        type = types.str;
        default = "/var/lib/libvirt/qemu/nvram/${cfg.vmName}_VARS.fd";
        defaultText = lib.literalExpression ''"/var/lib/libvirt/qemu/nvram/''${config.services.vfioVm.vmName}_VARS.fd"'';
        description = ''
          Per-domain NVRAM file. This holds the secure boot keys and the guest's
          UEFI boot entries, and is never regenerated once it exists.
        '';
      };

      hyperv = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Expose Hyper-V paravirtualisation enlightenments to the guest. They
          improve Windows performance, but they announce a hypervisor: the
          Hyper-V vendor appears at CPUID leaf 0x40000000 and Windows creates
          Hyper-V objects, both of which VM-detection tools flag. Set false to
          present as bare metal, at the cost of guest performance. The plain
          hypervisor CPUID bit stays hidden either way.
        '';
      };

      hypervVendorId = mkOption {
        type = types.str;
        default = "KVMKVMKVM";
        example = "Microsoft Hv";
        description = ''
          Hyper-V vendor ID reported to the guest at CPUID leaf 0x40000000, up
          to 12 characters. Only used when hyperv is enabled. "Microsoft Hv"
          mimics a real Windows box running on Hyper-V (normal for Win11 with
          VBS/HVCI), stealthier than an invented signature no real hypervisor
          emits - but note that exposing any Hyper-V vendor still reveals a
          hypervisor to tools that read leaf 0x40000000.
        '';
      };

      suspendToMem = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Advertise ACPI S3 (suspend-to-RAM) to the guest. Beyond enabling
          sleep, this makes Windows' GetPwrCapabilities report a supported
          sleep state - a machine that supports no sleep states at all is a
          VM tell. The guest still won't sleep unless its own power policy
          tells it to.
        '';
      };

      suspendToDisk = mkOption {
        type = types.bool;
        default = false;
        description = "Advertise ACPI S4 (hibernate) to the guest.";
      };

      pcieRootPorts = mkOption {
        type = types.int;
        default = 8;
        description = ''
          Number of PCIe root-port controllers to emit. Keep this to the minimum
          the guest needs rather than libvirt's default sprawl. It must be at
          least as high as the highest guest PCI bus referenced by any
          passthrough device's guestAddress, or that device has nowhere to
          attach; lowering it past that point renumbers the guest's PCI buses,
          which Windows sees as new hardware.
        '';
      };

      pcieRootPortModel = mkOption {
        type = types.enum ["pcie-root-port" "ioh3420"];
        default = "pcie-root-port";
        description = ''
          QEMU device backing the PCIe root ports.

          - "pcie-root-port": the modern default. It is a Red Hat device
            (PCI 1b36:000c), so it shows up under VEN_1B36 and gives the guest
            away as QEMU.
          - "ioh3420": an Intel IOH root port (PCI 8086:3420). Reports a genuine
            Intel vendor id instead, so nothing matches VEN_1B36. It is an older
            PCIe gen2 port, and changing the model changes the root-port hardware
            the guest sees, so Windows re-enumerates the ports (and may briefly
            re-detect devices behind them, including a passed-through GPU). Test
            a full boot after switching.
        '';
      };

      serialConsole = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to attach an emulated COM1 serial port and console. A real
          bare-metal machine has neither, so leave this off unless you need serial
          output to debug the guest.
        '';
      };

      network = {
        mac = mkOption {
          type = types.str;
          example = "00:1b:21:7a:3c:91";
          description = ''
            Guest NIC MAC address. Keep this stable, or the guest treats the NIC
            as new hardware and reconfigures its network profile.
          '';
        };

        source = mkOption {
          type = types.str;
          default = "default";
          description = "Libvirt network to attach the guest NIC to.";
        };

        model = mkOption {
          type = types.str;
          default = "e1000e";
          description = "Emulated NIC model.";
        };
      };

      disks = mkOption {
        default = [];
        description = "Disks attached to the guest, in order.";
        type = types.listOf (types.submodule {
          options = {
            type = mkOption {
              type = types.enum ["block" "file"];
              default = "file";
              description = "Whether the backing store is a block device or a file.";
            };

            device = mkOption {
              type = types.enum ["disk" "cdrom"];
              default = "disk";
              description = "How the guest should see this device.";
            };

            source = mkOption {
              type = types.str;
              description = "Path to the backing block device or file.";
            };

            target = mkOption {
              type = types.str;
              example = "sda";
              description = "Guest-side device name.";
            };

            bus = mkOption {
              type = types.str;
              default = "sata";
              description = "Guest-side bus.";
            };

            unit = mkOption {
              type = types.int;
              default = 0;
              description = "Unit number on the controller.";
            };

            driverType = mkOption {
              type = types.str;
              default = "raw";
              description = "Image format.";
            };

            cache = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "none";
              description = "Host cache mode.";
            };

            io = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "native";
              description = "Host IO mode.";
            };

            discard = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "unmap";
              description = "Discard behaviour.";
            };

            serial = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Serial number reported to the guest.";
            };

            readonly = mkOption {
              type = types.bool;
              default = false;
              description = "Whether the guest sees this device as read-only.";
            };

            bootOrder = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Boot priority, lower is tried first.";
            };
          };
        });
      };

      smbios = mkOption {
        default = [];
        description = ''
          SMBIOS sections written into the domain's sysinfo block, in order.
          Section order matters to libvirt's schema, hence a list rather than an
          attribute set.
        '';
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.enum ["bios" "system" "baseBoard" "chassis"];
              description = "SMBIOS section name.";
            };

            entries = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = "Entries within the section.";
            };
          };
        });
      };

      extraQemuArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["-smbios" "type=17,manufacturer=Samsung"];
        description = "Extra arguments appended to the QEMU command line.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.devices != [];
        message = "services.vfioVm.devices must contain at least one PCI device.";
      }
      {
        assertion = lib.any (device: device.pci == cfg.primaryDevice) cfg.devices;
        message = "services.vfioVm.primaryDevice must be one of services.vfioVm.devices.";
      }
      {
        assertion =
          !cfg.domain.enable
          || cfg.domain.vcpuPin == []
          || builtins.length cfg.domain.vcpuPin == cfg.domain.vcpus;
        message = "services.vfioVm.domain.vcpuPin must have one entry per vCPU, or be empty.";
      }
      {
        assertion =
          !cfg.domain.enable
          || cfg.domain.topology.sockets * cfg.domain.topology.cores * cfg.domain.topology.threads == cfg.domain.vcpus;
        message = "services.vfioVm.domain.topology must multiply out to services.vfioVm.domain.vcpus.";
      }
      {
        assertion = !cfg.domain.enable || cfg.domain.pcieRootPorts >= maxGuestBus;
        message = "services.vfioVm.domain.pcieRootPorts (${toString cfg.domain.pcieRootPorts}) is too low: a passthrough device is pinned to guest bus ${toString maxGuestBus}, which needs at least that many root ports.";
      }
    ];

    warnings =
      lib.optional
      (lib.any (device: device.romFile != null && device.romBar == "off") cfg.devices)
      "services.vfioVm: a device sets romFile together with romBar = \"off\", which hides the ROM from the guest and makes the file inert.";

    boot.kernelModules = [
      "vfio"
      "vfio-pci"
      "vfio_iommu_type1"
    ];

    virtualisation.libvirtd = {
      enable = true;

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };

      hooks.qemu.${hookName} = vfioHook;
    };

    programs.virt-manager.enable = true;

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "${startVfio}/bin/${startScriptName}" &&
            subject.isInGroup("libvirtd")) {
          return polkit.Result.YES;
        }
      });
    '';

    users.users.${cfg.user}.extraGroups = [
      "libvirtd"
    ];

    # libvirtd-config is what symlinks the hook into /var/lib/libvirt/hooks, but
    # upstream leaves it a oneshot with RemainAfterExit = no. It is therefore
    # inactive by the time the next rebuild runs, and switch-to-configuration
    # skips inactive units - so edits to the hook silently never reach libvirt
    # until the machine is rebooted. Keeping the unit active after it exits lets
    # the normal restart-on-change handling apply to it.
    systemd.services.libvirtd-config.serviceConfig.RemainAfterExit = true;

    systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart = lib.mkForce "${pkgs.writeShellScript "virt-secret-init-encryption-host-key" ''
      set -euo pipefail
      umask 0077
      ${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 \
        | ${pkgs.systemd}/bin/systemd-creds encrypt --with-key=host --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key
    ''}";

    systemd.services."libvirt-domain-${cfg.vmName}" = mkIf cfg.domain.enable {
      description = "Define the ${cfg.vmName} libvirt domain";
      wantedBy = ["multi-user.target"];
      after = ["libvirtd.service"];
      requires = ["libvirtd.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      # define only replaces the persistent config. A running domain keeps its
      # live definition until it is next started, and NVRAM is left alone.
      script = ''
        ${pkgs.libvirt}/bin/virsh -c qemu:///system define ${domainXml}
      '';
    };

    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      qemu_kvm
      startVfio
      restoreHost
      swtpm
      virt-manager
      virt-viewer
      (makeDesktopItem {
        name = cfg.desktopName;
        desktopName = cfg.desktopDisplayName;
        comment = cfg.desktopComment;
        exec = "${pkgs.polkit}/bin/pkexec ${startVfio}/bin/${startScriptName}";
        icon = cfg.desktopIcon;
        categories = ["System"];
        terminal = false;
      })
    ];
  };
}
