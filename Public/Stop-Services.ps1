function Stop-Services
{
    <#
        .DESCRIPTION
            Stops Services on each host

        .NOTES
            REQUIRED RunAs Administrator session, if targetting localhost
        
        .EXAMPLE
            Asyncronously stop each listed service, for each host.
            Stop-Service -Hosts @("LVDSHDRELAGT002", "FAKESERVER001") `
                -Services @("kCura EDDS Agent Manager", "WinRM", "kCura Service Host Manager") `
                -Session "mySession" `
                -Async
    #>
    [CmdletBinding()]
    param (
        [Switch]$Async,
        [System.Collections.Generic.List[String]]$Hosts = @(),
        [System.Collections.Generic.List[String]]$Services = @(),
        [String]$Session
    )

    $Task = [Plan_Service]::new($Hosts, $Session, [Action]::Stop, $Services, $Async)
    $Results = $Task.Run()

    Write-Host "[$($MyInvocation.MyCommand.Name)] Completed $($Task.Progress())%"
    Write-Host "Hosts: $($Hosts.count)"
}