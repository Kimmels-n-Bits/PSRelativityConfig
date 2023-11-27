<#
.SYNOPSIS
Retrieves a specific instance setting from a Relativity environment.

.DESCRIPTION
The Get-RelativityInstanceSetting function queries a Relativity SQL database to retrieve the value of a specified 
instance setting.

.PARAMETER SqlInstance
Specifies the SQL Server instance where the Relativity database resides. The parameter accepts the server instance 
in the format "ServerName" or "ServerName\InstanceName".

.PARAMETER Section
Specifies the section in the instance settings where the setting is categorized.

.PARAMETER Name
Specifies the name of the instance setting to be retrieved.

.PARAMETER MachineName
(Optional) Specifies the machine name for which the setting is relevant. If not provided, or if no specific setting 
is found for the given machine name, the function queries for a general setting with an empty machine name.

.EXAMPLE
$InstanceSetting = Get-RelativityInstanceSetting -SqlInstance "SQLInstanceName" -Section "kCura.LicenseManager" -Name "Instance"

This example retrieves the value of the 'Instance' setting from the 'kCura.LicenseManager' section of the instance settings 
in the specified SQL instance.

.INPUTS
None.

.OUTPUTS
System.Object.
Returns the value of the specified instance setting. The type of the output can vary based on the setting.

.NOTES
This function performs a SQL query against the specified SQL instance and requires appropriate permissions to access 
the instance settings. It is designed to handle situations where machine-specific settings might not exist and will 
fallback to general settings if needed.
#>
function Get-RelativityInstanceSetting
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SqlInstance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Section,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [String] $MachineName = ""
    )

    Begin
    {
        Write-Verbose "Started Get-RelativityInstanceSetting."
        $GetInstanceSettingValueQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\Relativity\Get-InstanceSettingValue.sql") -Raw
    }
    Process
    {
        try
        {
            Write-Verbose "Querying for instance setting. Section = $($Section). Name = $($Name). MachineName = $($MachineName)."
            $Parameters = @{
                "@Section" = $Section
                "@Name" = $Name
                "@MachineName" = $MachineName
            }
            $Value = Invoke-SqlQueryAsScalar -SqlInstance $SqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters

            if ($null -eq $Value -and $MachineName -ne "")
            {
                Write-Verbose "Instance setting not found for $($MachineName). Querying again with an empty MachineName."
                $Parameters["@MachineName"] = ""
                $Value = Invoke-SqlQueryAsScalar -SqlInstance $SqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters
            }

            return $Value
        }
        catch
        {
            Write-Error "An error occurred while querying for an instance setting: $($_.Exception.Message)."
            throw
        }
    }
    End
    {
        Write-Verbose "Completed Get-RelativityInstanceSetting."
    }
}