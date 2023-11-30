<#
.SYNOPSIS
Represents an instance of a Relativity environment, managing servers and their configurations.

.DESCRIPTION
The RelativityInstance class encapsulates details of a Relativity environment, including server management, 
credentials, and server properties. It allows for adding, merging, and validating servers within the instance.

.EXAMPLE
$instance = [RelativityInstance]::new("InstanceName")
Creates a new RelativityInstance with the specified name.

.EXAMPLE
$instance.AddServer($server)
Adds the specified server to the instance and validates related properties.

.PARAMETER Name
The name of the instance.

.PARAMETER FriendlyName
An optional friendly name for the instance.

.NOTES
#>
class RelativityInstance
{
    [ValidateNotNullOrEmpty()]
    [String] $Name
    [ValidateNotNullOrEmpty()]
    [String] $FriendlyName
    [ValidateNotNull()]
    [RelativityServer[]] $Servers
    [ValidateNotNull()]
    [PSCredential] $NetworkCredential
    [ValidateNotNull()]
    [PSCredential] $ServiceAccountCredential
    [ValidateNotNull()]
    [PSCredential] $EDDSDBOCredential
    [ValidateNotNull()]
    [PSCredential] $RabbitMQCredential
    [ValidateNotNull()]
    [RelativityInstallerBundle] $InstallerBundle
    [ValidateNotNullOrEmpty()]
    [String] $InstallerDirectory
    [ValidateNotNullOrEmpty()]
    [String] $PSSessionName

    RelativityInstance(
        [String] $name,
        [String] $friendlyName,
        [PSCredential] $networkCredential,
        [PSCredential] $serviceAccountCredential,
        [PSCredential] $eddsdboCredential,
        [PSCredential] $rabbitMQCredential
        )
    {
        try
        {
            Write-Verbose "Creating an instance of RelativityInstance."
            $this.Name = $name

            if ($null -eq $friendlyName)
            {
                $this.FriendlyName = $name
            }
            else
            {
                $this.FriendlyName = $friendlyName
            }

            $this.Servers = @()
            $this.NetworkCredential = $networkCredential
            $this.ServiceAccountCredential = $serviceAccountCredential
            $this.EDDSDBOCredential = $eddsdboCredential
            $this.RabbitMQCredential = $rabbitMQCredential
            Write-Verbose "Created an instance of RelativityInstance."
        }
        catch
        {
            Write-Error "An error occurred while creating an instance of RelativityInstance for $($this.Name): $($_.Exception.Message)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Adds a server to the Relativity instance.

    .DESCRIPTION
    The AddServer method adds a new RelativityServer object to the RelativityInstance.
    It first validates the response file properties of the server to ensure they are not null or empty.
    If a server with the same name already exists, it merges the new server's properties with the existing one.

    .EXAMPLE
    $instance.AddServer($server)
    Adds the specified RelativityServer object to the RelativityInstance.

    .PARAMETER server
    The RelativityServer object to be added to the instance.

    .NOTES
    #>
    [void] AddServer([RelativityServer] $server)
    {
        try
        {
            Write-Verbose "Adding the $($server.Name) server to $($this.Name)."
            $ExistingServer = ($this.Servers | Where-Object -Property Name -eq $server.Name)

            if ($null -eq $ExistingServer)
            {
                $this.Servers += $server
                Write-Verbose "Added the $($server.Name) server to $($this.Name)."
            }
            else
            {
                Write-Verbose "Could not add the $($server.Name) server to $($this.Name) because it already existed."
                $this.MergeServer($ExistingServer, $server)
            }
        }
        catch
        {
            Write-Error "An error occurred while adding the $($server.Name) server to $($this.Name): $($_.Exception.Message)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Merges an existing server with a new server.

    .DESCRIPTION
    The MergeServer method combines the properties of an existing server in the instance with those of a new server.
    Properties from the new server are used to fill in any null or empty properties in the existing server.

    .EXAMPLE
    $instance.MergeServer($existingServer, $newServer)
    Merges properties of $newServer into $existingServer within the RelativityInstance.

    .PARAMETER existingServer
    The existing server in the RelativityInstance.

    .PARAMETER newServer
    The new server whose properties are to be merged into the existing server.

    .NOTES
    #>
    [void] MergeServer([RelativityServer] $existingServer, [RelativityServer] $newServer)
    {
        try
        {
            Write-Verbose "Merging the $($newServer.Name) server with previously-existing server."
            foreach ($Property in $newServer.ResponseFileProperties.Keys)
            {
                if ([String]::IsNullOrEmpty($existingServer.ResponseFileProperties[$Property]))
                {
                    Write-Verbose "Adding $($Property) Property to $($existingServer.Name)."
                    $existingServer.ResponseFileProperties[$Property] = $newServer.ResponseFileProperties[$Property]
                    Write-Verbose "Added $($Property) Property to $($existingServer.Name)."
                }
            }
            Write-Verbose "Merged the $($newServer.Name) server with previously-existing server."
        }
        catch
        {
            Write-Error "An error occurred while merging the $($newServer.Name) server with previously-existing server: $($_.Exception.Message)."
            throw
        }
    }

    [void] SetInstall([Boolean] $install)
    {
        foreach ($Server in $this.Servers)
        {
            $Server.Install = $install
        }
    }

    [void] SetInstallerBundle([RelativityInstallerBundle] $installerBundle)
    {
        $this.InstallerBundle = $installerBundle
    }

    [void] SetInstallerDirectory([String] $installerDirectory)
    {
        $this.InstallerDirectory = $installerDirectory
    }

    [void] ValidateInstallProperties([Boolean] $setDefaults)
    {
        $ValidationErrorCount = 0

        <# Validate instance-level properties associated to installation. #>
        if ($null -eq $this.Servers -or $this.Servers.Count -eq 0)
        {
            Write-Error "Servers is null or empty for instance $($this.Name)."
            $ValidationErrorCount += 1
        }

        if ($null -eq $this.NetworkCredential)
        {
            Write-Error "NetworkCredential is null for instance $($this.Name)."
            $ValidationErrorCount += 1
        }

        if ($null -eq $this.ServiceAccountCredential)
        {
            Write-Error "ServiceAccountCredential is null for instance $($this.Name)."
            $ValidationErrorCount += 1
        }

        if ($null -eq $this.EDDSDBOCredential)
        {
            Write-Error "EDDSDBOCredential is null for instance $($this.Name)."
            $ValidationErrorCount += 1
        }

        if ($null -eq $this.RabbitMQCredential)
        {
            Write-Error "RabbitMQCredential is null for instance $($this.Name)."
            $ValidationErrorCount += 1
        }

        if ($null -eq $this.InstallerBundle)
        {
            Write-Error "InstallerBundle is null for instance $($this.Name)."
            $ValidationErrorCount += 1
        }

        if ([String]::IsNullOrEmpty($this.InstallerDirectory))
        {
            if ($setDefaults)
            {
                $this.InstallerDirectory = "C:\PSRelativityConfig"
            }
            else
            {
                Write-Error "InstallerDirectory is null or empty for instance $($this.Name)."
                $ValidationErrorCount += 1
            }
        }

        if ([String]::IsNullOrEmpty($this.PSSessionName))
        {
            if ($setDefaults)
            {
                $this.PSSessionName = "PSRelativityConfig"
            }
            else
            {
                Write-Error "PSSessionName is null or empty for instance $($this.Name)."
                $ValidationErrorCount += 1
            }
        }

        <# Validate server-level properties associated to installation. #>
        foreach ($Server in $this.Servers)
        {
            if ($null -eq $Server.Role -or $Server.Role.Count -eq 0)
            {
                Write-Error "Role is null or empty for server $($Server.Name)."
            }

            if ($null -eq $Server.NetworkCredential)
            {
                if ($setDefaults)
                {
                    $Server.NetworkCredential = $this.NetworkCredential
                }
                else
                {
                    Write-Error "NetworkCredential is null for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            if ($null -eq $Server.ServiceAccountCredential)
            {
                if ($setDefaults)
                {
                    $Server.ServiceAccountCredential = $this.ServiceAccountCredential
                }
                else
                {
                    Write-Error "ServiceAccountCredential is null for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            if ($null -eq $Server.EDDSDBOCredential)
            {
                if ($setDefaults)
                {
                    $Server.EDDSDBOCredential = $this.EDDSDBOCredential
                }
                else
                {
                    Write-Error "EDDSDBOCredential is null for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            if ($null -eq $Server.RabbitMQCredential)
            {
                if ($setDefaults)
                {
                    $Server.RabbitMQCredential = $this.RabbitMQCredential
                }
                else
                {
                    Write-Error "RabbitMQCredential is null for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            if ($null -eq $Server.InstallerBundle)
            {
                if ($setDefaults)
                {
                    $Server.InstallerBundle = $this.InstallerBundle
                }
                else
                {
                    Write-Error "InstallerBundle is null for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            if ([String]::IsNullOrEmpty($Server.InstallerDirectory))
            {
                if ($setDefaults)
                {
                    $Server.InstallerDirectory = $this.InstallerDirectory
                }
                else
                {
                    Write-Error "InstallerDirectory is null or empty for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            if ([String]::IsNullOrEmpty($Server.PSSessionName))
            {
                if ($setDefaults)
                {
                    $Server.PSSessionName = $this.PSSessionName
                }
                else
                {
                    Write-Error "PSSessionName is null or empty for server $($Server.Name)."
                    $ValidationErrorCount += 1
                }
            }

            foreach ($Property in @($Server.ResponseFileProperties.Keys))
            {
                if ([String]::IsNullOrEmpty($Server.ResponseFileProperties[$Property]))
                {
                    if ($setDefaults)
                    {
                        switch ($Property)
                        {
                            "DefaultAgents" { $Server.SetProperty("DefaultAgents", "0") }
                            "EnableWinAuth" { $Server.SetProperty("EnableWinAuth", "0") }
                            "InstallAgents" { $Server.SetProperty("InstallAgents", "1") }
                            "InstallDir" { $Server.SetProperty("InstallDir", "C:\Program Files\kCura Corporation\Relativity\") }
                            "InstallDistributedDatabase" { $Server.SetProperty("InstallDistributedDatabase", "1") }
                            "InstallPrimaryDatabase" { $Server.SetProperty("InstallPrimaryDatabase", "1") }
                            "InstallQueueManager" { $Server.SetProperty("InstallQueueManager", "1") }
                            "InstallServiceBus" { $Server.SetProperty("InstallServiceBus", "1") }
                            "InstallWeb" { $Server.SetProperty("InstallWeb", "1") }
                            "InstallWorker" { $Server.SetProperty("InstallWorker", "1") }
                            "NISTPackagePath" { $Server.SetProperty("NISTPackagePath", (Join-Path -Path $Server.InstallerDirectory -ChildPath "NISTPackage.zip")) }
                            "QueueManagerInstallPath" { $Server.SetProperty("QueueManagerInstallPath", "C:\Program Files\kCura Corporation\Invariant\QueueManager\") }
                            "SecretStoreInstallDir" { $Server.SetProperty("SecretStoreInstallDir", "C:\Program Files\Relativity Secret Store\") }
                            "ServiceBusProvider" { $Server.SetProperty("ServiceBusProvider", "RabbitMQ") }
                            "UseWinAuth" { $Server.SetProperty("UseWinAuth", "1") }
                            "WorkerInstallPath" { $Server.SetProperty("WorkerInstallPath", "C:\Program Files\kCura Corporation\Invariant\Worker\") }

                            default
                            {
                                Write-Error "ResponseFileProperty '$($Property)' is null or empty for server $($Server.Name)."
                                $ValidationErrorCount += 1
                            }
                        }
                    }
                    else
                    {
                        Write-Error "ResponseFileProperty '$($Property)' is null or empty for server $($Server.Name)."
                        $ValidationErrorCount += 1
                    }
                }
            }
        }

        if ($ValidationErrorCount -gt 0)
        {
            throw "$($ValidationErrorCount) validation errors were encountered for instance $($this.Name). See error output for details."
        }
    }
}
