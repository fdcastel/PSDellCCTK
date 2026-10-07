#
# Helper functions shared by the scripts in this folder.
#   Not meant to be called directly. Dot-source it.
#

function Get-CctkOption {
    # Returns the options supported by this computer's BIOS, as listed by 'cctk -H'.
    #   The list differs between Dell models. Read-only options are listed with a trailing '*'.
    #   Options listed without '--' (e.g. BootOrder) use a different syntax and are not returned.
    (Invoke-Cctk '-H' -Raw) -split '\s+|(?=--)' |
        ForEach-Object {
            if (($_ -match '^--([\w-]+)(\*?)$') -and ($Matches[1] -notin 'help', 'infile', 'logfile', 'outfile')) {
                [PSCustomObject]@{ Name = $Matches[1]; ReadOnly = [bool]$Matches[2] }
            }
        } |
        Sort-Object Name -Unique
}

function Assert-CctkOption {
    # Throws if any key is not supported by this computer's BIOS, or is read-only (for 'set').
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Key,

        [Parameter(Mandatory=$true)]
        [ValidateSet('get', 'set')]
        [string]
        $Kind
    )

    $options = Get-CctkOption
    $unsupported = @($Key | Where-Object { $_ -notin $options.Name })
    if ($unsupported) {
        throw "Option not supported by this computer's BIOS (see 'cctk -H'): $($unsupported -join ', ')"
    }

    if ($Kind -eq 'set') {
        $readOnly = @($options | Where-Object { $_.ReadOnly -and ($_.Name -in $Key) } | ForEach-Object Name)
        if ($readOnly) {
            throw "Option is read-only: $($readOnly -join ', ')"
        }
    }
}

function Hide-CctkSecret {
    # Masks password values (e.g. '--SetupPwd=secret' -> '--SetupPwd=****').
    Param (
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]
        $Text
    )

    $Text -replace '(\w*Pwd)=.*$', '$1=****'
}

function ConvertFrom-CctkOutput {
    # Parses cctk 'name=value' output lines into a single ordered dictionary.
    #   Some options (e.g. HddInfo) print a free-text block instead of 'name=value'. If exactly one
    #   of the requested keys is missing from the output, that block becomes its value.
    Param (
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]
        $Line,

        [string[]]
        $Key
    )

    $result = [ordered]@{}
    $freeText = @()
    foreach ($l in $Line) {
        if ([string]::IsNullOrWhiteSpace($l)) {
            continue
        }

        $i = $l.IndexOf('=')
        if ($i -gt 0) {
            $result[$l.Substring(0, $i).Trim()] = $l.Substring($i + 1).Trim()
        } else {
            $freeText += $l.TrimEnd()
        }
    }

    $missing = @($Key | Where-Object { $_ -and -not $result.Contains($_) })
    if ($freeText -and ($missing.Count -eq 1)) {
        $result[$missing[0]] = $freeText -join "`n"
        $missing = @()
    } else {
        $freeText | ForEach-Object { Write-Verbose "cctk: $_" }
    }

    if ($missing) {
        Write-Warning "cctk returned no value for: $($missing -join ', '). Use -Verbose to see its output."
    }

    return $result
}

function Invoke-Cctk {
    # Calls cctk.exe and returns its output as an ordered dictionary (or as lines, with -Raw). Throws on non-zero exit code.
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Arguments,

        # Keys expected in the output (see ConvertFrom-CctkOutput).
        [string[]]
        $Key,

        [switch]
        $Raw
    )

    # Do not let stderr output become a terminating error (Windows PowerShell 5.1).
    $ErrorActionPreference = 'Continue'

    $output = & "$PSScriptRoot/bin/cctk.exe" @Arguments 2>&1 | ForEach-Object { "$_" }
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Error calling cctk (exit code = $exitCode, arguments = $(Hide-CctkSecret $Arguments)): $((Hide-CctkSecret $output) -join ' ')"
    }

    if ($Raw) {
        return $output
    }

    return ConvertFrom-CctkOutput $output -Key $Key
}
