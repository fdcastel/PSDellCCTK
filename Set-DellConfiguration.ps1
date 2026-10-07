#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess=$true)]
Param (
    [Parameter(Position=0, Mandatory=$true, ParameterSetName='Single')]
    [string]
    $Key,

    [Parameter(Position=1, Mandatory=$true, ParameterSetName='Single')]
    [string]
    $Value,

    [Parameter(Position=0, Mandatory=$true, ParameterSetName='Multiple')]
    [System.Collections.IDictionary]
    $Values,

    [SecureString]
    $SetupPassword
)

. "$PSScriptRoot/CctkHelpers.ps1"

if (-not $Values) {
    $Values = [ordered]@{"$Key" = $Value}
}

Assert-CctkOption -Key @($Values.Keys) -Kind set

if ($SetupPassword -and ($Values.Keys -contains 'ValSetupPwd')) {
    throw 'Use either -SetupPassword or the ValSetupPwd key, not both.'
}

$arguments = @($Values.GetEnumerator() | ForEach-Object { "--$($_.Key)=$($_.Value)" })

if (-not $PSCmdlet.ShouldProcess("BIOS on $env:COMPUTERNAME", "Set $(Hide-CctkSecret $arguments)")) {
    return
}

if ($SetupPassword) {
    # cctk requires the BIOS setup password to be the first argument.
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SetupPassword)
    try {
        $arguments = @("--ValSetupPwd=$([Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr))") + $arguments
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

return Invoke-Cctk $arguments
