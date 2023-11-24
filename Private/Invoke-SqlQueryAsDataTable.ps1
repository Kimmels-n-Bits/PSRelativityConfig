<#
.SYNOPSIS
Executes a SQL query and returns the results as a DataTable.

.DESCRIPTION
The Invoke-SqlQueryAsDataTable function executes a provided SQL query on a specified SQL Server instance 
and returns the results as a DataTable. This function is suitable for queries that are expected to return 
multiple rows and columns, such as SELECT statements that retrieve data from one or more tables. It 
utilizes integrated security for database access.

.PARAMETER SqlInstance
Specifies the SQL Server instance on which the query will be executed. The parameter accepts the server 
instance in the format "ServerName" or "ServerName\InstanceName".

.PARAMETER Query
Defines the SQL query to be executed. The query should be crafted to retrieve data that can be represented 
in a DataTable.

.PARAMETER Parameters
A hashtable containing the parameters for the SQL query. Each key in the hashtable represents the name 
of a parameter (as used in the SQL query), and its corresponding value is the value to be assigned to 
that parameter. This approach is used to safely pass parameters to the SQL query and prevent SQL 
injection attacks.

.EXAMPLE
$DataTable = Invoke-SqlQueryAsDataTable -SqlInstance "ServerName" -Query "SELECT * FROM Employees"

This example retrieves all records from the Employees table and stores them in a DataTable.

.EXAMPLE
$Parameters = @{
    "@DepartmentId" = 4
}
$DataTable = Invoke-SqlQueryAsDataTable -SqlInstance "ServerName" -Query "SELECT * FROM Employees WHERE DepartmentId = @DepartmentId" -Parameters $Parameters

This example retrieves records from the Employees table for a specific department and stores them in a DataTable.

.EXAMPLE
$Parameters = @{
    "@StartDate" = '2023-01-01'
    "@EndDate"   = '2023-12-31'
}
$Query = "SELECT * FROM Orders WHERE OrderDate BETWEEN @StartDate AND @EndDate"
$DataTable = Invoke-SqlQueryAsDataTable -SqlInstance "ServerName" -Query $Query -Parameters $Parameters

This example retrieves all orders placed between two dates and stores the results in a DataTable.

.INPUTS
None.

.OUTPUTS
System.Data.DataTable.
Returns the results of the executed SQL query as a DataTable. The DataTable will contain rows and columns 
corresponding to the data retrieved by the query.

.NOTES
#>
function Invoke-SqlQueryAsDataTable
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SqlInstance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Query,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [Hashtable] $Parameters
    )

    Begin
    {
        Write-Verbose "Starting Invoke-SqlQueryAsDataTable."
    }
    Process 
    {
        try
        {
            Write-Verbose "Executing SQL query on $($SqlInstance)."
            $ConnectionString = "Server=$($SqlInstance);Integrated Security=True;"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $Connection.Open()
            $Command = $Connection.CreateCommand()
            $Command.CommandText = $Query

            if ($null -ne $Parameters)
            {
                foreach ($Parameter in $Parameters.GetEnumerator())
                {
                    $SqlParameter = New-Object System.Data.SqlClient.SqlParameter($Parameter.Key, $Parameter.Value)
                    $Command.Parameters.Add($SqlParameter) | Out-Null
                }
            }

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
            $DataTable = New-Object System.Data.DataTable
            $DataAdapter.Fill($DataTable)
            Write-Verbose "Executed SQL query on $($SqlInstance)."
            return $DataTable
        } 
        catch
        {
            Write-Error "An error occurred while executing a SQL statement: $($_.Exception.Message)."
            throw
        }
        finally
        {
            $Connection.Close()
        }
    }
    End
    {
        Write-Verbose "Completed Invoke-SqlQueryAsDataTable."
    }
}
