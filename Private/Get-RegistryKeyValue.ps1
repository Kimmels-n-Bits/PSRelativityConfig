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