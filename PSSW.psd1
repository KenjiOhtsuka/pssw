@{
    RootModule        = 'PSSW.psm1'
    ModuleVersion     = '0.1.1'
    GUID              = '9d742b80-7d80-4ec2-8e6c-c8d5231e98d9'
    Author            = 'Kenji Ohtsuka'
    CompanyName       = ''
    Copyright         = '(c) Kenji Ohtsuka. All rights reserved.'
    Description       = 'PowerShell stopwatch and countdown timer.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Start-PSSWStopwatch'
        'Start-PSSWTimer'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('PowerShell', 'stopwatch', 'timer', 'productivity')
            LicenseUri = 'https://github.com/KenjiOhtsuka/pssw/blob/main/LICENSE'
            ProjectUri = 'https://github.com/KenjiOhtsuka/pssw'
            ReleaseNotes = 'Maintenance release with the PowerShell stopwatch and countdown timer module version bumped to 0.1.1.'
        }
    }
}
