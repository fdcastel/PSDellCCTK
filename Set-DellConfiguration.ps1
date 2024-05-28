#Requires -RunAsAdministrator

[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateScript({
        $setOptions = Get-Content "$PSScriptRoot/set-options.txt"
        if ($_ -notin $setOptions) { throw "Invalid option: $_" }
        return $True
    })]
    [string]
    $Key,

    [Parameter(Position=1, Mandatory=$true)]
    [string]
    $Value
)

$result = & "$PSScriptRoot/bin/cctk.exe" "--$Key=$Value"
if (-not $?) {
    throw "Error calling cctk (key = '$Key')."
}

if ($result -match '(.*)=(.*)') {
    return $Matches[2]
}
throw "Unexpected result: '$result' (key = '$Key')."
