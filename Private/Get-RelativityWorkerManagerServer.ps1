function Get-RelativityWorkerManagerServer
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
        Write-Verbose "Started Get-RelativityWorkerManagerServer."
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Error "Get-RelativityWorkerManagerServer has not yet been implemented."

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving WorkerManager configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityWorkerManagerServer."
    }
}