class Plan_AdHoc : Plan
{
    <#
        .DESCRIPTION
            Generic [Plan] to execute parallel adhoc scripts across hosts.

        .EXAMPLE
            Typically expose the [Plan]/[Task] objects externally. and run()
                Import-Module .\
                Set-Output -CLI -Progress                           # Optional output settings
                $hosts = @("Host001","Host002","Host003")
                $script = { Get-PSDrive -PSProvider FileSystem }    # Any script

                $myPlan = [Plan_AdHoc]::new($Hosts, $script, $true) # Host_List, Script, Async_Enable
                $myPlan.Run()

    #>
    Plan_AdHoc($hostnames, $script, $session, $async)
    { 
        $this.Hostnames = $hostnames
        $this.Async = $async
        $this.ScriptBlock = $script
        $this.SessionName = $session
        $this.Init()
    }

    Init()
    {
        $this.WriteProgress = $true
        $this.Hostnames | ForEach-Object {
            $t = [Task_AdHoc]::new($_, $this.ScriptBlock)
            $this.Tasks.Add($t)
        }
    }
}