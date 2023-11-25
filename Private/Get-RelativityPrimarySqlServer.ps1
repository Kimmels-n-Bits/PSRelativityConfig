<#
.SYNOPSIS
Retrieves configured PrimarySql servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativityPrimarySqlServer function is designed to retrieve a collection of PrimarySql server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the installation directory, 
default file repository, and database settings. 

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's primary SQL servers.

.EXAMPLE
$PrimarySqlServers = Get-RelativityPrimarySqlServer -PrimarySqlInstance "SQLInstanceName"

This example retrieves configuration details of primary SQL servers from the specified SQL instance "SQLInstanceName".

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured PrimarySql server for Relativity. These objects 
contain properties such as the server name, roles, and installation directory.

.NOTES
This function performs complex data retrieval including running multiple SQL queries against the specified primary SQL instance and 
accessing remote registry settings on each identified server. Adequate permissions and network access are required to successfully 
execute these operations.
#>
function Get-RelativityPrimarySqlServer
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
        Write-Verbose "Started Get-RelativityPrimarySqlServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
        $GetDefaultFileRepositoryQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-DefaultFileRepository.sql") -Raw
        $GetInstanceSettingValueQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-InstanceSettingValue.sql") -Raw
        $GetCacheLocationQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-CacheLocation.sql") -Raw
        $GetDtSearchIndexPathQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-DtSearchIndexPath.sql") -Raw
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving PrimarySql servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "SQL - Primary"
            }
            $PrimarySqlServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters
            Write-Verbose "Retrieved PrimarySql servers from $($PrimarySqlInstance)."

            foreach ($PrimarySqlServer in $PrimarySqlServers)
            {
                Write-Verbose "Adding PrimarySql server: $($PrimarySqlServer['Name'])."
                $Server = New-RelativityServer -Name $PrimarySqlServer['Name']
                $Server.AddRole("PrimarySql")
                $Server.ResponseFileProperties["PrimarySqlInstance"] = $PrimarySqlInstance

                Write-Verbose "Retrieving InstallDir property for $($PrimarySqlServer['Name'])."
                $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $PrimarySqlServer['Name'])
                $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Relativity\\FeaturePaths")
                $InstallDir = $RegistryKey.GetValue("BaseInstallDir")

                if ($null -eq $InstallDir)
                {
                    throw "No installation directory was retrieved."
                }

                $Server.ResponseFileProperties["InstallDir"] = $InstallDir
                Write-Verbose "Retrieved InstallDir property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving DefaultFileRepository property for $($PrimarySqlServer['Name'])."
                $DefaultFileRepository = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetDefaultFileRepositoryQuery

                if ($null -eq $DefaultFileRepository)
                {
                    throw "No default file repository was retrieved."
                }

                $Server.ResponseFileProperties["DefaultFileRepository"] = $DefaultFileRepository
                Write-Verbose "Retrieved DefaultFileRepository property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving EddsFileShare property for $($PrimarySqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "Relativity.Data"
                    "@Name" = "EDDSFileShare"
                    "@MachineName" = ""
                }
                $EddsFileShare = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                if ($null -eq $EddsFileShare)
                {
                    throw "No EDDS file share was retrieved."
                }
                
                $Server.ResponseFileProperties["EddsFileShare"] = $EddsFileShare
                Write-Verbose "Retrieved EddsFileShare property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving CacheLocation property for $($PrimarySqlServer['Name'])."
                $CacheLocation = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetCacheLocationQuery

                if ($null -eq $CacheLocation)
                {
                    throw "No cache location was retrieved."
                }

                $Server.ResponseFileProperties["CacheLocation"] = $CacheLocation
                Write-Verbose "Retrieved CacheLocation property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving DtSearchIndexPath property for $($PrimarySqlServer['Name'])."
                $DtSearchIndexPath = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetDtSearchIndexPathQuery

                if ($null -eq $DtSearchIndexPath)
                {
                    throw "No dtSearch index path was retrieved."
                }

                $Server.ResponseFileProperties["DtSearchIndexPath"] = $DtSearchIndexPath
                Write-Verbose "Retrieved DtSearchIndexPath property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving RelativityInstanceName property for $($PrimarySqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.LicenseManager"
                    "@Name" = "Instance"
                    "@MachineName" = ""
                }
                $RelativityInstanceName = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

                if ($null -eq $EddsFileShare)
                {
                    throw "No instance name was retrieved."
                }
                
                $Server.ResponseFileProperties["RelativityInstanceName"] = $RelativityInstanceName
                Write-Verbose "Retrieved RelativityInstanceName property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving DatabaseBackupDir property for $($PrimarySqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "BackupDirectory"
                    "@MachineName" = "$($PrimarySqlServer['Name'])"
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
                
                $Server.ResponseFileProperties["DatabaseBackupDir"] = $DatabaseBackupDir
                Write-Verbose "Retrieved DatabaseBackupDir property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving LdfDir property for $($PrimarySqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "LDFDirectory"
                    "@MachineName" = "$($PrimarySqlServer['Name'])"
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
                
                $Server.ResponseFileProperties["LdfDir"] = $LdfDir
                Write-Verbose "Retrieved LdfDir property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving MdfDir property for $($PrimarySqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "DataDirectory"
                    "@MachineName" = "$($PrimarySqlServer['Name'])"
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
                
                $Server.ResponseFileProperties["MdfDir"] = $MdfDir
                Write-Verbose "Retrieved MdfDir property for $($PrimarySqlServer['Name'])."

                Write-Verbose "Retrieving FullTextDir property for $($PrimarySqlServer['Name'])."
                $Parameters = @{
                    "@Section" = "kCura.EDDS.SqlServer"
                    "@Name" = "FTDirectory"
                    "@MachineName" = "$($PrimarySqlServer['Name'])"
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
                
                $Server.ResponseFileProperties["FullTextDir"] = $FullTextDir
                Write-Verbose "Retrieved FullTextDir property for $($PrimarySqlServer['Name'])."

                $Servers += $Server
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving PrimarySql configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityPrimarySqlServer."
    }
}