function Invoke-RelativityInstallStaging
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [RelativityInstance] $Instance
    )

    Begin
    {
        Write-Verbose "Started Invoke-RelativityInstallStaging."
        Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Starting..." -PercentComplete 0.00
    }
    Process
    {
        try
        {
            $ThrottleLimit = Get-DefaultThrottleLimit

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Staging Response Files..." -PercentComplete 0.00
            Invoke-ResponseFileCreationJob -Servers $Instance.Servers -ThrottleLimit $ThrottleLimit
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
        Write-Verbose "Completed Invoke-RelativityInstallStaging."
    }
}