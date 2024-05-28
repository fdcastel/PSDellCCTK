#Requires -RunAsAdministrator

#
# Extracts all options from cctk.exe and writes into '.txt' files.
#

$threeColumnValues = & "$PSScriptRoot/bin/cctk.exe" -H |
    Select-String -Pattern '^\s{4}([0-9|A-Z|a-z|\-|\*|\s]{1,32})\s{0,31}([0-9|A-Z|a-z|\-|\*|\s]{1,32})\s{0,31}([0-9|A-Z|a-z|\-|\*|\s]{1,32})\s{0,31}$' | 
        ForEach-Object {
            Write-Output $_.Matches.Groups[1].Value.Trim()
            Write-Output $_.Matches.Groups[2].Value.Trim()
            Write-Output $_.Matches.Groups[3].Value.Trim()
        }

# Read-Only options (ending with '*')
$readOnlyOptions = $threeColumnValues | Select-String -Pattern '^--([0-9|A-Z|a-z|\-]+)\*$' | ForEach-Object { $_.Matches.Groups[1].Value } 

# Read-Write options (not ending with '*')
$readWriteOptions = $threeColumnValues | Select-String -Pattern '^--([0-9|A-Z|a-z|\-]+[^\*])$' | ForEach-Object { $_.Matches.Groups[1].Value }

$readOnlyOptions + $readWriteOptions | Out-File './get-options.txt' -Encoding ascii

$readWriteOptions | Out-File './set-options.txt' -Encoding ascii
