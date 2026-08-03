#!/usr/bin/env python3
# Generate a raw SMBIOS structure blob (no entry point) for `qemu -smbios file=`.
# QEMU appends these to its own generated tables. We add the structure types
# QEMU never emits, so that Windows' WMI classes (Win32_Fan, Win32_VoltageProbe,
# CIM_TemperatureSensor, Win32_PortConnector, CIM_Slot, ...) return >=1 instance
# instead of the empty result that gives a VM away.
import base64
import struct
import sys

out = bytearray()


def emit(stype, handle, formatted, strings):
    """One SMBIOS structure: 4-byte header + formatted area + string set."""
    length = 4 + len(formatted)
    assert length < 256
    out.extend(bytes([stype, length]))
    out.extend(struct.pack("<H", handle))
    out.extend(formatted)
    if strings:
        for s in strings:
            out.extend(s.encode("ascii") + b"\x00")
        out.append(0)  # extra null terminates the string set
    else:
        out.extend(b"\x00\x00")  # no strings -> double null


# --- Type 7: the three REAL cache structures from this host (byte-identical) ---
CACHE_B64 = (
    "BxsKAAGAAYACgAIQABAAAQYFB4ACAACAAgAATDEgLSBDYWNoZQAABxsLAAGBAQAgACAQAB"
    "AAAQYFCAAgAAAAIAAATDIgLSBDYWNoZQAABxsMAAGCAQCGAIYQABAAAQYFCAAGAIAABgCA"
    "TDMgLSBDYWNoZQAA"
)
out.extend(base64.b64decode(CACHE_B64))

# --- Type 6: Memory Module Information (legacy) -> Win32_MemoryDevice ---
for i, sock in enumerate(["A1", "A2"]):
    fmt = bytes(
        [
            1,  # socket designation -> string 1
            0xFF,  # bank connections (unknown)
            0x0A,  # current speed (ns)
        ]
    )
    fmt += struct.pack("<H", 0x0004)  # current memory type: bit2 = SDRAM-ish
    fmt += bytes(
        [
            0x7D,  # installed size (0x7D = 8 GB, encoded per spec bits)
            0x7D,  # enabled size
            0x00,  # error status
        ]
    )
    emit(6, 0x0600 + i, fmt, [sock])

# --- Type 8: Port Connectors -> Win32_PortConnector, CIM_PhysicalConnector ---
# (internal designator, internal type, external designator, external type, port type)
PORTS = [
    ("J1A1", 0x00, "PS2Mouse", 0x0F, 0x0D),
    ("J1A1", 0x00, "Keyboard", 0x0F, 0x0E),
    ("J2A1", 0x00, "USB1", 0x12, 0x10),
    ("J2A1", 0x00, "USB2", 0x12, 0x10),
    ("J2A2", 0x00, "USB3", 0x12, 0x10),
    ("J2A2", 0x00, "USB4", 0x12, 0x10),
    ("J3A1", 0x00, "USB5", 0x13, 0x10),
    ("J3A1", 0x00, "USB6", 0x13, 0x10),
    ("J3A2", 0x00, "USB-C1", 0x22, 0x10),
    ("J3A2", 0x00, "USB-C2", 0x22, 0x10),
    ("J4A1", 0x00, "LAN", 0x0B, 0x1F),
    ("J5A1", 0x00, "Line-Out", 0x1D, 0x1D),
    ("J5A1", 0x00, "Line-In", 0x1D, 0x1D),
    ("J5A1", 0x00, "Mic-In", 0x1D, 0x1D),
    ("J6A1", 0x00, "HDMI", 0x00, 0xFF),
    ("SATA0", 0x1F, "", 0x00, 0x1C),
    ("SATA1", 0x1F, "", 0x00, 0x1C),
    ("SATA2", 0x1F, "", 0x00, 0x1C),
    ("SATA3", 0x1F, "", 0x00, 0x1C),
    ("J7A1", 0x00, "TPM", 0x00, 0xFF),
]
for i, (intr, intt, extr, extt, ptype) in enumerate(PORTS):
    strings = []
    if intr:
        strings.append(intr)
        int_idx = len(strings)
    else:
        int_idx = 0
    if extr:
        strings.append(extr)
        ext_idx = len(strings)
    else:
        ext_idx = 0
    fmt = bytes([int_idx, intt, ext_idx, extt, ptype])
    emit(8, 0x0800 + i, fmt, strings)

# --- Type 9: System Slots -> Win32_SystemSlot / CIM_Slot ---
# SMBIOS 2.6 layout, length 0x11 (17)
SLOTS = [
    ("PCIE1", 0xB6, 0x0D, 0x03, 0x04, 0x01, 0x00, 0x01),  # PCIe x16, in use
    ("PCIE2", 0xB6, 0x0A, 0x03, 0x03, 0x02, 0x02, 0x00),  # PCIe x4, available
    ("PCIE3", 0xB6, 0x08, 0x03, 0x03, 0x03, 0x03, 0x00),  # PCIe x1
    ("M2_1", 0xB6, 0x0A, 0x03, 0x03, 0x04, 0x04, 0x00),  # M.2
    ("M2_2", 0xB6, 0x0A, 0x04, 0x03, 0x05, 0x05, 0x00),  # M.2 available
    ("PCIE4", 0xB6, 0x08, 0x04, 0x03, 0x06, 0x06, 0x00),  # PCIe x1 available
]
for i, (desig, stype, width, usage, length_e, sid, busno, devfn) in enumerate(SLOTS):
    fmt = bytes([1, stype, width, usage, length_e])
    fmt += struct.pack("<H", sid)
    fmt += bytes([0x0C, 0x00])  # slot characteristics 1 & 2 (PME/3.3V-ish)
    fmt += struct.pack("<H", 0x0000)  # segment group
    fmt += bytes([busno, devfn])
    emit(9, 0x0900 + i, fmt, [desig])

# --- Type 26: Voltage Probes -> Win32_VoltageProbe, CIM_VoltageSensor/Numeric/Sensor ---
# length 0x14 (20): desc, loc/status, max, min, res, tol, acc, oem(dword)
for i, (desc, nominal) in enumerate([("VCORE", 1200), ("+12V", 12000), ("+5V", 5000)]):
    fmt = bytes([1, 0x67])  # description str1; location=motherboard(0x07) status=OK(0x60)
    fmt += struct.pack("<H", int(nominal * 1.1))  # max mV
    fmt += struct.pack("<H", int(nominal * 0.9))  # min mV
    fmt += struct.pack("<H", 1)  # resolution
    fmt += struct.pack("<H", 0x8000)  # tolerance unknown
    fmt += struct.pack("<H", 0x8000)  # accuracy unknown
    fmt += struct.pack("<I", 0)  # oem defined
    emit(26, 0x1A00 + i, fmt, [desc])

# --- Type 27: Cooling Devices -> Win32_Fan ---
# length 0x0F (15): temp-probe-handle, dev-type/status, unit-group, oem, nominal-speed, desc
for i, (desc, speed, tph) in enumerate([("CPU Fan", 1800, 0x1C00), ("Chassis Fan", 1200, 0x1C01)]):
    fmt = struct.pack("<H", tph)  # associated temperature probe handle
    fmt += bytes([0x67, 0x01])  # device type = fan(0x03)+status OK(0x60); cooling unit group
    fmt += struct.pack("<I", 0)  # oem defined
    fmt += struct.pack("<H", speed)  # nominal speed rpm
    fmt += bytes([1])  # description -> string 1
    emit(27, 0x1B00 + i, fmt, [desc])

# --- Type 28: Temperature Probes -> Win32_TemperatureProbe, CIM_TemperatureSensor ---
# length 0x14 (20): desc, loc/status, max, min, res, tol, acc, oem(dword)
for i, (desc, nominal) in enumerate([("CPU Temp", 3500), ("System Temp", 3000), ("VRM Temp", 4000)]):
    fmt = bytes([1, 0x63])  # description str1; location=processor(0x03) status=OK(0x60)
    fmt += struct.pack("<H", 10000)  # max (0.1 degC) = 100C
    fmt += struct.pack("<H", 0)  # min
    fmt += struct.pack("<H", 1)  # resolution
    fmt += struct.pack("<H", 0x8000)  # tolerance
    fmt += struct.pack("<H", 0x8000)  # accuracy
    fmt += struct.pack("<I", 0)  # oem
    emit(28, 0x1C00 + i, fmt, [desc])

# --- Type 20: Memory Device Mapped Address -> Win32_MemoryDevice ---
# QEMU emits type 16/17/19 but never type 20, so Win32_MemoryDevice is empty.
# Reference QEMU's own generated handles (type 17 = 0x1100, type 19 = 0x1300 -
# confirmed by booting the guest) so the mapping resolves. One entry over the
# low memory range is enough for the WMI class to enumerate.
fmt = struct.pack("<I", 0x00000000)  # starting address, KB
fmt += struct.pack("<I", 0x017FFFFF)  # ending address, KB (~24 GiB)
fmt += struct.pack("<H", 0x1100)  # memory device handle (QEMU type 17)
fmt += struct.pack("<H", 0x1300)  # memory array mapped address handle (QEMU type 19)
fmt += bytes([0x01, 0x00, 0x00])  # partition row position, interleave pos, depth
emit(20, 0x1400, fmt, [])

data = bytes(out)
sys.stdout.buffer.write(data)
sys.stderr.write(f"blob: {len(data)} bytes\n")
