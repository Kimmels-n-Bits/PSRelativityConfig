function Get-DefaultThrottleLimit
{
    [CmdletBinding()]
    Param
    (

    )

    Begin
    {
        Write-Verbose "Started Get-DefaultThrottleLimit."
    }
    Process
    {
        return ((Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors * 2)
    }
    End
    {
        Write-Verbose "Completed Get-DefaultThrottleLimit."
    }
}