#!/usr/bin/env python3
# Emit a WSMT (Windows SMM Security Mitigations Table). Real UEFI boards ship
# one; QEMU does not, and its absence is used as a VM signal. This is a static
# ACPI data table (not AML), so we build the 36-byte header + 4-byte flags by
# hand and fix up the checksum, then hand it to the guest via `qemu -acpitable`.
import struct
import sys

SIG = b"WSMT"
LENGTH = 40
REVISION = 1
OEM_ID = b"ALASKA"
OEM_TABLE_ID = b"A M I \x00\x00"
OEM_REVISION = 1
CREATOR_ID = b"AMI "
CREATOR_REVISION = 0x20260408

# Protection flags: FIXED_COMM_BUFFERS | COMM_BUFFER_NESTED_PTR_PROTECTION |
# SYSTEM_RESOURCE_PROTECTION - what a locked-down real firmware advertises.
PROTECTION_FLAGS = 0x00000007

header = struct.pack(
    "<4sIBB6s8sI4sI",
    SIG,
    LENGTH,
    REVISION,
    0,  # checksum placeholder
    OEM_ID,
    OEM_TABLE_ID,
    OEM_REVISION,
    CREATOR_ID,
    CREATOR_REVISION,
)
table = bytearray(header + struct.pack("<I", PROTECTION_FLAGS))
table[9] = (256 - (sum(table) % 256)) % 256  # ACPI checksum: bytes sum to 0 mod 256

sys.stdout.buffer.write(bytes(table))
