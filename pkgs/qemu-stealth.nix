# QEMU with the most obvious "you are running under a hypervisor" fingerprints
# removed, so guests that refuse to run in a VM will boot.
#
# Two kinds of change:
#
#   * A source patch (postPatch) for the FADT Preferred_PM_Profile, which QEMU
#     hardcodes to 0 ("Unspecified"). A real desktop reports 1 ("Desktop"); 0 is
#     a VM tell. This has to be a source change because the value is a
#     compile-time literal with no string to patch in the binary.
#
#   * Length-preserving binary patches (postFixup) of VM-identifying string
#     constants - ACPI OEM ids, the WAET table signature, fw_cfg/pvpanic _HIDs,
#     and the "QEMU HARDDISK" model string. Each replacement is the same byte
#     length as the original, and occurrence counts are asserted, so a QEMU
#     update that moves or drops a marker fails the build loudly instead of
#     silently producing a half-patched binary.
#
# Because of the source patch this rebuilds QEMU from source (a few minutes, and
# again whenever the nixpkgs QEMU bumps). Dropping the postPatch below reverts to
# a fast binary-only patch of the prebuilt QEMU.
{
  python3,
  writeText,
  qemu_kvm,
}: let
  patchScript = writeText "qemu-stealth-patch.py" ''
    import sys

    path = sys.argv[1]
    data = bytearray(open(path, "rb").read())

    # (needle, replacement, expected occurrences, label)
    PATCHES = [
        (b"BOCHS ", b"ALASKA", 1, "ACPI OEM ID"),
        (b"BXPC    ", b"A M I \x00\x00", 1, "ACPI OEM table ID"),
        (b"QEMU0001", b"AMDI0041", 1, "pvpanic _HID"),
        (b"QEMU0002", b"AMDI0040", 1, "fw_cfg _HID"),
        # WAET ("Windows ACPI Emulated Devices Table") only exists under a
        # hypervisor - real firmware never emits it, so its mere presence is a
        # VM tell. Rename the 4-byte table signature so nothing recognises it as
        # WAET; Windows ignores the now-unknown OEM table and QEMU still writes a
        # valid checksum over the renamed header. Costs only the minor WAET timer
        # optimisation hint.
        (b"WAET", b"OEM1", 1, "WAET table signature (VM-only ACPI table)"),
        # The IDE/AHCI model string is built from two overlapping 8-byte movabs
        # immediates, and both hw/ide and hw/scsi/ahci carry a copy - hence two
        # occurrences of each half. Together they spell "QEMU HARDDISK", which
        # becomes "Samsung SSD".
        (b"QEMU HAR", b"Samsung ", 2, "IDE/AHCI model, first immediate"),
        (b"ARDDISK\x00", b"g SSD\x00\x00\x00", 2, "IDE/AHCI model, second immediate"),
    ]

    for needle, replacement, expected, label in PATCHES:
        if len(needle) != len(replacement):
            sys.exit(f"{label}: replacement changes length, this would corrupt the ELF")

        found = data.count(needle)
        if found != expected:
            sys.exit(
                f"{label}: expected {expected} occurrence(s) of {needle!r}, "
                f"found {found}. QEMU changed - revisit this marker."
            )

        offset = 0
        while True:
            at = data.find(needle, offset)
            if at < 0:
                break
            data[at:at + len(needle)] = replacement
            print(f"  patched {label} at 0x{at:x}")
            offset = at + len(needle)

    open(path, "wb").write(data)
  '';
in
  qemu_kvm.overrideAttrs (old: {
    pname = "qemu-stealth";

    # FADT Preferred_PM_Profile: 0 (Unspecified) -> 1 (Desktop). The literal
    # lives in build_fadt() and is unique thanks to its comment.
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace hw/acpi/aml-build.c \
          --replace-fail '0 /* Unspecified */, 1);' '1 /* Desktop */, 1);'
      '';

    # Upstream wraps the emulator with makeBinaryWrapper and keeps the real ELF
    # alongside it as a dotfile; that inner binary carries the strings we patch.
    # fixupOutputHooks (which do the wrapping) run before postFixup, so it is in
    # place here.
    postFixup =
      (old.postFixup or "")
      + ''
        inner="$out/bin/.qemu-system-x86_64-wrapped"
        if [ ! -e "$inner" ]; then
          echo "qemu-stealth: expected a wrapped binary at $inner" >&2
          echo "qemu-stealth: qemu is no longer wrapped, or its layout changed" >&2
          exit 1
        fi

        chmod +w "$inner"
        ${python3}/bin/python3 ${patchScript} "$inner"
        chmod a-w "$inner"
      '';

    meta =
      (old.meta or {})
      // {
        description = "QEMU with VM-identifying ACPI/SMBIOS fingerprints patched out";
      };
  })
