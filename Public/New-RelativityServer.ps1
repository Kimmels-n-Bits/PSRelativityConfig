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
        Write-Verbose "Starting New-RelativityServer"
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
            Write-Error "An error occurred when creating a new Relativity server: $($_.Exception.Message)"
            throw
        }
    }
    End
    {
        Write-Verbose "Completed New-RelativityServer"
    }
}