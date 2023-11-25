<#
.SYNOPSIS
Creates a new RelativityServer object.

.DESCRIPTION
The New-RelativityServer function creates a new RelativityServer object representing a server in a Relativity environment. 
The function initializes the server with a specified name. This object can then be used to associate various properties and 
roles relevant to the server within the Relativity environment. This function is primarily used in scripts where 
Relativity environments are being configured or managed.

.PARAMETER Name
Specifies the name of the server. This name is used to identify the server within the Relativity environment.

.EXAMPLE
$Server = New-RelativityServer -Name "Server01"

This example creates a new RelativityServer object with the name "Server01".

.INPUTS
None.

.OUTPUTS
RelativityServer
Returns a new RelativityServer object initialized with the specified name.

.NOTES
This function is part of a larger suite of functions designed to manage and configure Relativity environments. It is important to 
use this function in conjunction with other related functions to fully define and integrate the server within the Relativity environment.
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