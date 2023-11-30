<#
.SYNOPSIS
Calculates and returns the default throttle limit for parallel operations.

.DESCRIPTION
The Get-DefaultThrottleLimit function calculates the default throttle limit based on the number of logical processors 
available on the system.

.EXAMPLE
$ThrottleLimit = Get-DefaultThrottleLimit

This example retrieves the default throttle limit for the system, which can be used to optimize parallel processing tasks.

.INPUTS
None.

.OUTPUTS
System.Int32
Returns an integer value representing the default throttle limit calculated based on the system's logical processors.

.NOTES
This function is particularly useful in environments where parallel processing needs to be optimized without 
overloading the system's resources. It relies on the CIM instance of Win32_Processor to determine the number of logical 
processors.
#>
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