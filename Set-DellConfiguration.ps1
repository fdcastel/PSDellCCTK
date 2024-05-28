[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Key,

    [Parameter(Position=1, Mandatory=$true)]
    [string]
    $Value
)

$result = & ./bin/cctk.exe "--$Key=$Value"
if (-not $?) {
    throw "Error calling cctk (key = '$Key')."
}

if ($result -match '(.*)=(.*)') {
    return $Matches[2]
}
throw "Unexpected result: '$result' (key = '$Key')."
