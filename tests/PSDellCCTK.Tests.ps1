#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0' }

#
# Runs without administrative privileges or a Dell computer: the scripts are copied to a temporary folder,
#   minus '#Requires -RunAsAdministrator', with cctk.exe replaced by fixtures/FakeCctk.ps1.
#

Describe 'PSDellCCTK' {
    BeforeAll {
        $repo = Split-Path $PSScriptRoot -Parent
        $root = Join-Path $TestDrive 'PSDellCCTK'
        New-Item "$root/bin" -ItemType Directory -Force | Out-Null

        foreach ($f in 'CctkHelpers.ps1', 'Get-DellConfiguration.ps1', 'Set-DellConfiguration.ps1', 'Set-DellUnattendedOptions.ps1') {
            (Get-Content "$repo/$f") -notmatch '^#Requires -RunAsAdministrator' -replace 'bin/cctk\.exe', 'bin/cctk.ps1' |
                Set-Content "$root/$f"
        }
        Copy-Item "$PSScriptRoot/fixtures/FakeCctk.ps1" "$root/bin/cctk.ps1"
        Copy-Item "$PSScriptRoot/fixtures/*.txt" "$root/bin"

        . "$root/CctkHelpers.ps1"

        function Get-CctkCall {
            # Arguments of each fake cctk call, one string per call.
            @(Get-Content "$root/bin/calls.log" -ErrorAction SilentlyContinue)
        }

        function Set-CctkValue([string[]]$Line) {
            # Values the fake cctk returns for reads ('Key=Value' lines).
            $Line | Set-Content "$root/bin/values.txt"
        }

        $hddInfo = (Get-Content "$PSScriptRoot/fixtures/hddinfo.txt") -join "`n"
        $password = ConvertTo-SecureString 'p4ss' -AsPlainText -Force
    }

    BeforeEach {
        Remove-Item "$root/bin/calls.log", "$root/bin/values.txt" -ErrorAction SilentlyContinue
    }

    Context 'ConvertFrom-CctkOutput' {
        It 'returns a single ordered dictionary' {
            $r = ConvertFrom-CctkOutput 'A=1', 'B=2'
            $r | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            @($r.Keys) | Should -Be 'A', 'B'
        }

        It 'keeps backslashes' {
            (ConvertFrom-CctkOutput 'Path=C:\new\temp').Path | Should -Be 'C:\new\temp'
        }

        It 'splits on the first "="' {
            (ConvertFrom-CctkOutput 'K=a=b').K | Should -Be 'a=b'
        }

        It 'looks up keys case-insensitively' {
            (ConvertFrom-CctkOutput 'WakeOnLan=x').wakeonlan | Should -Be 'x'
        }

        It 'gives a free-text block to the one requested key missing from the output' {
            $r = ConvertFrom-CctkOutput 'WakeOnLan=x', 'line 1', 'line 2' -Key 'WakeOnLan', 'HddInfo'
            $r.WakeOnLan | Should -Be 'x'
            $r.HddInfo | Should -Be "line 1`nline 2"
        }

        It 'warns instead of guessing when several requested keys are missing' {
            $warnings = ConvertFrom-CctkOutput 'free text' -Key 'HddInfo', 'Mem' 3>&1 |
                Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            "$warnings" | Should -BeLike '*no value for: HddInfo, Mem*'
        }

        It 'warns when a requested key is missing and there is no free text' {
            $warnings = ConvertFrom-CctkOutput 'A=1' -Key 'A', 'B' 3>&1 |
                Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            "$warnings" | Should -BeLike '*no value for: B*'
        }

        It 'neither warns nor fails without -Key' {
            $out = @(ConvertFrom-CctkOutput 'A=1', 'B=2' 2>&1 3>&1)
            $out.Count | Should -Be 1
        }
    }

    Context 'Hide-CctkSecret' {
        It 'masks password arguments' {
            Hide-CctkSecret '--SetupPwd=abc', '--WakeOnLan=x' | Should -Be '--SetupPwd=****', '--WakeOnLan=x'
        }

        It 'masks passwords in the middle of an output line' {
            Hide-CctkSecret 'Error: bad password. SetupPwd=abc' | Should -Be 'Error: bad password. SetupPwd=****'
        }
    }

    Context 'Get-CctkOption (real cctk -H output)' {
        BeforeAll {
            $options = Get-CctkOption
        }

        It 'parses every option' {
            $options.Count | Should -Be 139
        }

        It 'flags read-only options' {
            ($options | Where-Object Name -eq 'SvcTag').ReadOnly | Should -BeTrue
            ($options | Where-Object Name -eq 'WakeOnLan').ReadOnly | Should -BeFalse
        }

        It 'splits names that fill their column' {
            $options.Name | Should -Contain 'BlockBootUntilChasIntrusionClr'
            $options.Name | Should -Contain 'MasterPasswordLockout'
        }

        It 'skips command-line switches and options without "--"' {
            $options.Name | Should -Not -Contain 'help'
            $options.Name | Should -Not -Contain 'infile'
            $options.Name | Should -Not -Contain 'BootOrder'
        }

        It 'lists only the options this model supports' {
            $options.Name | Should -Contain 'AcPwrRcvry'
            $options.Name | Should -Not -Contain 'WakeOnAc'
        }
    }

    Context 'Invoke-Cctk' {
        It 'throws with the exit code and output, with passwords masked' {
            { Invoke-Cctk '--Fail', '--SetupPwd=secret' } | Should -Throw -ExpectedMessage '*exit code = 58*Setup password is required*'
            try { Invoke-Cctk '--Fail', '--SetupPwd=secret' } catch { $message = "$_" }
            $message | Should -Not -BeLike '*secret*'
            $message | Should -Not -BeLike '*leak*'
        }
    }

    Context 'Get-DellConfiguration.ps1' {
        It 'returns several keys in one dictionary' {
            Set-CctkValue 'WakeOnLan=Disabled', 'WarningsAndErr=PromptWrnErr'
            $r = & "$root/Get-DellConfiguration.ps1" WakeOnLan, WarningsAndErr
            $r | Should -BeOfType [System.Collections.IDictionary]
            $r.WakeOnLan | Should -Be 'Disabled'
            $r.WarningsAndErr | Should -Be 'PromptWrnErr'
        }

        It 'returns HddInfo as a text block, alone or with other keys' {
            (& "$root/Get-DellConfiguration.ps1" HddInfo).HddInfo | Should -Be $hddInfo
            $r = & "$root/Get-DellConfiguration.ps1" WakeOnLan, HddInfo
            $r.WakeOnLan | Should -Be 'Default'
            $r.HddInfo | Should -Be $hddInfo
        }

        It 'reads read-only options' {
            (& "$root/Get-DellConfiguration.ps1" SvcTag).Contains('SvcTag') | Should -BeTrue
        }

        It 'rejects options this BIOS does not support, without reading them' {
            { & "$root/Get-DellConfiguration.ps1" WakeOnAc } | Should -Throw -ExpectedMessage "*not supported*WakeOnAc*"
            Get-CctkCall | Should -Be '-H'
        }
    }

    Context 'Set-DellConfiguration.ps1' {
        It 'sets a single value' {
            (& "$root/Set-DellConfiguration.ps1" WakeOnLan LanWlan).WakeOnLan | Should -Be 'LanWlan'
        }

        It 'applies values in the order given' {
            $r = & "$root/Set-DellConfiguration.ps1" ([ordered]@{ WakeOnDock = 'Enabled'; AcPwrRcvry = 'On'; Asset = 'X\Y' })
            (Get-CctkCall)[-1] | Should -Be '--WakeOnDock=Enabled --AcPwrRcvry=On --Asset=X\Y'
            @($r.Keys) | Should -Be 'WakeOnDock', 'AcPwrRcvry', 'Asset'
        }

        It 'rejects unsupported options before applying anything' {
            { & "$root/Set-DellConfiguration.ps1" ([ordered]@{ AcPwrRcvry = 'On'; WakeOnAc = 'Enabled'; Bogus = '1' }) } |
                Should -Throw -ExpectedMessage '*not supported*WakeOnAc, Bogus*'
            Get-CctkCall | Should -Be '-H'
        }

        It 'rejects read-only options' {
            { & "$root/Set-DellConfiguration.ps1" SvcTag X } | Should -Throw -ExpectedMessage '*read-only: SvcTag*'
        }

        It 'changes nothing with -WhatIf, but still validates' {
            & "$root/Set-DellConfiguration.ps1" WakeOnLan LanWlan -SetupPassword $password -WhatIf
            Get-CctkCall | Should -Be '-H'
            { & "$root/Set-DellConfiguration.ps1" WakeOnAc Enabled -WhatIf } | Should -Throw
        }

        It 'passes -SetupPassword first' {
            & "$root/Set-DellConfiguration.ps1" WakeOnLan LanWlan -SetupPassword $password | Out-Null
            (Get-CctkCall)[-1] | Should -Be '--ValSetupPwd=p4ss --WakeOnLan=LanWlan'
        }

        It 'rejects -SetupPassword together with a ValSetupPwd key' {
            { & "$root/Set-DellConfiguration.ps1" @{ ValSetupPwd = 'a'; WakeOnLan = 'x' } -SetupPassword $password } |
                Should -Throw -ExpectedMessage '*not both*'
        }
    }

    Context 'Set-DellUnattendedOptions.ps1' {
        BeforeEach {
            Push-Location $env:SystemRoot    # Must work from any folder.
        }

        AfterEach {
            Pop-Location
        }

        It 'skips settings this BIOS does not support and applies the rest' {
            Set-CctkValue 'EmbSataRaid=Ahci'
            $r = & "$root/Set-DellUnattendedOptions.ps1" -WarningVariable warnings -WarningAction SilentlyContinue
            "$warnings" | Should -Be "Skipping WakeOnAc: not supported by this computer's BIOS."
            (Get-CctkCall)[-1] | Should -Be '--WarningsAndErr=ContWrn --AcPwrRcvry=On --WakeOnLan=LanWlan'
            $r.AcPwrRcvry | Should -Be 'On'
        }

        It 'warns when EmbSataRaid is not Ahci' {
            Set-CctkValue 'EmbSataRaid=Raid'
            & "$root/Set-DellUnattendedOptions.ps1" -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
            "$warnings" | Should -BeLike '*EmbSataRaid is not in "Ahci" mode.*'
        }

        It 'changes nothing with -WhatIf' {
            & "$root/Set-DellUnattendedOptions.ps1" -WhatIf -WarningAction SilentlyContinue
            Get-CctkCall | Where-Object { $_ -like '--WarningsAndErr=*' } | Should -BeNullOrEmpty
        }
    }
}
