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
    [ValidateNotNullOrEmpty()]
    [String] $InstallerDirectory
    [ValidateNotNull()]
    [PSCredential] $ServiceAccountCredential
    [ValidateNotNull()]
    [PSCredential] $EDDSDBOCredential
    [ValidateNotNull()]
    [PSCredential] $RabbitMQCredential

    RelativityInstance(
        [String] $name,
        [String] $friendlyName,
        [String] $installerDirectory,
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
            $this.InstallerDirectory = $installerDirectory
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
            $this.ValidateResponseFileProperties($server)

            Write-Verbose "Propagating instance-level settings to $($server.Name)."
            $server.InstallerDirectory = $this.InstallerDirectory
            $server.ServiceAccountCredential = $this.ServiceAccountCredential
            $server.EDDSDBOCredential = $this.EDDSDBOCredential
            $server.RabbitMQCredential = $this.RabbitMQCredential

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
            Write-Error "An error occurred while validating response file properties for $($server.Name): $($_.Exception.Message)."
            throw
        }
    }

    [void] FlagAllServersForInstallation()
    {
        try
        {
            Write-Verbose "Flagging all servers for installation."
            {
                foreach ($Server in $this.Servers)
                {
                    Write-Verbose "Flagging $($Server.Name) for installation."
                    $Server.DoInstall = $true
                }
            }
       }
       catch
       {
        Write-Error "An error occurred while flagging a server for installation: $($_.Exception.Message)."
        throw
       }
    }
}
