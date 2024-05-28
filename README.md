# PSDellCCTK

Powershell scripts for Dell [Client Configuration Toolkit](https://www.dell.com/support/kbdoc/000134806/how-to-install-use-dell-client-configuration-toolkit).

Binaries included. For Windows 64-bit only.



## Installation

To download all scripts into your `$env:temp` folder:

```powershell
iex (iwr 'https://raw.githubusercontent.com/fdcastel/PSDellCCTK/master/bootstrap.ps1' -UseBasicParsing)
```




## Usage

> **IMPORTANT**: All scripts requires administrative privileges to run.

### Get-DellConfiguration

```powershell
Get-DellConfiguration.ps1 [-Key] <string[]> [<CommonParameters>]
```

Returns one or more configuration values in a hash table.

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
Set-DellConfiguration.ps1 [-Key] <string> [-Value] <string> [<CommonParameters>]
Set-DellConfiguration.ps1 [-Values] <hashtable> [<CommonParameters>]
```

Sets one or more configuration values. Returns a hash table with updated values.

Examples:

```powershell
.\Set-DellConfiguration.ps1 -Key 'WakeOnLan' -Value 'LanWLan'

Name                           Value
----                           -----
WakeOnLan                      LanWlan
```

```powershell
.\Set-DellConfiguration.ps1 @{ AcPwrRcvry = 'On' ; WakeOnAc = 'Enabled' }

Name                           Value
----                           -----
AcPwrRcvry                     On
WakeOnAc                       Enabled
```
