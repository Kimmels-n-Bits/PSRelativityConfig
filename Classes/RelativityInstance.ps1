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

    RelativityInstance([String] $name)
    {
        $this.Name = $name
        $this.FriendlyName = $name
    }

    RelativityInstance([String] $name, [String] $friendlyName)
    {
        $this.Name = $name
        $this.FriendlyName = $friendlyName
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

class RelativityServer
{
    [ValidateNotNullOrEmpty()]
    [String] $Name
    [ValidateNotNull()]
    [String[]] $Role
    [String] $ServerFQDN
    [String] $InstallDirectory
    [String] $SecretStoreInstallDirectory
    [String] $QueueManagerInstallDirectory
    [String] $WorkerInstallDirectory
    [String] $DefaultFileRepository
    [String] $EDDSFileShare
    [String] $CacheLocation
    [String] $DtSearchIndexPath
    [String] $DataFilesNetworkPath
    [String] $SqlInstance
    [Int32] $SqlPort
    [Boolean] $UseWinAuth
    [String] $SqlBackupDirectory
    [String] $SqlLogDirectory
    [String] $SqlDataDirectory
    [String] $SqlFulltextDirectory
    [String] $ServiceNamespace
    [Boolean] $RabbitMQTLSEnabled
    [Boolean] $EnableWinAuth
    [String] $WorkerNetworkPath
    [String] $IdentityServerUrl
    [String] $NISTPackagePath

    RelativityServer([String] $name)
    {
        $this.Name = $name
        $this.Role = @()
        $this.ServerFQDN = "$($name).$((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain)"
        $this.InstallDirectory = "C:\Program Files\kCura Corporation\Relativity\"
        $this.SecretStoreInstallDirectory = "C:\Program Files\Relativity Secret Store\"
        $this.QueueManagerInstallDirectory = "C:\Program Files\kCura Corporation\Invariant\QueueManager\"
        $this.WorkerInstallDirectory = "C:\Program Files\kCura Corporation\Invariant\Worker\"
    }

    [void] AddRole([String] $role)
    {
        if (-not ($role -in @("SecretStore", "PrimarySql", "DistributedSql", "ServiceBus", "Web", "Agent", "WorkerManager", "Worker")))
        {
            throw "$($role) is not an expected server role!"
        }

        $this.Role += $role
    }
}