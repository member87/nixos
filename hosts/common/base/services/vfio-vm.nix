{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.vfioVm;

  inherit (lib) mkEnableOption mkIf mkOption types;

  shellArg = lib.escapeShellArg;
  scriptName = "start-${cfg.vmName}-vfio";
  hookName = "10-${cfg.vmName}-vfio";
  stateFile = "/run/libvirt/${cfg.vmName}-vfio-active";
  logPrefix = "${cfg.vmName}-vfio-hook";

  stopServiceCommands =
    lib.concatMapStringsSep "\n" (service: ''
      log "stopping ${service}"
      "$SYSTEMCTL" stop ${shellArg service} || true
    '')
    cfg.stopServices;

  restartServiceCommands =
    lib.concatMapStringsSep "\n" (service: ''
      log "starting ${service}"
      "$SYSTEMCTL" start ${shellArg service} || true
    '')
    cfg.restartServices;

  bindToVfioCommands =
    lib.concatMapStringsSep "\n" (device: ''
      log "binding ${device.pci} to vfio-pci"
      echo vfio-pci > "/sys/bus/pci/devices/${device.pci}/driver_override"
      unbind_if_bound ${shellArg device.pci}
      echo ${shellArg device.pci} > /sys/bus/pci/drivers/vfio-pci/bind
    '')
    cfg.devices;

  restoreHostDriverCommands =
    lib.concatMapStringsSep "\n" (device: ''
      if [ -e "/sys/bus/pci/devices/${device.pci}/driver" ] && [ "$(basename "$(readlink -f "/sys/bus/pci/devices/${device.pci}/driver")")" = "vfio-pci" ]; then
        log "unbinding ${device.pci} from vfio-pci"
        unbind_if_bound ${shellArg device.pci}
      fi
      echo "" > "/sys/bus/pci/devices/${device.pci}/driver_override"
      bind_to_driver ${shellArg device.pci} ${shellArg device.hostDriver}
    '')
    cfg.devices;

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

  startVfio = pkgs.writeShellScriptBin scriptName ''
    set -euo pipefail

    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run"
    VIRSH="${pkgs.libvirt}/bin/virsh"

    if [ "$($VIRSH -c qemu:///system domstate ${shellArg cfg.vmName})" = "running" ]; then
      exit 0
    fi

    "$SYSTEMD_RUN" --unit=${shellArg "${cfg.vmName}-vfio-start"} \
      "$VIRSH" -c qemu:///system start ${shellArg cfg.vmName}
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = cfg.desktopName;
    desktopName = cfg.desktopDisplayName;
    comment = cfg.desktopComment;
    exec = "${pkgs.polkit}/bin/pkexec ${startVfio}/bin/${scriptName}";
    icon = cfg.desktopIcon;
    categories = ["System"];
    terminal = false;
  };

  vfioHook = pkgs.writeShellScript "${cfg.vmName}-vfio-hook" ''
        set -euo pipefail

        VM_NAME="''${1:-}"
        OPERATION="''${2:-}"
        SUB_OPERATION="''${3:-}"
        DOMAIN_XML="$(cat)"

        VM=${shellArg cfg.vmName}
        PRIMARY_DEVICE=${shellArg cfg.primaryDevice}
        STATE_FILE=${shellArg stateFile}

        SYSTEMCTL="${pkgs.systemd}/bin/systemctl"
        LOGINCTL="${pkgs.systemd}/bin/loginctl"
        MODPROBE="${pkgs.kmod}/bin/modprobe"
        PYTHON="${pkgs.python3}/bin/python3"
        RM="${pkgs.coreutils}/bin/rm"
        SLEEP="${pkgs.coreutils}/bin/sleep"
        TOUCH="${pkgs.coreutils}/bin/touch"

        log() {
          printf '${logPrefix}: %s\n' "$*" >&2
        }

        unbind_if_bound() {
          local dev="$1"

          if [ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]; then
            echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind"
          fi
        }

        bind_to_driver() {
          local dev="$1"
          local driver="$2"

          if [ -d "/sys/bus/pci/drivers/$driver" ]; then
            echo "$dev" > "/sys/bus/pci/drivers/$driver/bind" || true
          fi
        }

        start_passthrough() {
          trap 'log "passthrough start failed; restoring host devices"; stop_passthrough "force"' ERR

          ${stopServiceCommands}

          log "terminating ${cfg.user} user session to release GPU resources"
          "$LOGINCTL" terminate-user ${shellArg cfg.user} || true
          "$SYSTEMCTL" stop ${shellArg "user@${toString cfg.userUid}.service"} || true
          "$SLEEP" ${toString cfg.sessionReleaseDelaySeconds}

          log "unbinding EFI framebuffer if present"
          if [ -e /sys/bus/platform/drivers/efi-framebuffer/unbind ]; then
            echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind || true
          fi

          log "loading vfio-pci"
          "$MODPROBE" vfio-pci

          ${bindToVfioCommands}

          "$TOUCH" "$STATE_FILE"

          trap - ERR
        }

        stop_passthrough() {
          local force="''${1:-}"
          if [ ! -e "$STATE_FILE" ] && [ "$force" != "force" ]; then
            exit 0
          fi

          log "binding passthrough devices back to host drivers"
          ${restoreHostDriverCommands}

          log "rebinding EFI framebuffer if present"
          if [ -e /sys/bus/platform/drivers/efi-framebuffer/bind ]; then
            echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind || true
          fi

          ${restartServiceCommands}

          "$RM" -f "$STATE_FILE"
        }

    has_primary_hostdev() {
      printf '%s' "$DOMAIN_XML" | "$PYTHON" ${hasHostdevScript} "$PRIMARY_DEVICE"
    }

        if [ "$VM_NAME" != "$VM" ]; then
          exit 0
        fi

        case "$OPERATION:$SUB_OPERATION" in
          prepare:begin)
            if ! has_primary_hostdev; then
              log "$VM has no $PRIMARY_DEVICE hostdev yet; skipping passthrough"
              exit 0
            fi

            start_passthrough
            ;;
          release:end)
            stop_passthrough
            ;;
        esac
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
      default = [];
      description = "System services to restart after restoring host drivers.";
    };

    sessionReleaseDelaySeconds = mkOption {
      type = types.int;
      default = 5;
      description = "Seconds to wait after terminating the user session before detaching devices.";
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
    ];

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
            action.lookup("program") == "${startVfio}/bin/${scriptName}" &&
            subject.isInGroup("libvirtd")) {
          return polkit.Result.YES;
        }
      });
    '';

    users.users.${cfg.user}.extraGroups = [
      "libvirtd"
    ];

    systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart = lib.mkForce "${pkgs.writeShellScript "virt-secret-init-encryption-host-key" ''
      set -euo pipefail
      umask 0077
      ${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 \
        | ${pkgs.systemd}/bin/systemd-creds encrypt --with-key=host --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key
    ''}";

    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      qemu_kvm
      desktopItem
      startVfio
      swtpm
      virt-manager
      virt-viewer
    ];
  };
}
