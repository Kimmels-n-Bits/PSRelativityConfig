function Remove-PSSession
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
        [String]$Session
    )

    $Task = [Plan_Remove_PSSession]::new($Hosts, $Session, $Async)
    $Results = $Task.Run()

    Write-Host "[$($MyInvocation.MyCommand.Name)] Completed $($Task.Progress())%"
    Write-Host "Hosts: $($Hosts.count)"
}