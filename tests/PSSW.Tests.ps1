Describe 'PSSW module' {
    Import-Module (Join-Path $PSScriptRoot '..\PSSW.psd1') -Force

    It 'imports the public commands' {
        (Get-Command Start-PSSWStopwatch).CommandType | Should -Be 'Function'
        (Get-Command Start-PSSWTimer).CommandType | Should -Be 'Function'
    }

    It 'formats hours, minutes, and seconds' {
        InModuleScope PSSW {
            Format-PSSWTime -Seconds 3661.25 -Precision 3 |
                Should -Be '01 h 01 m 01.250 s'
        }
    }

    It 'formats negative values as zero' {
        InModuleScope PSSW {
            Format-PSSWTime -Seconds -1 -Precision 0 |
                Should -Be '00 h 00 m 00 s'
        }
    }

    It 'parses compound durations' {
        InModuleScope PSSW {
            ConvertFrom-PSSWDuration -Duration @('1h', '30m', '5.5s') |
                Should -Be 5405.5
        }
    }

    It 'treats unitless durations as seconds' {
        InModuleScope PSSW {
            ConvertFrom-PSSWDuration -Duration @('10') | Should -Be 10
        }
    }

    It 'rejects invalid durations' {
        InModuleScope PSSW {
            { ConvertFrom-PSSWDuration -Duration @('five') } | Should -Throw
            { ConvertFrom-PSSWDuration -Duration @('0s') } | Should -Throw
        }
    }

    It 'rejects invalid repeat counts before starting a timer' {
        { Start-PSSWTimer -Duration 1s -Repeat 0 } | Should -Throw
        { Start-PSSWTimer -Duration 1s -Repeat -2 } | Should -Throw
    }

    It 'runs the requested number of timer cycles' {
        InModuleScope PSSW {
            Mock Get-PSSWTimerElapsed { 1.0 }
            Mock Read-PSSWKey { $null }
            Mock Start-Sleep {}
            Mock Invoke-PSSWTimerNotification {}

            { Start-PSSWTimer -Duration 1s -Repeat 2 -Mute } | Should -Not -Throw
            Should -Invoke Invoke-PSSWTimerNotification -Exactly 2
            Should -Invoke Read-PSSWKey -Exactly 2
        }
    }

    It 'supports pause and resume without counting paused time' {
        InModuleScope PSSW {
            $elapsedReads = [Collections.Generic.Queue[double]]::new()
            $elapsedReads.Enqueue(0.25)
            $elapsedReads.Enqueue(0.25)
            $elapsedReads.Enqueue(1.0)
            Mock Get-PSSWTimerElapsed { $elapsedReads.Dequeue() }
            $keys = [Collections.Generic.Queue[string]]::new()
            foreach ($key in @('s', 's', 'q')) { $keys.Enqueue($key) }
            Mock Read-PSSWKey {
                if ($keys.Count -gt 0) { return $keys.Dequeue() }
                return 'q'
            }
            Mock Start-Sleep {}

            $output = & { Start-PSSWTimer -Duration 1s -Precision 0 -Mute } 6>&1 |
                ForEach-Object { $_.ToString() }

            ($output -join "`n") | Should -Match 'Timer canceled by user'
            Should -Invoke Get-PSSWTimerElapsed -Exactly 3
            Should -Invoke Read-PSSWKey -Exactly 3
        }
    }

    It 'does not notify when muted' {
        InModuleScope PSSW {
            Mock Get-PSSWTimerElapsed { 1.0 }
            Mock Read-PSSWKey { $null }
            Mock Start-Sleep {}
            Mock Invoke-PSSWTimerNotification {}

            Start-PSSWTimer -Duration 1s -Mute

            Should -Invoke Invoke-PSSWTimerNotification -ParameterFilter { $Mute } -Exactly 1
        }
    }

    It 'quits cleanly without interactive input' {
        InModuleScope PSSW {
            $elapsedReads = [Collections.Generic.Queue[double]]::new()
            $elapsedReads.Enqueue(1.0)
            $elapsedReads.Enqueue(2.0)
            Mock Get-PSSWStopwatchElapsed { $elapsedReads.Dequeue() }
            Mock Read-PSSWKey { 'q' }
            Mock Start-Sleep {}

            $exception = $null
            try {
                $output = & { Start-PSSWStopwatch -Precision 0 } 6>&1 |
                    ForEach-Object { $_.ToString() }
            }
            catch {
                $exception = $_
            }

            $exception | Should -BeNullOrEmpty
            ($output -join "`n") | Should -Match 'Total Time: 00 h 00 m 02 s'
            Should -Invoke Read-PSSWKey -Exactly 1
            Should -Invoke Get-PSSWStopwatchElapsed -Exactly 2
        }
    }

    It 'supports pause, lap, reset, and resume controls' {
        InModuleScope PSSW {
            $keys = [Collections.Generic.Queue[string]]::new()
            foreach ($key in @('l', 's', 'l', 's', 'l', 'q')) {
                $keys.Enqueue($key)
            }

            Mock Read-PSSWKey {
                if ($keys.Count -gt 0) {
                    return $keys.Dequeue()
                }
                return 'q'
            }
            Mock Start-Sleep {}

            $output = & { Start-PSSWStopwatch -Precision 0 } 6>&1 |
                ForEach-Object { $_.ToString() }

            ($output -join "`n") | Should -Match '--- Finished ---'
            ($output -join "`n") | Should -Match 'Total Time:'
            ($output -join "`n") | Should -Not -Match 'Lap #02'
            (($output | Select-String 'Lap #01').Count) | Should -Be 4
            Should -Invoke Read-PSSWKey -Exactly 6
        }
    }

    It 'validates stopwatch precision' {
        { Start-PSSWStopwatch -Precision -1 } | Should -Throw
        { Start-PSSWStopwatch -Precision 16 } | Should -Throw
    }
}
