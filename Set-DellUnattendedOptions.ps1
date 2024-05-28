#Requires -RunAsAdministrator

$sataRaidMode = .\Get-DellConfiguration.ps1 -Key 'EmbSataRaid'
if ($sataRaidMode -ne 'Ahci') {
    Write-Warning 'EmbSataRaid is not in "Ahci" mode.'
} 

.\Set-DellConfiguration.ps1 -Key 'WarningsAndErr' -Value 'ContWrn'

.\Set-DellConfiguration.ps1 -Key 'AcPwrRcvry' -Value 'On'

.\Set-DellConfiguration.ps1 -Key 'WakeOnAc' -Value 'Enabled'

.\Set-DellConfiguration.ps1 -Key 'WakeOnLan' -Value 'LanWlan'
