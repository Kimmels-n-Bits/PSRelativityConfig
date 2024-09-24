class Task_PreConfig : Task
{
    [Server]$Server = [Server]::new()
    [String]$SxS

    Task_PreConfig($server, $sxs)
    {
        $this.Server = $server
        $this.SxS = $sxs
        $this.Hostname = $this.Server.Name
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @(
            $this.Server.Role,
            $this.SxS
        )
    }

    hidden $ScriptBlock = {
        param($roles, $netSource)
        Write-Output ":::: [$($env:COMPUTERNAME)]"

        # Jumbo Frames
        # WARN: Interrupts Connection
        Set-NetAdapterAdvancedProperty -Name * -RegistryKeyword "*JumboPacket" -RegistryValue 9014
        $jumboFramesUpdated = Get-NetAdapterAdvancedProperty -Name * | Where-Object { $_.RegistryKeyword -eq "*JumboPacket" -and $_.RegistryValue -eq 9014 }
        if ($jumboFramesUpdated) {
            Write-Output "Jumbo Frames updated successfully."
        } else {
            Write-Output "Failed to update Jumbo Frames."
        }

        # Power Plan
        $powerPlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        powercfg.exe -SETACTIVE $powerPlanGUID
        $currentPlan = powercfg.exe /GETACTIVESCHEME
        if ($currentPlan -like "*$powerPlanGUID*") {
            Write-Output "Power plan updated successfully."
        } else {
            Write-Output "Failed to update power plan."
        }

        # Windows Performance Settings
        $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (!(Test-Path -Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }
        New-ItemProperty -Path $RegistryPath -Name "VisualFXSetting" -Value "2" -PropertyType DWORD -Force | Out-Null
        $visualFxSetting = Get-ItemProperty -Path $RegistryPath | Select-Object -ExpandProperty VisualFXSetting
        if ($visualFxSetting -eq 2) {
            Write-Output "Windows Performance Settings updated successfully."
        } else {
            Write-Output "Failed to update Windows Performance Settings."
        }

        # Processing Schedule Settings
        $registry_path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        $registry_name = "Win32PrioritySeparation"
        $registry_value = "2"

        if (!(Test-Path -Path $registry_path)) {
            New-Item -Path $registry_path -Force | Out-Null
        }
        New-ItemProperty -Path $registry_path -Name $registry_name -Value $registry_value -PropertyType DWORD -Force | Out-Null
        $prioritySetting = Get-ItemProperty -Path $registry_path | Select-Object -ExpandProperty $registry_name
        if ($prioritySetting -eq $registry_value) {
            Write-Output "Processing Schedule Settings updated successfully."
        } else {
            Write-Output "Failed to update Processing Schedule Settings."
        }

        # Paging File Size
        $ComputerSystem = Get-CimInstance Win32_ComputerSystem
        if ($ComputerSystem) {
            $ComputerSystem.AutomaticManagedPageFile = $false
            $ComputerSystem | Set-CimInstance | Out-Null
            Write-Output "Automatic Page File Management disabled."

            $PageFile = Get-CimInstance -Query "SELECT * FROM Win32_PageFileSetting WHERE Name = 'C:\\pagefile.sys'"
            if ($PageFile) {
                $PageFile.InitialSize = 4096
                $PageFile.MaximumSize = 4096
                $PageFile | Set-CimInstance | Out-Null
                Write-Output "Paging File Size updated to 4096MB."
            } else {
                Write-Output "Failed to find or update the paging file settings."
            }
        } else {
            Write-Output "Failed to retrieve ComputerSystem information."
        }

        # Install .NET Framework
        # NOTE: Get-WindowsFeature is part of ServerManager, which isnt native to WinCore.
        # ServerManager would need to be installed manually first.
        # .NET Install requires reboot
        $features = @(
            "NET-Framework-Core",
            "NET-HTTP-Activation",
            "NET-Non-HTTP-Activ",
            "NET-Framework-45-Core",
            "NET-WCF-HTTP-Activation45",
            "NET-WCF-MSMQ-Activation45",
            "NET-WCF-Pipe-Activation45",
            "NET-WCF-TCP-Activation45",
            "NET-WCF-TCP-PortSharing45"
        )

        #TODO refactor to handle aws scenarios
        foreach ($feature in $features) {
            if (Get-WindowsFeature -Name $feature | Where-Object { $_.InstallState -ne "Installed" }) {
                if($feature -eq "NET-Framework-Core")
                {
                    if (Test-Path $netSource) {
                        Install-WindowsFeature -Name $feature -Source $netSource
                    } else {
                        Write-Output "The path '$netSource' is unreachable."
                    }                    
                }
                else { Install-WindowsFeature -Name $feature }

                if (Get-WindowsFeature -Name $feature | Where-Object { $_.InstallState -eq "Installed" }) {
                    Write-Output "$feature installed successfully."
                } else {
                    Write-Output "Failed to install $feature."
                }
            } else {
                Write-Output "$feature is already installed."
            }
        }

        # Enable Microsoft DTC
        $dtcPath = "HKLM:\Software\Microsoft\MSDTC\Security"
        $dtcValue = 1
        Set-ItemProperty -Path $dtcPath -Name NetworkDtcAccess -Value $dtcValue -Force
        $dtcAccess = Get-ItemProperty -Path $dtcPath | Select-Object -ExpandProperty NetworkDtcAccess
        if ($dtcAccess -eq $dtcValue) {
            Write-Output "Microsoft DTC Network Access enabled."
        } else {
            Write-Output "Failed to enable Microsoft DTC Network Access."
        }

        Set-DtcNetworkSetting -InboundTransactionsEnabled $true -OutboundTransactionsEnabled $true -Confirm:$false
        $dtcSettings = Get-DtcNetworkSetting
        if ($dtcSettings.InboundTransactionsEnabled -and $dtcSettings.OutboundTransactionsEnabled) {
            Write-Output "DTC Network Settings updated successfully."
        } else {
            Write-Output "Failed to update DTC Network Settings."
        }

        return
    }
}