function Invoke-RelativityInstall
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [RelativityInstance] $Instance,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [Switch] $StageOnly
    )

    Begin
    {
        Write-Verbose "Started Invoke-RelativityInstall."
        Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Starting..." -PercentComplete 0.00
    }
    Process
    {
        try
        {
            $Servers = ($Instance.Servers | Where-Object { $_.IsOnline -eq $true -and $_.Install -eq $true })
            $ThrottleLimit = Get-DefaultThrottleLimit

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Validating Install Properties..." -PercentComplete 0.00
            $Instance.ValidateInstallProperties($true)

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Staging Response Files..." -PercentComplete 50.00
            Invoke-ResponseFileCreationJob -Servers $Servers -ThrottleLimit $ThrottleLimit
        }
        catch
        {
            Write-Error "An error occurred while staging the Relativity install: $($_.Exception.Message)."
            throw
        }
    }
    End
    {
        Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Completed" -Completed
        Write-Verbose "Completed Invoke-RelativityInstall."
    }
}