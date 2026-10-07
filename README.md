# PSDellCCTK

Powershell scripts for Dell [Client Configuration Toolkit](https://www.dell.com/support/kbdoc/000134806/how-to-install-use-dell-client-configuration-toolkit).

Binaries included. For Windows 64-bit only.



## Installation

To download all scripts into your `$env:temp` folder:

```powershell
iex (iwr 'https://raw.githubusercontent.com/fdcastel/PSDellCCTK/master/bootstrap.ps1' -UseBasicParsing)
```




## Usage

> **IMPORTANT**: All scripts require administrative privileges to run.

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



### Set-DellConfiguration

```powershell
Set-DellConfiguration.ps1 [-Key] <string> [-Value] <string> [-SetupPassword <securestring>] [-WhatIf] [-Confirm] [<CommonParameters>]
Set-DellConfiguration.ps1 [-Values] <IDictionary> [-SetupPassword <securestring>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

Sets one or more configuration values. Returns an ordered dictionary with updated values.

Before anything is changed, all keys are checked against the options this computer's BIOS supports (as listed by `bin\cctk.exe -H`, which differs between Dell models). Unsupported or read-only keys are rejected. Get-DellConfiguration rejects unsupported keys too, but can read read-only ones.

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

Example preset for machines that must come back on their own after a power loss: warns if `EmbSataRaid` is not `Ahci`, then sets `WarningsAndErr=ContWrn`, `AcPwrRcvry=On`, `WakeOnAc=Enabled` and `WakeOnLan=LanWlan`.

`AcPwrRcvry` and `WakeOnAc` are the same feature (turn the system on when AC power is restored) under different names on different Dell models. Settings this computer's BIOS doesn't support are skipped with a warning.
