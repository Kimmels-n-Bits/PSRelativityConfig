class Task_Validate_Agent : Task
{
    Task_Validate_Agent($hostname) { $this.Hostname = $hostname; $this.Init() }

    Init()
    {
        $this.Arguments = @()
    }    

    hidden $ScriptBlock = {
        Set-NetAdapterAdvancedProperty -Name * -RegistryKeyword "*JumboPacket" -Registryvalue 9014
        Write-Output "[SUCCESS]`t.Jumbo Frames enabled"

        # Edit Power Plan
        $currentPlan = powercfg.exe /GETACTIVESCHEME
        if(-not ($currentPlan -like "*8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c*"))
        {
            Write-Output "[SUCCESS]`tCurrent Plan changing to High Performance"
            powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }
        else { Write-Output "[SUCCESS]`tCurrent Plan is already set to High Performance" }


        # Adjust Windows Performance Settings
        $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (!(Test-Path -Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }
        New-ItemProperty -Path $RegistryPath -Name "VisualFXSetting" -Value "2" -PropertyType DWORD -Force | Out-Null
        Write-Output "[SUCCESS]`tWindows Performance set VisualFX"

        # 3.6 Adjust Processing Schedule Settings
        $registry_path_1 = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        $registry_name = "Win32PrioritySeparation"
        $registry_value = "2"

        if (!(Test-Path -Path $registry_path_1)) {
            New-Item -Path $registry_path_1 -Force | Out-Null
        }
        New-ItemProperty -Path $registry_path_1 -Name $registry_name -Value $registry_value -PropertyType DWORD -Force | Out-Null
        Write-Output "[SUCCESS]`tAutomatic Paging management Disabled"

        # 3.7 Adjust Paging File Size
        $ComputerSystem = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
        $ComputerSystem.AutomaticManagedPageFile = $false
        $ComputerSystem.Put() | Out-Null

        $PageFile = Get-WmiObject -Query "SELECT * FROM Win32_PageFileSetting WHERE Name = 'C:\\pagefile.sys'"
        $PageFile.InitialSize = 4096
        $PageFile.MaximumSize = 4096
        $PageFile.Put() | Out-Null
        Write-Output "[SUCCESS]`tPaging File Sizes Set"

        # Verify .NET
        if((Get-WindowsFeature -Name NET-Framework-Core).Installed)
        {
            Write-Output "[SUCCESS]`t.NET 3.5 Framework is Installed"
        }
        else
        {
            Write-Output "[ERROR]`t.NET 3.5 Framework is NOT installed"
        }

        $netVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release).Release
        if ($netVersion -ge 393295) {
            Write-Output "[SUCCESS]`t.NET Framework 4.6 or higher is installed"
        } else {
            Write-Output "[ERROR]`t.NET Framework 4.6 or higher is NOT installed"
        }

        # 3.9 Enable Microsoft DTC
        Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccess -Value 1 -Force

        $dtc = Get-DtcNetworkSetting -DtcName "Local"
        Set-DtcNetworkSetting -InboundTransactionsEnabled $true -OutboundTransactionsEnabled $true -Confirm:$false
        Write-Output "[SUCCESS]`tCurrent DTC -InboundTransactionsEnabled $($dtc.InboundTransactionsEnabled) set to TRUE"
        Write-Output "[SUCCESS]`tCurrent DTC -OutboundTransactionsEnabled $($dtc.OutboundTransactionsEnabled) set to TRUE"
    }
}