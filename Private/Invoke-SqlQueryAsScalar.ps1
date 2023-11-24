<#
.SYNOPSIS
Executes a SQL query and returns a single scalar value.

.DESCRIPTION
The Invoke-SqlQueryAsScalar function executes a provided SQL query on a specified SQL Server instance 
and returns the first column of the first row in the result set returned by the query. This function is 
ideal for queries that are expected to return a single value, such as counts, sums, or specific field 
values. It utilizes integrated security for database access.

.PARAMETER SqlInstance
Specifies the SQL Server instance on which the query will be executed. The parameter accepts the server 
instance in the format "ServerName" or "ServerName\InstanceName".

.PARAMETER Query
Defines the SQL query to be executed. The query should be crafted to return a single scalar value.

.PARAMETER Parameters
A hashtable containing the parameters for the SQL query. Each key in the hashtable represents the name 
of a parameter (as used in the SQL query), and its corresponding value is the value to be assigned to 
that parameter. This approach is used to safely pass parameters to the SQL query and prevent SQL 
injection attacks.

.EXAMPLE
Invoke-SqlQueryAsScalar -SqlInstance "ServerName" -Query "SELECT COUNT(*) FROM Employees"

This example counts the number of records in the Employees table.

.EXAMPLE
$Parameters = @{
    "@DepartmentId" = 4
}
Invoke-SqlQueryAsScalar -SqlInstance "ServerName" -Query "SELECT MAX(Salary) FROM Employees WHERE DepartmentId = @DepartmentId" -Parameters $Parameters

This example retrieves the maximum salary from a specific department.

.EXAMPLE
$Parameters = @{
    "@CustomerId" = 1001
    "@Year"       = 2023
}
$Query = "SELECT SUM(Amount) FROM Orders WHERE CustomerId = @CustomerId AND YEAR(OrderDate) = @Year"
Invoke-SqlQueryAsScalar -SqlInstance "ServerName" -Query $Query -Parameters $Parameters

This example retrieves the total amount of orders for a specific customer in a specific year.

.INPUTS
None.

.OUTPUTS
System.Object.
Returns the first column of the first row in the result set. The type of the output can vary based on the 
query and the data in the database.

.NOTES
#>
function Invoke-SqlQueryAsScalar
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
        Write-Verbose "Starting Invoke-SqlQueryAsScalar."
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

            $Scalar = $Command.ExecuteScalar()
            Write-Verbose "Executed SQL query on $($SqlInstance)."
            return $Scalar
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
        Write-Verbose "Completed Invoke-SqlQueryAsScalar."
    }
}