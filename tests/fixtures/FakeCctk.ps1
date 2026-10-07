#
# Stand-in for cctk.exe, used by the tests. Logs its arguments to calls.log and replays recorded output:
#   -H           -> cctk-help.txt (real output of Dell Command | Configure 4.11.1 on an OptiPlex)
#   --HddInfo    -> hddinfo.txt (real output, serial number replaced)
#   --Key        -> the 'Key=...' line from values.txt, or 'Key=Default'
#   --Key=Value  -> 'Key=Value' (like cctk after a change)
#   --Fail       -> an error message containing a password, and exit code 58
#

($args -join ' ') | Add-Content "$PSScriptRoot/calls.log" -WhatIf:$false

if ($args[0] -eq '-H') {
    Get-Content "$PSScriptRoot/cctk-help.txt"
    exit 0
}

if ($args -contains '--Fail') {
    'Error: Setup password is required. SetupPwd=leak'
    exit 58
}

$values = @(Get-Content "$PSScriptRoot/values.txt" -ErrorAction SilentlyContinue)
foreach ($a in $args) {
    if ($a -match '^--ValSetupPwd=') {
        continue
    }

    if ($a -match '^--(\w+)=(.*)$') {
        "$($Matches[1])=$($Matches[2])"
    } elseif ($a -eq '--HddInfo') {
        Get-Content "$PSScriptRoot/hddinfo.txt"
    } elseif ($a -match '^--(\w+)$') {
        $k = $Matches[1]
        $line = $values | Where-Object { $_ -like "$k=*" } | Select-Object -First 1
        if ($line) { $line } else { "$k=Default" }
    }
}

exit 0
