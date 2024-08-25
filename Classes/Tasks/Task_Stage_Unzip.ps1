class Task_Stage_Unzip : Task
{
    $SourcePath = ""
    $CopyToPath = "C:\sysprep\StressTest\"
    $ExtractToPath = ""

    Task_Stage_Unzip($hostname, $sessionName, $sourcePath, $copyToPath, $extractToPath)
    {
        $this.Hostname = $hostname
        $this.SessionName = $sessionName
        $this.SourcePath = $sourcePath
        $this.CopyToPath = $copyToPath
        $this.ExtractToPath = $extractToPath
        
        $this.Init()
    }

    Init()
    {
        if ($this.ExtractToPath -eq "") { $this.ExtractToPath = $this.CopyToPath }
        $this.Arguments = @($this.SourcePath, $this.CopyToPath, $this.ExtractToPath)
    }    

    hidden $ScriptBlock = {
        param($sourcePath, $copyToPath, $extractToPath)

        if ($sourcePath -eq "") { return "Path Error" }
        
        if (-not (Test-Path -Path $CopyToPath)) { New-Item -Path $CopyToPath -ItemType Directory }
        if (-not (Test-Path -Path $extractToPath)) { New-Item -Path $extractToPath -ItemType Directory }

        Copy-Item -Path $sourcePath -Destination $copyToPath -Force
        Expand-Archive -Path "$($copyToPath)\$(Split-Path -Path $sourcePath -Leaf)" -DestinationPath $extractToPath -Force

        return "Staged OK"
    }
}