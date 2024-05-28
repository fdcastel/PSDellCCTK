#Requires -RunAsAdministrator

[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true, ParameterSetName='Single')]
    [ValidateScript({
        $setOptions = Get-Content "$PSScriptRoot/set-options.txt"
        if ($_ -notin $setOptions) { throw "Invalid option: $_" }
        return $True
    })]
    [string]
    $Key,

    [Parameter(Position=1, Mandatory=$true, ParameterSetName='Single')]
    [string]
    $Value,

    [Parameter(Position=0, Mandatory=$true, ParameterSetName='Multiple')]
    [hashtable]
    $Values
)

if (-not $Values) {
    $Values = @{"$Key" = $Value}
}

$arguments = $Values.GetEnumerator() | ForEach-Object { "--$($_.Name)=$($_.Value)" }
$result = & "$PSScriptRoot/bin/cctk.exe" $arguments
if (-not $?) {
    throw "Error calling cctk (arguments = $arguments)."
}

return $result | ConvertFrom-StringData
