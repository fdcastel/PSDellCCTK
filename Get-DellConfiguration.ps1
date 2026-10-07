#Requires -RunAsAdministrator

[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [string[]]
    $Key
)

. "$PSScriptRoot/CctkHelpers.ps1"

Assert-CctkOption -Key $Key -Kind get

$arguments = $Key | ForEach-Object { "--$_" }
return Invoke-Cctk $arguments -Key $Key
