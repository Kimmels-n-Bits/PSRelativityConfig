class Plan_RemoveOldData : Plan
{
    <#
        .DESCRIPTION
            This will clear out a staging location, presumably old hotfix data.
            It will also clear out temp files used but Relativity.

        .PARAMETER StagePath
            Typically the path to Hotfix Staging, which may contain old patch files.
    #>
    [String] $StagePath

    Plan_RemoveOldData($hostnames, $session, $stagePath, $async)
    {
        $this.Async = $async
        $this.Hostnames = $hostnames
        $this.SessionName = $session
        $this.StagePath = $stagePath
        $this.Init()
    }

    Init()
    {
        $this.Hostnames | ForEach-Object {
            $this.Tasks.Add([Task_RemoveOldData]::new($_, $this.StagePath))
        }
    }
}