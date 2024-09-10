function Invoke-AdHoc
{
    <#
        .DESCRIPTION
            Optional wrapper function to execute arbitrary code across many hosts.

        .EXAMPLE
            $script = {
                Set-Location -Path "C:\RelativityInstall"
                & C:\sysprep\someOtherOptionalScript.ps1
            }
            $hosts = @("HOST001","HOST002","HOST003")

            Invoke-AdHoc -Async -hosts $hosts -script $script
    #>
    param(
        [Switch]$Async,
        [System.Collections.Generic.List[String]]$hosts = @(),
        [System.Object]$script
    )

    $Plan = [Plan_AdHoc]::new($hosts, $script, $Async)
    $Plan.Run()

    return $Plan
}