function Invoke-RelativityInstallAWS
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [String]$CopyTo = "C:\RelInstall\",
        [Parameter(Mandatory = $false)]
        [PSCredential]$CredsNetwork,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [String]$ExtractTo = "C:\RelInstall\",
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Instance] $Instance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String]$Source,
        [Switch]$StageOnly
    )

    if(-not $CredsNetwork) { $CredsNetwork = Get-Credential -Message "AD Network Credentials" }


    <# NEW SESSION #>
    $Task = [Plan_New_PSSession]::new($Instance.Servers.Name, $CredsNetwork, $true)
    $Task.WriteProgressActivity = "Creating New Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 1
    $_session = $Task.Run()

    <# INSTALL PRIMARY SQL #>
    <# INSTALL RSS #>

    <# INSTALL RELATIVITY.EXE #>
        <#
            Install-Relativity -Servers $servers
            1   Find the Host with [Role]PrimarySQL
            2   
            3   Remove Host from list.
            4   
        #>
    <# INSTALL PSQ #>
    <# INSTALL RMQ #>
    <# INSTALL DSQ #>

    <# REGISTER WITH RSS #>
    <# INSTALL WEB > AGENT #>
    $Task = [Plan_Remove_PSSession]::new($Instance.Servers.Name, $_session, $true)
    $Task.WriteProgressActivity = "Removing Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 3
    $_result = $Task.Run()

    <# INSTALL INVARIANT #>
    <# INSTALL ANALYTICS #>

    <# HOTFIX #>
    # Invoke-Hotfix

    <# REMOVE SESSION #>
    $Task = [Plan_Remove_PSSession]::new($Instance.Servers.Name, $_session, $true)
    $Task.WriteProgressActivity = "Removing Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 3
    $_result = $Task.Run()


    Write-Host "Session Used: $_session"
}