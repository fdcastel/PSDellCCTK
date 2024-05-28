[CmdletBinding()]
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]
    $Key
)

$result = & ./bin/cctk.exe --$Key
if (-not $?) {
    throw "Error calling cctk (key = '$Key')."
}

if ($result -match '(.*)=(.*)') {
    return $Matches[2]
}
throw "Unexpected result: '$result' (key = '$Key')."
