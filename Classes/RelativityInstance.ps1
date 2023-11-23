<#
.SYNOPSIS
  Enum for defining server roles within a Relativity environment.

.DESCRIPTION
  The RelativityServerRole enum enumerates the various roles that a server can be assigned in a Relativity deployment.
  Each role corresponds to specific functionalities and responsibilities within the system.

.EXAMPLE
  [RelativityServerRole]::Agent
  Demonstrates how to reference the Agent role from the enum.

.NOTES
#>
enum RelativityServerRole
{
    Agent
    Analytics
    DistributedSql
    PrimarySql
    SecretStore
    ServiceBus
    Web
    Worker
    WorkerManager
}

<#
.SYNOPSIS
  Represents a server in a Relativity environment, encapsulating roles, status, and configuration.

.DESCRIPTION
  The RelativityServer class models a server within a Relativity environment. It holds information about the server's roles,
  online status, and configuration properties necessary for each role. The class provides methods to manage server roles,
  configure properties, and validate server readiness.

.EXAMPLE
  $server = [RelativityServer]::new("ServerName")
  Creates a new RelativityServer instance with the specified server name.

.EXAMPLE
  $server.AddRole([RelativityServerRole]::Agent)
  Adds the Agent role to the server and configures related properties.

.PARAMETER Name
  The name of the server. This should be a valid network name.

.NOTES
#>
class RelativityServer
{
    [ValidateNotNullOrEmpty()]
    [String] $Name
    [ValidateNotNull()]
    [Boolean] $IsOnline
    [System.Collections.Generic.HashSet[RelativityServerRole]] $Role
    [Hashtable] $ResponseFileProperties

    hidden static [Hashtable] $RoleResponseFileProperties = @{
        [RelativityServerRole]::Agent = @(
            "InstallAgents",
            "InstallDir",
            "PrimarySqlInstance",
            "UseWinAuth",
            "DefaultAgents"
        )
        [RelativityServerRole]::Analytics = @(

        )
        [RelativityServerRole]::DistributedSql = @(
            "InstallDistributedDatabase",
            "InstallDir",
            "PrimarySqlInstance",
            "UseWinAuth",
            "DistributedSqlInstance",
            "DatabaseBackupDir",
            "LdfDir",
            "MdfDir",
            "FullTextDir"
        )
        [RelativityServerRole]::PrimarySql = @(
            "InstallPrimaryDatabase",
            "InstallDir",
            "PrimarySqlInstance",
            "UseWinAuth",
            "DefaultFileRepository",
            "EddsFileShare",
            "CacheLocation",
            "DtSearchIndexPath",
            "RelativityInstanceName",
            "DatabaseBackupDir",
            "LdfDir",
            "MdfDir",
            "FullTextDir"
        )
        [RelativityServerRole]::SecretStore = @(
            "SqlInstanceServerName",
            "UseWinAuth",
            "InstallDir"
        )
        [RelativityServerRole]::ServiceBus = @(
            "InstallServiceBus",
            "InstallDir",
            "PrimarySqlInstance",
            "UseWinAuth",
            "ServiceBusProvider",
            "ServerFQDN",
            "TlsEnabled"
        )
        [RelativityServerRole]::Web = @(
            "InstallWeb",
            "InstallDir",
            "PrimarySqlInstance",
            "UseWinAuth",
            "EnableWinAuth"
        )
        [RelativityServerRole]::Worker = @(
            "InstallWorker",
            "SqlInstance",
            "RelativitySqlInstance",
            "WorkerInstallPath"
        )
        [RelativityServerRole]::WorkerManager = @(
            "InstallQueueManager",
            "SqlInstance",
            "RelativitySqlInstance",
            "UseWinAuth",
            "WorkerNetworkPath",
            "IdentityServerUrl",
            "QueueManagerInstallPath",
            "MdfDir",
            "LdfDir",
            "DtSearchIndexPath",
            "DataFilesNetworkPath",
            "NistPackagePath"
        )
    }

    RelativityServer([String] $name)
    {
        try
        {
            Write-Verbose "Creating an instance of RelativityServer."
            $this.Name = $name
            $this.Role = New-Object 'System.Collections.Generic.HashSet[RelativityServerRole]'
            $this.ResponseFileProperties = @{}
            $this.TestConnection()
            Write-Verbose "Created an instance of RelativityServer."
        }
        catch
        {
            Write-Error "An error occurred while creating an instance of RelativityServer for $($this.Name)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Adds a role to the server and configures default properties for that role.

    .DESCRIPTION
    The AddRole method assigns a specified role to the server. It automatically populates the server's
    configuration with default properties relevant to the role, avoiding overwriting existing values.

    .PARAMETER role
    The role to be added to the server. Must be a valid value from RelativityServerRole enum.

    .EXAMPLE
    $server.AddRole([RelativityServerRole]::Agent)
    Adds the Agent role to the server.

    .NOTES
    #>
    [void] AddRole([RelativityServerRole] $role)
    {
        try
        {
            if (-not $this.Role.Contains($role))
            {
                Write-Verbose "Adding $($role) role to $($this.Name)."
                $this.Role.Add($role)
                foreach ($Property in [RelativityServer]::RoleResponseFileProperties[$role])
                {
                    if (-not $this.ResponseFileProperties.ContainsKey($property))
                    {
                        Write-Verbose "Adding $($Property) Property to $($this.Name)."
                        switch ($Property)
                        {
                            "InstallAgents" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallDistributedDatabase" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallPrimaryDatabase" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallServiceBus" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallWeb" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallWorker" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallQueueManager" { $this.ResponseFileProperties[$Property] = "1" }
                            "InstallDir" { $this.ResponseFileProperties[$Property] = "C:\Program Files\kCura Corporation\Relativity\" }
                            "UseWinAuth" { $this.ResponseFileProperties[$Property] = "1" }
                            "DefaultAgents" { $this.ResponseFileProperties[$Property] = "0" }
                            "WorkerInstallPath" { $this.ResponseFileProperties[$Property] = "C:\Program Files\kCura Corporation\Invariant\Worker\" }
                            "QueueManagerInstallPath" { $this.ResponseFileProperties[$Property] = "C:\Program Files\kCura Corporation\Invariant\QueueManager\" }

                            default { $this.ResponseFileProperties[$Property] = $null }
                        }
                        Write-Verbose "Added $($Property) Property to $($this.Name)."
                    }
                }
                Write-Verbose "Added $($role) role to $($this.Name)."
            }
        }
        catch
        {
            Write-Error "An error occurred while adding the $($role) role to $($this.Name)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Removes a role from the server and cleans up related properties.

    .DESCRIPTION
    The RemoveRole method removes a specified role from the server. It also checks and removes
    the properties associated with that role if they are not shared with other roles on the server.

    .PARAMETER role
    The role to be removed from the server. Must be a valid value from RelativityServerRole enum.

    .EXAMPLE
    $server.RemoveRole([RelativityServerRole]::Agent)
    Removes the Agent role from the server.

    .NOTES
    #>
    [void] RemoveRole([RelativityServerRole] $role)
    {
        try
        {
            if ($this.Role.Contains($role))
            {
                Write-Verbose "Removing $($role) role from $($this.Name)."
                $this.Role.Remove($role)
                foreach ($Property in [RelativityServer]::RoleResponseFileProperties[$role])
                {
                    $AllOtherRoles = $this.Role -ne $role
                    $IsShared = $AllOtherRoles | ForEach-Object {
                        [RelativityServer]::RoleResponseFileProperties[$_].Contains($Property)
                    } | Where-Object { $_ }
                    if (-not $IsShared)
                    {
                        Write-Verbose "Removing $($Property) Property from $($this.Name)."
                        $this.ResponseFileProperties.Remove($Property)
                        Write-Verbose "Removed $($Property) Property from $($this.Name)."
                    }
                }
                Write-Verbose "Removed $($role) role from $($this.Name)."
            }
        }
        catch
        {
            Write-Error "An error occurred while removing the $($role) role from $($this.Name)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Sets a specific property for the server's configuration.

    .DESCRIPTION
    The SetProperty method assigns a value to a specific configuration property of the server.
    It validates if the property is relevant to the server's assigned roles before setting it.

    .PARAMETER property
    The name of the property to set.

    .PARAMETER value
    The value to assign to the property.

    .EXAMPLE
    $server.SetProperty("InstallDir", "C:\InstallPath")
    Sets the InstallDir property to the specified path.

    .NOTES
    #>
    [void] SetProperty([String] $property, [String] $value)
    {
        try
        {
            if ($this.ResponseFileProperties.ContainsKey($property))
            {
                Write-Verbose "Setting $($property) Property to $($value) for $($this.Name)."
                $this.ResponseFileProperties[$property] = $value
                Write-Verbose "Set $($property) Property to $($value) for $($this.Name)."
            }
            else
            {
                Write-Error "$($property) Property is not valid for the roles assigned to $($this.Name)."
            }
        }
        catch
        {
            Write-Error "An error occurred while setting the $($property) Property to $($value) for $($this.Name)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Retrieves the configuration properties for the server.

    .DESCRIPTION
    The GetResponseFileProperties method compiles and returns a list of the server's configuration
    properties formatted as key-value pairs. This is useful for generating configuration files or reports.

    .EXAMPLE
    $server.GetResponseFileProperties()
    Returns an array of the server's properties in key=value format.

    .RETURN
    An array of strings, each representing a configuration property in key=value format.

    .NOTES
    #>
    [String[]] GetResponseFileProperties()
    {
        try
        {
            $Properties = @()
            foreach ($Key in $this.ResponseFileProperties.Keys)
            {
                $Value = $this.ResponseFileProperties[$Key]
                $FormattedKey = $Key.ToUpper()
                $Property = "$($FormattedKey)=$($Value)"
                $Properties += $Property
            }

            return $Properties
        }
        catch
        {
            Write-Error "An error occurred while retrieving response file properties for $($this.Name)."
            throw
        }
    }

    <#
    .SYNOPSIS
    Tests network connectivity to the server.

    .DESCRIPTION
    The TestConnection method checks if the server is reachable over the network using a ping test.
    It sets the IsOnline property based on the outcome of the test.

    .EXAMPLE
    $server.TestConnection()
    Performs a connectivity test and updates the IsOnline property accordingly.

    .NOTES
    #>
    [void] TestConnection()
    {
        Write-Verbose "Testing network connectivity to $($this.Name)."
        if (Test-Connection -ComputerName $this.Name -Count 1 -Quiet)
        {
            $this.IsOnline = $true
        }
        else
        {
            Write-Warning "Network connectivity test for $($this.Name) was unsuccessful. Flagging server as offline."
            $this.IsOnline = $false
        }
        Write-Verbose "Tested network connectivity to $($this.Name)."
    }
}

class RelativityInstance
{
    [ValidateNotNullOrEmpty()]
    [String] $Name
    [ValidateNotNullOrEmpty()]
    [String] $FriendlyName
    [RelativityServer[]] $Servers
    [ValidateNotNull()]
    [PSCredential] $ServiceAccountWindowsCredential
    [ValidateNotNull()]
    [PSCredential] $EDDSDBOSqlCredential
    [ValidateNotNull()]
    [PSCredential] $ServiceAccountSqlCredential
    [ValidateNotNull()]
    [PSCredential] $RabbitMQCredential
    [ValidateNotNull()]
    [PSCredential] $AdminUserRelativityCredential
    [ValidateNotNull()]
    [PSCredential] $ServiceAccountRelativityCredential

    RelativityInstance([String] $name, [String] $friendlyName = $null)
    {
        $this.Name = $name

        if ($null -eq $friendlyName)
        {
            $this.FriendlyName = $name
        }
        else
        {
            $this.FriendlyName = $friendlyName
        }
    }

    [void] AddServer([RelativityServer] $server)
    {
        $this.ValidateServerRole($server.Role)

        foreach ($role in $server.Role)
        {
            $this.ValidateRoleSpecificProperties($server, $role)
        }

        $ExistingServer = ($this.Servers | Where-Object -Property Name -eq $server.Name)

        if ($null -eq $ExistingServer)
        {
            $this.Servers += $server
        }
        else
        {
            $this.MergeServer($ExistingServer, $server)
        }
    }

    [void] ValidateServerRole([String[]] $serverRole)
    {
        if ($null -eq $serverRole)
        {
            throw "Server role cannot be null!"
        }

        foreach ($Role in $serverRole)
        {
            if (-not ($Role -in @("SecretStore", "PrimarySql", "DistributedSql", "ServiceBus", "Web", "Agent", "WorkerManager", "Worker")))
            {
                throw "$($Role) is not an expected server role!"
            }
        }
    }

    [void] ValidateRoleSpecificProperties([RelativityServer] $server, [String] $role)
    {
        switch ($role)
        {
            "SecretStore"
            {
                $this.ValidateInstallationDirectory($server.SecretStoreInstallDirectory)
                $this.ValidateCoreSqlProperties($server.SqlInstance, $server.SqlPort)
                break
            }
            "PrimarySql"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                $this.ValidateCoreSqlProperties($server.SqlInstance, $server.SqlPort)
                $this.ValidateCoreSqlDirectories($server.SqlBackupDirectory, $server.SqlLogDirectory, $server.SqlDataDirectory)
                $this.ValidateExtendedSqlDirectories($server.SqlFulltextDirectory)
                $this.ValidatePrimarySqlProperties($server.DefaultFileRepository, $server.EDDSFileShare, $server.CacheLocation, $server.DtSearchIndexPath)
                break
            }
            "DistributedSql"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                $this.ValidateCoreSqlProperties($server.SqlInstance, $server.SqlPort)
                $this.ValidateCoreSqlDirectories($server.SqlBackupDirectory, $server.SqlLogDirectory, $server.SqlDataDirectory)
                $this.ValidateExtendedSqlDirectories($server.SqlFulltextDirectory)
                break
            }
            "ServiceBus"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                $this.ValidateServiceBusProperties($server.ServerFQDN, $server.ServiceNamespace, $server.RabbitMQTLSEnabled)
                break
            }
            "Web"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                $this.ValidateWebServerProperties($server.EnableWinAuth)
                break
            }
            "Agent"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                break
            }
            "WorkerManager"
            {
                $this.ValidateInstallationDirectory($server.QueueManagerInstallDirectory)
                $this.ValidateCoreSqlProperties($server.SqlInstance, $server.SqlPort)
                $this.ValidateCoreSqlDirectories($server.SqlBackupDirectory, $server.SqlLogDirectory, $server.SqlDataDirectory)
                $this.ValidateWorkerManagerProperties($server.WorkerNetworkPath, $server.IdentityServerUrl)
                break
            }
            "Worker"
            {
                $this.ValidateInstallationDirectory($server.WorkerInstallDirectory)
                break
            }
        }
    }

    [void] ValidateInstallationDirectory([String] $installationDirectory)
    {
        if ([String]::IsNullOrEmpty($installationDirectory))
        {
            throw "The installation directory must not be null or empty!"
        }
    }

    [void] ValidateCoreSqlProperties([String] $sqlInstance, [Int32] $sqlPort)
    {
        if ([String]::IsNullOrEmpty($sqlInstance))
        {
            throw "The SQL instance must not be null or empty!"
        }

        if ($null -eq $sqlPort)
        {
            throw "The SQL port must not be null!"
        }
    }

    [void] ValidateCoreSqlDirectories([String] $sqlBackupDirectory, [String] $sqlLogDirectory, [String] $sqlDataDirectory)
    {
        if ([String]::IsNullOrEmpty($sqlBackupDirectory))
        {
            throw "The SQL backup directory must be valid!"
        }

        if ([String]::IsNullOrEmpty($sqlLogDirectory))
        {
            throw "The SQL log directory must be valid!"
        }

        if ([String]::IsNullOrEmpty($sqlDataDirectory))
        {
            throw "The SQL data directory must be valid!"
        }
    }

    [void] ValidateExtendedSqlDirectories([String] $sqlFulltextDirectory)
    {
        if ([String]::IsNullOrEmpty($sqlFulltextDirectory))
        {
            throw "The SQL fulltext directory must be valid!"
        }
    }

    [void] ValidatePrimarySqlProperties([String] $defaultFileRepository, [String] $eddsFileShare, [String] $cacheLocation, [String] $dtSearchIndexPath)
    {
        if (-not ($null -eq ($this.Servers | Where-Object { "PrimarySql" -in $_.Role })))
        {
            throw "A server with the PrimarySql server role already exists!"
        }

        if ([String]::IsNullOrEmpty($defaultFileRepository))
        {
            throw "The default file repository must be a valid UNC path!"
        }

        if ([String]::IsNullOrEmpty($eddsFileShare))
        {
            throw "The EDDS file share must be a valid UNC path!"
        }

        if ([String]::IsNullOrEmpty($cacheLocation))
        {
            throw "The cache location must be a valid UNC path!"
        }

        if ([String]::IsNullOrEmpty($dtSearchIndexPath))
        {
            throw "The DTSearch index path must be a valid UNC path!"
        }
    }

    [void] ValidateServiceBusProperties([String] $serverFQDN, [String] $serviceNamespace, [Boolean] $rabbitMQTLSEnabled)
    {
        if ([String]::IsNullOrEmpty($serverFQDN))
        {
            throw "The server fully-qualified domain name must not be null or empty!"
        }

        if ([String]::IsNullOrEmpty($serviceNamespace))
        {
            throw "The RabbitMQ service namespace must not be null or empty!"
        }

        if ($null -eq $rabbitMQTLSEnabled)
        {
            throw "The RabbitMQ TLS Enabled setting must not be null!"
        }
    }

    [void] ValidateWebServerProperties([Boolean] $enableWinAuth)
    {
        if ($null -eq $enableWinAuth)
        {
            throw "The Enable Win Auth setting must not be null!"
        }
    }

    [void] ValidateWorkerManagerProperties([String] $workerNetworkPath, [String] $identityServerUrl)
    {
        if ([String]::IsNullOrEmpty($workerNetworkPath))
        {
            throw "The worker network path must not be null or empty!"
        }

        if ([String]::IsNullOrEmpty($identityServerUrl))
        {
            throw "The identity server URL must not be null or empty!"
        }
    }

    [void] SetServiceAccountWindowsCredential([PSCredential] $serviceAccountWindowsCredential)
    {
        $this.ServiceAccountWindowsCredential = $serviceAccountWindowsCredential
    }

    [void] SetEDDSDBOSqlCredential([PSCredential] $eDDSDBOSqlCredential)
    {
        $this.EDDSDBOSqlCredential = $eDDSDBOSqlCredential
    }

    [void] SetServiceAccountSqlCredential([PSCredential] $serviceAccountSqlCredential)
    {
        $this.ServiceAccountSqlCredential = $serviceAccountSqlCredential
    }

    [void] SetRabbitMQCredential([PSCredential] $rabbitMQCredential)
    {
        $this.RabbitMQCredential = $rabbitMQCredential
    }

    [void] SetAdminUserRelativityCredential([PSCredential] $adminUserRelativityCredential)
    {
        $this.AdminUserRelativityCredential = $adminUserRelativityCredential
    }

    [void] SetServiceAccountRelativityCredential([PSCredential] $serviceAccountRelativityCredential)
    {
        $this.ServiceAccountRelativityCredential = $serviceAccountRelativityCredential
    }

    [void] MergeServer([RelativityServer] $existingServer, [RelativityServer] $newServer)
    {
        $this.Servers = ($this.Servers | Where-Object -Property Name -ne $existingServer.Name)

        foreach ($Role in $newServer.Role)
        {
            if ($Role -notin $existingServer.Role)
            {
                $existingServer.AddRole($Role)
            }
        }

        $existingServer.ServerFQDN = if ([String]::IsNullOrEmpty($existingServer.ServerFQDN)) { $newServer.ServerFQDN } else { $existingServer.ServerFQDN }
        $existingServer.InstallDirectory = if ([String]::IsNullOrEmpty($existingServer.InstallDirectory)) { $newServer.InstallDirectory } else { $existingServer.InstallDirectory }
        $existingServer.SecretStoreInstallDirectory = if ([String]::IsNullOrEmpty($existingServer.SecretStoreInstallDirectory)) { $newServer.SecretStoreInstallDirectory } else { $existingServer.SecretStoreInstallDirectory }
        $existingServer.QueueManagerInstallDirectory = if ([String]::IsNullOrEmpty($existingServer.QueueManagerInstallDirectory)) { $newServer.QueueManagerInstallDirectory } else { $existingServer.QueueManagerInstallDirectory }
        $existingServer.WorkerInstallDirectory = if ([String]::IsNullOrEmpty($existingServer.WorkerInstallDirectory)) { $newServer.WorkerInstallDirectory } else { $existingServer.WorkerInstallDirectory }
        $existingServer.DefaultFileRepository = if ([String]::IsNullOrEmpty($existingServer.DefaultFileRepository)) { $newServer.DefaultFileRepository } else { $existingServer.DefaultFileRepository }
        $existingServer.EDDSFileShare = if ([String]::IsNullOrEmpty($existingServer.EDDSFileShare)) { $newServer.EDDSFileShare } else { $existingServer.EDDSFileShare }
        $existingServer.CacheLocation = if ([String]::IsNullOrEmpty($existingServer.CacheLocation)) { $newServer.CacheLocation } else { $existingServer.CacheLocation }
        $existingServer.DtSearchIndexPath = if ([String]::IsNullOrEmpty($existingServer.DtSearchIndexPath)) { $newServer.DtSearchIndexPath } else { $existingServer.DtSearchIndexPath }
        $existingServer.DataFilesNetworkPath = if ([String]::IsNullOrEmpty($existingServer.DataFilesNetworkPath)) { $newServer.DataFilesNetworkPath } else { $existingServer.DataFilesNetworkPath }
        $existingServer.SqlInstance = if ([String]::IsNullOrEmpty($existingServer.SqlInstance)) { $newServer.SqlInstance } else { $existingServer.SqlInstance }
        $existingServer.SqlPort = if ($null -eq $existingServer.SqlPort) { $newServer.SqlPort } else { $existingServer.SqlPort }
        $existingServer.UseWinAuth = if ($null -eq $existingServer.UseWinAuth) { $newServer.UseWinAuth } else { $existingServer.UseWinAuth }
        $existingServer.SqlBackupDirectory = if ([String]::IsNullOrEmpty($existingServer.SqlBackupDirectory)) { $newServer.SqlBackupDirectory } else { $existingServer.SqlBackupDirectory }
        $existingServer.SqlLogDirectory = if ([String]::IsNullOrEmpty($existingServer.SqlLogDirectory)) { $newServer.SqlLogDirectory } else { $existingServer.SqlLogDirectory }
        $existingServer.SqlDataDirectory = if ([String]::IsNullOrEmpty($existingServer.SqlDataDirectory)) { $newServer.SqlDataDirectory } else { $existingServer.SqlDataDirectory }
        $existingServer.SqlFulltextDirectory = if ([String]::IsNullOrEmpty($existingServer.SqlFulltextDirectory)) { $newServer.SqlFulltextDirectory } else { $existingServer.SqlFulltextDirectory }
        $existingServer.ServiceNamespace = if ([String]::IsNullOrEmpty($existingServer.ServiceNamespace)) { $newServer.ServiceNamespace } else { $existingServer.ServiceNamespace }
        $existingServer.RabbitMQTLSEnabled = if ($null -eq $existingServer.RabbitMQTLSEnabled) { $newServer.RabbitMQTLSEnabled } else { $existingServer.RabbitMQTLSEnabled }
        $existingServer.EnableWinAuth = if ($null -eq $existingServer.EnableWinAuth) { $newServer.EnableWinAuth } else { $existingServer.EnableWinAuth }
        $existingServer.WorkerNetworkPath = if ([String]::IsNullOrEmpty($existingServer.WorkerNetworkPath)) { $newServer.WorkerNetworkPath } else { $existingServer.WorkerNetworkPath }
        $existingServer.IdentityServerUrl = if ([String]::IsNullOrEmpty($existingServer.IdentityServerUrl)) { $newServer.IdentityServerUrl } else { $existingServer.IdentityServerUrl }
        $existingServer.NISTPackagePath = if ([String]::IsNullOrEmpty($existingServer.NISTPackagePath)) { $newServer.NISTPackagePath } else { $existingServer.NISTPackagePath }

        $this.Servers += $existingServer
    }
}
