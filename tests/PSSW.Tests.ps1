Describe 'PSSW module' {
    Import-Module (Join-Path $PSScriptRoot '..\PSSW.psd1') -Force

    It 'imports the public commands' {
        (Get-Command Start-PSSWStopwatch).CommandType | Should Be 'Function'
        (Get-Command Start-PSSWTimer).CommandType | Should Be 'Function'
    }

    It 'formats hours, minutes, and seconds' {
        InModuleScope PSSW {
            Format-PSSWTime -Seconds 3661.25 -Precision 3 |
                Should Be '01 h 01 m 01.250 s'
        }
    }

    It 'formats negative values as zero' {
        InModuleScope PSSW {
            Format-PSSWTime -Seconds -1 -Precision 0 |
                Should Be '00 h 00 m 00 s'
        }
    }

    It 'parses compound durations' {
        InModuleScope PSSW {
            ConvertFrom-PSSWDuration -Duration @('1h', '30m', '5.5s') |
                Should Be 5405.5
        }
    }

    It 'treats unitless durations as seconds' {
        InModuleScope PSSW {
            ConvertFrom-PSSWDuration -Duration @('10') | Should Be 10
        }
    }

    It 'rejects invalid durations' {
        InModuleScope PSSW {
            { ConvertFrom-PSSWDuration -Duration @('five') } | Should Throw
            { ConvertFrom-PSSWDuration -Duration @('0s') } | Should Throw
        }
    }

    It 'rejects invalid repeat counts before starting a timer' {
        { Start-PSSWTimer -Duration 1s -Repeat 0 } | Should Throw
        { Start-PSSWTimer -Duration 1s -Repeat -2 } | Should Throw
    }
}
