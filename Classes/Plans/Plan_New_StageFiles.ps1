#TODO Rethink this. This assumes a .zip and attempts to extract
class Plan_New_StageFiles : Plan
{
    [String]$SourcePath
    [String]$CopyToPath
    [String]$ExtractToPath

    Plan_New_StageFiles($hostnames, $sessionName, $sourcePath, $copyToPath, $extractToPath, $async)
    { 
        $this.Hostnames = $hostnames
        $this.SessionName = $sessionName
        $this.SourcePath = $sourcePath
        $this.CopyToPath = $copyToPath
        $this.ExtractToPath = $extractToPath
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $this.Hostnames | ForEach-Object {
            $t = [Task_Stage_Unzip]::new($_, $this.SessionName, $SourcePath, $CopyToPath, $ExtractToPath)
            $this.Tasks.Add($t)
        }
    }
}