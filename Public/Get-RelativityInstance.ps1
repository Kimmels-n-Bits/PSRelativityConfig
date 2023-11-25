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

        $GetInstanceSettingValueQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\Private\Queries\Relativity\Get-InstanceSettingValue.sql") -Raw
    }
    Process
    {
        try
        {
            Write-Verbose "Retrieving Relativity instance name from $($PrimarySqlInstance)."
            $Parameters = @{
                "@Section" = "kCura.LicenseManager"
                "@Name" = "Instance"
                "@MachineName" = ""
            }
            $InstanceName = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters
            
            if ($null -ne $InstanceName)
            {
                Write-Verbose "Retrieved Relativity instance $($InstanceName) from $($PrimarySqlInstance)."
                $Instance = New-RelativityInstance -Name $InstanceName
            }
            else 
            {
                throw "No instance name was retrieved."
            }
            
            Get-RelativityAgentServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityDistributedSqlServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityPrimarySqlServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativitySecretStoreServer -SecretStoreServers $SecretStoreServers -SecretStoreSqlInstance $SecretStoreSqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityServiceBusServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityWebServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityWorkerManagerServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

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
        Write-Verbose "Completed Get-RelativityInstance"
    }
}