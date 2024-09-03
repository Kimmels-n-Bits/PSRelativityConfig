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
        [String]$Session,
        [Switch]$WriteProgress,
        [Int32]$WriteProgressID = 0
    )

    if($Session -eq "")
    {
        $Session = "SESS$(-join ((0..9) | Get-Random -Count 5))"
    }

    $Task = [Plan_New_PSSession]::new($Hosts, $Session, $Credentials, $Async)
    if ($WriteProgress) { $Task.WriteProgress = $true; $Task.WriteProgressID = $WriteProgressID }

    $Results = $Task.Run()

    return $Session
}