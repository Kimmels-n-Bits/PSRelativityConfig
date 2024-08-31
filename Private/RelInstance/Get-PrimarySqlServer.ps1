<#
.SYNOPSIS
Retrieves configured PrimarySql servers for Relativity and their properties.

.DESCRIPTION
The Get-PrimarySqlServer function is designed to retrieve a collection of PrimarySql server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the installation directory, 
default file repository, and database settings. 

.PARAMETER PrimarySqlInstance
Specifies the primary SQL instance to query. This instance is used to gather data about the configuration and properties of 
Relativity's PrimarySql servers.

.EXAMPLE
$PrimarySqlServers = Get-PrimarySqlServer -PrimarySqlInstance "SQLInstanceName"

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
function Get-PrimarySqlServer
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
        Write-Verbose "Started Get-PrimarySqlServer."
        $GetRelativityServersByTypeQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-RelativityServersByType.sql") -Raw
        $GetDefaultFileRepositoryQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-DefaultFileRepository.sql") -Raw
        $GetCacheLocationQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-CacheLocation.sql") -Raw
        $GetDtSearchIndexPathQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-DtSearchIndexPath.sql") -Raw
    }
    Process
    {
        try
        {
            $Servers = @()

            Write-Verbose "Retrieving PrimarySql servers from $($PrimarySqlInstance)."
            $Parameters = @{
                "@ServerType" = "SQL - Primary"
            }
            $PrimarySqlServers = Invoke-SqlQueryAsDataTable -SqlInstance $PrimarySqlInstance -Query $GetRelativityServersByTypeQuery -Parameters $Parameters

            foreach ($PrimarySqlServer in $PrimarySqlServers)
            {
                Write-Verbose "Adding PrimarySql server: $($PrimarySqlServer['Name'])."
                $Server = New-RelativityServer -Name $PrimarySqlServer['Name']

                if ($Server.IsOnline)
                {
                    Write-Verbose "Retrieving CacheLocation property for $($PrimarySqlServer['Name'])."
                    $CacheLocation = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetCacheLocationQuery

                    Write-Verbose "Retrieving DatabaseBackupDir property for $($PrimarySqlServer['Name'])."
                    $DatabaseBackupDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "BackupDirectory" -MachineName $PrimarySqlServer['Name']

                    Write-Verbose "Retrieving DefaultFileRepository property for $($PrimarySqlServer['Name'])."
                    $DefaultFileRepository = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetDefaultFileRepositoryQuery

                    Write-Verbose "Retrieving DtSearchIndexPath property for $($PrimarySqlServer['Name'])."
                    $DtSearchIndexPath = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetDtSearchIndexPathQuery

                    Write-Verbose "Retrieving EddsFileShare property for $($PrimarySqlServer['Name'])."
                    $EddsFileShare = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "Relativity.Data" -Name "EDDSFileShare" -MachineName $PrimarySqlServer['Name']

                    Write-Verbose "Retrieving FullTextDir property for $($PrimarySqlServer['Name'])."
                    $FullTextDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "FTDirectory" -MachineName $PrimarySqlServer['Name']

                    Write-Verbose "Retrieving LdfDir property for $($PrimarySqlServer['Name'])."
                    $LdfDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "LDFDirectory" -MachineName $PrimarySqlServer['Name']

                    Write-Verbose "Retrieving MdfDir property for $($PrimarySqlServer['Name'])."
                    $MdfDir = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.EDDS.SqlServer" -Name "DataDirectory" -MachineName $PrimarySqlServer['Name']

                    Write-Verbose "Retrieving InstallDir property for $($PrimarySqlServer['Name'])."
                    $InstallDir = Get-RegistryKeyValue -ServerName $PrimarySqlServer['Name'] -RegistryPath "SOFTWARE\\kCura\\Relativity\\FeaturePaths" -KeyName "BaseInstallDir"

                    Write-Verbose "Retrieving RelativityInstanceName property for $($PrimarySqlServer['Name'])."
                    $RelativityInstanceName = Get-InstanceSetting -SqlInstance $PrimarySqlInstance -Section "kCura.LicenseManager" -Name "Instance" -MachineName $PrimarySqlServer['Name']

                    Write-Verbose "Validating retrieved properties for $($PrimarySqlServer['Name'])."
                    if ($null -eq $CacheLocation) { throw "CacheLocation property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $DatabaseBackupDir) { throw "DatabaseBackupDir property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $DefaultFileRepository) { throw "DefaultFileRepository property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $DtSearchIndexPath) { throw "DtSearchIndexPath property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $EddsFileShare) { throw "EddsFileShare property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $FullTextDir) { throw "FullTextDir property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $InstallDir) { throw "InstallDir property was not retrieved for $($PrimarySqlServer['Name'])." }                    
                    if ($null -eq $LdfDir) { throw "LdfDir property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $MdfDir) { throw "MdfDir property was not retrieved for $($PrimarySqlServer['Name'])." }
                    if ($null -eq $RelativityInstanceName) { throw "RelativityInstanceName property was not retrieved for $($PrimarySqlServer['Name'])." }

                    Write-Verbose "Setting properties for $($PrimarySqlServer['Name'])."
                    $Server.AddRole("PrimarySql")
                    $Server.SetProperty("CacheLocation", $CacheLocation)
                    $Server.SetProperty("DatabaseBackupDir", $DatabaseBackupDir)
                    $Server.SetProperty("DefaultFileRepository", $DefaultFileRepository)
                    $Server.SetProperty("DtSearchIndexPath", $DtSearchIndexPath)
                    $Server.SetProperty("EddsFileShare", $EddsFileShare)
                    $Server.SetProperty("FullTextDir", $FullTextDir)
                    $Server.SetProperty("InstallDir", $InstallDir)
                    $Server.SetProperty("LdfDir", $LdfDir)
                    $Server.SetProperty("MdfDir", $MdfDir)
                    $Server.SetProperty("PrimarySqlInstance", $PrimarySqlInstance)
                    $Server.SetProperty("RelativityInstanceName", $RelativityInstanceName)

                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($PrimarySqlServer['Name']) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving PrimarySql configuration: $($_.Exception.Message)."
            throw        
        }
    }
    End
    {
        Write-Verbose "Completed Get-PrimarySqlServer."
    }
}