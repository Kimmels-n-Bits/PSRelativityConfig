class Plan_New_PSSession : Plan
{
    <#  .DESCRIPTION
            Creates a PSConfiguration for each hostname

        .FUNCTIONALITY
            This object is best instantiated via its function New-PSSession
    #>
    Plan_New_PSSession($hostnames, $credential, $async)
    { 
        $this.Hostnames = $hostnames
        $this.Credentials = $credential
        $this.Async = $async
        $this.Init()
    }
    Plan_New_PSSession($hostnames, $sessionName, $credential, $async)
    {
        $this.Hostnames = $hostnames
        $this.SessionName = $sessionName
        $this.Credentials = $credential
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        if(-not $this.SessionName)
        {
            $this.SessionName = "SESS$(-join ((0..9) | Get-Random -Count 5))"
        }

        $this.Hostnames | ForEach-Object {
            $t = [Task_New_PSSession]::new($_, $this.Credentials, $this.SessionName)
            $this.Tasks.Add($t)
        }
    }

    Final()
    {
        $this.Result = $this.SessionName
    }
}