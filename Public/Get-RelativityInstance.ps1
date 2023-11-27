<#
.SYNOPSIS
Retrieves the configuration of a Relativity instance including all associated servers and their roles.

.DESCRIPTION
The Get-RelativityInstance function gathers comprehensive information about a specific Relativity instance. 
It retrieves the instance name and the configuration of various server roles including Agent, Distributed SQL, 
Primary SQL, Secret Store, Service Bus, Web, Worker Manager, and Worker servers.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties 
of the Relativity instance and its various servers.

.PARAMETER SecretStoreServers
Specifies an array of server names where the Relativity Secret Store is installed. These servers will be queried to 
retrieve their configuration and installation details.

.PARAMETER SecretStoreSqlInstance
Specifies the name of the SQL instance associated with the Secret Store. This information is used to set properties 
on each server object.

.EXAMPLE
$RelativityInstance = Get-RelativityInstance -PrimarySqlInstance "SQLInstanceName" -SecretStoreServers @("Server1", "Server2") -SecretStoreSqlInstance "SQLInstanceName"

This example retrieves the configuration of a Relativity instance, including details of its various servers, from the specified primary SQL instance.

.INPUTS
None.

.OUTPUTS
RelativityInstance
Returns a RelativityInstance object that encapsulates details of the Relativity instance and its associated servers.

.NOTES
This function is a composite command that internally calls multiple functions to aggregate information about different 
server roles within the Relativity instance. Adequate permissions and network access are required to successfully execute 
these sub-commands.
#>
function Get-RelativityInstance
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PrimarySqlInstance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $SecretStoreServers,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SecretStoreSqlInstance
    )

    Begin
    {
        Write-Verbose "Starting Get-RelativityInstance"
        Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Starting..." -PercentComplete 0.00
    }
    Process
    {
        try
        {
            Write-Verbose "Retrieving Relativity instance name from $($PrimarySqlInstance)."
            $InstanceName = Get-RelativityInstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.LicenseManager" -Name "Instance"
            
            if ($null -ne $InstanceName)
            {
                Write-Verbose "Retrieved Relativity instance $($InstanceName) from $($PrimarySqlInstance)."
                $Instance = New-RelativityInstance -Name $InstanceName
            }
            else 
            {
                throw "No instance name was retrieved."
            }
            
            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing Agent Servers..." -PercentComplete 0.00
            Get-RelativityAgentServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing DistributedSql Servers..." -PercentComplete 12.50
            Get-RelativityDistributedSqlServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing PrimarySql Servers..." -PercentComplete 25.00
            Get-RelativityPrimarySqlServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing SecretStore Servers..." -PercentComplete 37.50
            Get-RelativitySecretStoreServer -SecretStoreServers $SecretStoreServers -SecretStoreSqlInstance $SecretStoreSqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing ServiceBus Servers..." -PercentComplete 50.00
            Get-RelativityServiceBusServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing Web Servers..." -PercentComplete 62.50
            Get-RelativityWebServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing WorkerManager Servers..." -PercentComplete 75.00
            Get-RelativityWorkerManagerServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Processing Worker Servers..." -PercentComplete 87.50
            Get-RelativityWorkerServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            return $Instance
        }
        catch
        {
            Write-Error "An error occurred when retrieving a Relativity instance: $($_.Exception.Message)"
            throw
        }
    }
    End
    {
        Write-Progress -Activity "Retrieving Relativity Instance Configuration" -Status "Completed" -Completed
        Write-Verbose "Completed Get-RelativityInstance"
    }
}