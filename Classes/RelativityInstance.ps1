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
                            "InstallDir" { if ($role -eq [RelativityServerRole]::SecretStore) { $this.ResponseFileProperties[$Property] = "C:\Program Files\Relativity Secret Store\" } else { $this.ResponseFileProperties[$Property] = "C:\Program Files\kCura Corporation\Relativity\" } }
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

    .EXAMPLE
    $server.SetProperty("InstallDir", "C:\InstallPath")
    Sets the InstallDir property to the specified path.

    .PARAMETER property
    The name of the property to set.

    .PARAMETER value
    The value to assign to the property.

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

    .OUTPUTS
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
            Write-Verbose "Created an instance of RelativityInstance."
        }
        catch
        {
            Write-Error "An error occurred while creating an instance of RelativityInstance for $($this.Name)."
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
            $this.ValidateResponseFileProperties($server)

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
            Write-Error "An error occurred while adding the $($server.Name) server to $($this.Name)."
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
            Write-Error "An error occurred while merging the $($newServer.Name) server with previously-existing server."
            throw
        }
    }

    <#
    .SYNOPSIS
    Validates the response file properties of a Relativity server.

    .DESCRIPTION
    The ValidateResponseFileProperties method checks the response file properties of a given RelativityServer.
    It ensures that each property is neither null nor an empty string, throwing an exception if this condition is not met.

    .EXAMPLE
    $instance.ValidateResponseFileProperties($server)
    Validates the response file properties of the specified RelativityServer.
    
    .PARAMETER server
    The RelativityServer whose properties are to be validated.

    .NOTES
    #>
    [void] ValidateResponseFileProperties([RelativityServer] $server)
    {
        try
        {
            Write-Verbose "Validating response file properties for $($server.Name)."
            foreach ($Property in $server.ResponseFileProperties.Keys)
            {
                if ([String]::IsNullOrEmpty($server.ResponseFileProperties[$Property]))
                {
                    throw "$($Property) Property of $($server.Name) cannot be null or empty."
                }
            }
            Write-Verbose "Validated response file properties for $($server.Name)."
        }
        catch
        {
            Write-Error "An error occurred while validating response file properties for $($server.Name)."
            throw
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
