<#
.SYNOPSIS
Retrieves configured Web servers for Relativity and their properties.

.DESCRIPTION
The Get-WebServer function is designed to retrieve a collection of Web server objects for Relativity. 
Each server object includes its name, role, and additional properties such as the installation directory and 
Windows Authentication settings.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's Web servers.

.EXAMPLE
$WebServers = Get-WebServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of Web servers from the specified primary SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured Web server for Relativity. These objects 
contain properties such as the server name, roles, installation directory, and Windows Authentication settings.

.NOTES
This function performs complex data retrieval, including running multiple SQL queries against the specified primary SQL instance and 
accessing remote registry settings on each identified server. Adequate permissions and network access are required to successfully 
execute these operations.
#>
function Get-WebServer
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
        Write-Verbose "Started Get-WebServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
        $GetWebEnableWinAuthQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-WebEnableWinAuth.sql") -Raw
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving Web servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "Web:Forms Authentication"
            }
            $WebServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters

            foreach ($WebServer in $WebServers)
            {
                Write-Verbose "Adding Web server: $($WebServer['Name'])."
                $Server = New-RelativityServer -Name $WebServer['Name']

                if ($Server.IsOnline)
                {
                    Write-Verbose "Retrieving EnableWinAuth property for $($WebServer['Name'])."
                    $Parameters = @{
                        "@Name" = "$($WebServer['Name'])"
                    }
                    $EnableWinAuth = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetWebEnableWinAuthQuery -Parameters $Parameters

                    Write-Verbose "Retrieving InstallDir property for $($WebServer['Name'])."
                    $InstallDir = Get-RegistryKeyValue -ServerName $WebServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Relativity\\FeaturePaths" -KeyName "BaseInstallDir"

                    Write-Verbose "Validating retrieved properties for $($WebServer['Name'])."
                    if ($null -eq $InstallDir) { throw "InstallDir property was not retrieved for $($WebServer['Name'])." }
                    if ($null -eq $EnableWinAuth) { throw "EnableWinAuth property was not retrieved for $($WebServer['Name'])." }
                    
                    Write-Verbose "Setting properties for $($WebServer['Name'])."
                    $Server.AddRole("Web")
                    $Server.SetProperty("EnableWinAuth", $EnableWinAuth)
                    $Server.SetProperty("InstallDir", $InstallDir)
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($WebServer['Name']) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving Web configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-WebServer."
    }
}