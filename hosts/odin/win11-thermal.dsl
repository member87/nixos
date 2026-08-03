/*
 * Supplementary ACPI table adding one passive thermal zone. QEMU emits no
 * thermal zones, so Windows' ACPI thermal driver has nothing to enumerate and
 * the ThermalZoneInformation performance counters come back empty - a state a
 * real machine is never in. This gives the guest a plausible, stable CPU
 * thermal zone (reported ~26 C) so those counters are populated. Added to the
 * guest via `qemu -acpitable file=`.
 */
DefinitionBlock ("", "SSDT", 2, "ALASKA", "TZONE", 0x00000001)
{
    Scope (\_TZ)
    {
        ThermalZone (TZ00)
        {
            Name (_TZP, 0x64)                                  // poll every 10s
            Method (_TMP, 0, Serialized) { Return (0x0BB8) }   // 300.0 K (26.85 C)
            Method (_CRT, 0, Serialized) { Return (0x0F3C) }   // 390.0 K critical
            Method (_PSV, 0, Serialized) { Return (0x0E10) }   // 360.0 K passive trip
            Method (_TC1, 0, Serialized) { Return (0x04) }
            Method (_TC2, 0, Serialized) { Return (0x03) }
            Method (_TSP, 0, Serialized) { Return (0x64) }
        }
    }
}
