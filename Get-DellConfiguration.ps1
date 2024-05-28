#Requires -RunAsAdministrator

[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateScript({
        $getOptions = Get-Content "$PSScriptRoot/get-options.txt"
        if ($_ -notin $getOptions) { throw "Invalid option: $_" }
        return $True
    })]
    [string]
    $Key
)

$result = & "$PSScriptRoot/bin/cctk.exe" --$Key
if (-not $?) {
    throw "Error calling cctk (key = '$Key')."
}

if ($result -match '(.*)=(.*)') {
    return $Matches[2]
}
throw "Unexpected result: '$result' (key = '$Key')."
