function Invoke-Test1
{
    param (
        [System.Collections.Generic.List[String]]$Hosts = @(),
        [PSCredential]$Credentials,
        [String]$Source,
        [String]$CopyTo,
        [String]$ExtractTo
    )

    if($Credentials -eq $null)
    {
        $Credentials = Get-Credential -Message "Domain Login"
    }

    $Stress = [Plan_StagingStress]::new($Hosts, $Credentials, $Source, $CopyTo, $ExtractTo, $true)
    $results = $Stress.Run()

    $Stress.Tasks | ForEach-Object {
        Write-Host "[$_.Name] Completed $($_.Progress())%. Time ($($_.Runtime))"
    }
    Write-Host "Total Completion: $($Stress.Progress())" -ForegroundColor Yellow
    Write-Host "Closing Status: $($Stress.Status)" -ForegroundColor Yellow
    return $Stress
}