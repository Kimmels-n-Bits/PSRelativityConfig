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

            foreach ($WorkerManagerServer in $WorkerManagerServers)
            {
                Write-Verbose "Adding WorkerManager server: $($WorkerManagerServer['Name'])."
                $Server = New-RelativityServer -Name $WorkerManagerServer['Name']

                if ($Server.IsOnline)
                {
                    <# Getting and validating SqlInstance property out of alphabetical order because it's required to retrieve the IdentityServerUrl property. #>
                    Write-Verbose "Retrieving SqlInstance property for $($WorkerManagerServer['Name'])."
                    $SqlInstance = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "SQLInstance_QM"

                    Write-Verbose "Validating SqlInstance property for $($WorkerManagerServer['Name'])."
                    if ($null -eq $SqlInstance) { throw "SqlInstance property was not retrieved for $($WorkerManagerServer['Name'])." }

                    Write-Verbose "Retrieving DataFilesNetworkPath property for $($WorkerManagerServer['Name'])."
                    $DataFilesNetworkPath = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "DataFilesPath"

                    Write-Verbose "Retrieving DtSearchIndexPath property for $($WorkerManagerServer['Name'])."
                    $DtSearchIndexPath = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "dtSearchPath"

                    Write-Verbose "Retrieving IdentityServerUrl property for $($WorkerManagerServer['Name'])."
                    $Parameters = @{
                        "@Category" = "IdentityServerURL"
                    }
                    $IdentityServerUrl = Invoke-SqlQueryAsScalar -SqlInstance $SqlInstance -Query $GetAppSettingValueQuery -Parameters $Parameters

                    Write-Verbose "Retrieving LdfDir property for $($WorkerManagerServer['Name'])."
                    $LdfDir = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "SQLLDFPath"

                    Write-Verbose "Retrieving MdfDir property for $($WorkerManagerServer['Name'])."
                    $MdfDir = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "SQLMDFPath"

                    Write-Verbose "Retrieving QueueManagerInstallPath property for $($WorkerManagerServer['Name'])."
                    $QueueManagerInstallPath = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "QueueManagerPath"

                    Write-Verbose "Retrieving WorkerNetworkPath property for $($WorkerManagerServer['Name'])."
                    $WorkerNetworkPath = Get-RegistryKeyValue -ServerName $WorkerManagerServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Invariant" -KeyName "WorkerNetworkPath"

                    Write-Verbose "Validating retrieved properties for $($WorkerManagerServer['Name'])."
                    if ($null -eq $DataFilesNetworkPath) { throw "DataFilesNetworkPath property was not retrieved for $($WorkerManagerServer['Name'])."}
                    if ($null -eq $DtSearchIndexPath) { throw "DtSearchIndexPath property was not retrieved for $($WorkerManagerServer['Name'])." }
                    if ($null -eq $IdentityServerUrl) { throw "IdentityServerUrl property was not retrieved for $($WorkerManagerServer['Name'])." }
                    if ($null -eq $MdfDir) { throw "MdfDir property was not retrieved for $($WorkerManagerServer['Name'])." }
                    if ($null -eq $LdfDir) { throw "LdfDir property was not retrieved for $($WorkerManagerServer['Name'])." }
                    if ($null -eq $QueueManagerInstallPath) { throw "QueueManagerInstallPath property was not retrieved for $($WorkerManagerServer['Name'])." }
                    if ($null -eq $WorkerNetworkPath) { throw "WorkerNetworkPath property was not retrieved for $($WorkerManagerServer['Name'])." }

                    Write-Verbose "Setting properties for $($WorkerManagerServer['Name'])."
                    $Server.AddRole("WorkerManager")
                    $Server.SetProperty("DataFilesNetworkPath", $DataFilesNetworkPath)
                    $Server.SetProperty("DtSearchIndexPath", $DtSearchIndexPath)
                    $Server.SetProperty("IdentityServerUrl", $IdentityServerUrl)
                    $Server.SetProperty("LdfDir", $LdfDir)
                    $Server.SetProperty("MdfDir", $MdfDir)
                    $Server.SetProperty("QueueManagerInstallPath", $QueueManagerInstallPath)
                    $Server.SetProperty("RelativitySqlInstance", $PrimarySqlInstance)
                    $Server.SetProperty("SqlInstance", $SqlInstance)
                    $Server.SetProperty("WorkerNetworkPath", $WorkerNetworkPath)

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($WorkerManagerServer['Name']) was not reachable and has been skipped."
                }
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