function Copy-Files
{
    <#
        .DESCRIPTION
            Copy files or directories from a source to a local drive. Unzipping

        .EXAMPLE
            This has each host copy a zip file, then unzip it:
            Copy-Files -Hosts @("LVDSHDRELAGT002", "FAKESERVER001") `
                        -Session "mySession" `
                        -Source "\\FS\file.zip" `
                        -CopyTo "C:\stage" `
                        -ExtractTo "C:\Install" `
                        -Unzip `
                        -Async
    #>
    [CmdletBinding()]
    param (
        [Switch]$Async,
        [String]$CopyTo,
        [String]$ExtractTo,
        [System.Collections.Generic.List[String]]$Hosts = @(),
        [String]$Session,
        [String]$Source,
        [Switch]$Unzip,
        [Switch]$WriteProgress,
        [Int32]$WriteProgressID = 0
    )

    $Task = [Plan_CopyFiles]::new(
        $Hosts,
        $Session,
        $Source,
        $CopyTo,
        $ExtractTo,
        $Unzip,
        $Async)

    if($WriteProgress) { $Task.WriteProgress = $true; $Task.WriteProgressID = $WriteProgressID }
    $Results = $Task.Run()

    #Write-Host "[$($MyInvocation.MyCommand.Name)] Completed $($Task.Progress())%"
    #Write-Host "Hosts: $($Hosts.count)"
}