class Plan_CopyFiles : Plan
{
    [String]$SourcePath
    [String]$CopyToPath
    [String]$ExtractToPath
    [Boolean]$Unzip = $false

    Plan_CopyFiles($hostnames, $sessionName, $sourcePath, $copyToPath, $extractToPath, $unzip, $async)
    { 
        $this.Hostnames = $hostnames
        $this.SessionName = $sessionName
        $this.SourcePath = $sourcePath
        $this.CopyToPath = $copyToPath
        $this.ExtractToPath = $extractToPath
        $this.Unzip = $unzip
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $this.Hostnames | ForEach-Object {
            $t = [Task_CopyFile]::new($_, $this.SessionName, $SourcePath, $CopyToPath, $ExtractToPath)
            $t.Unzip = $this.Unzip
            $this.Tasks.Add($t)
        }
    }
}