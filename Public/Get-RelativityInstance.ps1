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
        [String[]] $SecretStore,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SecretStoreSqlInstance,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [Boolean] $UseWinAuth = $true
    )

    Begin
    {
        Write-Verbose "Starting Get-RelativityInstance"

        $GetRelativityInstanceNameQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetRelativityInstanceName.sql") -Raw
        $GetPrimarySqlServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetPrimarySqlServerSettings.sql") -Raw
        $GetDistributedSqlServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetDistributedSqlServerSettings.sql") -Raw
        $GetRabbitMQServerSettingsQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetRabbitMQServerSettings.sql") -Raw
    }
    Process
    {
        try
        {
            Write-Verbose "Connecting to SQL Server: $($PrimarySqlInstance)"
            
            $ConnectionString = "Server=$($PrimarySqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $GetRelativityInstanceNameQuery
            $InstanceName = $Command.ExecuteScalar()

            if ($null -ne $InstanceName)
            {
                Write-Verbose "Retrieved instance name: $($InstanceName)"
                $Instance = New-RelativityInstance -Name $InstanceName
            }
            else
            {
                throw "No instance name was retrieved!"
            }

            $Connection.Close()


            foreach($SecretStoreServer in $SecretStore)
            {
                Write-Verbose "Adding SecretStore server: $($SecretStoreServer)"
                $Server = New-RelativityServer -Name $SecretStoreServer
                $Server.SqlInstance = $SecretStoreSqlInstance
                $Server.SqlPort = 1433
                $Server.UseWinAuth = $UseWinAuth
                $Server.AddRole("SecretStore")
                $Instance.AddServer($Server)
            }

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