enum ServiceStartupType
{
    Automatic
    Disabled
    Manual
}

enum Software
{
    Invariant
    Relativity
    SecretStore
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
    [Boolean] $Install
    [ValidateNotNull()]
    [System.Collections.Generic.HashSet[RelativityServerRole]] $Role
    [ValidateNotNull()]
    [Hashtable] $ResponseFileProperties
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
    [ValidateNotNull()]
    [String] $InstallerDirectory
    [ValidateNotNull()]
    [String] $PSSessionName

    static [Hashtable] $SoftwareRoles = @{
        [Software]::Invariant = @(
            [RelativityServerRole]::Worker,
            [RelativityServerRole]::WorkerManager
        )
        [Software]::Relativity = @(
            [RelativityServerRole]::Agent,
            [RelativityServerRole]::DistributedSql,
            [RelativityServerRole]::PrimarySql,
            [RelativityServerRole]::ServiceBus,
            [RelativityServerRole]::Web
        )
        [Software]::SecretStore = @(
            [RelativityServerRole]::SecretStore
        )
    }

    static [Hashtable] $RoleResponseFileProperties = @{
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
            "SecretStoreInstallDir"
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
                $this.SetServiceStartupType("WinRM", [ServiceStartupType]::Automatic)
                $this.EnsureServiceRunning("WinRM")
                $this.SetServiceStartupType("RemoteRegistry", [ServiceStartupType]::Automatic)
                $this.EnsureServiceRunning("RemoteRegistry")
            }

            $this.Install = $false

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
                        $this.ResponseFileProperties[$Property] = $null
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

    [void] SetServiceStartupType([String] $serviceName, [ServiceStartupType] $startupType)
    {
        $CimSession = $null
        
        try
        {
            $CimSession = New-CimSession -ComputerName $this.Name
            $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($serviceName)'"

            if ($Service.StartMode -ne $startupType.ToString())
            {
                Write-Verbose "Setting startup type of the $($serviceName) service on $($this.Name) to $($startupType.ToString()) using CIM."
                $MethodParameters = @{
                    StartMode = $startupType.ToString()
                }
                $Service | Invoke-CimMethod -MethodName ChangeStartMode -Arguments $MethodParameters
            }
        }
        catch
        {
            Write-Verbose "Failed to use CIM for managing the $($serviceName) service on $($this.Name). Falling back to WMI."
            try
            {
                $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'" -ComputerName $this.Name

                if ($Service.StartMode -ne $startupType.ToString())
                {
                    Write-Verbose "Setting startup type of the $($serviceName) service on $($this.Name) to $($startupType.ToString()) using WMI."
                    $Service.ChangeStartMode($startupType.ToString())
                }
            }
            catch
            {
                Write-Error "An error occurred while setting the startup type of the $($serviceName) service on $($this.Name): $($_.Exception.Message)"
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

    [void] EnsureServiceRunning([String] $serviceName)
    {
        $CimSession = $null
        $Timeout = New-TimeSpan -Minutes 5
        $Stopwatch = $null

        try
        {
            IF ($serviceName -eq "WinRM")
            {
                throw
            }

            $CimSession = New-CimSession -ComputerName $this.Name
            $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
            $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($serviceName)'"

            while ($Service.State -ne "Running" -and $Stopwatch.Elapsed -lt $Timeout)
            {
                if ($Service.State -ne "Starting")
                {
                    Write-Verbose "Starting the $($serviceName) service on $($this.Name) using CIM."
                    $Service | Invoke-CimMethod -MethodName StartService
                }

                Start-Sleep -Seconds 2
                $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($serviceName)'"
            }

            if ($Service.State -ne "Running")
            {
                throw
            }
        }
        catch
        {
            Write-Verbose "Failed to use CIM for managing the $($serviceName) service on $($this.Name). Falling back to WMI."
            try
            {
                $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
                $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'" -ComputerName $this.Name

                while ($Service.State -ne "Running" -and $Stopwatch.Elapsed -lt $Timeout)
                {
                    if ($Service.State -ne "Starting")
                    {
                        Write-Verbose "Starting the $($serviceName) service on $($this.Name) using WMI."
                        $Service.StartService()
                    }

                    Start-Sleep -Seconds 2
                    $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'" -ComputerName $this.Name
                }

                if ($Service.State -ne "Running")
                {
                    Write-Error "Failed to start the $($serviceName) service on $($this.Name) within the 10-minute timeout."
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

            if ($Stopwatch)
            {
                $Stopwatch.Stop()
            }
        }
    }

    [void] EnsureServiceStopped([String] $serviceName)
    {
        $CimSession = $null
        $Timeout = New-TimeSpan -Minutes 5
        $Stopwatch = $null
        
        try
        {
            IF ($serviceName -eq "WinRM")
            {
                throw
            }
            
            $CimSession = New-CimSession -ComputerName $this.Name
            $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
            $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($serviceName)'"

            while ($Service.State -ne "Stopped" -and $Stopwatch.Elapsed -lt $Timeout)
            {
                if ($Service.State -ne "Stopping")
                {
                    Write-Verbose "Stopping the $($serviceName) service on $($this.Name) using CIM."
                    $Service | Invoke-CimMethod -MethodName StopService
                }

                Start-Sleep -Seconds 2
                $Service = Get-CimInstance -CimSession $CimSession -ClassName Win32_Service -Filter "Name='$($serviceName)'"
            }

            if ($Service.State -ne "Stopped")
            {
                throw
            }
        }
        catch
        {
            Write-Verbose "Failed to use CIM for managing the $($serviceName) service on $($this.Name). Falling back to WMI."
            try
            {
                $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
                $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'" -ComputerName $this.Name

                while ($Service.State -ne "Stopped" -and $Stopwatch.Elapsed -lt $Timeout)
                {
                    if ($Service.State -ne "Stopping")
                    {
                        Write-Verbose "Stopping the $($serviceName) service on $($this.Name) using WMI."
                        $Service.StopService()
                    }

                    Start-Sleep -Seconds 2
                    $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'" -ComputerName $this.Name
                }

                if ($Service.State -ne "Stopped")
                {
                    Write-Error "Failed to stop the $($serviceName) service on $($this.Name) within the 10-minute timeout."
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

            if ($Stopwatch)
            {
                $Stopwatch.Stop()
            }
        }
    }
}