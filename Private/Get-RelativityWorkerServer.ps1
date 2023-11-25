<#
.SYNOPSIS
Retrieves configured Worker servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativityWorkerServer function is designed to retrieve a collection of Worker server objects for Relativity. 
Each server object includes its name, role, and additional properties such as the SQL instance and worker install path. 

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's Worker servers.

.EXAMPLE
$WorkerServers = Get-RelativityWorkerServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of Worker servers from the specified primary SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured Worker server for Relativity. These objects 
contain properties such as the server name, roles, SQL instance, and worker install path.

.NOTES
This function performs complex data retrieval, including running multiple SQL queries against the specified primary SQL instance and 
accessing remote registry settings on each identified server. Adequate permissions and network access are required to successfully 
execute these operations.
#>
function Get-RelativityWorkerServer
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
        Write-Verbose "Started Get-RelativityWorkerServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving Worker servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "Worker"
            }
            $WorkerServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters
            Write-Verbose "Retrieved Worker servers from $($PrimarySqlInstance)."

            foreach ($WorkerServer in $WorkerServers)
            {
                Write-Verbose "Adding Worker server: $($WorkerServer['Name'])."
                $Server = New-RelativityServer -Name $WorkerServer['Name']

                if ($Server.IsOnline)
                {
                    Start-RemoteService -ServiceName "RemoteRegistry" -ServerName $WorkerServer['Name']
                    $Server.AddRole("Worker")
                    $Server.SetProperty("RelativitySqlInstance", $PrimarySqlInstance)

                    Write-Verbose "Retrieving SqlInstance property for $($WorkerServer['Name'])."
                    $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $WorkerServer['Name'])
                    $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Invariant")
                    $SqlInstance = $RegistryKey.GetValue("SQLInstance_W")

                    if ($null -eq $SqlInstance)
                    {
                        throw "No SQL instance was retrieved."
                    }

                    $Server.SetProperty("SqlInstance", $SqlInstance)
                    Write-Verbose "Retrieved SqlInstance property for $($WorkerServer['Name'])."

                    Write-Verbose "Retrieving WorkerInstallPath property for $($WorkerServer['Name'])."
                    $WorkerInstallPath = $RegistryKey.GetValue("Path")

                    if ($null -eq $WorkerInstallPath)
                    {
                        throw "No worker install path was retrieved."
                    }

                    $Server.SetProperty("WorkerInstallPath", $WorkerInstallPath)
                    Write-Verbose "Retrieved WorkerInstallPath property for $($WorkerServer['Name'])."

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($WorkerServer['Name']) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving Worker configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityWorkerServer."
    }
}