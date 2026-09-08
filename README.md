# PSSW

PSSW is a PowerShell stopwatch and countdown timer module.

## Status

The module is under development. The current implementation targets PowerShell
5.1 and PowerShell 7+ on Windows, macOS, and Linux.

Run the tests with Pester:

```powershell
Install-Module Pester -MinimumVersion 5.0.0 -Scope CurrentUser
Invoke-Pester ./tests/PSSW.Tests.ps1
```

## Planned commands

```powershell
Import-Module PSSW

Start-PSSWStopwatch
Start-PSSWTimer -Duration 5m, 30s
```

While a command is running, use `s` to pause or resume and `q` to quit. The
stopwatch also uses `l` to record a lap while running, or reset after pausing.

Timer examples:

```powershell
Start-PSSWTimer -Duration 5m, 30s
Start-PSSWTimer -Duration 1m -Repeat 3
Start-PSSWTimer -Duration 10s -Repeat -1 -Mute
```
