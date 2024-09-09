function Invoke-RelativityInstall
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


    $Task = [Plan_New_PSSession]::new($Instance.Servers.Name, $CredsNetwork, $true)
    $Task.WriteProgressActivity = "Creating New Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 1
    $_session = $Task.Run()

    $Task = [Plan_CopyFiles]::new($Instance.Servers.Name, $_session, $Source, $CopyTo, $ExtractTo, $true, $true)
    $Task.WriteProgressActivity = "Staging Relativity Installation Files"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 2
    $_result = $Task.Run()

    $Task = [Plan_Remove_PSSession]::new($Instance.Servers.Name, $_session, $true)
    $Task.WriteProgressActivity = "Removing Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 3
    $_result = $Task.Run()


    Write-Host "Session Used: $_session"
}