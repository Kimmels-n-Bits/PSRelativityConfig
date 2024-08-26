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

    [System.Collections.Generic.List[Int32]]$_total = @()
    $Stress.Tasks | ForEach-Object {
        $_prog = $_.Progress()
        $_total.Add($_prog)
        Write-Host "[$_.Name] Completed $($_prog)%. Time ($($_.Runtime))"
    }
    Write-Host "Total Completion: $($Stress.Progress())%" -ForegroundColor Yellow
    Write-Host "Closing Status: $($Stress.Status)" -ForegroundColor Yellow
    return $Stress
}