class Plan_CopyFiles : Plan
{
    <#
        .DESCRIPTION
            Stages files from a path source to one/many hosts.
        
        .PARAMETER CopyToPath
            Path to stage files

        .PARAMETER ExtractToPath
            (optional) Path to extract a zip to, before copying to Stage location.

        .PARAMETER SourcePath
            Path of the source files, can be a File or a Folder

        .PARAMETER Unzip
            (optional) Flag to unzip file after copy.
    #>
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

    Final()
    {
        $this.Hostnames | ForEach-Object {
            Write-Output "[$_]`tCopyTo: $($this.CopyToPath)"
        }
    }
}