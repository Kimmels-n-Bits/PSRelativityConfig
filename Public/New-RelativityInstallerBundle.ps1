function New-RelativityInstallerBundle
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $SecretStore,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Relativity,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Invariant,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $NISTPackage
    )

    Begin
    {
        Write-Verbose "Started New-RelativityInstallerBundle."
    }
    Process
    {
        try
        {
            $InstallerBundle = [RelativityInstallerBundle]::New(
                $SecretStore,
                $Relativity,
                $Invariant,
                $NISTPackage
            )

            return $InstallerBundle
        }
        catch
        {
            Write-Error "An error occurred when creating a new Relativity installer bundle: $($_.Exception.Message)"
            throw
        }
    }
    End
    {
        Write-Verbose "Completed New-RelativityInstallerBundle."
    }
}