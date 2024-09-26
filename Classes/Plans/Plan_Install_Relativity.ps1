class Plan_Install_Relativity : Plan
{
    [PathTable]$Paths = [PathTable]::new()
    [System.Collections.Generic.List[Server]]$Servers = @()
    [Boolean]$SkipPreConfig
    [Boolean]$Validate
    

    Plan_Install_Relativity() { $this.Init() }
    Plan_Install_Relativity($servers, $Paths, $validate, $async)
    { 
        $this.Servers = $servers
        $this.Paths = $Paths
        $this.Validate = $validate
        $this.Async = $async
        $this.Hostnames = $servers.name
        $this.Init()
    }

    Init()
    {
        $this.WriteProgress = $true
        $this.WriteProgressActivity = "Executing Relativity Installer Workflows"

        <# PRECONFIG #>
        #TODO Add-LocalGroupMember -Group "Administrators" -Member "OASISDISCOVERY\svclvdshdrel"
        if(-not $this.SkipPreConfig)
        {
            $this.WriteProgressActivity = "Executing PreConfiguration Plan"
            $_preConfig = [Plan_PreConfig]::new($this.Servers, $this.Async, $this.Paths.SxS)
            $_preConfig.SessionName = $this.SessionName
            $_preConfig.WriteProgress = $true
            $this.Tasks.Add($_preConfig)
        }

        <# REGISTER RSS #>
        # .\secretstore whitelist write $hostname.oasisdiscovery.com
        # Create .\RSS\
        # Copy-Item -Path "\\lvdshdrelscs001\C$\Program Files\Relativity Secret Store\Client\*" -Destination "C:\RelInstall\RSS\" -Recurse
        # Run clientregistration.ps1       Workaround 'hit enter to continue'

        <# INSTALL #>
        $this.WriteProgressActivity = "Executing Relativity Installer"
        $this.Servers | ForEach-Object {
            $t = [Task_InstallRelativity]::new($_, $this.Paths)
            $t.SessionName = $this.SessionName
            $this.Tasks.Add($t)
        }

        <# POST CONFIG #>
        $this.WriteProgressActivity = "Executing PostConfig Plan"
        <# VALIDATE #>
        $this.WriteProgressActivity = "Validating Relativity Installer Workflow"

        $this.WriteProgressActivity = "Plan Completed"
    }

    <#
    Final()
    {
        $this.Result = 44
    }
    #>
}