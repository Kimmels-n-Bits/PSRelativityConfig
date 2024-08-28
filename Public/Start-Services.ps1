function Start-Services
{
    <#
        .DESCRIPTION
            Deletes a named PSSessionConfiguration for each host

        .EXAMPLE
            Asyncronously deletes a session for each host
            Remove-PSSession -Hosts @("LVDSHDRELAGT002", "FAKESERVER001") `
                        -Session "MySession" `
                        -Async
    #>
    [CmdletBinding()]
    param (
        [Switch]$Async,
        [System.Collections.Generic.List[String]]$Hosts = @(),
        [System.Collections.Generic.List[String]]$Services = @(),
        [String]$Session
    )

    $Task = [Plan_Service]::new($Hosts, $Session, [Action]::Start, $Services, $Async)
    $Results = $Task.Run()

    Write-Host "[$($MyInvocation.MyCommand.Name)] Completed $($Task.Progress())%"
    Write-Host "Hosts: $($Hosts.count)"
}