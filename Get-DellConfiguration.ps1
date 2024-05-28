#Requires -RunAsAdministrator

[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateScript({
        $getOptions = Get-Content "$PSScriptRoot/get-options.txt"
        if ($_ -notin $getOptions) { throw "Invalid option: $_" }
        return $True
    })]
    [string[]]
    $Key
)

$arguments = $Key | ForEach-Object { "--$_" }
$result = & "$PSScriptRoot/bin/cctk.exe" $arguments
if (-not $?) {
    throw "Error calling cctk (arguments = $arguments)."
}

return $result | ConvertFrom-StringData
