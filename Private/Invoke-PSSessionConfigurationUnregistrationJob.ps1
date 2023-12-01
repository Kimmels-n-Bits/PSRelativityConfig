function Invoke-PSSessionConfigurationUnregistrationJob
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
        [Int32] $ThrottleLimit
    )

    Begin
    {
        Write-Verbose "Started Invoke-PSSessionConfigurationUnregistrationJob."
        Write-Progress -Id 2 -ParentId 1 -Activity "Unregistering PSSessionConfigurations" -Status "Starting..." -PercentComplete 0.00
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

                Write-Progress -Id 2 -ParentId 1 -Activity "Unregistering PSSessionConfigurations" -Status "Running Jobs. $($JobCount) total. $($CompletedJobCount) completed. $($FailedJobCount) failed." -PercentComplete $PercentComplete

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
                            [String] $PSSessionName
                        )

                        try
                        {
                            $ScriptBlock = {
                                Param
                                (
                                    [Parameter(Mandatory = $true)]
                                    [ValidateNotNullOrEmpty()]
                                    [String] $PSSessionName
                                )

                                try
                                {
                                    if ($null -ne (Get-PSSessionConfiguration -Name $PSSessionName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue))
                                    {
                                        Unregister-PSSessionConfiguration -Name $PSSessionName -NoServiceRestart | Out-Null
                                    }
                                }
                                catch
                                {
                                    throw
                                }
                            }

                            Invoke-Command -ComputerName $ServerName -ScriptBlock $ScriptBlock -ArgumentList $PSSessionName
                        }
                        catch
                        {
                            Write-Error "an error occurred in the job for $($Server.Name) : $($_.Exception.Message)."
                            throw
                        }
                    }

                    Write-Verbose "Running job to unregister PSSessionConfiguration on $($Server.Name)."
                    $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Server.Name, $Server.PSSessionName
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
                Write-Progress -Id 2 -ParentId 1 -Activity "Unregistering PSSessionConfigurations" -Status "Running Jobs. $($JobCount) total. $($CompletedJobCount) completed. $($FailedJobCount) failed." -PercentComplete $PercentComplete
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
            Write-Error "An error occurred while attempting to start the PSSessionConfiguration unregistration job(s): $($_.Exception.Message)."
            throw
        }
        finally
        {
            $JobsStarted | Remove-Job
        }
    }
    End
    {
        Write-Progress -Id 2 -ParentId 1 -Activity "Unregistering PSSessionConfigurations" -Status "Completed" -Completed
        Write-Verbose "Completed Invoke-PSSessionConfigurationUnregistrationJob"
    }
}