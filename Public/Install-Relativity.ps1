function Install-Relativity
{
    <#
        .DESCRIPTION
            Performs an installation of the relativity.exe installer.

        .FUNCTIONALITY
            [Server].Role will guide this operation.
            [Server].ResponseFileProperties will guide installation parameters.
            [InstallerBundle] will provide remote and local installation paths.
    #>
    param(
        [Switch]$Async,    
        [System.Collections.Generic.List[Server]] $Servers = [System.Collections.Generic.List[Server]]::new(),
        [InstallerBundle]$InstallerBundle = [InstallerBundle]::new(),
        [Switch]$Validate,
        [String]$SessionName
    )


    $Plan = [Plan_Install_Relativity]::new(
        $Servers,
        $InstallerBundle,
        $Validate,
        $Async)
    
    #$Plan.SessionName = $s
    $Plan.Run()

    return $Plan
}