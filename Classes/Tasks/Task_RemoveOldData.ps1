class Task_RemoveOldData : Task
{
    [String] $StagePath

    Task_RemoveOldData($hostname, $stagePath)
    {
        $this.Hostname = $hostname
        $this.StagePath = $stagePath
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @($this.StagePath)
    }    

    hidden $ScriptBlock = {
        Param ($stagePath)

        $protectedPaths = @(
            "C:\Windows",
            "C:\Program Files",
            "C:\Program Files (x86)",
            "C:\ProgramData",
            "C:\Users",
            "C:\System Volume Information"
        )

        # DELETE Hotfix Staging Location        
        if ($protectedPaths -contains $stagePath)
        {
            throw "Cannot delete: The specified path '$stagePath' is a protected system path."
        }
        else
        {
            try {
                if (Test-Path -Path $stagePath) { 
                    Remove-Item -Path $stagePath -Recurse -Force 
                }
                Write-Output "[$($env:COMPUTERNAME)] Deleted $stagePath"
            }
            catch {
                throw $_.Exception.Message
            }
            
        }

        # DELETE Rel Temp Locations
        #TODO
    }
}