class Task_InstallDLLs : Task
{
    [String] $Roles
    [string] $StagePath

    Task_InstallDLLs($hostname, $roles, $stagePath)
    {
        $this.Hostname = $hostname
        $this.Roles = $roles
        $this.StagePath = $stagePath
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @($this.Roles, $this.StagePath)
    }    

    hidden $ScriptBlock = {
        Param (
            [String] $Roles,
            [String] $StagePath
        )

        $relPath = Join-Path $stagePath 'RelativityDropIt'
        $invPath = Join-Path $stagePath 'InvariantDropIt'

        Write-Output "$($env:COMPUTERNAME) - $Roles"

        function Backup
        {
            Param ($StagePath)

            # Set Backup Directory 1 level up
            $parentDirectory = Split-Path $StagePath -Parent
            $HotfixBackupLocation = Join-Path (Join-Path $parentDirectory '_Original_DLLs') "$((Get-Date).ToString('yyyyMMdd-HHmmss'))"

            $DropItManifestLocation = (Join-Path -Path $StagePath -ChildPath "manifest.xml")
            $WorkerNetworkPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\kCura\Invariant" -Name "Path").Path #TODO Review with jk

            Write-Output "Starting Backup to $HotfixBackupLocation"
            if (Test-Path -Path $StagePath)
            {                
                # Rename Invariant nodes to standardize
                $DropItManifestString = Get-Content -Path $DropItManifestLocation -Raw
                $DropItManifestString = $DropItManifestString -replace 'dll-file', 'dropped-file'
                [XML]$DropItManifest = $DropItManifestString

                foreach($FileToDrop in $DropItManifest.manifest.'dropped-files'.'dropped-file')
                {
                    foreach($FileToDropLocation in $FileToDrop.'installed-location')
                    {
                        $InstalledLocation = $FileToDropLocation.'#text';

                        if ($InstalledLocation.StartsWith("%Relativity%"))
                        {
                            $BackupLocation = $InstalledLocation.Replace("%Relativity%", (Join-Path -Path $HotfixBackupLocation -ChildPath "Relativity"));
                            $InstalledLocation = $InstalledLocation.Replace("%Relativity%", "C:\Program Files\kCura Corporation\Relativity");
                            
                        }
                        elseif ($InstalledLocation.StartsWith("%InvariantWorker%"))
                        {
                            $BackupLocation = $InstalledLocation.Replace("%InvariantWorker%", (Join-Path -Path $HotfixBackupLocation -ChildPath "Invariant\Worker"));
                            $InstalledLocation = $InstalledLocation.Replace("%InvariantWorker%", "C:\Program Files\kCura Corporation\Invariant\Worker");
                        }
                        elseif ($InstalledLocation.StartsWith("%InvariantQueueManager%"))
                        {
                            $BackupLocation = $InstalledLocation.Replace("%InvariantQueueManager%", (Join-Path -Path $HotfixBackupLocation -ChildPath "Invariant\QueueManager"));
                            $InstalledLocation = $InstalledLocation.Replace("%InvariantQueueManager%", "C:\Program Files\kCura Corporation\Invariant\QueueManager");
                        }
                        elseif ($InstalledLocation.StartsWith("%Invariant%"))
                        {
                            $BackupLocation = $InstalledLocation.Replace("%Invariant%", (Join-Path -Path $HotfixBackupLocation -ChildPath "Invariant"));
                            $InstalledLocation = $InstalledLocation.Replace("%Invariant%", "C:\Program Files\kCura Corporation\Invariant");
                        }
                        elseif ($InstalledLocation.StartsWith("%WorkerNetworkPath%"))
                        {
                            #TODO review this childpath change with jk
                            $BackupLocation = $InstalledLocation.Replace("%WorkerNetworkPath%", (Join-Path -Path $HotfixBackupLocation -ChildPath "Worker"));
                            $InstalledLocation = $InstalledLocation.Replace("%WorkerNetworkPath%", $WorkerNetworkPath);
                        }
                        else
                        {
                            throw "Error: could not find $($InstalledLocation)";
                        }

                        if (Test-Path -Path $InstalledLocation)
                        {
                            New-Item -Path (Split-Path -Path $BackupLocation -Parent) -ItemType "Directory" -Force > $null
                            Copy-Item -Path $InstalledLocation -Destination $BackupLocation -Force > $null
                            #Write-Output ">$InstalledLocation"
                        }
                        else {
                            #Write-Output ":$InstalledLocation"
                        }
                    }
                }
            }
            else
            {
                throw "Could not find 'manifest.xml' at $($StagePath)";
            }
        }

        # Relativity DropIt
        if ($Roles -match 'Web|Agent')
        {
            if (Test-Path $relPath)
            {
                # Backup DLLs
                Backup -StagePath $relPath
            }
            else { throw "RelativityDropIt Path FAIL" }
        }
        
        # Invariant DropIt
        if ($Roles -match 'Worker')
        {
            if (Test-Path $invPath)
            {
                # Backup DLLs
                Backup -StagePath $invPath
            }
            else { throw "InvariantDropIt Path FAIL" }
        }
    }
}