function Get-RelativityInstance
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PrimarySqlInstance,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]] $SecretStore,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String] $SecretStoreSqlInstance
    )

    Begin
    {
        Write-Verbose "Starting Get-RelativityInstance"

        $GetRelativityInstanceNameQuery = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Queries\GetRelativityInstanceName.sql") -Raw
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
                $Server = New-RelativityServer -Name $SecretStoreServer
                $Instance.AddServer($Server)
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