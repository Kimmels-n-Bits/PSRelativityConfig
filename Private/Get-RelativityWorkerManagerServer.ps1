<#
.SYNOPSIS
Retrieves configured Worker Manager servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativityWorkerManagerServer function is designed to retrieve a collection of Worker Manager server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the data files network path, 
dtSearch index path, SQL instance, SQL data and log directories, worker network path, queue manager install path, and identity server URL.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's Worker Manager servers.

.EXAMPLE
$WorkerManagerServers = Get-RelativityWorkerManagerServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of Worker Manager servers from the specified primary SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured Worker Manager server for Relativity. These objects 
contain properties such as the server name, roles, and various configuration settings.

.NOTES
This function performs complex data retrieval, including running multiple SQL queries against the specified primary SQL instance and 
accessing remote registry settings on each identified server. Adequate permissions and network access are required to successfully 
execute these operations.
#>
function Get-RelativityWorkerManagerServer
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
        Write-Verbose "Started Get-RelativityWorkerManagerServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
        $GetAppSettingValueQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Invariant\Get-AppSettingValue.sql") -Raw
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving WorkerManager servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "Worker Manager Server"
            }
            $WorkerManagerServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters
            Write-Verbose "Retrieved WorkerManager servers from $($PrimarySqlInstance)."

            foreach ($WorkerManagerServer in $WorkerManagerServers)
            {
                Write-Verbose "Adding WorkerManager server: $($WorkerManagerServer['Name'])."
                $Server = New-RelativityServer -Name $WorkerManagerServer['Name']
                $Server.AddRole("WorkerManager")
                $Server.SetProperty("RelativitySqlInstance", $PrimarySqlInstance)

                Write-Verbose "Retrieving DataFilesNetworkPath property for $($WorkerManagerServer['Name'])."
                $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $WorkerManagerServer['Name'])
                $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Invariant")
                $DataFilesNetworkPath = $RegistryKey.GetValue("DataFilesPath")

                if ($null -eq $DataFilesNetworkPath)
                {
                    throw "No data files network path was retrieved."
                }

                $Server.SetProperty("DataFilesNetworkPath", $DataFilesNetworkPath)
                Write-Verbose "Retrieved DataFilesNetworkPath property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving DtSearchIndexPath property for $($WorkerManagerServer['Name'])."
                $DtSearchIndexPath = $RegistryKey.GetValue("dtSearchPath")

                if ($null -eq $DtSearchIndexPath)
                {
                    throw "No dtSearch index path was retrieved."
                }

                $Server.SetProperty("DtSearchIndexPath", $DtSearchIndexPath)
                Write-Verbose "Retrieved DtSearchIndexPath property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving SqlInstance property for $($WorkerManagerServer['Name'])."
                $SqlInstance = $RegistryKey.GetValue("SQLInstance_QM")

                if ($null -eq $SqlInstance)
                {
                    throw "No SQL instance was retrieved."
                }

                $Server.SetProperty("SqlInstance", $SqlInstance)
                Write-Verbose "Retrieved SqlInstance property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving MdfDir property for $($WorkerManagerServer['Name'])."
                $MdfDir = $RegistryKey.GetValue("SQLMDFPath")

                if ($null -eq $MdfDir)
                {
                    throw "No SQL data directory was retrieved."
                }

                $Server.SetProperty("MdfDir", $MdfDir)
                Write-Verbose "Retrieved MdfDir property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving LdfDir property for $($WorkerManagerServer['Name'])."
                $LdfDir = $RegistryKey.GetValue("SQLLDFPath")

                if ($null -eq $LdfDir)
                {
                    throw "No SQL log directory was retrieved."
                }

                $Server.SetProperty("LdfDir", $LdfDir)
                Write-Verbose "Retrieved LdfDir property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving WorkerNetworkPath property for $($WorkerManagerServer['Name'])."
                $WorkerNetworkPath = $RegistryKey.GetValue("WorkerNetworkPath")

                if ($null -eq $WorkerNetworkPath)
                {
                    throw "No worker network path was retrieved."
                }

                $Server.SetProperty("WorkerNetworkPath", $WorkerNetworkPath)
                Write-Verbose "Retrieved WorkerNetworkPath property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving QueueManagerInstallPath property for $($WorkerManagerServer['Name'])."
                $QueueManagerInstallPath = $RegistryKey.GetValue("QueueManagerPath")

                if ($null -eq $QueueManagerInstallPath)
                {
                    throw "No queue manager install path was retrieved."
                }

                $Server.SetProperty("QueueManagerInstallPath", $QueueManagerInstallPath)
                Write-Verbose "Retrieved QueueManagerInstallPath property for $($WorkerManagerServer['Name'])."

                Write-Verbose "Retrieving IdentityServerUrl property for $($WorkerManagerServer['Name'])."
                $Parameters = @{
                    "@Category" = "IdentityServerURL"
                }
                $IdentityServerUrl = Invoke-SqlQueryAsScalar -SqlInstance $SqlInstance -Query $GetAppSettingValueQuery -Parameters $Parameters

                if ($null -eq $IdentityServerUrl)
                {
                    throw "No identity server URL was retrieved."
                }
                
                $Server.SetProperty("IdentityServerUrl", $IdentityServerUrl)
                Write-Verbose "Retrieved IdentityServerUrl property for $($WorkerManagerServer['Name'])."

                $Servers += $Server
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving WorkerManager configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityWorkerManagerServer."
    }
}