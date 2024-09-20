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
        [String]$Session,
        [Switch]$WriteProgress,
        [Int32]$WriteProgressID = 0
    )

    $Task = [Plan_Remove_PSSession]::new($Hosts, $Session, $Async)
    if ($WriteProgress) { $Task.WriteProgress = $true; $Task.WriteProgressID = $WriteProgressID }    

    $Results = $Task.Run()
}