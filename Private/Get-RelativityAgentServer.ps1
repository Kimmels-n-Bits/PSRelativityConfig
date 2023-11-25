function Get-RelativityAgentServer
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
        Write-Verbose "Started Get-RelativityAgentServer."
    }
    process
    {
        try
        {
            $Servers = @()

            Write-Error "Get-RelativityAgentServer has not yet been implemented."

            return $Servers
        }
        catch
        {
            Write-Error "An error occurred while retrieving Agent configuration: $($_.Exception.Message)."
            throw        
        }
    }
    end
    {
        Write-Verbose "Completed Get-RelativityAgentServer."
    }
}