<#
.SYNOPSIS
Retrieves configured DistributedSql servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativityDistributedSqlServer function is designed to retrieve a collection of DistributedSql server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the installation directory, 
and database settings.

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's DistributedSql servers.

.EXAMPLE
$DistributedSqlServers = Get-RelativityDistributedSqlServer -PrimarySqlInstance "SQLInstanceName"

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
function Get-RelativityDistributedSqlServer
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
        Write-Verbose "Started Get-RelativityDistributedSqlServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
        $GetDistributedSqlInstanceNameQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-DistributedSqlInstanceName.sql") -Raw
        $GetInstanceSettingValueQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-InstanceSettingValue.sql") -Raw
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving DistributedSql servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "SQL - Distributed"
            }
            $DistributedSqlServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters
            Write-Verbose "Retrieved DistributedSql servers from $($PrimarySqlInstance)."

            foreach ($DistributedSqlServer in $DistributedSqlServers)
            {
                Write-Verbose "Adding DistributedSql server: $($DistributedSqlServer['Name'])."
                $Server = New-RelativityServer -Name $DistributedSqlServer['Name']
                $Server.AddRole("DistributedSql")
                $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)

                Write-Verbose "Retrieving InstallDir property for $($DistributedSqlServer['Name'])."
                $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $DistributedSqlServer['Name'])
                $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Relativity\\FeaturePaths")
                $InstallDir = $RegistryKey.GetValue("BaseInstallDir")

                if ($null -eq $InstallDir)
                {
                    throw "No installation directory was retrieved."
                }

                $Server.SetProperty("InstallDir", $InstallDir)
                Write-Verbose "Retrieved InstallDir property for $($DistributedSqlServer['Name'])."

                Write-Verbose "Retrieving DistributedSqlInstance property for $($DistributedSqlServer['Name'])."
                $Parameters = @{
                    "@Name" = "$($DistributedSqlServer['Name'])"
                }
                $DistributedSqlInstance = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetDistributedSqlInstanceNameQuery -Parameters $Parameters

                if ($null -eq $DistributedSqlInstance)
                {
                    throw "No distributed SQL instance name was retrieved."
                }

                $Server.SetProperty("DistributedSqlInstance", $DistributedSqlInstance)
                Write-Verbose "Retrieved DistributedSqlInstance property for $($DistributedSqlServer['Name'])."

                Write-Verbose "Retrieving DatabaseBackupDir property for $($DistributedSqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "BackupDirectory"
                    "@MachineName" = "$($DistributedSqlServer['Name'])"
                }
                $DatabaseBackupDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                if ($null -eq $DatabaseBackupDir)
                {
                    $Parameters = @{
                        "@Section" = "kCura.EDDS.SqlServer"
                        "@Name" = "BackupDirectory"
                        "@MachineName" = ""
                    }
                    $DatabaseBackupDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                    if ($null -eq $DatabaseBackupDir)
                    {
                        throw "No database backup directory was retrieved."
                    }
                }
                
                $Server.SetProperty("DatabaseBackupDir", $DatabaseBackupDir)
                Write-Verbose "Retrieved DatabaseBackupDir property for $($DistributedSqlServer['Name'])."

                Write-Verbose "Retrieving LdfDir property for $($DistributedSqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "LDFDirectory"
                    "@MachineName" = "$($DistributedSqlServer['Name'])"
                }
                $LdfDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                if ($null -eq $LdfDir)
                {
                    $Parameters = @{
                        "@Section" = "kCura.EDDS.SqlServer"
                        "@Name" = "LDFDirectory"
                        "@MachineName" = ""
                    }
                    $LdfDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                    if ($null -eq $LdfDir)
                    {
                        throw "No database log directory was retrieved."
                    }
                }
                
                $Server.SetProperty("LdfDir", $LdfDir)
                Write-Verbose "Retrieved LdfDir property for $($DistributedSqlServer['Name'])."

                Write-Verbose "Retrieving MdfDir property for $($DistributedSqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "DataDirectory"
                    "@MachineName" = "$($DistributedSqlServer['Name'])"
                }
                $MdfDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                if ($null -eq $MdfDir)
                {
                    $Parameters = @{
                        "@Section" = "kCura.EDDS.SqlServer"
                        "@Name" = "DataDirectory"
                        "@MachineName" = ""
                    }
                    $MdfDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                    if ($null -eq $MdfDir)
                    {
                        throw "No database data directory was retrieved."
                    }
                }
                
                $Server.SetProperty("MdfDir", $MdfDir)
                Write-Verbose "Retrieved MdfDir property for $($DistributedSqlServer['Name'])."

                Write-Verbose "Retrieving FullTextDir property for $($DistributedSqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "FTDirectory"
                    "@MachineName" = "$($DistributedSqlServer['Name'])"
                }
                $FullTextDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                if ($null -eq $FullTextDir)
                {
                    $Parameters = @{
                        "@Section" = "kCura.EDDS.SqlServer"
                        "@Name" = "FTDirectory"
                        "@MachineName" = ""
                    }
                    $FullTextDir = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                    if ($null -eq $FullTextDir)
                    {
                        throw "No database fulltext directory was retrieved."
                    }
                }
                
                $Server.SetProperty("FullTextDir", $FullTextDir)
                Write-Verbose "Retrieved FullTextDir property for $($DistributedSqlServer['Name'])."

                $Servers += $Server
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving DistributedSql configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityDistributedSqlServer."
    }
}