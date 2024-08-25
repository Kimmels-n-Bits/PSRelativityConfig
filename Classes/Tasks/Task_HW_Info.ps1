class Task_HW_Info : Task
{
    Task_HW_Info($hostname) { $this.Hostname = $hostname; $this.Init() }

    Init()
    {
        $this.Arguments = @()
    }    

    hidden $ScriptBlock = {
        $hardwareInfo = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            CPU = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
            MemoryGB = [math]::Round((Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
            OS = (Get-WmiObject Win32_OperatingSystem).Caption
            DiskSizeGB = [math]::Round((Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
            GPU = Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Name
        }

        return $hardwareInfo
    }
}