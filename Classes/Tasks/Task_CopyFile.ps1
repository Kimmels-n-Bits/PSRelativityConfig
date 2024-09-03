class Task_CopyFile : Task
{
    #TODO REFACTOR to use ROBOCOPY
    [String]$SourcePath = ""
    [String]$CopyToPath = "C:\sysprep\"
    [String]$ExtractToPath = ""
    [Boolean]$Unzip = $false

    Task_CopyFile($hostname, $sessionName, $sourcePath, $copyToPath, $extractToPath)
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
        $this.Arguments = @($this.SourcePath, $this.CopyToPath, $this.ExtractToPath, $true)
    }    

    hidden $ScriptBlock = {
        param($sourcePath, $copyToPath, $extractToPath, $unzip)

        if (-not (Test-Path -Path $copyToPath)) { New-Item -Path $copyToPath -ItemType Directory }

        if (Test-Path -Path $sourcePath -PathType Container)
        {
            Copy-Item -Path $sourcePath -Destination $copyToPath -Recurse -Force
        }
        elseif (Test-Path -Path $sourcePath -PathType Leaf)
        {
            Copy-Item -Path $sourcePath -Destination $copyToPath -Force
            if ($true -and ($sourcePath.EndsWith('.zip')))
            {
                if (-not (Test-Path -Path $extractToPath)) { New-Item -Path $extractToPath -ItemType Directory }
                Expand-Archive -Path "$($copyToPath)\$(Split-Path -Path $sourcePath -Leaf)" -DestinationPath $extractToPath -Force
            }
        }
        else { return "PathInvalid" }

        return "Staged OK"
    }
}