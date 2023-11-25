function Get-RelativityWorkerServer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PrimarySqlInstance
    )

    begin
    {
        Write-Verbose "Started Get-RelativityWorkerServer."
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Error "Get-RelativityWorkerServer has not yet been implemented."

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving Worker configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityWorkerServer."
    }
}