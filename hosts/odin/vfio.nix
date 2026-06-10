{
  lib,
  pkgs,
  ...
}: let
  startWin11Vfio = pkgs.writeShellScriptBin "start-win11-vfio" ''
    set -euo pipefail

    SYSTEMCTL="${pkgs.systemd}/bin/systemctl"
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run"
    VIRSH="${pkgs.libvirt}/bin/virsh"
    BASH="${pkgs.bash}/bin/bash"

    if [ "$($VIRSH -c qemu:///system domstate win11)" = "running" ]; then
      exit 0
    fi

    # "$SYSTEMCTL" stop win11-vfio-recover.timer win11-vfio-recover.service \
    #   win11-vfio-reboot-fallback.timer win11-vfio-reboot-fallback.service 2>/dev/null || true
    #
    # "$SYSTEMD_RUN" --unit=win11-vfio-recover --on-active=300 \
    #   "$BASH" -lc "${pkgs.libvirt}/bin/virsh -c qemu:///system destroy win11 || true; ${pkgs.systemd}/bin/systemctl start greetd.service || true; ${pkgs.systemd}/bin/systemctl stop win11-vfio-reboot-fallback.timer win11-vfio-reboot-fallback.service 2>/dev/null || true"
    #
    # "$SYSTEMD_RUN" --unit=win11-vfio-reboot-fallback --on-active=600 \
    #   ${pkgs.systemd}/bin/systemctl reboot

    "$SYSTEMD_RUN" --unit=win11-vfio-start \
      "$VIRSH" -c qemu:///system start win11
  '';

  startWin11Desktop = pkgs.makeDesktopItem {
    name = "windows";
    desktopName = "Windows";
    comment = "Start the Windows 11 gaming VM with GPU passthrough";
    exec = "${pkgs.polkit}/bin/pkexec ${startWin11Vfio}/bin/start-win11-vfio";
    icon = "windows";
    categories = ["System"];
    terminal = false;
  };

  win11GpuHook = pkgs.writeShellScript "win11-vfio-hook" ''
            set -euo pipefail

            VM_NAME="''${1:-}"
            OPERATION="''${2:-}"
            SUB_OPERATION="''${3:-}"
            DOMAIN_XML="$(cat)"

            GPU="0000:03:00.0"
            GPU_AUDIO="0000:03:00.1"
    STATE_FILE="/run/libvirt/win11-vfio-active"

    SYSTEMCTL="${pkgs.systemd}/bin/systemctl"
    LOGINCTL="${pkgs.systemd}/bin/loginctl"
    MODPROBE="${pkgs.kmod}/bin/modprobe"
    PYTHON="${pkgs.python3}/bin/python3"
            RM="${pkgs.coreutils}/bin/rm"
            SLEEP="${pkgs.coreutils}/bin/sleep"
            TOUCH="${pkgs.coreutils}/bin/touch"

            log() {
              printf 'win11-vfio-hook: %s\n' "$*" >&2
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
      trap 'log "passthrough start failed; restoring host GPU"; stop_passthrough "force"' ERR

      log "stopping greetd before detaching GPU"
      "$SYSTEMCTL" stop greetd.service || true
      "$SLEEP" 1

      log "stopping services that may touch the host GPU"
      "$SYSTEMCTL" stop openrgb.service || true

      log "terminating jack user session to release amdgpu"
      "$LOGINCTL" terminate-user jack || true
      "$SYSTEMCTL" stop user@1000.service || true
      "$SLEEP" 5

      log "unbinding EFI framebuffer if present"
      if [ -e /sys/bus/platform/drivers/efi-framebuffer/unbind ]; then
        echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind || true
      fi

              log "loading vfio-pci"
              "$MODPROBE" vfio-pci

              for dev in "$GPU" "$GPU_AUDIO"; do
                log "binding $dev to vfio-pci"
                echo vfio-pci > "/sys/bus/pci/devices/$dev/driver_override"
                unbind_if_bound "$dev"
                echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
              done

              "$TOUCH" "$STATE_FILE"

              trap - ERR
            }

            stop_passthrough() {
              local force="''${1:-}"
              if [ ! -e "$STATE_FILE" ] && [ "$force" != "force" ]; then
                exit 0
              fi

              for dev in "$GPU" "$GPU_AUDIO"; do
                if [ -e "/sys/bus/pci/devices/$dev/driver" ] && [ "$(basename "$(readlink -f "/sys/bus/pci/devices/$dev/driver")")" = "vfio-pci" ]; then
                  log "unbinding $dev from vfio-pci"
                  unbind_if_bound "$dev"
                fi
                echo "" > "/sys/bus/pci/devices/$dev/driver_override"
              done

              log "binding GPU back to host drivers"
              bind_to_driver "$GPU" amdgpu
              bind_to_driver "$GPU_AUDIO" snd_hda_intel

              log "rebinding EFI framebuffer if present"
              if [ -e /sys/bus/platform/drivers/efi-framebuffer/bind ]; then
                echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind || true
              fi

              log "starting greetd"
              "$SYSTEMCTL" start greetd.service || true

              "$RM" -f "$STATE_FILE"
            }

            has_gpu_hostdev() {
              printf '%s' "$DOMAIN_XML" | "$PYTHON" -c '
    import sys
    import xml.etree.ElementTree as ET

    def pci_num(value):
        if value is None:
            return None
        return int(value, 0)

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

        if (pci_num(address.get("domain")), pci_num(address.get("bus")), pci_num(address.get("slot")), pci_num(address.get("function"))) == (0, 3, 0, 0):
            sys.exit(0)

    sys.exit(1)
        '
            }

            if [ "$VM_NAME" != "win11" ]; then
              exit 0
            fi

            case "$OPERATION:$SUB_OPERATION" in
              prepare:begin)
                if ! has_gpu_hostdev; then
                  log "win11 has no 03:00.0 hostdev yet; skipping passthrough"
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

    hooks.qemu = {
      "10-win11-vfio" = win11GpuHook;
    };
  };

  programs.virt-manager.enable = true;

  users.users.jack.extraGroups = [
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
    startWin11Desktop
    startWin11Vfio
    swtpm
    virt-manager
    virt-viewer
  ];
}
