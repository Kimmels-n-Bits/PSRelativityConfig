<#
.SYNOPSIS
Retrieves configured Agent servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativityAgentServer function is designed to retrieve a collection of Agent server objects for Relativity. 
Each server object includes its name, role, and additional properties such as the installation directory.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's Agent servers.

.EXAMPLE
$AgentServers = Get-RelativityAgentServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of Agent servers from the specified primary SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured Agent server for Relativity. These objects 
contain properties such as the server name, roles, and installation directory.

.NOTES
This function performs complex data retrieval, including running multiple SQL queries against the specified primary SQL instance and 
accessing remote registry settings on each identified server. Adequate permissions and network access are required to successfully 
execute these operations.
#>
function Get-RelativityAgentServer
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
        Write-Verbose "Started Get-RelativityAgentServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving Agent servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "Agent"
            }
            $AgentServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters
            Write-Verbose "Retrieved Agent servers from $($PrimarySqlInstance)."

            foreach ($AgentServer in $AgentServers)
            {
                Write-Verbose "Adding Agent server: $($AgentServer['Name'])."
                $Server = New-RelativityServer -Name $AgentServer['Name']

                if ($Server.IsOnline)
                {
                    Start-RemoteService -ServiceName "RemoteRegistry" -ServerName $AgentServer['Name']
                    $Server.AddRole("Agent")
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)

                    Write-Verbose "Retrieving InstallDir property for $($AgentServer['Name'])."
                    $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $AgentServer['Name'])
                    $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Relativity\\FeaturePaths")
                    $InstallDir = $RegistryKey.GetValue("BaseInstallDir")

                    if ($null -eq $InstallDir)
                    {
                        throw "No installation directory was retrieved."
                    }

                    $Server.SetProperty("InstallDir", $InstallDir)
                    Write-Verbose "Retrieved InstallDir property for $($AgentServer['Name'])."

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($AgentServer['Name']) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving Agent configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityAgentServer."
    }
}