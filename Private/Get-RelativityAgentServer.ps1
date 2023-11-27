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

    Begin
    {
        Write-Verbose "Started Get-RelativityAgentServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
    }
    Process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving Agent servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "Agent"
            }
            $AgentServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters

            foreach ($AgentServer in $AgentServers)
            {
                Write-Verbose "Adding Agent server: $($AgentServer['Name'])."
                $Server = New-RelativityServer -Name $AgentServer['Name']

                if ($Server.IsOnline)
                {
                    Write-Verbose "Retrieving InstallDir property for $($AgentServer['Name'])."
                    $InstallDir = Get-RegistryKeyValue -ServerName $AgentServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Relativity\\FeaturePaths" -KeyName "BaseInstallDir"

                    Write-Verbose "Validating retrieved properties for $($AgentServer['Name'])."
                    if ($null -eq $InstallDir) { throw "InstallDir property was not retrieved for $($AgentServer['Name'])." }

                    Write-Verbose "Setting properties for $($AgentServer['Name'])."
                    $Server.AddRole("Agent")
                    $Server.SetProperty("InstallDir", $InstallDir)
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)

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
    End
    {
        Write-Verbose "Completed Get-RelativityAgentServer."
    }
}