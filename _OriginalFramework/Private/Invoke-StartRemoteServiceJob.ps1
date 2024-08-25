function Invoke-StartRemoteServiceJob
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [RelativityServer[]] $Servers,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateRange(1, 128)]
        [Int32] $ThrottleLimit,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ServiceName

    )

    Begin
    {
        Write-Verbose "Started Invoke-StartRemoteServiceJob."
        Write-Progress -Id 2 -ParentId 1 -Activity "Starting Services" -Status "Starting..." -PercentComplete 0.00
    }
    Process
    {
        try
        {
            $JobsToStart = @()
            $JobsStarted = @()
            $JobCount = 0
            $CompletedJobCount = 0
            $FailedJobCount = 0

            foreach ($Server in $Servers)
            {
                $JobsStarted = ($JobsToStart | Get-Job)
                $JobCount = $JobsStarted.Count
                $CompletedJobCount = ($JobsStarted | Where-Object -Property State -eq "Completed").Count
                $FailedJobCount = ($JobsStarted | Where-Object -Property State -eq "Failed").Count
                if ($JobCount -eq 0){ $PercentComplete = 0.00 } else { $PercentComplete = ($CompletedJobCount + $FailedJobCount) / $JobCount * 100 }

                Write-Progress -Id 2 -ParentId 1 -Activity "Starting Services" -Status "Running Jobs. $($JobCount) total. $($CompletedJobCount) completed. $($FailedJobCount) failed." -PercentComplete $PercentComplete

                if (($JobsStarted | Where-Object State -eq "Running").Count -lt $ThrottleLimit)
                {
                    $ScriptBlock = {
                        Param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [String] $ServerName,
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [String] $ServiceName
                        )

                        try
                        {
                            function Start-RemoteService
                            {
                                Param
                                (
                                    [Parameter(Mandatory = $true)]
                                    [ValidateNotNullOrEmpty()]
                                    [String] $ServerName,
                                    [Parameter(Mandatory = $true)]
                                    [ValidateNotNullOrEmpty()]
                                    [String] $ServiceName
                                )

                                $CimSession = $null
                                $Timeout = New-TimeSpan -Minutes 5
                                $Stopwatch = $null
                        
                                try
                                {
                                    if ($ServiceName -eq "WinRM")
                                    {
                                        throw
                                    }
                                    
                                    $CimSession = New-CimSession -ComputerName $ServerName
                                    $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
                                    $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($ServiceName)'"
                        
                                    while ($Service.State -ne "Running" -and $Stopwatch.Elapsed -lt $Timeout)
                                    {
                                        if ($Service.State -ne "Starting")
                                        {
                                            Write-Verbose "Starting the $($ServiceName) service on $($ServerName) using CIM."
                                            $Service | Invoke-CimMethod -MethodName StartService | Out-Null
                                        }
                        
                                        Start-Sleep -Seconds 2
                                        $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($ServiceName)'"
                                    }
                        
                                    if ($Service.State -ne "Running")
                                    {
                                        throw
                                    }
                                }
                                catch
                                {
                                    Write-Verbose "Failed to use CIM for managing the $($ServiceName) service on $($ServerName). Falling back to WMI."
                                    try
                                    {
                                        $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
                                        $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($ServiceName)'" -ComputerName $ServerName
                        
                                        while ($Service.State -ne "Running" -and $Stopwatch.Elapsed -lt $Timeout)
                                        {
                                            if ($Service.State -ne "Starting")
                                            {
                                                Write-Verbose "Starting the $($ServiceName) service on $($ServerName) using WMI."
                                                $Service.StartService() | Out-Null
                                            }
                        
                                            Start-Sleep -Seconds 2
                                            $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($ServiceName)'" -ComputerName $ServerName
                                        }
                        
                                        if ($Service.State -ne "Running")
                                        {
                                            Write-Error "Failed to start the $($ServiceName) service on $($ServerName) within the 10-minute timeout."
                                        }
                                    }
                                    catch
                                    {
                                        Write-Error "An error occurred while ensuring the $($ServiceName) service was running on $($ServerName): $($_.Exception.Message)"
                                        throw
                                    }
                                }
                                finally
                                {
                                    if ($CimSession)
                                    {
                                        Remove-CimSession -CimSession $CimSession
                                    }
                        
                                    if ($Stopwatch)
                                    {
                                        $Stopwatch.Stop()
                                    }
                                }
                            }

                            Start-RemoteService -ServerName $ServerName -ServiceName $ServiceName
                        }
                        catch
                        {
                            Write-Error "an error occurred in the job for $($Server.Name) : $($_.Exception.Message)."
                            throw
                        }
                    }

                    Write-Verbose "Running job to start the '$($ServiceName)' service on $($Server.Name)."
                    $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Server.Name, $ServiceName
                    $JobsToStart += $Job
                }
                else
                {
                    Start-Sleep -Seconds 3
                }
            }

            $JobsStarted = ($JobsToStart | Get-Job)
            $JobCount = $JobsStarted.Count

            while ($JobsStarted.State -contains "Running" -or $JobsStarted.State -contains "NotStarted")
            {
                $CompletedJobCount = ($JobsStarted | Where-Object -Property State -eq "Completed").Count
                $FailedJobCount = ($JobsStarted | Where-Object -Property State -eq "Failed").Count
                if ($JobCount -eq 0) { $PercentComplete = 0.00 } else { $PercentComplete = ($CompletedJobCOunt + $FailedJobCount) / $JobCount * 100 }
                Write-Progress -Id 2 -ParentId 1 -Activity "Starting Services" -Status "Running Jobs. $($JobCount) total. $($CompletedJobCount) completed. $($FailedJobCount) failed." -PercentComplete $PercentComplete
                Start-Sleep -Seconds 3
            }

            foreach ($Job in $JobsStarted)
            {
                if ($Job.State -eq "Failed")
                {
                    $ErrorDetails = $Job.ChildJobs[0].JobStateInfo.Reason
                    Write-Error "An error occurred while processing job $($Job.Id) : $($ErrorDetails)."
                }
            }

            if ($FailedJobCount -gt 0)
            {
                throw "An error occurred while processing one or more jobs."
            }

            return ($JobsStarted | Receive-Job)
        }
        catch
        {
            Write-Error "An error occurred while attempting to start the job(s): $($_.Exception.Message)."
            throw
        }
        finally
        {
            $JobsStarted | Remove-Job
        }
    }
    End
    {
        Write-Progress -Id 2 -ParentId 1 -Activity "Starting Services" -Status "Completed" -Completed
        Write-Verbose "Completed Invoke-StartRemoteServiceJob"
    }
}