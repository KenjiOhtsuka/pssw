<#
.SYNOPSIS
    Provides an interactive stopwatch and countdown timer for PowerShell.

.DESCRIPTION
    PSSW exports commands for measuring elapsed time with a stopwatch and
    counting down one or more durations with a timer. Both commands update
    an interactive terminal display and respond to keyboard controls while
    they are running.

.NOTES
    The commands require an interactive terminal. Use S to pause or resume
    either command and Q to quit. The stopwatch also uses L to record a lap
    while running or print the completed run and reset while paused.

.LINK
    Start-PSSWStopwatch

.LINK
    Start-PSSWTimer
#>
Set-StrictMode -Version 3.0

function ConvertFrom-PSSWDuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Duration
    )

    $totalSeconds = 0.0
    foreach ($part in $Duration) {
        if ([string]::IsNullOrWhiteSpace($part)) {
            throw 'Duration parts cannot be empty.'
        }

        $match = [regex]::Match($part.Trim().ToLowerInvariant(), '^([0-9]+(?:\.[0-9]+)?)([hms]?)$')
        if (-not $match.Success) {
            throw "Invalid duration part '$part'. Use values such as 1h, 30m, or 45s."
        }

        $value = [double]::Parse(
            $match.Groups[1].Value,
            [Globalization.CultureInfo]::InvariantCulture
        )
        switch ($match.Groups[2].Value) {
            'h' { $totalSeconds += $value * 3600 }
            'm' { $totalSeconds += $value * 60 }
            default { $totalSeconds += $value }
        }
    }

    if ($totalSeconds -le 0) {
        throw 'Total duration must be greater than zero.'
    }

    return $totalSeconds
}

function Format-PSSWTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double] $Seconds,

        [ValidateRange(0, 15)]
        [int] $Precision = 3
    )

    if ($Seconds -lt 0) {
        $Seconds = 0
    }

    $hours = [math]::Floor($Seconds / 3600)
    $minutes = [math]::Floor(($Seconds % 3600) / 60)
    $remainingSeconds = $Seconds % 60
    $secondsFormat = '00.' + ('0' * $Precision)
    $formattedSeconds = $remainingSeconds.ToString($secondsFormat, [Globalization.CultureInfo]::InvariantCulture)

    if ([double]::Parse($formattedSeconds, [Globalization.CultureInfo]::InvariantCulture) -ge 60) {
        $formattedSeconds = (0).ToString($secondsFormat, [Globalization.CultureInfo]::InvariantCulture)
        $minutes++
    }
    if ($minutes -ge 60) {
        $minutes = 0
        $hours++
    }

    return '{0:00} h {1:00} m {2} s' -f $hours, $minutes, $formattedSeconds
}

<#
.SYNOPSIS
    Starts an interactive stopwatch.

.DESCRIPTION
    Starts a stopwatch that displays elapsed time in an interactive terminal.
    Press S to pause or resume, L to record a lap while running, or Q to
    quit. While paused, press L to print the completed run and reset the
    stopwatch. The final elapsed time and recorded laps are printed when the
    stopwatch quits.

.SYNTAX
    Start-PSSWStopwatch [[-Precision] <Int32>]

.PARAMETER Precision
    Specifies the number of fractional-second digits shown in the display.
    The value must be between 0 and 15. The default is 3.

.EXAMPLE
    Start-PSSWStopwatch

    Starts a stopwatch with three fractional-second digits.

.EXAMPLE
    Start-PSSWStopwatch -Precision 0

    Starts a stopwatch that displays whole seconds.

.INPUTS
    None. You cannot pipe input to this command.

.OUTPUTS
    None. The stopwatch display and summary are written to the host.

.NOTES
    This command requires an interactive terminal. Press S to pause or resume,
    L to record a lap or reset while paused, and Q to quit.
#>
function Start-PSSWStopwatch {
    [CmdletBinding()]
    param(
        [ValidateRange(0, 15)]
        [int] $Precision = 3
    )

    $elapsed = 0.0
    $baseElapsed = 0.0
    $running = $true
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $laps = New-Object System.Collections.Generic.List[string]

    Write-Host "Stopwatch started. Press 's' to pause/resume, 'l' for lap/reset, or 'q' to quit."
    Write-Host ''
    try {
        while ($true) {
            if ($running) {
                $elapsed = $baseElapsed + (Get-PSSWStopwatchElapsed -Clock $clock)
            }
            Write-PSSWTimeLine -Seconds $elapsed -Precision $Precision

            $key = Read-PSSWKey
            if ($key -eq 'q') {
                break
            }
            if ($key -eq 's') {
                if ($running) {
                    $elapsed = $baseElapsed + (Get-PSSWStopwatchElapsed -Clock $clock)
                    $running = $false
                }
                else {
                    $clock = [Diagnostics.Stopwatch]::StartNew()
                    $baseElapsed = $elapsed
                    $running = $true
                }
            }
            elseif ($key -eq 'l') {
                if ($running) {
                    $lap = '  Lap #{0:00}: {1}' -f ($laps.Count + 1), (Format-PSSWTime -Seconds $elapsed -Precision $Precision)
                    [void]$laps.Add($lap)
                    Write-Host $lap
                }
                else {
                    if ($elapsed -gt 0) {
                        Write-Host ''
                        Write-Host '--- Finished ---'
                        Write-Host ('Total Time: {0}' -f (Format-PSSWTime -Seconds $elapsed -Precision $Precision))
                        foreach ($lap in $laps) { Write-Host $lap }
                    }
                    $elapsed = 0.0
                    $laps.Clear()
                }
            }
            Start-Sleep -Milliseconds $(if ($Precision -gt 2) { 10 } else { 50 })
        }
    }
    finally {
        if ($running) {
            $elapsed = $baseElapsed + (Get-PSSWStopwatchElapsed -Clock $clock)
        }
        $clock.Stop()
        Write-Host ''
        if ($elapsed -gt 0 -or $laps.Count -gt 0) {
            Write-Host '--- Finished ---'
            Write-Host ('Total Time: {0}' -f (Format-PSSWTime -Seconds $elapsed -Precision $Precision))
            foreach ($lap in $laps) { Write-Host $lap }
        }
    }
}

function Get-PSSWStopwatchElapsed {
    param(
        [Diagnostics.Stopwatch] $Clock
    )

    return $Clock.Elapsed.TotalSeconds
}

<#
.SYNOPSIS
    Starts an interactive countdown timer.

.DESCRIPTION
    Counts down one or more duration values in an interactive terminal. Each
    duration may use hours (h), minutes (m), or seconds (s); a unitless value
    is interpreted as seconds. Multiple duration values are added together.
    Press S to pause or resume, or Q to cancel. When a cycle finishes, the
    timer displays a completion message and, unless muted, emits an audible
    notification.

.SYNTAX
    Start-PSSWTimer [-Duration] <String[]> [[-Precision] <Int32>] [[-Repeat] <Int32>] [-Mute]

.PARAMETER Duration
    Specifies one or more positive duration values. Values can be written as
    1h, 30m, or 45s; unitless values are treated as seconds. Multiple values
    are added together.

.PARAMETER Precision
    Specifies the number of fractional-second digits shown in the display.
    The value must be between 0 and 15. The default is 3.

.PARAMETER Repeat
    Specifies how many timer cycles to run. The default is 1. Use -1 to repeat
    indefinitely until the user presses Q. The value must be positive or -1.

.PARAMETER Mute
    Suppresses the audible completion notification. The completion message is
    still displayed.

.EXAMPLE
    Start-PSSWTimer -Duration 5m, 30s

    Counts down for five minutes and thirty seconds.

.EXAMPLE
    Start-PSSWTimer -Duration 1m -Repeat 3

    Runs three one-minute countdown cycles.

.EXAMPLE
    Start-PSSWTimer -Duration 10s -Repeat -1 -Mute

    Repeats a silent ten-second countdown until the user presses Q.

.INPUTS
    None. You cannot pipe input to this command.

.OUTPUTS
    None. The timer display and status messages are written to the host.

.NOTES
    This command requires an interactive terminal. Press S to pause or resume
    and Q to cancel the current timer. A duration must be greater than zero.
#>
function Start-PSSWTimer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]] $Duration,

        [ValidateRange(0, 15)]
        [int] $Precision = 3,

        [int] $Repeat = 1,

        [switch] $Mute
    )

    if ($Repeat -eq 0 -or $Repeat -lt -1) {
        throw 'Repeat must be a positive number or -1 for infinite repeat.'
    }

    $totalSeconds = ConvertFrom-PSSWDuration -Duration $Duration
    $cycle = 0
    try {
        while ($Repeat -eq -1 -or $cycle -lt $Repeat) {
            $cycle++
            Write-Host ('--- Timer Cycle #{0} ---' -f $cycle)
            Write-Host "Press 's' to pause/resume, or 'q' to quit."
            $remaining = $totalSeconds
            $running = $true
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $baseRemaining = $remaining
            try {
                while ($remaining -gt 0) {
                    if ($running) {
                        $remaining = [math]::Max(0, $baseRemaining - (Get-PSSWTimerElapsed -Clock $clock))
                    }
                    Write-PSSWTimeLine -Seconds $remaining -Precision $Precision
                    $key = Read-PSSWKey
                    if ($key -eq 'q') {
                        Write-Host 'Timer canceled by user.'
                        return
                    }
                    if ($key -eq 's') {
                        if ($running) {
                            $remaining = [math]::Max(0, $baseRemaining - (Get-PSSWTimerElapsed -Clock $clock))
                            $running = $false
                        }
                        else {
                            $clock = [Diagnostics.Stopwatch]::StartNew()
                            $baseRemaining = $remaining
                            $running = $true
                        }
                    }
                    Start-Sleep -Milliseconds $(if ($Precision -gt 2) { 10 } else { 50 })
                }
                Write-PSSWTimeLine -Seconds 0 -Precision $Precision
                Write-Host ''
                Invoke-PSSWTimerNotification -Mute:$Mute
                Write-Host "Time's up!"
            }
            finally {
                $clock.Stop()
            }

            if ($Repeat -eq -1 -or $cycle -lt $Repeat) {
                Start-Sleep -Seconds 1
            }
        }
    }
    finally {
        Write-Host ''
    }
}

function Get-PSSWTimerElapsed {
    param(
        [Diagnostics.Stopwatch] $Clock
    )

    return $Clock.Elapsed.TotalSeconds
}

function Invoke-PSSWTimerNotification {
    param(
        [switch] $Mute
    )

    if (-not $Mute) {
        try { [Console]::Beep() } catch { [Console]::Write([char]7) }
    }
}

function Read-PSSWKey {
    if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable) {
        return ([Console]::ReadKey($true)).KeyChar.ToString().ToLowerInvariant()
    }
    return $null
}

function Write-PSSWTimeLine {
    param(
        [double] $Seconds,
        [int] $Precision
    )

    Write-Host ("`r{0}" -f (Format-PSSWTime -Seconds $Seconds -Precision $Precision)) -NoNewline
}
