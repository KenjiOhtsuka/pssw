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
                    Write-Host ''
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
    while ($Repeat -eq -1 -or $cycle -lt $Repeat) {
        $cycle++
        Write-Host ('--- Timer Cycle #{0} ---' -f $cycle)
        Write-Host "Press 's' to pause/resume, or 'q' to quit."
        $remaining = $totalSeconds
        $running = $true
        $clock = [Diagnostics.Stopwatch]::StartNew()
        $startRemaining = $remaining

        while ($remaining -gt 0) {
            if ($running) {
                $remaining = [math]::Max(0, $startRemaining - $clock.Elapsed.TotalSeconds)
            }
            Write-PSSWTimeLine -Seconds $remaining -Precision $Precision
            $key = Read-PSSWKey
            if ($key -eq 'q') {
                Write-Host 'Timer canceled by user.'
                return
            }
            if ($key -eq 's') {
                if ($running) {
                    $remaining = [math]::Max(0, $startRemaining - $clock.Elapsed.TotalSeconds)
                    $running = $false
                }
                else {
                    $clock = [Diagnostics.Stopwatch]::StartNew()
                    $startRemaining = $remaining
                    $running = $true
                }
            }
            Start-Sleep -Milliseconds $(if ($Precision -gt 2) { 10 } else { 50 })
        }

        Write-PSSWTimeLine -Seconds 0 -Precision $Precision
        if (-not $Mute) {
            try { [Console]::Beep() } catch { [Console]::Write([char]7) }
        }
        Write-Host "Time's up!"
        if ($Repeat -eq -1 -or $cycle -lt $Repeat) { Start-Sleep -Seconds 1 }
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
