function New-PSSession
{
    <#
        .DESCRIPTION
            Creates a named PSSessionConfiguration for each host

        .EXAMPLE
            Asyncronously creates a session for each host, and lets script generate a name.
            New-PSSession -Hosts @("LVDSHDRELAGT002", "FAKESERVER001") 
                        -Credentials $myCredentials
                        -Async
    #>
    [CmdletBinding()]
    param (
        [Switch]$Async,
        [PSCredential]$Credentials,
        [System.Collections.Generic.List[String]]$Hosts = @(),
        [String]$Session
    )

    if($Session -eq "")
    {
        $Session = "SESS$(-join ((0..9) | Get-Random -Count 5))"
    }

    $Task = [Plan_New_PSSession]::new($Hosts, $Session, $Credentials, $Async)
    $Results = $Task.Run()

    Write-Host "[$($MyInvocation.MyCommand.Name)] Completed $($Task.Progress())%"
    Write-Host "Hosts: $($Hosts.count)"

    return $Session
}