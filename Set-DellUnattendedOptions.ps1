#Requires -RunAsAdministrator

$result = .\Get-DellConfiguration.ps1 -Key 'EmbSataRaid'
if ($result.Values[0] -ne 'Ahci') {
    Write-Warning 'EmbSataRaid is not in "Ahci" mode.'
} 

.\Set-DellConfiguration.ps1 -Values @{
    WarningsAndErr = 'ContWrn'
    AcPwrRcvry = 'On'
    WakeOnAc = 'Enabled'
    WakeOnLan ='LanWlan'
}
