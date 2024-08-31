<#
.SYNOPSIS
Retrieves configured ServiceBus servers for Relativity and their properties.

.DESCRIPTION
The Get-ServiceBusServer function is designed to retrieve a collection of ServiceBus server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the installation directory,
ServiceBus namespace, TLS settings, and shared access keys.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's ServiceBus servers.

.EXAMPLE
$ServiceBusServers = Get-ServiceBusServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of ServiceBus servers from the specified primary SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured ServiceBus server for Relativity. These objects 
contain properties such as the server name, roles, server FQDN, ServiceBus namespace, TLS enablement, 
and installation directory.

.NOTES
This function executes SQL queries to retrieve configuration data and uses REST calls to gather information about each 
ServiceBus server. Adequate permissions for SQL query execution and REST API access are required. Additionally, it accesses 
remote registry settings for installation directory information. Adequate permissions and network access are required to
successfully execute these operations.
#>
function Get-ServiceBusServer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PrimarySqlInstance
    )

    Begin
    {
        Write-Verbose "Started Get-ServiceBusServer."
    }
    Process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving ServerFQDN property for ServiceBus."
            $ServerFQDN = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "Relativity.ServiceBus" -Name "ServiceBusFullyQualifiedDomainName"

            Write-Verbose "Retrieving ServiceNamespace property for ServiceBus."
            $ServiceNamespace = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "Relativity.ServiceBus" -Name "ServiceNamespace"

            Write-Verbose "Retrieving SharedAccessKey property for ServiceBus."
            $SharedAccessKey = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "Relativity.ServiceBus" -Name "SharedAccessKey"
            $SharedAccessKey = ($SharedAccessKey | ConvertTo-SecureString -AsPlainText -Force)

            Write-Verbose "Retrieving SharedAccessKeyName property for ServiceBus."
            $SharedAccessKeyName = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "Relativity.ServiceBus" -Name "SharedAccessKeyName"

            Write-Verbose "Retrieving TlsEnabled property for ServiceBus."
            $TlsEnabled = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "Relativity.ServiceBus" -Name "EnableTLSForServiceBus"

            Write-Verbose "Validating retrieved properties for ServiceBus."
            if ($null -eq $ServerFQDN) { throw "ServerFQDN property was not retrieved for ServiceBus." }
            if ($null -eq $ServiceNamespace) { throw "ServiceNamespace property was not retrieved for ServiceBus." }
            if ($null -eq $SharedAccessKey) { throw "SharedAccessKey property was not retrieved for ServiceBus." }
            if ($null -eq $SharedAccessKeyName) { throw "SharedAccessKeyName property was not retrieved for ServiceBus." }
            if ($null -eq $TlsEnabled) { throw "TlsEnabled property was not retrieved for ServiceBus." }
            
            if ($TlsEnabled -eq "True")
            { 
                $TlsEnabled = 1
                $Protocol = "https"
                $Port = 15671
            }
            else
            {
                $TlsEnabled = 0
                $Protocol = "http"
                $Port = 15672
            }

            Write-Verbose "Retrieving ServiceBus servers from $($ServerFQDN)."
            $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($SharedAccessKeyName, $SharedAccessKey)
            $ServiceBusServers = Invoke-RestMethod -Uri "$($Protocol)://$($ServerFQDN):$($Port)/api/nodes" -Credential $Credential

            foreach ($ServiceBusServer in ($ServiceBusServers).name.Replace("rabbit@", ""))
            {
                Write-Verbose "Adding ServiceBus server: $($ServiceBusServer)."
                $Server = New-RelativityServer -Name $ServiceBusServer

                if ($Server.IsOnline)
                {
                    Write-Verbose "Retrieving InstallDir property for $($ServiceBusServer)."
                    $InstallDir = Get-RegistryKeyValue -ServerName $ServiceBusServer -RegistryPath "SOFTWARE\\kCura\\Relativity\\FeaturePaths" -KeyName "BaseInstallDir"

                    Write-Verbose "Setting properties for $($SecretStoreServer)."
                    $Server.AddRole("ServiceBus")
                    if ($null -ne $InstallDir) { $Server.SetProperty("InstallDir", $InstallDir) }
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)
                    $Server.SetProperty("ServerFQDN", $ServerFQDN)
                    $Server.SetProperty("ServiceNamespace", $ServiceNamespace)
                    $Server.SetProperty("TlsEnabled", $TlsEnabled)

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($ServiceBusServer) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving ServiceBus configuration: $($_.Exception.Message)."
            throw        
        }
    }
    End
    {
        Write-Verbose "Completed Get-ServiceBusServer."
    }
}