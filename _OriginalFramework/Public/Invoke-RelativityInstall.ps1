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
            $ThrottleLimit = Get-DefaultThrottleLimit

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Validating Install Properties..." -PercentComplete 0.00
            $Instance.ValidateInstallProperties($true)

            $Servers = ($Instance.Servers | Where-Object { $_.IsOnline -eq $true -and $_.Install -eq $true }) #TODO uptime checks should be a part of the Job. The server list could be stale

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Registering PSSessionConfigurations..." -PercentComplete 12.50
            Invoke-PSSessionConfigurationRegistrationJob -Servers $Servers -ThrottleLimit $ThrottleLimit

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Stopping WinRM Services..." -PercentComplete 25.00
            Invoke-StopRemoteServiceJob -Servers $Servers -ThrottleLimit $ThrottleLimit -ServiceName "WinRM"

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Starting WinRM Services..." -PercentComplete 37.50
            Invoke-StartRemoteServiceJob -Servers $Servers -ThrottleLimit $ThrottleLimit -ServiceName "WinRM"

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Staging Response Files..." -PercentComplete 50.00
            Invoke-ResponseFileCreationJob -Servers $Servers -ThrottleLimit $ThrottleLimit
        }
        catch
        {
            Write-Error "An error occurred while staging the Relativity install: $($_.Exception.Message)."
            throw
        }
        finally
        {
            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Unregistering PSSessionConfigurations..." -PercentComplete 62.50
            Invoke-PSSessionConfigurationUnregistrationJob -Servers $Servers -ThrottleLimit $ThrottleLimit

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Stopping WinRM Services..." -PercentComplete 75.00
            Invoke-StopRemoteServiceJob -Servers $Servers -ThrottleLimit $ThrottleLimit -ServiceName "WinRM"

            Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Starting WinRM Services..." -PercentComplete 87.50
            Invoke-StartRemoteServiceJob -Servers $Servers -ThrottleLimit $ThrottleLimit -ServiceName "WinRM"
        }
    }
    End
    {
        Write-Progress -Id 1 -Activity "Staging Relativity Installation Files" -Status "Completed" -Completed
        Write-Verbose "Completed Invoke-RelativityInstall."
    }
}