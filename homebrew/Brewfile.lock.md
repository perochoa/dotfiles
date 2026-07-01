# Brewfile Lock Notes

> [!IMPORTANT]
> **TL;DR:** `homebrew/Brewfile` tracks reusable tooling only. Machine-specific or preference-heavy apps are intentionally excluded to keep replication stable.

## Intentionally excluded categories

1. Hardware-specific drivers and utilities.
2. Personal productivity apps that vary by machine role.
3. One-off experiment tools not needed across all devices.
4. Organization-restricted software installed by MDM.

## How to treat additions

1. Add package only if it is needed across most of your machines.
2. Prefer formulae/casks that are stable and publicly resolvable.
3. Avoid adding credentialed taps unless required.
