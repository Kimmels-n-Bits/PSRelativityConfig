<#
.SYNOPSIS
Retrieves configured DistributedSql servers for Relativity and their properties.

.DESCRIPTION
The Get-DistributedSqlServer function is designed to retrieve a collection of DistributedSql server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the installation directory, 
and database settings.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's DistributedSql servers.

.EXAMPLE
$DistributedSqlServers = Get-DistributedSqlServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of DistributedSql servers from the specified primary SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured DistributedSql server for Relativity. These objects 
contain properties such as the server name, roles, and installation directory.

.NOTES
This function performs complex data retrieval, including running multiple SQL queries against the specified primary SQL instance and 
accessing remote registry settings on each identified server. Adequate permissions and network access are required to successfully 
execute these operations.
#>
function Get-DistributedSqlServer
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
        Write-Verbose "Started Get-DistributedSqlServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
        $GetDistributedSqlInstanceNameQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-DistributedSqlInstanceName.sql") -Raw
    }
    Process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving DistributedSql servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "SQL - Distributed"
            }
            $DistributedSqlServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters

            foreach ($DistributedSqlServer in $DistributedSqlServers)
            {
                Write-Verbose "Adding DistributedSql server: $($DistributedSqlServer['Name'])."
                $Server = New-RelativityServer -Name $DistributedSqlServer['Name']

                if ($Server.IsOnline)
                {
                    Write-Verbose "Retrieving DatabaseBackupDir property for $($DistributedSqlServer['Name'])."
                    $DatabaseBackupDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "BackupDirectory" -MachineName $DistributedSqlServer['Name']

                    Write-Verbose "Retrieving DistributedSqlInstance property for $($DistributedSqlServer['Name'])."
                    $Parameters = @{
                        "@Name" = "$($DistributedSqlServer['Name'])"
                    }
                    $DistributedSqlInstance = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetDistributedSqlInstanceNameQuery -Parameters $Parameters

                    Write-Verbose "Retrieving FullTextDir property for $($DistributedSqlServer['Name'])."
                    $FullTextDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "FTDirectory" -MachineName $DistributedSqlServer['Name']

                    Write-Verbose "Retrieving InstallDir property for $($DistributedSqlServer['Name'])."
                    $InstallDir = Get-RegistryKeyValue -ServerName $DistributedSqlServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Relativity\\FeaturePaths" -KeyName "BaseInstallDir"

                    Write-Verbose "Retrieving LdfDir property for $($DistributedSqlServer['Name'])."
                    $LdfDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "LDFDirectory" -MachineName $DistributedSqlServer['Name']

                    Write-Verbose "Retrieving MdfDir property for $($DistributedSqlServer['Name'])."
                    $MdfDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "DataDirectory" -MachineName $DistributedSqlServer['Name']

                    Write-Verbose "Validating retrieved properties for $($DistributedSqlServer['Name'])."
                    if ($null -eq $DatabaseBackupDir) { throw "DatabaseBackupDir property was not retrieved for $($DistributedSqlServer['Name'])."}
                    if ($null -eq $DistributedSqlInstance) { throw "DistributedSqlInstance property was not retrieved for $($DistributedSqlServer['Name'])."}
                    if ($null -eq $InstallDir) { throw "InstallDir property was not retrieved for $($DistributedSqlServer['Name'])." }
                    if ($null -eq $LdfDir) { throw "LdfDir property was not retrieved for $($DistributedSqlServer['Name'])." }
                    if ($null -eq $MdfDir) { throw "MdfDir property was not retrieved for $($DistributedSqlServer['Name'])." }
                    if ($null -eq $FullTextDir) { throw "FullTextDir property was not retrieved for $($DistributedSqlServer['Name'])." }

                    Write-Verbose "Setting properties for $($DistributedSqlServer['Name'])."
                    $Server.AddRole("DistributedSql")
                    $Server.SetProperty("DatabaseBackupDir", $DatabaseBackupDir)
                    $Server.SetProperty("DistributedSqlInstance", $DistributedSqlInstance)
                    $Server.SetProperty("FullTextDir", $FullTextDir)
                    $Server.SetProperty("InstallDir", $InstallDir)
                    $Server.SetProperty("LdfDir", $LdfDir)
                    $Server.SetProperty("MdfDir", $MdfDir)
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($DistributedSqlServer['Name']) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving DistributedSql configuration: $($_.Exception.Message)."
            throw        
        }
    }
    End
    {
        Write-Verbose "Completed Get-DistributedSqlServer."
    }
}