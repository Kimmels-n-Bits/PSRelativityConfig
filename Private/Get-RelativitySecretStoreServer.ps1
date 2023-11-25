<#
.SYNOPSIS
Retrieves configured SecretStore servers for Relativity and their properties.

.DESCRIPTION
The Get-RelativitySecretStoreServer function is designed to retrieve a collection of SecretStore server objects for 
Relativity. Each server object includes its name, role, and additional properties such as the SQL instance 
server name and the installation directory of the Relativity Secret Store.

.PARAMETER SecretStoreServers
Specifies an array of server names where the Relativity Secret Store is installed. These servers will be 
queried to retrieve their configuration and installation details.

.PARAMETER SecretStoreSqlInstance
Specifies the name of the SQL instance associated with the Secret Store. This information is used to set 
properties on each server object.

.EXAMPLE
$SecretStores = Get-RelativitySecretStoreServer -SecretStoreServers @("Server1", "Server2") -SecretStoreSqlInstance "SQLInstanceName"

This example retrieves the configuration and installation details for SecretStore servers 'Server1' and 'Server2'.

.INPUTS
None.

.OUTPUTS
System.Object[]
Returns an array of objects, each representing a configured SecretStore server for Relativity. These objects 
contain properties such as the server name, roles, and installation directory.

.NOTES
The function relies on remote WMI queries to each server to determine the installation path of the 
Relativity Secret Store service. Appropriate permissions and network access are required for these queries 
to succeed. It is assumed that the Relativity Secret Store service name is consistent across installations.
#>
function Get-RelativitySecretStoreServer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $SecretStoreServers,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SecretStoreSqlInstance
    )

    Begin
    {
        Write-Verbose "Starting Get-RelativitySecretStoreServer."
    }
    Process
    {
        try
        {
            $Servers = @()
            foreach($SecretStoreServer in $SecretStoreServers)
            {
                Write-Verbose "Adding SecretStore server: $($SecretStoreServer)."
                $Server = New-RelativityServer -Name $SecretStoreServer

                if ($Server.IsOnline)
                {
                    $Server.AddRole("SecretStore")
                    $Server.SetProperty("SqlInstanceServerName", $SecretStoreSqlInstance)

                    Write-Verbose "Retrieving InstallDir property for $($SecretStoreServer)."
                    $ServicePathWithArguments = (Get-CimInstance -ComputerName $SecretStoreServer -ClassName "Win32_Service" -Filter 'Name = "Relativity Secret Store"').PathName
                    
                    if ($null -eq $ServicePathWithArguments)
                    {
                        throw "No installation directory was retrieved."
                    }

                    $ServicePath = ($ServicePathWithArguments -replace "https://\*:.*$","").Trim().Trim('"')
                    $InstallDir = "$((New-Object System.IO.DirectoryInfo $ServicePath).Parent.Parent.FullName)\"
                    $Server.SetProperty("InstallDir", $InstallDir)
                    Write-Verbose "Retrieved InstallDir property for $($SecretStoreServer)."
                    
                    $Servers += $Server
                }
                else
                {
                    Write-Warning "$($SecretStoreServer) was not reachable and has been skipped."
                }
            }

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving SecretStore configuration: $($_.Exception.Message)."
            throw
        }
    }
    End
    {
        Write-Verbose "Completed Get-RelativitySecretStoreServer."
    }
}