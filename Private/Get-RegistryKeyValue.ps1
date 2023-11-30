<#
.SYNOPSIS
Retrieves the value of a specified key from the registry on a remote server.

.DESCRIPTION
The Get-RegistryKeyValue function is designed to access a remote server's registry and retrieve the value of a specified 
key.

.PARAMETER ServerName
Specifies the name of the remote server from which the registry key value will be retrieved.

.PARAMETER RegistryPath
Specifies the registry path where the key is located. This path should be provided in a format compatible with 
the system's registry structure.

.PARAMETER KeyName
Specifies the name of the registry key whose value is to be retrieved.

.EXAMPLE
$KeyValue = Get-RegistryKeyValue -ServerName "Server01" -RegistryPath "SOFTWARE\kCura\Relativity" -KeyName "InstallDir"

This example retrieves the value of the 'InstallDir' key from the specified registry path on 'Server01'.

.INPUTS
None.

.OUTPUTS
System.Object
Returns the value of the specified registry key. The type of the output can vary based on the key's data type in the registry.

.NOTES
This function uses the .NET class Microsoft.Win32.RegistryKey to interact with the registry. It includes error handling 
to manage exceptions that may occur during the registry access. Proper permissions are required to read the registry 
on the remote server.
#>
function Get-RegistryKeyValue
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ServerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $RegistryPath,
        [Parameter(Mandatory = $true)]
        [validateNotNullOrEmpty()]
        [String] $KeyName
    )

    Begin
    {
        Write-Verbose "Started Get-RegistryKeyValue."
    }
    Process
    {
        try
        {
            $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ServerName)
            $RegistryKey = $Registry.OpenSubKey($RegistryPath)
            
            if ($null -ne $RegistryKey)
            {
                return $RegistryKey.GetValue($KeyName)
            }
            else
            {
                Write-Verbose "Registry path '$($RegistryPath)' was not found on $($ServerName)."
                return $null
            }
        }
        catch
        {
            Write-Error "An error occurred while accessing the registry on $($ServerName): $($_.Exception.Message)."
            throw
        }
        finally
        {
            if ($null -ne $RegistryKey)
            {
                $RegistryKey.Close()
            }

            if ($null -ne $Registry)
            {
                $Registry.Close()
            }
        }
    }
    End
    {
        Write-Verbose "Completed Get-RegistryKeyValue."
    }
}