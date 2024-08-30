#
# Module manifest for module 'PSRelativityConfig'
#
# Generated by: Jarrod Kimmel
#
# Generated on: 11/22/2023
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'PSRelativityConfig.psm1'

    # Version number of this module.
    ModuleVersion = '0.2.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')

    # ID used to uniquely identify this module
    GUID = '05208826-974f-4e29-a43b-4e88fdff9471'

    # Author of this module
    Author = 'Jarrod Kimmel'

    # Company or vendor of this module
    CompanyName = 'Jarrod Kimmel'

    # Copyright statement for this module
    Copyright = 'Jarrod Kimmel'

    # Description of the functionality provided by this module
    Description = 'A PowerShell module with functions to manage the configuration of Relativity environments.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        # Private
        "$PSScriptRoot\Private\Set-Output.ps1",

        # JobManager
        "$PSScriptRoot\JobManager\Enums.ps1",
        "$PSScriptRoot\JobManager\Task.ps1",
        "$PSScriptRoot\JobManager\Plan.ps1",

        # Tasks
        "$PSScriptRoot\Classes\Tasks\Task_CopyFile.ps1",
        "$PSScriptRoot\Classes\Tasks\Task_HW_Info.ps1",
        "$PSScriptRoot\Classes\Tasks\Task_New_PSSession.ps1",
        "$PSScriptRoot\Classes\Tasks\Task_Remove_PSSession.ps1",
        "$PSScriptRoot\Classes\Tasks\Task_Timer.ps1",
        "$PSScriptRoot\Classes\Tasks\Task_Service.ps1",

        # Plans
        "$PSScriptRoot\Classes\Plans\Plan_Get_HardwareSpecs.ps1",
        "$PSScriptRoot\Classes\Plans\Plan_New_PSSession.ps1",
        "$PSScriptRoot\Classes\Plans\Plan_CopyFiles.ps1",
        "$PSScriptRoot\Classes\Plans\Plan_Remove_PSSession.ps1",
        "$PSScriptRoot\Classes\Plans\Plan_StagingStress.ps1",
        "$PSScriptRoot\Classes\Plans\Plan_Service.ps1",

        # Public
        "$PSScriptRoot\Public\Copy-Files.ps1",
        "$PSScriptRoot\Public\Get-RelativityInstance.ps1",
        "$PSScriptRoot\Public\Invoke-RelativityInstall.ps1",
        "$PSScriptRoot\Public\Invoke-Test1.ps1",
        "$PSScriptRoot\Public\New-PSSession.ps1",
        "$PSScriptRoot\Public\Remove-PSSession.ps1",
        "$PSScriptRoot\Public\Start-Services.ps1",
        "$PSScriptRoot\Public\Stop-Services.ps1"
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        "Copy-Files",
        "Get-RelativityInstance",
        "Invoke-RelativityInstall",
        "Invoke-Test1",
        "New-PSSession",
        "Remove-PSSession",
        "Set-Output",
        "Start-Services",
        "Stop-Services"
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    #FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('relativity')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Kimmels-n-Bits/PSRelativityConfig/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Kimmels-n-Bits/PSRelativityConfig/'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

