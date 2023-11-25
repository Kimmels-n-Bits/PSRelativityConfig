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
        <#$GetPrimarySqlServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetPrimarySqlServerSettings.sql") -Raw
        $GetDistributedSqlServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetDistributedSqlServerSettings.sql") -Raw
        $GetRabbitMQServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetRabbitMQServerSettings.sql") -Raw
        $GetWebServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetWebServerSettings.sql") -Raw
        $GetAgentServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetAgentServerSettings.sql") -Raw
        $GetWorkerManagerServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetWorkerManagerServerSettings.sql") -Raw#>
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
            <#
            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetPrimarySqlServerSettingsQuery
            $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $ResultTable = New-Object System.Data.DataTable
            $Adapter.Fill($ResultTable)

            foreach ($Row in $ResultTable.Rows)
            {
                Write-Verbose "Adding PrimarySql server: $($Row['Name'])"
                $Server = New-RelativityServer -Name $Row['Name']
                $Server.DefaultFileRepository = $Row['DefaultFileRepository']
                $Server.EDDSFileShare = $Row['EDDSFileShare']
                $Server.CacheLocation = $Row['CacheLocation']
                $Server.DtSearchIndexPath = $Row['DtSearchIndexPath']
                $Server.SqlInstance = $Row['SqlInstance']
                $Server.SqlPort = $Row['SqlPort']
                $Server.SqlBackupDirectory = $Row['SqlBackupDirectory']
                $Server.SqlLogDirectory = $Row['SqlLogDirectory']
                $Server.SqlDataDirectory = $Row['SqlDataDirectory']
                $Server.SqlFulltextDirectory = $Row['SqlFulltextDirectory']
                $Server.UseWinAuth = $UseWinAuth
                $Server.AddRole("PrimarySql")
                $Instance.AddServer($Server)
            }

            $Connection.Close()

            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetDistributedSqlServerSettingsQuery
            $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $ResultTable = New-Object System.Data.DataTable
            $Adapter.Fill($ResultTable)

            foreach ($Row in $ResultTable.Rows)
            {
                Write-Verbose "Adding DistributedSql server: $($Row['Name'])"
                $Server = New-RelativityServer -Name $Row['Name']
                $Server.SqlInstance = $Row['SqlInstance']
                $Server.SqlPort = $Row['SqlPort']
                $Server.SqlBackupDirectory = $Row['SqlBackupDirectory']
                $Server.SqlLogDirectory = $Row['SqlLogDirectory']
                $Server.SqlDataDirectory = $Row['SqlDataDirectory']
                $Server.SqlFulltextDirectory = $Row['SqlFulltextDirectory']
                $Server.UseWinAuth = $UseWinAuth
                $Server.AddRole("DistributedSql")
                $Instance.AddServer($Server)
            }

            $Connection.Close()

            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetRabbitMQServerSettingsQuery
            $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $ResultTable = New-Object System.Data.DataTable
            $Adapter.Fill($ResultTable)

            foreach ($Row in $ResultTable.Rows)
            {
                $RabbitMQFQDN = $Row['RabbitMQFQDN']
                $UserName = $Row['UserName']
                $Password = $Row['Password']
                $RabbitMQTLSEnabled = if ($Row['RabbitMQTLSEnabled'] -eq "True") { $true } else { $false }
                $ServiceNamespace = $Row['ServiceNamespace']
                $Protocol = if ($RabbitMQTLSEnabled) { "https" } else { "http" }
                $HttpPort = if ($RabbitMQTLSEnabled) { 15671 } else { 15672 }
                $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($UserName, (ConvertTo-SecureString -String $Password -AsPlainText -Force))

                $Instance.RabbitMQCredential = $Credential

                $Nodes = Invoke-RestMethod -Uri "$($Protocol)://$($RabbitMQFQDN):$($HttpPort)/api/nodes" -Credential $Credential

                foreach ($Node in ($Nodes | Select-Object name).name)
                {
                    $ServiceBusServer = $Node.Replace("rabbit@", "") 
                    Write-Verbose "Adding ServiceBus server: $($ServiceBusServer)"
                    $Server = New-RelativityServer -Name $ServiceBusServer
                    $Server.ServiceNamespace = $ServiceNamespace
                    $Server.RabbitMQTLSEnabled = $RabbitMQTLSEnabled
                    $Server.AddRole("ServiceBus")
                    $Instance.AddServer($Server)
                }
            }

            $Connection.Close()

            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetWebServerSettingsQuery
            $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $ResultTable = New-Object System.Data.DataTable
            $Adapter.Fill($ResultTable)

            foreach ($Row in $ResultTable.Rows)
            {
                Write-Verbose "Adding Web server: $($Row['Name'])"
                $Server = New-RelativityServer -Name $Row['Name']
                $Server.EnableWinAuth = if ($Row['EnableWinAuth'] -eq 1) { $true } else { $false }
                $Server.AddRole("Web")
                $Instance.AddServer($Server)
            }

            $Connection.Close()

            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetAgentServerSettingsQuery
            $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $ResultTable = New-Object System.Data.DataTable
            $Adapter.Fill($ResultTable)

            foreach ($Row in $ResultTable.Rows)
            {
                Write-Verbose "Adding Agent server: $($Row['Name'])"
                $Server = New-RelativityServer -Name $Row['Name']
                $Server.AddRole("Agent")
                $Instance.AddServer($Server)
            }

            $Connection.Close()

            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetWorkerManagerServerSettingsQuery
            $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $ResultTable = New-Object System.Data.DataTable
            $Adapter.Fill($ResultTable)

            foreach ($Row in $ResultTable.Rows)
            {
                $WorkerManagerServer = $Row['Name']

                $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $WorkerManagerServer)
                $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Invariant")
                $DataFilesNetworkPath = $RegistryKey.GetValue("DataFilesPath")
                $DtSearchIndexPath = $RegistryKey.GetValue("dtSearchPath")
                $SqlInstance = $RegistryKey.GetValue("SQLInstance_QM")
                $SqlDataDirectory = $RegistryKey.GetValue("SQLMDFPath")
                $SqlLogDirectory = $RegistryKey.GetValue("SQLLDFPath")
                $WorkerNetworkPath = $RegistryKey.GetValue("WorkerNetworkPath")

                Write-Verbose "Adding Worker Manager server: $($Row['Name'])"
                $Server = New-RelativityServer -Name $Row['Name']
                $Server.DataFilesNetworkPath = $DataFilesNetworkPath
                $Server.DtSearchIndexPath = $DtSearchIndexPath
                $Server.SqlInstance = $SqlInstance
                $Server.SqlDataDirectory = $SqlDataDirectory
                $Server.SqlLogDirectory = $SqlLogDirectory
                $Server.SqlBackupDirectory = "K:\Backup\"
                $Server.WorkerNetworkPath = $WorkerNetworkPath
                $Server.AddRole("WorkerManager")
                $Instance.AddServer($Server)


                
                $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', "LVDZ99RELPQM001")
                $RegistryKey = $Registry.OpenSubKey("SOFTWARE\\kCura\\Invariant")
                $DataFilesNetworkPath = $RegistryKey.GetValue("DataFilesPath")
                $DtSearchIndexPath = $RegistryKey.GetValue("dtSearchPath")
                $SqlInstance = $RegistryKey.GetValue("SQLInstance_QM")
                $SqlDataDirectory = $RegistryKey.GetValue("SQLMDFPath")
                $SqlLogDirectory = $RegistryKey.GetValue("SQLLDFPath")
                $WorkerNetworkPath = $RegistryKey.GetValue("WorkerNetworkPath")

                $DataFilesNetworkPath
                $DtSearchIndexPath
                $SqlInstance
                $SqlDataDirectory
                $SqlLogDirectory
                $WorkerNetworkPath
                
            }

            $Connection.Close()
            #>
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