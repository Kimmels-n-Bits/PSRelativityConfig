<#
.SYNOPSIS
Creates a new RelativityInstance object with specified properties and credentials.

.DESCRIPTION
The New-RelativityInstance function creates a new RelativityInstance object. This object represents a Relativity instance 
and includes properties such as name, friendly name, and various credentials necessary for different aspects of the 
instance like database access, service account, and admin user access.

.PARAMETER Name
Specifies the name of the Relativity instance. This name is used to identify the instance.

.PARAMETER FriendlyName
Specifies a friendly name for the Relativity instance, used for display purposes. If not provided, defaults to the value of Name.

.PARAMETER ServiceAccountWindowsCredential
Specifies the Windows credential object for the service account associated with the Relativity instance.

.PARAMETER EDDSDBOSqlCredential
Specifies the SQL credential object for the EDDS database owner in the Relativity instance.

.PARAMETER ServiceAccountSqlCredential
Specifies the SQL credential object for the service account in the Relativity instance.

.PARAMETER RabbitMQCredential
Specifies the credential object for RabbitMQ in the Relativity instance.

.PARAMETER AdminUserRelativityCredential
Specifies the Relativity admin user credential object.

.PARAMETER ServiceAccountRelativityCredential
Specifies the Relativity service account credential object.

.EXAMPLE
$RelativityInstance = New-RelativityInstance -Name "RelativityInstance01" -FriendlyName "Relativity Dev Instance"

This example creates a new RelativityInstance object with the name "RelativityInstance01" and a friendly name "Relativity Dev Instance".

.INPUTS
None.

.OUTPUTS
RelativityInstance
Returns a new RelativityInstance object with the specified properties and credentials.

.NOTES
The function accepts PSCredential objects for various credentials, ensuring secure handling of sensitive information. 
It's crucial to provide correct and valid credentials for the Relativity instance to function properly.
#>
function New-RelativityInstance
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String] $FriendlyName = $Name,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential] $ServiceAccountWindowsCredential,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential] $EDDSDBOSqlCredential,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential] $ServiceAccountSqlCredential,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential] $RabbitMQCredential,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential] $AdminUserRelativityCredential,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential] $ServiceAccountRelativityCredential
    )

    Begin
    {
        Write-Verbose "Starting New-RelativityInstance"
    }
    Process
    {
        try
        {
            $Instance = [RelativityInstance]::New($Name, $Friendlyname)

            if (-not ($null -eq $ServiceAccountWindowsCredential))
            {
                $Instance.SetServiceAccountWindowsCredential($ServiceAccountWindowsCredential)
            }

            if (-not ($null -eq $EDDSDBOSqlCredential))
            {
                $Instance.SetEDDSDBOSqlCredential($EDDSDBOSqlCredential)
            }

            if (-not ($null -eq $ServiceAccountSqlCredential))
            {
                $Instance.SetServiceAccountSqlCredential($ServiceAccountSqlCredential)
            }

            if (-not ($null -eq $RabbitMQCredential))
            {
                $Instance.SetRabbitMQCredential($RabbitMQCredential)
            }

            if (-not ($null -eq $AdminUserRelativityCredential))
            {
                $Instance.SetAdminUserRelativityCredential($AdminUserRelativityCredential)
            }

            if (-not ($null -eq $ServiceAccountRelativityCredential))
            {
                $Instance.SetServiceAccountRelativityCredential($ServiceAccountRelativityCredential)
            }

            return $Instance
        }
        catch
        {
            Write-Error "An error occurred when creating a new Relativity instance: $($_.Exception.Message)"
            throw
        }
    }
    End
    {
        Write-Verbose "Completed New-RelativityInstance"
    }
}