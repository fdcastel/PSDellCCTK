# PSDellCCTK

PowerShell scripts to read and change BIOS settings on Dell computers, using Dell's command-line tool `cctk.exe` from [Dell Command | Configure](https://www.dell.com/support/kbdoc/000134806/how-to-install-use-dell-client-configuration-toolkit) (formerly Client Configuration Toolkit).

A copy of `cctk.exe` and its DLLs (Dell Command | Configure **4.11.1**, 64-bit) is included in `bin/`. No separate installation is needed.



## Requirements

- A Dell computer supported by Dell Command | Configure.
- Windows 64-bit.
- Windows PowerShell 5.1 or PowerShell 7.
- An elevated (Run as administrator) PowerShell session. All scripts require administrative privileges.



## Installation

Run in an elevated PowerShell session:

```powershell
iex (iwr 'https://raw.githubusercontent.com/fdcastel/PSDellCCTK/master/bootstrap.ps1' -UseBasicParsing)
```

This downloads the latest `master` into `$env:TEMP\PSDellCCTK-master`, replacing any previous copy there, and changes the current folder to it.

Alternatively, `git clone https://github.com/fdcastel/PSDellCCTK.git`, or download the repository as a zip from GitHub, and run the scripts from that folder.



## Finding options and values

The available options differ between Dell models. To list the options this computer's BIOS supports (read-only ones are marked with `*`):

```powershell
.\bin\cctk.exe -H
```

To show what an option does and which values it accepts (values marked with `+` are supported on this computer):

```powershell
.\bin\cctk.exe -H --AcPwrRcvry

AcPwrRcvry:  Sets the behavior of the system after AC power is lost.

Off - When AC power is restored, the system remains turned off.
On - When AC power is restored, the system turns on.
Last - When the AC power is restored, the system returns to the state it was in when the power was lost.

Arguments: Off+ | Last+ | On+
```



## Usage

### Get-DellConfiguration

```powershell
Get-DellConfiguration.ps1 [-Key] <string[]> [<CommonParameters>]
```

Returns one or more configuration values in an ordered dictionary.

Example:
```powershell
.\Get-DellConfiguration.ps1 'WakeOnLan','WarningsAndErr'

Name                           Value
----                           -----
WakeOnLan                      LanWlan
WarningsAndErr                 ContWrn
```

Some options (e.g. `HddInfo`) return a multi-line text block, which the table display cuts short with `...`. Read the value directly to see all of it:

```powershell
$r = .\Get-DellConfiguration.ps1 HddInfo
$r.HddInfo
```



### Set-DellConfiguration

```powershell
Set-DellConfiguration.ps1 [-Key] <string> [-Value] <string> [-SetupPassword <securestring>] [-WhatIf] [-Confirm] [<CommonParameters>]
Set-DellConfiguration.ps1 [-Values] <IDictionary> [-SetupPassword <securestring>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

Sets one or more configuration values. Returns an ordered dictionary with updated values. Most settings take effect on the next restart.

Before anything is changed, all keys are checked against the options this computer's BIOS supports (as listed by `bin\cctk.exe -H`). Unsupported or read-only keys are rejected. Get-DellConfiguration rejects unsupported keys too, but can read read-only ones.

Values are applied in the order given. Use `[ordered]@{ ... }` when the order matters (a plain `@{ ... }` hash table has no defined order).

If the BIOS has a setup (admin) password, pass it with `-SetupPassword`. Password values are masked in error and `-WhatIf` messages.

Examples:

```powershell
.\Set-DellConfiguration.ps1 -Key 'WakeOnLan' -Value 'LanWlan'

Name                           Value
----                           -----
WakeOnLan                      LanWlan
```

```powershell
.\Set-DellConfiguration.ps1 ([ordered]@{ AcPwrRcvry = 'On' ; WakeOnLan = 'LanWlan' })

Name                           Value
----                           -----
AcPwrRcvry                     On
WakeOnLan                      LanWlan
```

```powershell
.\Set-DellConfiguration.ps1 -Key 'WakeOnLan' -Value 'LanWlan' -SetupPassword (Read-Host -AsSecureString 'BIOS setup password')
```

```powershell
.\Set-DellConfiguration.ps1 -Key 'WakeOnLan' -Value 'LanWlan' -WhatIf

What if: Performing the operation "Set --WakeOnLan=LanWlan" on target "BIOS on MYPC".
```



### Set-DellUnattendedOptions

```powershell
Set-DellUnattendedOptions.ps1 [-SetupPassword <securestring>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

Example preset for computers that must come back on their own after a power loss, with no one at the keyboard. It warns if `EmbSataRaid` is not `Ahci`, then sets:

| Setting | Effect |
|---|---|
| `WarningsAndErr=ContWrn` | The boot continues past POST warnings instead of waiting for a key press. |
| `AcPwrRcvry=On` | The computer turns on when AC power is restored. |
| `WakeOnAc=Enabled` | Same as `AcPwrRcvry=On`, on models that use this name. |
| `WakeOnLan=LanWlan` | The computer can be woken over the network, wired or wireless. |

Settings this computer's BIOS doesn't support are skipped with a warning. On most models only one of `AcPwrRcvry` and `WakeOnAc` exists.



## Third-party software

The files in `bin/` are Dell Command | Configure, which is Dell's software and is subject to Dell's license terms.
