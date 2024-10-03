function Invoke-RelativityInstall
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Instance] $Instance,
        [Switch]$SkipStage,
        [Switch]$SkipPreConfig
    )

    [System.Collections.Generic.List[System.Object]]$PlanResults = @()
    $ServersToInstall = $Instance.Servers | Where-Object { $_.Install -eq $true }
    $RssServers = $Instance.Servers | Where-Object { $_.Role -contains "SecretStore" }

    # Check For duplicates
    $dupes = $Instance.Servers | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }
    if($dupes)
    {
        foreach ($group in $dupes) {
            Write-Error "[$($group.Name)]`tDuplicate Server Found!"
        }
        return
    }

    # Handle Credentials
    if (-not $Instance.CredPack.ADCredential()) { Write-Warning "Missing Credentials"; return }

    <# START SESSION #>
    $_session = New-PSSession -Async `
                        -Hosts $ServersToInstall.Name `
                        -Credentials $Instance.CredPack.ADCredential() `
                        -WriteProgressActivity "Creating Sessions" `
                        -WriteProgress
    $s = [String]$_session.Result
    $PlanResults += $_session

    <# STAGE FILES #>
    if(-not $SkipStage)
    {
        $_staging = Copy-Files -Async `
                        -Hosts $ServersToInstall.Name `
                        -Session $s `
                        -Source $Instance.Paths.Relativity `
                        -CopyTo $Instance.Paths.RelativityStage `
                        -ExtractTo $Instance.Paths.RelativityStage `
                        -Unzip `
                        -WriteProgressActivity "Staging Relativity Installation Files" `
                        -WriteProgress
        $PlanResults += $_staging
    }

    <# START INSTALL RELATIVITY #>
    $_installRel = Install-Relativity -Async `
                        -Servers $ServersToInstall `
                        -RssServers $RssServers `
                        -Session $s `
                        -Paths $Instance.Paths `
                        -WriteProgressActivity "Runnning Relativity Install Workflow"`
                        -WriteProgress `
                        -Validate #` @($true -eq $SkipPreConfig) { -SkipPreConfig }
    $PlanResults += $_installRel


    <# REMOVE SESSION #>
    $_session = Remove-PSSession -Async `
                        -Hosts $ServersToInstall.Name `
                        -Session $s `
                        -WriteProgressActivity "Removing Sessions" `
                        -WriteProgress
    $PlanResults += $_session    

    Write-Host "Session Used: $s"
    return $PlanResults
}