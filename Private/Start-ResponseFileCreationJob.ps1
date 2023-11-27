function Start-ResponseFileCreationJob
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [RelativityInstance] $Instance
    )

    Begin
    {
        Write-Verbose "Started Start-ResponseFileCreationJob."
    }
    Process
    {
        try
        {
            $Jobs = @()

            foreach ($Server in $Instance.Servers)
            {
                if ($Server.Role -contains "SecretStore" -and $Server.Role.Count -eq 1)
                {
                    Write-Verbose "Skipping SecretStore server: $($Server.Name)."
                }
                else
                {
                    $ScriptBlock = {
                        Param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNull()]
                            [RelativityServer] $Server
                        )

                        try
                        {
                            $ResponseFile = Join-Path -Path $Server.InstallerDirectory -ChildPath "$($Server.Name)_ResponseFile.txt"
                            $ResponseFileContent = $Server.GetResponseFileProperties()

                            $ScriptBlock = {
                                Param
                                (
                                    [Parameter(Mandatory = $true)]
                                    [ValidateNotNullOrEmpty()]
                                    [String] $InstallerDirectory,
                                    
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

                            Invoke-Command -ComputerName $Server.Name -ScriptBlock $ScriptBlock -ArgumentList $Server.InstallerDirectory, $ResponseFile, $ResponseFileContent
                        }
                        catch
                        {
                            Write-Error "An error occurred in the job for $($Server.Name): $($_.Exception.Message)"
                            throw
                        }
                    }

                    $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Server
                    $Jobs += $Job
                }
            }

            return $Jobs
        }
        catch
        {
            Write-Error "An error occurred while attempting to start the response file creation job(s): $($_.Exception.Message)."
            throw
        }
    }
    End
    {
        Write-Verbose "Completed Start-ResponseFileCreationJob."
    }
}