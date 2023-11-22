<#
.SYNOPSIS
Function to create a new instance of a RelativityInstance object.

.DESCRIPTION
This function creates and returns a new instance of a RelativityInstance object.

.PARAMETER Name
Mandatory. Specifies the name of the Relativity instance.

.PARAMETER FriendlyName
Optional. Specifies the friendly name of the Relativity instance. By default this will be equal to the Name parameter.

.PARAMETER ServiceAccountWindowsCredential
Optional. Specifies a PSCredential object containing the service account credentials.

.PARAMETER EDDSDBOSqlCredential
Optional. Specifies a PSCredential object containing the EDDSDBO SQL credentials.

.PARAMETER ServiceAccountSqlCredential
Optional. Specifies a PSCredential object containing sysadmin-level SQL credentials.

.PARAMETER RabbitMQCredential
Optional. Specifies a PSCredential object containing the RabbitMQ credentials.

.PARAMETER AdminUserRelativityCredential
Optional. Specifies a PSCredential object containing the admin Relativity User credentials.

.PARAMETER ServiceAccountRelativityCredential
Optional. Specifies a PSCredential object containing the service account Relativity User credentials.

.INPUTS
None. You cannot pipe objects to New-RelativityInstance.

.OUTPUTS
New-RelativityInstance returns a new instance of a RelativityInstance object.

.EXAMPLE
New-RelativityInstance -Name "Instance01"

This example creates a new RelativityInstance object named "Instance01".

.EXAMPLE
New-RelativityInstance -Name "Instance01" -FriendlyName "Detroit"

This example creates a new RelativityInstance object named "Instance01" with the friendly name "Detroit".

.EXAMPLE
$ServiceAccountCred = Get-Credential
New-RelativityInstance -Name "Instance01" -ServiceAccountWindowsCredential $ServiceAccountCred

This example creates a new RelativityInstance object named "Instance01 with the specified Windows service account credentials.
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
            $RelativityInstance = [RelativityInstance]::New($Name, $Friendlyname)

            if (-not ($null -eq $ServiceAccountWindowsCredential))
            {
                $RelativityInstance.SetServiceAccountWindowsCredential($ServiceAccountWindowsCredential)
            }

            if (-not ($null -eq $EDDSDBOSqlCredential))
            {
                $RelativityInstance.SetEDDSDBOSqlCredential($EDDSDBOSqlCredential)
            }

            if (-not ($null -eq $ServiceAccountSqlCredential))
            {
                $RelativityInstance.SetServiceAccountSqlCredential($ServiceAccountSqlCredential)
            }

            if (-not ($null -eq $RabbitMQCredential))
            {
                $RelativityInstance.SetRabbitMQCredential($RabbitMQCredential)
            }

            if (-not ($null -eq $AdminUserRelativityCredential))
            {
                $RelativityInstance.SetAdminUserRelativityCredential($AdminUserRelativityCredential)
            }

            if (-not ($null -eq $ServiceAccountRelativityCredential))
            {
                $RelativityInstance.SetServiceAccountRelativityCredential($ServiceAccountRelativityCredential)
            }

            return $RelativityInstance
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