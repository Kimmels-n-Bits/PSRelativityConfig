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
        $this.ValidateServerName($server.Name)
        $this.ValidateServerRole($server.Role)

        foreach ($role in $server.Role)
        {
            $this.ValidateRoleSpecificProperties($server, $role)
        }

        $this.Servers += $server
    }

    [void] ValidateServerName([String] $serverName)
    {
        if (-not ($null -eq ($this.Servers | Where-Object -Property Name -eq $serverName)))
        {
            throw "A server with this name already exists!"
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
            if (-not ($Role -in @("SecretStore", "PrimarySql", "DistributedSql", "ServiceBus", "Web", "Agent", "QueueManager", "Worker")))
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
                $this.ValidateCoreSqlPropertes($server.SqlInstance, $server.SqlPort)
                break
            }
            "PrimarySql"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                $this.ValidateCoreSqlPropertes($server.SqlInstance, $server.SqlPort)
                $this.ValidateCoreSqlDirectories($server.SqlBackupDirectory, $server.SqlLogDirectory, $server.SqlDataDirectory)
                $this.ValidateExtendedSqlDirectories($server.SqlFulltextDirectory)
                $this.ValidatePrimarySqlProperties($server.DefaultFileRepository, $server.EDDSFileShare, $server.CacheLocation, $server.DtSearchIndexPath)
                break
            }
            "DistributedSql"
            {
                $this.ValidateInstallationDirectory($server.InstallDirectory)
                $this.ValidateCoreSqlPropertes($server.SqlInstance, $server.SqlPort)
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
            "QueueManager"
            {
                $this.ValidateInstallationDirectory($server.QueueManagerInstallDirectory)
                $this.ValidateCoreSqlPropertes($server.SqlInstance, $server.SqlPort)
                $this.ValidateCoreSqlDirectories($server.SqlBackupDirectory, $server.SqlLogDirectory, $server.SqlDataDirectory)
                $this.ValidateQueueManagerProperties($server.WorkerNetworkPath, $server.IdentityServerUrl)
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

    [void] ValidateQueueManagerProperties([String] $workerNetworkPath, [String] $identityServerUrl)
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
}

class RelativityServer
{
    [String] $Name
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
    }

    [void] AddRole([String] $role)
    {
        if (-not ($role -in @("SecretStore", "PrimarySql", "DistributedSql", "ServiceBus", "Web", "Agent", "QueueManager", "Worker")))
        {
            throw "$($role) is not an expected server role!"
        }

        $this.Role += $role
    }
}