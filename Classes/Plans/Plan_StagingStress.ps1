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
        
        $this.Tasks.Add([Plan_New_PSSession]::new($this.Hostnames[0..11], $_SessionName, $this.Credentials, $this.Async))
        $this.Tasks.Add([Plan_CopyFiles]::new($this.Hostnames[0..1], $_SessionName, $this.SourcePath, $this.CopyToPath, $this.ExtractToPath, $true, $this.Async))
        #$this.Tasks.Add([Plan_CopyFiles]::new($this.Hostnames[6..11], $_SessionName, $this.SourcePath, $this.CopyToPath, $this.ExtractToPath, $true, $this.Async))
        $this.Tasks.Add([Plan_Remove_PSSession]::new($this.Hostnames[0..11], $_SessionName, $this.Async))
    }
}