# PSSW

PSSW is a PowerShell stopwatch and countdown timer module.

The module targets PowerShell 5.1 and PowerShell 7+ on Windows, macOS, and
Linux.

Run the tests with Pester:

```powershell
Install-Module Pester -MinimumVersion 5.0.0 -Scope CurrentUser
Invoke-Pester ./tests/PSSW.Tests.ps1
```

## Commands

```powershell
Import-Module PSSW

Start-PSSWStopwatch -Precision 3
Start-PSSWTimer -Duration 5m, 30s
```

`-Precision` controls the number of fractional-second digits and accepts values
from 0 through 15. While a command is running, use `s` to pause or resume and
`q` to quit. The stopwatch uses `l` to record a lap while running. Press `l`
while paused to print the completed run and reset the stopwatch for a new run.
The final elapsed time and recorded laps are printed when the stopwatch quits
or is interrupted.

Timer examples:

```powershell
Start-PSSWTimer -Duration 5m, 30s
Start-PSSWTimer -Duration 1m -Repeat 3
Start-PSSWTimer -Duration 10s -Repeat -1 -Mute
```

Timer durations accept hours (`h`), minutes (`m`), seconds (`s`), or unitless
values interpreted as seconds. Multiple values are added together, so
`-Duration 1m, 30s` runs for 90 seconds. `-Repeat` accepts a positive cycle
count or `-1` for infinite repetition; `-Mute` suppresses the completion
notification. Press `s` to pause/resume or `q` to cancel cleanly.
