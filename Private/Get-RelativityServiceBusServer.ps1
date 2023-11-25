<#
.SYNOPSIS
Retrieves configured ServiceBus servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativityServiceBusServer function is designed to retrieve a collection of ServiceBus server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the installation directory,
ServiceBus namespace, TLS settings, and shared access keys.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's ServiceBus servers.

.EXAMPLE
$ServiceBusServers = Get-RelativityServiceBusServer -PrimarySqlInstance "SQLInstanceName"

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
function Get-RelativityServiceBusServer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PrimarySqlInstance
    )

    begin
    {
        Write-Verbose "Started Get-RelativityServiceBusServer."
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving ServerFQDN property for ServiceBus."
            $Parameters = @{
                "@Section" = "Relativity.ServiceBus"
                "@Name" = "ServiceBusFullyQualifiedDomainName"
                "@MachineName" = ""
            }
            $ServerFQDN = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

            if ($null -eq $ServerFQDN)
            {
                throw "No ServiceBus server fully qualified domain name was retrieved."
            }
            
            Write-Verbose "Retrieved ServerFQDN property for ServiceBus."

            Write-Verbose "Retrieving ServiceNamespace property for ServiceBus."
            $Parameters = @{
                "@Section" = "Relativity.ServiceBus"
                "@Name" = "ServiceNamespace"
                "@MachineName" = ""
            }
            $ServiceNamespace = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

            if ($null -eq $ServiceNamespace)
            {
                throw "No ServiceBus service namespace was retrieved."
            }
            
            Write-Verbose "Retrieved ServiceNamespace property for ServiceBus."

            Write-Verbose "Retrieving TlsEnabled property for ServiceBus."
            $Parameters = @{
                "@Section" = "Relativity.ServiceBus"
                "@Name" = "EnableTLSForServiceBus"
                "@MachineName" = ""
            }
            $TlsEnabled = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

            if ($null -eq $TlsEnabled)
            {
                throw "No ServiceBus TLS setting was retrieved."
            }
            
            if ($TlsEnabled -eq "True")
            {
                $TlsEnabled = 1
            }
            else
            {
                $TlsEnabled = 0
            }

            Write-Verbose "Retrieved TlsEnabled property for ServiceBus."

            Write-Verbose "Retrieving SharedAccessKeyName property for ServiceBus."
            $Parameters = @{
                "@Section" = "Relativity.ServiceBus"
                "@Name" = "SharedAccessKeyName"
                "@MachineName" = ""
            }
            $SharedAccessKeyName = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

            if ($null -eq $SharedAccessKeyName)
            {
                throw "No ServiceBus shared access key name was retrieved."
            }
            
            Write-Verbose "Retrieved SharedAccessKeyName property for ServiceBus."

            Write-Verbose "Retrieving SharedAccessKey property for ServiceBus."
            $Parameters = @{
                "@Section" = "Relativity.ServiceBus"
                "@Name" = "SharedAccessKey"
                "@MachineName" = ""
            }
            $SharedAccessKey = (Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters | ConvertTo-SecureString -AsPlainText -Force)

            if ($null -eq $SharedAccessKey)
            {
                throw "No ServiceBus shared access key was retrieved."
            }
            
            Write-Verbose "Retrieved SharedAccessKey property for ServiceBus."

            Write-Verbose "Retrieving ServiceBus servers from $($ServerFQDN)."

            if ($TlsEnabled -eq 1)
            {
                $Protocol = "https"
                $Port = 15671
            }
            else
            {
                $Protocol = "http"
                $Port = 15672
            }

            $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($SharedAccessKeyName, $SharedAccessKey)
            $ServiceBusServers = Invoke-RestMethod -Uri "$($Protocol)://$($ServerFQDN):$($Port)/api/nodes" -Credential $Credential

            Write-Verbose "Retrieved ServiceBus servers from $($ServerFQDN)."

            foreach ($ServiceBusServer in ($ServiceBusServers).name.Replace("rabbit@", ""))
            {
                Write-Verbose "Adding ServiceBus server: $($ServiceBusServer)."
                $Server = New-RelativityServer -Name $ServiceBusServer

                if ($Server.IsOnline)
                {
                    Start-RemoteService -ServiceName "RemoteRegistry" -ServerName $ServiceBusServer
                    $Server.AddRole("ServiceBus")
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)
                    $Server.SetProperty("ServerFQDN", $ServerFQDN)
                    $Server.SetProperty("ServiceNamespace", $ServiceNamespace)
                    $Server.SetProperty("TlsEnabled", $TlsEnabled)

                    Write-Verbose "Retrieving InstallDir property for $($ServiceBusServer)."
                    $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ServiceBusServer)
                    $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Relativity\\FeaturePaths")

                    if (-not $null -eq $RegistryKey)
                    {
                        $InstallDir = $RegistryKey.GetValue("BaseInstallDir")
                        $Server.SetProperty("InstallDir", $InstallDir)
                    }

                    Write-Verbose "Retrieved InstallDir property for $($ServiceBusServer)."

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
    end
    {
        Write-Verbose "Completed Get-RelativityServiceBusServer."
    }
}