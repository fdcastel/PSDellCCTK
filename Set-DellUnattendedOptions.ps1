#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess=$true)]
Param (
    [SecureString]
    $SetupPassword
)

. "$PSScriptRoot/CctkHelpers.ps1"

$result = & "$PSScriptRoot/Get-DellConfiguration.ps1" -Key 'EmbSataRaid'
if ($result.EmbSataRaid -ne 'Ahci') {
    Write-Warning 'EmbSataRaid is not in "Ahci" mode.'
}

# Different Dell models expose the same feature under different names (e.g. AcPwrRcvry and WakeOnAc both
#   turn the system on when AC power is restored). Only the options this computer's BIOS supports are set.
$preset = [ordered]@{
    WarningsAndErr = 'ContWrn'
    AcPwrRcvry = 'On'
    WakeOnAc = 'Enabled'
    WakeOnLan ='LanWlan'
}

$supported = (Get-CctkOption).Name
$values = [ordered]@{}
foreach ($entry in $preset.GetEnumerator()) {
    if ($entry.Key -in $supported) {
        $values[$entry.Key] = $entry.Value
    } else {
        Write-Warning "Skipping $($entry.Key): not supported by this computer's BIOS."
    }
}

& "$PSScriptRoot/Set-DellConfiguration.ps1" -SetupPassword $SetupPassword -Values $values
