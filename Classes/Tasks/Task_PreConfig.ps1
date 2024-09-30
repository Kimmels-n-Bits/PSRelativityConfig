class Task_PreConfig : Task
{
    [PathTable]$Paths
    [Server]$Server
    [System.Collections.Generic.List[Server]]$RSSServers = @()

    Task_PreConfig($server, $rssServers, $paths)
    {
        $this.Server = $server
        $this.RSSServers = $rssServers
        $this.Paths = $paths
        $this.Hostname = $this.Server.Name
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @(
            $this.Server.Role,
            $this.Paths.SxS,
            $this.Paths.SecretStoreStage,
            $this.RSSServers[0].Name,
            $this.Server.ParentInstance.CredPack.SERVICEUSERNAME
        )
    }

    hidden $ScriptBlock = {
        param($roles, $netSource, $rssStage, $rss, $svcAccount)

        [System.Collections.Generic.List[String]]$Results = @()

        $Results += ":::: [$($env:COMPUTERNAME)]"

        # Local Admin
        Add-LocalGroupMember -Group "Administrators" -Member $svcAccount

        # RSS Cert Registration
        if (-not (Test-Path $rssStage)) { New-Item -Path $rssStage -ItemType Directory }
        
        try {
            #TODO investigate why this does not do anything at all. (but copy files [Plan] still works)
            #Set-Location "\\LVDSHDRELSCS001\C$\Program Files\Relativity Secret Store\Client\"
            #Copy-Item -Path "Y:\*" -Destination $rssStage -Recurse
        }
        catch { $Results += "[ERROR] $_" }
        
        
        $regScript = Join-path -Path $rssStage -ChildPath "\Client\clientregistration.ps1"
        if (Test-Path $regScript)
        {
            Set-Location -Path $(Join-path -Path $rssStage -ChildPath "Client")
            & .\clientregistration.ps1 -Confirm -ForceReRegistration | Write-Output

            Get-Location | Write-Output

            #TODO Validate local cert
        }


        # Jumbo Frames
        # WARN: Interrupts Connection.  Also fails in AWS due to network policy
        try {
            Get-NetIPInterface | Where-Object { $_.ConnectionState -eq 'Connected' } | ForEach-Object {
                Set-NetIPInterface -InterfaceAlias $_.InterfaceAlias -NlMtu 9001
            }
            $Results += "Jumbo Frames updated successfully."
            #Set-NetAdapterAdvancedProperty -Name * -RegistryKeyword "*JumboPacket" -RegistryValue 9014
        }
        catch {
            $Results += "Failed to update Jumbo Frames. $_"
        }
        
        <#$jumboFramesUpdated = Get-NetAdapterAdvancedProperty -Name * | Where-Object { $_.RegistryKeyword -eq "*JumboPacket" -and $_.RegistryValue -eq 9014 }
        if ($jumboFramesUpdated) {
            $Results += "Jumbo Frames updated successfully."
        } else {
            $Results += "Failed to update Jumbo Frames."
        }#>

        # Power Plan
        $powerPlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        powercfg.exe -SETACTIVE $powerPlanGUID
        $currentPlan = powercfg.exe /GETACTIVESCHEME
        if ($currentPlan -like "*$powerPlanGUID*") {
            $Results += "Power plan updated successfully."
        } else {
            $Results += "Failed to update power plan."
        }

        # Windows Performance Settings
        $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (!(Test-Path -Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }
        New-ItemProperty -Path $RegistryPath -Name "VisualFXSetting" -Value "2" -PropertyType DWORD -Force | Out-Null
        $visualFxSetting = Get-ItemProperty -Path $RegistryPath | Select-Object -ExpandProperty VisualFXSetting
        if ($visualFxSetting -eq 2) {
            $Results += "Windows Performance Settings updated successfully."
        } else {
            $Results += "Failed to update Windows Performance Settings."
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
            $Results += "Processing Schedule Settings updated successfully."
        } else {
            $Results += "Failed to update Processing Schedule Settings."
        }

        # Paging File Size
        $ComputerSystem = Get-CimInstance Win32_ComputerSystem
        if ($ComputerSystem) {
            $ComputerSystem.AutomaticManagedPageFile = $false
            $ComputerSystem | Set-CimInstance | Out-Null
            $Results += "Automatic Page File Management disabled."

            $PageFile = Get-CimInstance -Query "SELECT * FROM Win32_PageFileSetting WHERE Name = 'C:\\pagefile.sys'"
            if ($PageFile) {
                $PageFile.InitialSize = 4096
                $PageFile.MaximumSize = 4096
                $PageFile | Set-CimInstance | Out-Null
                $Results += "Paging File Size updated to 4096MB."
            } else {
                $Results += "Failed to find or update the paging file settings."
            }
        } else {
            $Results += "Failed to retrieve ComputerSystem information."
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

        foreach ($feature in $features) {
            if (Get-WindowsFeature -Name $feature | Where-Object { $_.InstallState -ne "Installed" }) {
                if($feature -eq "NET-Framework-Core")
                {
                    if (Test-Path $netSource) {
                        Install-WindowsFeature -Name $feature -Source $netSource
                    } else {
                        $Results += "The path '$netSource' is unreachable."
                    }                    
                }
                else { Install-WindowsFeature -Name $feature }

                if (Get-WindowsFeature -Name $feature | Where-Object { $_.InstallState -eq "Installed" }) {
                    $Results += "$feature installed successfully."
                } else {
                    $Results += "Failed to install $feature."
                }
            } else {
                $Results += "$feature is already installed."
            }
        }

        # Enable Microsoft DTC
        $dtcPath = "HKLM:\Software\Microsoft\MSDTC\Security"
        $dtcValue = 1
        Set-ItemProperty -Path $dtcPath -Name NetworkDtcAccess -Value $dtcValue -Force
        $dtcAccess = Get-ItemProperty -Path $dtcPath | Select-Object -ExpandProperty NetworkDtcAccess
        if ($dtcAccess -eq $dtcValue) {
            $Results += "Microsoft DTC Network Access enabled."
        } else {
            $Results += "Failed to enable Microsoft DTC Network Access."
        }

        Set-DtcNetworkSetting -InboundTransactionsEnabled $true -OutboundTransactionsEnabled $true -Confirm:$false
        $dtcSettings = Get-DtcNetworkSetting
        if ($dtcSettings.InboundTransactionsEnabled -and $dtcSettings.OutboundTransactionsEnabled) {
            $Results += "DTC Network Settings updated successfully."
        } else {
            $Results += "Failed to update DTC Network Settings."
        }

        return $Results
    }
}