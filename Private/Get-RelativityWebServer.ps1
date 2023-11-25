function Get-RelativityWebServer
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
        Write-Verbose "Started Get-RelativityWebServer."
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Error "Get-RelativityWebServer has not yet been implemented."

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving Web configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityWebServer."
    }
}