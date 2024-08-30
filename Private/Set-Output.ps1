function Set-Output
{
    <#
        .DESCRIPTION
            Sets Module scoped Output options
        
        .PARAMETER CLI
            Sets formatted output to CLI
        
        .PARAMETER Log
            Sets writing to Logfile

        .PARAMETER LogDirectory
            Sets log file location

        .PARAMETER Progress
            Sets progress bar output to CLI

        .EXAMPLE
            Set-Output -Progress -Log -LogDirectory "C:\Logs"
    #>
    param(
        [Switch]$CLI,
        [Switch]$Log,
        [String]$LogDirectory,
        [Switch]$Progress
    )

    if ($LogDirectory) { $script:LogDir = $LogDirectory }
    if ($CLI) { $script:OutputCLI = $true }
    if ($Log) { $script:OutputLog = $true }
    if ($Progress) { $script:OutputProgress = $true }
}