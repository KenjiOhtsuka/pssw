# PSSW

PSSW is a PowerShell stopwatch and countdown timer module.

## Requirements and support

- Windows PowerShell 5.1 on Windows
- PowerShell 7.0 or later on Windows, macOS, and Linux
- An interactive terminal for the stopwatch and timer controls

## Installation

Install the released module from the PowerShell Gallery:

```powershell
Install-Module -Name PSSW -Scope CurrentUser
Import-Module PSSW
```

To install a specific version, add `-RequiredVersion <version>` to
`Install-Module`. To update an existing installation, use:

```powershell
Update-Module -Name PSSW
```

For development, clone the repository and import the manifest directly:

```powershell
Import-Module ./PSSW.psd1 -Force
```

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
count or `-1` for infinite repetition; `-Mute` suppresses only the audible
completion alert, while the "Time's up!" message still prints. Press `s` to
pause/resume or `q` to cancel cleanly.

## Publishing

Publishing is intentionally manual. A maintainer can run the
`Publish PowerShell Gallery` workflow with a version, tag, and repository
secret named `PSGALLERY_API_KEY`. The workflow verifies that the tag is
`v<version>` and that the version matches `PSSW.psd1` before publishing. No
API key is stored in the repository.
