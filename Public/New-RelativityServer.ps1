<#
.SYNOPSIS
Creates a new instance of a RelativityServer.

.DESCRIPTION
The New-RelativityServer function initializes a new instance of the RelativityServer class.
It takes a server name as input and returns an object representing a server within the Relativity environment.

.PARAMETER Name
The name of the server to be created. This should be a valid network name.

.EXAMPLE
New-RelativityServer -Name "Server01"
Creates a new RelativityServer instance named "Server01".

.INPUTS
None.

.OUTPUTS
RelativityServer.
Returns an instance of the RelativityServer class.

.NOTES
#>
function New-RelativityServer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    Begin
    {
        Write-Verbose "Starting New-RelativityServer."
    }
    Process
    {
        try
        {
            $Server = [RelativityServer]::New($Name)

            return $Server
        }
        catch
        {
            Write-Error "An error occurred when creating a new Relativity server: $($_.Exception.Message)."
            throw
        }
    }
    End
    {
        Write-Verbose "Completed New-RelativityServer."
    }
}