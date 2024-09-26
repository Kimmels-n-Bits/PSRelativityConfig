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

    if (-not $Instance.CredPack.ADCredential()) { Write-Warning "Missing Credentials"; return }

    <# START SESSION #>
    $_session = New-PSSession -Async `
                        -Hosts $Instance.Servers.Name `
                        -Credentials $Instance.CredPack.ADCredential() `
                        -WriteProgressActivity "Creating Sessions" `
                        -WriteProgress
    $s = [String]$_session.Result
    $PlanResults += $_session

    <# STAGE FILES #>
    if(-not $SkipStage)
    {
        $_staging = Copy-Files -Async `
                        -Hosts $Instance.Servers.Name `
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
                        -Servers $Instance.Servers `
                        -Session $s `
                        -Paths $Instance.Paths `
                        -WriteProgressActivity "Runnning Relativity Install Workflow"`
                        -WriteProgress `
                        -Validate `
                        -SkipPreConfig
    
    try {
        $PlanResults += $_installRel
    }
    catch {
        Write-Warning "Variable is type: $($_installRel.GetType())"
        Write-Host $_installRel
    }

    <# REMOVE SESSION #>
    $_session = Remove-PSSession -Async `
                        -Hosts $Instance.Servers.Name `
                        -Session $s `
                        -WriteProgressActivity "Removing Sessions" `
                        -WriteProgress
    $PlanResults += $_session    

    Write-Host "Session Used: $s"
    return $PlanResults
}