[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String[]] $Computers,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.IO.FileInfo] $ErlangInstallerPath,
    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [String] $LocalStagingPath = "C:\PSRelativityConfig",
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String] $PrimaryNode,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.IO.FileInfo] $RabbitMqCaCertPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.IO.FileInfo] $RabbitMqCertKeyPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.IO.FileInfo] $RabbitMqCertPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [PSCredential] $RabbitMqCredential,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.IO.FileInfo] $RabbitMqInstallerPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [PSCredential] $ServiceAccountCredential
)

#region Copy-File
function Copy-File
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String] $Path,
        [Parameter(Mandatory = $true)]
        [String] $Destination
    )

    if (Test-Path -Path $Destination)
    {
        Write-Verbose "File exists at destination, comparing hashes"
        $SourceFileHash = Get-FileHash -Path $Path
        $DestinationFileHash = Get-FileHash -Path $Destination

        if ($SourceFileHash.Hash -ne $DestinationFileHash.Hash)
        {
            Write-Verbose "File hash values do not match, replacing destination file"
            Remove-Item -Path $Destination -Force
            Copy-Item -Path $Path -Destination $Destination -Force
        }
        else
        {
            Write-Verbose "File hash values match, not copying file"
        }
    }
    else
    {
        Write-Verbose "Copying file to destination"
        Copy-Item -Path $Path -Destination $Destination -Force
    }
}
#endregion Copy-File

#region Grant-LogonAsService
function Grant-LogonAsService
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String] $Computer,
        [Parameter(Mandatory = $true)]
        [PSCredential] $ServiceAccountCredential
    )

    $ScriptBlock = {
        [CmdletBinding()]
        Param
        (
        )

        $VerbosePreference = $using:VerbosePreference

        $TempPath = [Environment]::GetEnvironmentVariable("TEMP", "User")
        Write-Output $TempPath
    }

    $TempPath = Invoke-Command `
        -ComputerName $Computer `
        -Credential $ServiceAccountCredential `
        -ScriptBlock $ScriptBlock

    if (-not [String]::IsNullOrEmpty($TempPath))
    {
        Write-Verbose "TEMP: $($TempPath)"

        $SecurityTemplatePath = Join-Path -Path $TempPath -ChildPath "SecurityTemplate.inf"
        $SecurityDatabasePath = Join-Path -Path $TempPath -ChildPath "SecurityDB.sdb"
        $SecurityEditLogPath = Join-Path -Path $TempPath -ChildPath "SecurityEditLog.log"

        $ScriptBlock = {
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory = $true)]
                [PSCredential] $ServiceAccountCredential,
                [Parameter(Mandatory = $true)]
                [String] $SecurityTemplatePath,
                [Parameter(Mandatory = $true)]
                [String] $SecurityDatabasePath,
                [Parameter(Mandatory = $true)]
                [String] $SecurityEditLogPath
            )

            $VerbosePreference = $using:VerbosePreference

            Write-Verbose "Retrieving SID for $($ServiceAccountCredential.UserName)"
            $ServiceAccountObject = [Security.Principal.NTAccount]::New($ServiceAccountCredential.UserName)
            $ServiceAccountSid = ($ServiceAccountObject.Translate([Security.Principal.SecurityIdentifier])).Value
            Write-Verbose "SID: $($ServiceAccountSid)"

            Write-Verbose "Exporting current security settings to $($SecurityTemplatePath)"
            secedit /export /cfg $SecurityTemplatePath /quiet

            try
            {
                Write-Verbose "Reading current security settings"
                $SecurityTemplateContent = Get-Content -Path $SecurityTemplatePath

                $ServiceLogonRight = $SecurityTemplateContent | 
                    Where-Object { $_ -match "^SeServiceLogonRight\s*=\s*.*" }

                if (-not [String]::IsNullOrEmpty($ServiceLogonRight) -and
                    $ServiceLogonRight -notmatch [Regex]::Escape($ServiceAccountSid))
                {
                    $ModifiedRight = "$($ServiceLogonRight.TrimEnd()),*$($ServiceAccountSid)"
                    $SecurityTemplateContent = $SecurityTemplateContent `
                        -replace [Regex]::Escape($ServiceLogonRight), $ModifiedRight

                    $SecurityTemplateContent | Set-Content -Path $SecurityTemplatePath

                    secedit /import /db $SecurityDatabasePath /cfg $SecurityTemplatePath
                    secedit /configure /db $SecurityDatabasePath /log $SecurityEditLogPath /quiet

                    gpupdate /force | Out-Null

                    Write-Verbose "Granted $($ServiceAccountCredential.UserName) the 'Log on as a service' right"
                }
                else
                {
                    Write-Verbose "$($ServiceAccountCredential.UserName) already has the 'Log on as a service' right"
                }
            }
            catch
            {
                throw
            }
            finally
            {
                Remove-Item -Path $SecurityTemplatePath -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $SecurityDatabasePath -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $SecurityEditLogPath -Force -ErrorAction SilentlyContinue
            }
        }

        [Object[]] $ArgumentList = @()
        $ArgumentList += $ServiceAccountCredential
        $ArgumentList += $SecurityTemplatePath
        $ArgumentList += $SecurityDatabasePath
        $ArgumentList += $SecurityEditLogPath

        Invoke-Command `
            -ComputerName $Computer `
            -Credential $ServiceAccountCredential `
            -ScriptBlock $ScriptBlock `
            -ArgumentList $ArgumentList
    }
    else
    {
        Write-Verbose "TEMP: (null)"
        throw "Could not retrieve temp location for $($ServiceAccountCredential.UserName)"
    }
}
#endregion Grant-LogonAsService

#region Install-Erlang
function Install-Erlang
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String[]] $Computers,
        [Parameter(Mandatory = $true)]
        [PSCredential] $ServiceAccountCredential,
        [Parameter(Mandatory = $true)]
        [String] $LocalStagingPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $ErlangInstallerPath
    )

    foreach ($Computer in $Computers)
    {
        Write-Verbose "Working on computer: $($Computer)"

        $RemoteStagingPath = "\\$($Computer)\$($LocalStagingPath -replace ":", "`$")"

        if (-not (Test-Path -Path $RemoteStagingPath))
        {
            Write-Verbose "Creating directory: $($RemoteStagingPath)"
            New-Item -Path $RemoteStagingPath -ItemType Directory -Force | Out-Null
        }

        $ScriptBlock = {
            [CmdletBinding()]
            Param
            (
            )

            $VerbosePreference = $using:VerbosePreference

            $ErlangRegistryPath = "HKLM:\SOFTWARE\Wow6432Node\Ericsson\Erlang"
            $ErlangInstallPath = $null

            if (Test-Path -Path $ErlangRegistryPath)
            {
                Write-Verbose "Erlang registry path exists, retrieving Erlang install path"
                $ErlangInstallPath = ((Get-ChildItem -Path $ErlangRegistryPath)[0] | 
                        Get-ItemProperty)."(default)"
                Write-Verbose "Erlang install path: $($ErlangInstallPath)"
            }
            else
            {
                Write-Verbose "Erlang install path: (null)"
            }

            Write-Output $ErlangInstallPath
        }

        $ErlangInstallPath = Invoke-Command `
            -ComputerName $Computer `
            -Credential $ServiceAccountCredential `
            -ScriptBlock $ScriptBlock

        if ([String]::IsNullOrEmpty($ErlangInstallPath))
        {
            Write-Verbose "Erlang install path does not exist, preparing to install Erlang"

            $LocalInstallerPath = Join-Path -Path $LocalStagingPath -ChildPath $ErlangInstallerPath.Name
            $RemoteInstallerPath = Join-Path -Path $RemoteStagingPath -ChildPath $ErlangInstallerPath.Name

            Copy-File -Path $ErlangInstallerPath.FullName -Destination $RemoteInstallerPath

            $ScriptBlock = {
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $true)]
                    [String] $LocalInstallerPath
                )

                $VerbosePreference = $using:VerbosePreference

                $ErlangRegistryPath = "HKLM:\SOFTWARE\Wow6432Node\Ericsson\Erlang"

                Write-Verbose "Installing Erlang"
                $Result = Start-Process -FilePath $LocalInstallerPath -ArgumentList "/S" -PassThru | Wait-Process
                Write-Verbose "Erlang installation successful"
                $ErlangInstallPath = ((Get-ChildItem -Path $ErlangRegistryPath)[0] | 
                        Get-ItemProperty)."(default)"
                Write-Verbose "Erlang install path: $($ErlangInstallPath)"
                Write-Output $ErlangInstallPath
            }

            $ErlangInstallPath = Invoke-Command `
                -ComputerName $Computer `
                -Credential $ServiceAccountCredential `
                -ScriptBlock $ScriptBlock `
                -ArgumentList @($LocalInstallerPath)
        }

        if (-not [String]::IsNullOrEmpty($ErlangInstallPath))
        {
            Write-Verbose "Erlang install path exists, validating ERLANG_HOME environment variable"
            $ScriptBlock = {
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $true)]
                    [String] $ErlangInstallPath
                )

                $VerbosePreference = $using:VerbosePreference

                $ErlangHomeValue = [Environment]::GetEnvironmentVariable("ERLANG_HOME", "Machine")

                if ([String]::IsNullOrEmpty($ErlangHomeValue))
                {
                    Write-Verbose "ERLANG_HOME environment variable is not set, setting environment variable"
                    [Environment]::SetEnvironmentVariable("ERLANG_HOME", $ErlangInstallPath, "Machine")
                    $ErlangHomeValue = [Environment]::GetEnvironmentVariable("ERLANG_HOME", "Machine") 
                }

                Write-Verbose "ERLANG_HOME: $($ErlangHomeValue)"
                Write-Output $ErlangHomeValue
            }

            $ErlangHomeValue = Invoke-Command `
                -ComputerName $Computer `
                -Credential $ServiceAccountCredential `
                -ScriptBlock $ScriptBlock `
                -ArgumentList @($ErlangInstallPath)
        }

        if ([String]::IsNullOrEmpty($ErlangInstallPath) -or [String]::IsNullOrEmpty($ErlangHomevalue))
        {
            throw "Erlang installation was not able to be validated"
        }
    }
}
#endregion Install-Erlang

#region Install-RabbitMq
function Install-RabbitMq
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String[]] $Computers,
        [Parameter(Mandatory = $true)]
        [PSCredential] $ServiceAccountCredential,
        [Parameter(Mandatory = $true)]
        [String] $LocalStagingPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqInstallerPath
    )

    foreach ($Computer in $Computers)
    {
        Write-Verbose "Working on computer: $($Computer)"

        $RemoteStagingPath = "\\$($Computer)\$($LocalStagingPath -replace ":", "`$")"

        if (-not (Test-Path -Path $RemoteStagingPath))
        {
            Write-Verbose "Creating directory: $($RemoteStagingPath)"
            New-Item -Path $RemoteStagingPath -ItemType Directory -Force | Out-Null
        }

        $ScriptBlock = {
            [CmdletBinding()]
            Param
            (
            )

            $VerbosePreference = $using:VerbosePreference

            $RabbitMqRegistryPath = "HKLM:\SOFTWARE\Ericsson\Erlang\Erlsrv\1.1"
            $RabbitMqInstallPath = $null

            if (Test-Path -Path $RabbitMqRegistryPath)
            {
                Write-Verbose "RabbitMQ registry path exists, retrieving RabbitMQ install path"
                $RabbitMqEnv = ((Get-ChildItem -Path $RabbitMqRegistryPath)[0] | Get-ItemProperty).Env
                $RabbitMqEnv = ($RabbitMqEnv -join "`r`n" | Out-String) -replace "\\", "\\\\"
                $RabbitMqEnv = ConvertFrom-StringData -StringData $RabbitMqEnv

                $RabbitMqInstallPath = [IO.DirectoryInfo]::New(
                    ($RabbitMqEnv.ERL_LIBS -replace "\\\\", "\\")
                ).Parent.FullName
                
                Write-Verbose "RabbitMQ install path: $($RabbitMqInstallPath)"
            }
            else
            {
                Write-Verbose "RabbitMQ install path: (null)"
            }

            Write-Output $RabbitMqInstallPath
        }

        $RabbitMqInstallPath = Invoke-Command `
            -ComputerName $Computer `
            -Credential $ServiceAccountCredential `
            -ScriptBlock $ScriptBlock

        Grant-LogonAsService -Computer $Computer -ServiceAccountCredential $ServiceAccountCredential

        if ([String]::IsNullOrEmpty($RabbitMqInstallPath))
        {
            Write-Verbose "RabbitMQ install path does not exist, preparing to install RabbitMQ"

            $LocalInstallerPath = Join-Path -Path $LocalStagingPath -ChildPath $RabbitMqInstallerPath.Name
            $RemoteInstallerPath = Join-Path -Path $RemoteStagingPath -ChildPath $RabbitMqInstallerPath.Name

            Copy-File -Path $RabbitMqInstallerPath.FullName -Destination $RemoteInstallerPath

            $ScriptBlock = {
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $true)]
                    [String] $LocalInstallerPath
                )

                $VerbosePreference = $using:VerbosePreference

                $RabbitMqRegistryPath = "HKLM:\SOFTWARE\Ericsson\Erlang\Erlsrv\1.1"

                Write-Verbose "Installing RabbitMQ"
                $Result = Start-Process -FilePath $LocalInstallerPath -ArgumentList "/S" -PassThru | Wait-Process
                Write-Verbose "RabbitMQ installation successful"
                
                $RabbitMqEnv = ((Get-ChildItem -Path $RabbitMqRegistryPath)[0] | Get-ItemProperty).Env
                $RabbitMqEnv = ($RabbitMqEnv -join "`r`n" | Out-String) -replace "\\", "\\\\"
                $RabbitMqEnv = ConvertFrom-StringData -StringData $RabbitMqEnv

                $RabbitMqInstallPath = [IO.DirectoryInfo]::New(
                    ($RabbitMqEnv.ERL_LIBS -replace "\\\\", "\\")
                ).Parent.FullName

                Write-Verbose "RabbitMQ install path: $($RabbitMqInstallPath)"
                Write-Output $RabbitMqInstallPath
            }

            $RabbitMqInstallPath = Invoke-Command `
                -ComputerName $Computer `
                -Credential $ServiceAccountCredential `
                -ScriptBlock $ScriptBlock `
                -ArgumentList @($LocalInstallerPath)
        }

        if (-not [String]::IsNullOrEmpty($RabbitMqInstallPath))
        {
            Write-Verbose "RabbitMQ install path exists, validating PATH environment variable contains sbin folder"
            $ScriptBlock = {
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $true)]
                    [String] $RabbitMqInstallPath
                )

                $VerbosePreference = $using:VerbosePreference

                $RabbitMqSbinPath = Join-Path -Path $RabbitMqInstallPath -ChildPath "sbin"
                $PathValue = [Environment]::GetEnvironmentVariable("PATH", "Machine").Split(";")

                if ($RabbitMqSbinPath -notin $PathValue)
                {
                    Write-Verbose "RabbitMQ sbin folder not found in PATH environment variable"
                    $PathValue += $RabbitMqSbinPath

                    $PathValue = ($PathValue | Where-Object { -not [String]::IsNullOrEmpty($_) }) -join ";"
                    
                    [Environment]::SetEnvironmentVariable("PATH", $PathValue, "Machine")
                    Write-Verbose "RabbitMQ sbin folder added to the PATH environment variable"
                }
                else
                {
                    Write-Verbose "RabbitMQ sbin folder is already in the PATH environment variable"
                }
            }

            Invoke-Command `
                -ComputerName $Computer `
                -Credential $ServiceAccountCredential `
                -ScriptBlock $ScriptBlock `
                -ArgumentList @($RabbitMqInstallPath)

            Write-Verbose "Configuring RabbitMQ service to run under service account context"
            $ScriptBlock = {
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $true)]
                    [PSCredential] $ServiceAccountCredential
                )

                $VerbosePreference = $using:VerbosePreference

                $RabbitMqService = Get-CimInstance Win32_Service -Filter "Name='RabbitMQ'"

                if (-not $null -eq $RabbitMqService)
                {
                    Write-Verbose "RabbitMQ service currently runs under $($RabbitMqService.StartName) context"
                    if ($RabbitMqService.StartName -ne $ServiceAccountCredential.UserName)
                    {
                        Write-Verbose "Updating RabbitMQ service to run under $($ServiceAccountCredential.UserName)"
                        
                        Stop-Service -Name $RabbitMqService.Name
                        Start-Sleep -Seconds 5

                        $ServiceChangeArguments = @{
                            StartName = $ServiceAccountCredential.UserName
                            StartPassword = $ServiceAccountCredential.GetNetworkCredential().Password
                        }

                        $ServiceChangeResult = $RabbitMqService |
                            Invoke-CimMethod -MethodName Change -Arguments $ServiceChangeArguments

                        switch ($ServiceChangeResult.ReturnValue)
                        {
                            0 { Write-Verbose "Service logon details changed successfully" }
                            2 { throw "$($ServiceAccountCredential.UserName) did not have the necessary access" }
                            5 { throw "The service cannot accept control messages at this time" }
                            7 { throw "The service account name and/or password is invalid" }
                            Default
                            {
                                throw "Failed to change service logon details: $($ServiceChangeResult.ReturnValue)"
                            }
                        }

                        Start-Service -Name $RabbitMqService.Name
                        Start-Sleep -Seconds 5
                    }
                }
                else
                {
                    throw "RabbitMQ service was not found"
                }
            }

            Invoke-Command `
                -ComputerName $Computer `
                -Credential $ServiceAccountCredential `
                -ScriptBlock $ScriptBlock `
                -ArgumentList @($ServiceAccountCredential)
        }

        if ([String]::IsNullOrEmpty($RabbitMqInstallPath))
        {
            throw "RabbitMQ installation was not able to be validated"
        }
    }
}
#endregion Install-RabbitMq

#region Get-RabbitMqConfiguration
function Get-DefaultRabbitMqConfiguration
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String] $LocalStagingPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqCaCertPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqCertKeyPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqCertPath
    )

    $CertFileInfo = @{
        RabbitMqCaCertPath = $RabbitMqCaCertPath
        RabbitMqCertKeyPath = $RabbitMqCertKeyPath
        RabbitMqCertPath = $RabbitMqCertPath
    }

    $CertFiles = @{}

    foreach ($Key in $CertFileInfo.Keys)
    {
        if (-not (Test-Path -Path $CertFileInfo[$Key].FullName))
        {
            throw "Required certificate file not found at location: $($CertFileInfo[$Key].FullName)"
        }

        $CertFile = Join-Path -Path $LocalStagingPath -ChildPath "Certificates_Do_Not_Remove"
        $CertFile = Join-Path -Path $CertFile -ChildPath $CertFileInfo[$Key].Name
        $CertFiles.Add($Key, ($CertFile -replace "\\", "/"))
    }

    $RabbitMqConfiguration = @{}
    
    $RabbitMqConfiguration.Add("consumer_timeout", 7200000)
    $RabbitMqConfiguration.Add("listeners.ssl.default", 5671)
    $RabbitMqConfiguration.Add("listeners.tcp", "none")
    $RabbitMqConfiguration.Add("log.file.level", "debug")
    $RabbitMqConfiguration.Add("log.file.rotation.count", 20)
    $RabbitMqConfiguration.Add("log.file.rotation.size", 10485760)
    $RabbitMqConfiguration.Add("management.ssl.cacertfile", $CertFiles["RabbitMqCaCertPath"])
    $RabbitMqConfiguration.Add("management.ssl.certfile", $CertFiles["RabbitMqCertPath"])
    $RabbitMqConfiguration.Add("management.ssl.depth", 2)
    $RabbitMqConfiguration.Add("management.ssl.fail_if_no_peer_cert", $false.ToString().ToLower())
    $RabbitMqConfiguration.Add("management.ssl.keyfile", $CertFiles["RabbitMqCertKeyPath"])
    $RabbitMqConfiguration.Add("management.ssl.port", 15671)
    $RabbitMqConfiguration.Add("management.ssl.verify", "verify_none")
    $RabbitMqConfiguration.Add("management.ssl.versions.1", "tlsv1.2")
    $RabbitMqConfiguration.Add("ssl_options.cacertfile", $CertFiles["RabbitMqCaCertPath"])
    $RabbitMqConfiguration.Add("ssl_options.certfile", $CertFiles["RabbitMqCertPath"])
    $RabbitMqConfiguration.Add("ssl_options.depth", 2)
    $RabbitMqConfiguration.Add("ssl_options.fail_if_no_peer_cert", $false.ToString().ToLower())
    $RabbitMqConfiguration.Add("ssl_options.keyfile", $CertFiles["RabbitMqCertKeyPath"])
    $RabbitMqConfiguration.Add("ssl_options.verify", "verify_none")
    $RabbitMqConfiguration.Add("ssl_options.versions.1", "tlsv1.2")
    $RabbitMqConfiguration.Add("vm_memory_high_watermark.relative", 0.75)

    return $RabbitMqConfiguration
}
#endregion Get-RabbitMqConfiguration

#region Set-RabbitMqConfiguration
function Set-RabbitMqConfiguration
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String[]] $Computers,
        [Parameter(Mandatory = $true)]
        [PSCredential] $ServiceAccountCredential,
        [Parameter(Mandatory = $true)]
        [String] $LocalStagingPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqCaCertPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqCertKeyPath,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $RabbitMqCertPath,
        [Parameter(Mandatory = $false)]
        [Hashtable] $RabbitMqConfiguration
    )

    if ($null -eq $RabbitMqConfiguration)
    {
        $RabbitMqConfiguration = Get-DefaultRabbitMqConfiguration `
            -RabbitMqCaCertPath $RabbitMqCaCertPath `
            -RabbitMqCertKeyPath $RabbitMqCertKeyPath `
            -RabbitMqCertPath $RabbitMqCertPath `
            -LocalStagingPath $LocalStagingPath
    }
        
    foreach ($Computer in $Computers)
    {
        $ScriptBlock = {
            [CmdletBinding()]
            Param
            (
            )

            $VerbosePreference = $using:VerbosePreference

            $RabbitMqService = Get-Service -Name "RabbitMQ"

            if ($RabbitMqService.Status -ne "Running")
            {
                Write-Verbose "RabbitMQ service stopped, starting service"
                $RabbitMqService | Start-Service
                Start-Sleep 5
                $RabbitMqService = Get-Service -Name "RabbitMQ"

                if ($RabbitMqService.Status -eq "Stopped")
                {
                    throw "Could not start RabbitMQ service, troubleshoot and resolve before continuing."
                }
            }

            Write-Verbose "Enabling rabbitmq_management plugin"
            rabbitmq-plugins enable rabbitmq_management | Out-Null
        }

        Invoke-Command `
            -ComputerName $Computer `
            -Credential $ServiceAccountCredential `
            -ScriptBlock $ScriptBlock

        $RemoteStagingPath = "\\$($Computer)\$($LocalStagingPath -replace ":", "`$")"
        $RemoteCertPath = Join-Path -Path $RemoteStagingPath -ChildPath "Certificates_Do_Not_Remove"

        $RemotePaths = @($RemoteStagingPath, $RemoteCertPath)
        $CertFilePaths = @()
        $CertFilePaths += $RabbitMqCaCertPath
        $CertFilePaths += $RabbitMqCertKeyPath
        $CertFilePaths += $RabbitMqCertPath

        foreach ($RemotePath in $RemotePaths)
        {
            if (-not (Test-Path -Path $RemotePath))
            {
                Write-Verbose "Creating directory: $($RemotePath)"
                New-Item -Path $RemotePath -ItemType Directory -Force | Out-Null
            }
        }

        foreach ($CertFilePath in $CertFilePaths)
        {
            Copy-File `
                -Path $CertFilePath.FullName `
                -Destination (Join-Path -Path $RemoteCertPath -ChildPath $CertFilePath.Name)
        }

        $ScriptBlock = {
            [CmdletBinding()]
            Param
            (
                [HashTable] $RabbitMqConfiguration
            )

            $VerbosePreference = $using:VerbosePreference

            Write-Verbose "Stopping RabbitMQ service"
            Stop-Service -Name "RabbitMQ"
            Start-Sleep -Seconds 5

            $RabbitMqConfigFolderPath = Join-Path `
                -Path ([Environment]::GetEnvironmentVariable("APPDATA")) `
                -ChildPath "RabbitMQ"
            $RabbitMqConfigFilePath = Join-Path -Path $RabbitMqConfigFolderPath -ChildPath "rabbitmq.conf"

            $OldRabbitMqConfiguration = @{}

            if (Test-Path -Path $RabbitMqConfigFilePath)
            {
                Write-Verbose "Backing up existing RabbitMQ configuration file"
                $RabbitMqConfigFileBackupPath = "$($RabbitMqConfigFilePath).$(Get-Date -f "yyyy-MM-dd-HHmmss")"
                Copy-Item -Path $RabbitMqConfigFilePath -Destination $RabbitMqConfigFileBackupPath -Force

                Write-Verbose "Reading existing RabbitMQ configuration settings"
                $RabbitMqConfigFileContents = Get-Content -Path $RabbitMqConfigFilePath -Raw
	
                if (-not [String]::IsNullOrEmpty($RabbitMqConfigFileContents))
                {
                    $OldRabbitMqConfiguration = ConvertFrom-StringData -StringData $RabbitMqConfigFileContents
                }
            }

            Write-Verbose "Updating or adding RabbitMQ configuration settings"
            $NewRabbitMqConfiguration = @{}

            foreach ($Key in $RabbitMqConfiguration.Keys)
            {
                if ($OldRabbitMqConfiguration.ContainsKey($Key))
                {
                    $OldRabbitMqConfiguration.Remove($Key)
                }

                $NewRabbitMqConfiguration.Add($Key, $RabbitMqConfiguration[$Key])
            }

            foreach ($Key in $OldRabbitMqConfiguration.Keys)
            {
                $NewRabbitMqConfiguration.Add($Key, $OldRabbitMqConfiguration[$Key])
            }

            Write-Verbose "Writing RabbitMQ configuration settings to file"
            New-Item `
                -Path $RabbitMqConfigFilePath `
                -ItemType "File" `
                -Force `
                -Value (($NewRabbitMqConfiguration.GetEnumerator() |
                        ForEach-Object { "$($_.Name) = $($_.Value)" }) -join "`r`n") |
                    Out-Null
            
            Write-Verbose "Starting RabbitMQ service"
            Start-Service -Name "RabbitMQ"
            Start-Sleep -Seconds 5
        }

        Invoke-Command `
            -ComputerName $Computer `
            -Credential $ServiceAccountCredential `
            -ScriptBlock $ScriptBlock `
            -ArgumentList @($RabbitMqConfiguration)
    }
}
#endregion Set-RabbitMqConfiguration

#region Join-RabbitMqCluster
function Join-RabbitMqCluster
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String[]] $Computers,
        [Parameter(Mandatory = $true)]
        [PSCredential] $ServiceAccountCredential,
        [Parameter(Mandatory = $true)]
        [String] $PrimaryNode
    )

    $ScriptBlock = {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory = $true)]
            [PSCredential] $ServiceAccountCredential
        )

        $VerbosePreference = $using:VerbosePreference

        Write-Verbose "Retrieving .erlang.cookie value from primary node)"
        $UserPath = Join-Path -Path "C:\Users" -ChildPath ($ServiceAccountCredential.UserName -replace "^.*?\\", "")
        $ErlangCookiePath = Join-Path -Path $UserPath -ChildPath ".erlang.cookie"
        
        $ErlangCookieValue = $null

        if (Test-Path -Path $ErlangCookiePath)
        {
            $ErlangCookieValue = Get-Content -Path $ErlangCookiePath
        }
        else
        {
            throw ".erlang.cookie file does not exist on primary node"
        }

        Write-Output $ErlangCookieValue
    }

    $ErlangCookieValue = Invoke-Command `
        -ComputerName $PrimaryNode `
        -Credential $ServiceAccountCredential `
        -ScriptBlock $ScriptBlock `
        -ArgumentList @($ServiceAccountCredential)

    foreach ($Computer in $Computers)
    {
        if ($Computer -ne $PrimaryNode)
        {
            $ScriptBlock = {
                [CmdletBinding()]
                Param
                (
                    [Parameter(Mandatory = $true)]
                    [PSCredential] $ServiceAccountCredential,
                    [Parameter(Mandatory = $true)]
                    [String] $ErlangCookieValue,
                    [Parameter(Mandatory = $true)]
                    [String] $PrimaryNode
                )

                $VerbosePreference = $using:VerbosePreference

                $UserPath = Join-Path -Path "C:\Users" -ChildPath ($ServiceAccountCredential.UserName -replace "^.*?\\", "")
                $UserErlangCookiePath = Join-Path -Path $UserPath -ChildPath ".erlang.cookie"
                $WindowsErlangCookiePath = "C:\Windows\System32\config\systemprofile\.erlang.cookie"
                $ErlangCookiePaths = @($UserErlangCookiePath, $WindowsErlangCookiePath)

                $RabbitMqService = Get-Service -Name "RabbitMQ"
                
                if ($RabbitMqService.Status -ne "Stopped")
                {
                    Write-Verbose "Stopping RabbitMQ service"
                    $RabbitMqService | Stop-Service
                    Start-Sleep -Seconds 5
                }

                $RabbitMqService = Get-Service -Name "RabbitMQ"

                if ($RabbitMqService.Status -eq "Stopped")
                {
                    foreach ($ErlangCookiePath in $ErlangCookiePaths)
                    {
                        $OldErlangCookieValue = $null

                        if (Test-Path -Path $ErlangCookiePath)
                        {
                            $ErlangCookieFile = Get-Item $ErlangCookiePath
                            $ErlangCookieFile.IsReadOnly = $false
                            $OldErlangCookieValue = Get-Content -Path $ErlangCookiePath
                        }

                        if ($ErlangCookieValue -ne $OldErlangCookieValue)
                        {
                            Write-Verbose "Writing cookie to $($ErlangCookiePath)"
                            New-Item `
                                -Path $ErlangCookiePath `
                                -ItemType "File" `
                                -Force `
                                -Value $ErlangCookieValue |
                                Out-Null
                        }
                    }

                    Write-Verbose "Starting RabbitMQ service"
                    $RabbitMqService | Start-Service
                    Start-Sleep -Seconds 5

                    $RabbitMqService = Get-Service -Name "RabbitMQ"

                    if ($RabbitMqService.Status -eq "Running")
                    {
                        Write-Verbose "Stopping RabbitMQ app"
                        rabbitmqctl stop_app | Out-Null

                        Write-Verbose "Joining RabbitMQ cluster"
                        rabbitmqctl join_cluster rabbit@$PrimaryNode | Out-Null

                        Write-Verbose "Starting RabbitMQ app"
                        rabbitmqctl start_app | Out-Null
                    }
                    else
                    {
                        throw "Unable to start RabbitMQ service after writing cookie values"
                    }
                }
                else
                {
                    throw "Unable to stop RabbitMQ service"
                }
            }

            Invoke-Command `
                -ComputerName $Computer `
                -Credential $ServiceAccountCredential `
                -ScriptBlock $ScriptBlock `
                -ArgumentList @($ServiceAccountCredential, $ErlangCookieValue, $PrimaryNode)
        }
    }
}
#endregion Join-RabbitMqCluster

#region Set-RabbitMqClusterConfiguration
function Set-RabbitMqClusterConfiguration
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String] $PrimaryNode,
        [Parameter(Mandatory = $true)]
        [PSCredential] $ServiceAccountCredential,
        [Parameter(Mandatory = $true)]
        [PSCredential] $RabbitMqCredential
    )

    $ScriptBlock = {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory = $true)]
            [PSCredential] $RabbitMqCredential
        )

        $VerbosePreference = $using:VerbosePreference

        Write-Verbose "Creating RabbitMQ user: $($RabbitMqCredential.UserName)"
        rabbitmqctl add_user $RabbitMqCredential.UserName $RabbitMqCredential.GetNetworkCredential().Password |
            Out-Null

        Write-Verbose "Setting RabbitMQ user as administrator: $($RabbitMqCredential.UserName)"
        rabbitmqctl set_user_tags $RelativityMqCredential.UserName administrator | Out-Null

        Write-Verbose "Creating Relativity virtual host"
        rabbitmqctl add_vhost Relativity | Out-Null

        Write-Verbose "Setting permissions to Relativity vhost for RabbitMQ user: $($RabbitMqCredential.UserName)"
        rabbitmqctl set_permissions -p Relativity $RabbitMqCredential.UserName ".*" ".*" ".*" | Out-Null

        Write-Verbose "Setting SignalR policy on Relativity vhost"
        rabbitmqctl set_policy -p Relativity --priority 10 --apply-to all SignalR SIGNALR '{"""expires""":240000}' | Out-Null

        Write-Verbose "Setting Ha-all policy on Relativity vhost"
        rabbitmqctl set_policy -p Relativity --priority -10 --apply-to all Ha-all .* '{"""expires""":86400000,"""ha-mode""":"""all""","""ha-sync-mode""":"""automatic"""}' | Out-Null
    }

    Invoke-Command `
        -ComputerName $PrimaryNode `
        -Credential $ServiceAccountCredential `
        -ScriptBlock $ScriptBlock `
        -ArgumentList @($RabbitMqCredential)
}
#endregion Set-RabbitMqClusterConfiguration

Install-Erlang `
    -Computers $Computers `
    -ServiceAccountCredential $ServiceAccountCredential `
    -LocalStagingPath $LocalStagingPath `
    -ErlangInstallerPath $ErlangInstallerPath

Install-RabbitMq `
    -Computers $Computers `
    -ServiceAccountCredential $ServiceAccountCredential `
    -LocalStagingPath $LocalStagingPath `
    -RabbitMqInstallerPath $RabbitMqInstallerPath

Set-RabbitMqConfiguration `
    -Computers $Computers `
    -ServiceAccountCredential $ServiceAccountCredential `
    -LocalStagingPath $LocalStagingPath `
    -RabbitMqCaCertPath $RabbitMqCaCertPath `
    -RabbitMqCertKeyPath $RabbitMqCertKeyPath `
    -RabbitMqCertPath $RabbitMqCertPath

Join-RabbitMqCluster `
    -Computers $Computers `
    -ServiceAccountCredential $ServiceAccountCredential `
    -PrimaryNode $PrimaryNode

Set-RabbitMqClusterConfiguration `
    -PrimaryNode $PrimaryNode `
    -ServiceAccountCredential $ServiceAccountCredential `
    -RabbitMqCredential $RabbitMqCredential
