enum Software
{
    Invariant
    Relativity
}

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
    [ValidateNotNull()]
    [Boolean] $DoInstall
    [System.Collections.Generic.HashSet[RelativityServerRole]] $Role
    [Hashtable] $ResponseFileProperties
    [String] $InstallerDirectory
    [PSCredential] $ServiceAccountCredential
    [PSCredential] $EDDSDBOCredential
    [PSCredential] $RabbitMQCredential

    hidden static [Hashtable] $SoftwareRoles = @{
        [Software]::Invariant = @(
            "Worker",
            "WorkerManager"
        )
        [Software]::Relativity = @(
            "Agent",
            "DistributedSql",
            "PrimarySql",
            "ServiceBus",
            "Web"
        )
    }

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
            "ServiceNamespace",
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

            if ($this.IsOnline)
            {
                $this.EnsureServiceRunning("WinRM")
                $this.EnsureServiceRunning("RemoteRegistry")
            }

            $this.DoInstall = $false

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
                            "ServiceBusProvider" { $this.ResponseFileProperties[$Property] = "RabbitMQ" }
                            "EnableWinAuth" { $this.ResponseFileProperties[$Property] = "0" }
                            "NISTPackagePath" { $this.ResponseFileProperties[$Property] = "C:\PSRelativityConfig\NISTPackage.zip" }
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
    [String[]] GetResponseFileProperties([Software] $software)
    {
        try
        {
            $Properties = @()
            $RelevantRoles = [RelativityServer]::SoftwareRoles[$software]

            foreach ($Role in $this.Role)
            {
                if ($RelevantRoles -contains $Role.ToString())
                {
                    foreach ($Property in [RelativityServer]::RoleResponseFileProperties[$Role])
                    {
                        if ($this.ResponseFileProperties.ContainsKey($Property))
                        {
                            $Value = $this.ResponseFileProperties[$Property]
                            $FormattedKey = $Property.ToUpper()
                            $PropertyString = "$($FormattedKey)=$($Value)"
                            $Properties += $PropertyString
                        }
                    }
                }

                if ($Role.ToString() -eq "ServiceBus")
                {
                    $Properties += "SHAREDACCESSKEYNAME=$($this.RabbitMQCredential.UserName)"
                    $Properties += "SHAREDACCESSKEY=$($this.RabbitMQCredential.GetNetworkCredential().Password)"
                }
            }

            $Properties += "SERVICEUSERNAME=$($this.ServiceAccountCredential.UserName)"
            $Properties += "SERVICEPASSWORD=$($this.ServiceAccountCredential.GetNetworkCredential().Password)"
            $Properties += "EDDSDBOPASSWORD=$($this.EDDSDBOCredential.GetNetworkCredential().Password)"

            return ($Properties | Get-Unique)
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

    [void] EnsureServiceRunning([String] $serviceName)
    {
        $CimSession = $null
        
        try
        {
            $CimSession = New-CimSession -ComputerName $this.Name
            $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($serviceName)'"

            if ($Service.StartMode -ne "Automatic")
            {
                Write-Verbose "Setting startup type of the $($serviceName) service on $($this.Name) to automatic using CIM."
                $MethodParameters = @{
                    StartMode = "Automatic"
                }
                $Service | Invoke-CimMethod -MethodName ChangeStartMode -Arguments $MethodParameters
            }

            if ($Service.Status -ne "Running")
            {
                Write-Verbose "Starting the $($serviceName) service on $($this.Name) using CIM."
                $Service | Invoke-CimMethod -MethodName StartService
            }
        }
        catch
        {
            Write-Verbose "Failed to use CIM for managing the $($serviceName) service on $($this.Name). Falling back to WMI."
            try
            {
                $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'" -ComputerName $this.Name

                if ($Service.StartMode -ne "Automatic")
                {
                    Write-Verbose "Setting startup type of the $($serviceName) service on $($this.Name) to automatic using WMI."
                    $Service.ChangeStartMode("Automatic")
                }

                if ($Service.Status -ne "Running")
                {
                    Write-Verbose "Starting the $($serviceName) service on $($this.Name) using WMI."
                    $Service.StartService()
                }
            }
            catch
            {
                Write-Error "An error occurred while ensuring the $($serviceName) service was running on $($this.Name): $($_.Exception.Message)"
                throw
            }
        }
        finally
        {
            if ($CimSession)
            {
                Remove-CimSession -CimSession $CimSession
            }
        }
    }
}