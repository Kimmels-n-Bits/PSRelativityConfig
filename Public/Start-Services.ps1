function Start-Services
{
    <#
        .DESCRIPTION
            Starts Services on each host
        
        .NOTES
            REQUIRED RunAs Administrator session, if targetting localhost

        .EXAMPLE
            Asyncronously Starts each listed service, for each host.
            Start-Service -Hosts @("LVDSHDRELAGT002", "FAKESERVER001") `
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

    #TODO investigate support for sessionless start/stops
    $Task = [Plan_Service]::new($Hosts, $Session, [Action]::Start, $Services, $Async)
    $Results = $Task.Run()

    Write-Host "[$($MyInvocation.MyCommand.Name)] Completed $($Task.Progress())%"
    Write-Host "Hosts: $($Hosts.count)"
}