<#
.SYNOPSIS
Initiates the creation of response files on multiple servers concurrently.

.DESCRIPTION
The Invoke-ResponseFileCreationJob function creates response files for software installations on specified servers 
in a Relativity environment. It leverages PowerShell jobs to perform these tasks in parallel across multiple servers, 
thus optimizing the process. The function uses the server details and the software requirements to create the necessary 
response files for each server. It also provides progress updates and handles any errors encountered during the process.

.PARAMETER Servers
Specifies an array of RelativityServer objects. Each server in the array will have response files created for the 
specified software installations.

.PARAMETER ThrottleLimit
Specifies the maximum number of concurrent jobs to run. This parameter helps in controlling the load and ensuring 
that the server resources are not overutilized.

.EXAMPLE
$Servers = @($Server1, $Server2, $Server3)
Invoke-ResponseFileCreationJob -Servers $Servers -ThrottleLimit 10

This example initiates the creation of response files on the servers specified in the $Servers array, with a maximum 
of 10 concurrent jobs.

.INPUTS
RelativityServer[]
An array of RelativityServer objects representing the servers on which the response files will be created.

.OUTPUTS
None.

.NOTES
The function requires proper network connectivity and permissions to access the target servers.
#>
function Invoke-ResponseFileCreationJob
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
        Write-Verbose "Started Invoke-ResponseFileCreationJob."
        Write-Progress -Id 2 -ParentId 1 -Activity "Staging Response Files" -Status "Starting..." -PercentComplete 0.00
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
                $SoftwareToInstall = @()
                
                foreach ($Role in $Server.Role)
                {
                    Write-Verbose "Determining if Relativity response file is needed for $($Server.Name)."
                    if ([RelativityServer]::SoftwareRoles[[Software]::Relativity] -contains $Role.ToString())
                    {
                        if (-not $SoftwareToInstall -contains "Relativity")
                        {
                            $SoftwareToInstall += "Relativity"
                        }
                    }

                    Write-Verbose "Determining if Invariant response file is needed for $($Server.Name)."
                    if ([RelativityServer]::SoftwareRoles[[Software]::Invariant] -contains $Role.ToString())
                    {
                        if (-not $SoftwareToInstall -contains "Invariant")
                        {
                            $SoftwareToInstall += "Invariant"
                        }
                    }
                }

                foreach ($Software in $SoftwareToInstall)
                {
                    $JobsStarted = ($JobsToStart | Get-Job)
                    $JobCount = $JobsStarted.Count
                    $CompletedJobCount = ($JobsStarted | Where-Object -Property State -eq "Completed").Count
                    $FailedJobCount = ($JobsStarted | Where-Object -Property State -eq "Failed").Count
                    if ($JobCount -eq 0){ $PercentComplete = 0.00 } else { $PercentComplete = ($CompletedJobCount + $FailedJobCount) / $JobCount * 100 }

                    Write-Progress -Id 2 -ParentId 1 -Activity "Staging Response Files" -Status "Running Jobs. $($JobCount) total. $($CompletedJobCount) completed. $($FailedJobCount) failed." -PercentComplete $PercentComplete

                    if (($JobsStarted | Where-Object -Property -State -eq "Running").Count -lt $ThrottleLimit)
                    {
                        $ScriptBlock = {
                            Param
                            (
                                [Parameter(Mandatory = $true)]
                                [ValidateNotNullOrEmpty()]
                                [String] $ServerName,
                                [Parameter(Mandatory = $true)]
                                [ValidateNotNullOrEmpty()]
                                [String] $InstallerDirectory,
                                [Parameter(Mandatory = $true)]
                                [ValidateNotNullOrEmpty()]
                                [String] $Software,
                                [Parameter(Mandatory = $true)]
                                [ValidateNotNull()]
                                [String[]] $ResponseFileContent
                            )

                            try
                            {
                                $ResponseFile = Join-Path -Path $InstallerDirectory -ChildPath "$($ServerName)_$($Software)Response.txt"

                                $ScriptBlock = {
                                    Param
                                    (
                                        [Parameter(Mandatory = $true)]
                                        [ValidateNotNullOrEmpty()]
                                        [String] $InstallerDirectory,
                                        [Parameter(Mandatory = $true)]
                                        [ValidateNotNullOrEmpty()]
                                        [String] $Software,
                                        [Parameter(Mandatory = $true)]
                                        [ValidateNotNullOrEmpty()]
                                        [String] $ResponseFile,
                                        [Parameter(Mandatory = $true)]
                                        [ValidateNotNull()]
                                        [String[]] $ResponseFileContent
                                    )

                                    try
                                    {
                                        if (-not (Test-Path -Path $InstallerDirectory))
                                        {
                                            New-Item -Path $InstallerDirectory -ItemType Directory | Out-Null
                                        }

                                        $ResponseFileContent | Out-File -FilePath $ResponseFile
                                    }
                                    catch
                                    {
                                        throw
                                    }
                                }

                                Invoke-Command -ComputerName $ServerName -ScriptBlock $ScriptBlock -ArgumentList $InstallerDirectory, $Software, $ResponseFile, $ResponseFileContent
                            }
                            catch
                            {
                                Write-Error "An error occurred in the job for $($Server.Name): $($_.Exception.Message)."
                                throw
                            }
                        }

                        Write-Verbose "Running job to create $($Software) response file on $($Server.Name)."
                        $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Server.Name, $Server.InstallerDirectory, $Software, $Server.GetResponseFileProperties($Software)
                        $JobsToStart += $Job
                    }
                    else
                    {
                        Start-Sleep -Seconds 3
                    }
                }
            }

            $JobsStarted = ($JobsToStart | Get-Job)
            $JobCount = $JobsStarted.Count

            while ($JobsStarted.State -contains "Running" -or $JobsStarted.State -contains "NotStarted")
            {
                $CompletedJobCount = ($JobsStarted | Where-Object -Property State -eq "Completed").Count
                $FailedJobCount = ($JobsStarted | Where-Object -Property State -eq "Failed").Count
                if ($JobCount -eq 0) { $PercentComplete = 0.00 } else { $PercentComplete = ($CompletedJobCount + $FailedJobCount) / $JobCount * 100 }
                Write-Progress -Id 2 -ParentId 1 -Activity "Staging Response Files" -Status "Running Jobs. $($JobCount) total. $($CompletedJobCount) completed. $($FailedJobCount) failed." -PercentComplete $PercentComplete
                Start-Sleep -Seconds 3
            }

            foreach ($Job in $JobsStarted)
            {
                if ($Job.State -eq "Failed")
                {
                    $ErrorDetails = $Job.ChildJobs[0].JobStateInfo.Reason
                    Write-Error "An error occurred while processing job $($Job.Id): $($ErrorDetails)."
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
            Write-Error "An error occurred while attempting to start the response file creation job(s): $($_.Exception.Message)."
            throw
        }
        finally
        {
            $JobsStarted | Remove-Job
        }
    }
    End
    {
        Write-Progress -Id 2 -ParentId 1 -Activity "Staging Response Files" -Status "Completed" -Completed
        Write-Verbose "Completed Invoke-ResponseFileCreationJob."
    }
}