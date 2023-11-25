function Get-RelativityInstance
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PrimarySqlInstance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $SecretStoreServers,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SecretStoreSqlInstance
    )

    Begin
    {
        Write-Verbose "Starting Get-RelativityInstance"

        $GetInstanceSettingValueQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\Private\Queries\Relativity\Get-InstanceSettingValue.sql") -Raw
    }
    Process
    {
        try
        {
            Write-Verbose "Retrieving Relativity instance name from $($PrimarySqlInstance)."
            $Parameters = @{
                "@Section" = "kCura.LicenseManager"
                "@Name" = "Instance"
                "@MachineName" = ""
            }
            $InstanceName = Invoke-SqlQueryAsScalar -SqlInstance $PrimarySqlInstance -Query $GetInstanceSettingValueQuery -Parameters $Parameters
            
            if ($null -ne $InstanceName)
            {
                Write-Verbose "Retrieved Relativity instance $($InstanceName) from $($PrimarySqlInstance)."
                $Instance = New-RelativityInstance -Name $InstanceName
            }
            else 
            {
                throw "No instance name was retrieved."
            }
            
            Get-RelativitySecretStoreServer -SecretStoreServers $SecretStoreServers -SecretStoreSqlInstance $SecretStoreSqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityPrimarySqlServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityDistributedSqlServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityServiceBusServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityWebServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityAgentServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityWorkerManagerServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            Get-RelativityWorkerServer -PrimarySqlInstance $PrimarySqlInstance | ForEach-Object {
                $Instance.AddServer($_)
            }

            return $Instance
        }
        catch
        {
            Write-Error "An error occurred when retrieving a Relativity instance: $($_.Exception.Message)"
            throw
        }
    }
    End
    {
        Write-Verbose "Completed Get-RelativityInstance"
    }
}