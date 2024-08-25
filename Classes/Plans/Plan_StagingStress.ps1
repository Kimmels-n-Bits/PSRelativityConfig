class Plan_StagingStress : Plan
{
    [String]$SourcePath
    [String]$CopyToPath
    [String]$ExtractToPath

    Plan_StagingStress($hostnames, $creds, $sourcePath, $copyToPath, $extractToPath, $async)
    { 
        $this.Hostnames = $hostnames
        $this.Credentials = $creds
        $this.SourcePath = $sourcePath
        $this.CopyToPath = $copyToPath
        $this.ExtractToPath = $extractToPath
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $_SessionName = $this.SessionName = "SESS$(-join ((0..9) | Get-Random -Count 5))"
        

        $this.Tasks.Add([Plan_New_PSSession]::new($this.Hostnames, $_SessionName, $this.Credentials, $this.Async))
        $this.Tasks.Add([Plan_New_StageFiles]::new($this.Hostnames, $_SessionName, $this.SourcePath, $this.CopyToPath, $this.ExtractToPath, $this.Async))
        $this.Tasks.Add([Plan_Remove_PSSession]::new($this.Hostnames, $_SessionName, $this.Async))
    }
}