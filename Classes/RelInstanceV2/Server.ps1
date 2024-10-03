class Server
{
    <#
        .DESCRIPTION
            [Server] object holds information on a single Host.
        
        .PARAMETER Install
            Toggle to flag this server for install or hotfix
        .PARAMETER Name
            Hostname
        .PARAMETER Role
            List of Relativity roles for this Host
        .PARAMETER ResponseFileProperties
            [Hashtable] of values to be used in response file
        .PARAMETER ParentInstance
            reference to Parent
    #>
    [Boolean]$Install
    [String] $Name
    [System.Object] $ParentInstance
    [System.Collections.Generic.List[RelativityServerRole]] $Role = @()
    [Hashtable] $ResponseFileProperties = @{}
    

    SetProperty([Hashtable] $properties)
    {
        foreach ($kvp in $properties.GetEnumerator())
        {
            $this.SetProperty($kvp.Key, $kvp.Value)
        }
    }

    SetProperty([String] $property, [String] $value)
    {
        $this.ResponseFileProperties[$property] = $value
    }

    InitResponseProperties()
    {
        $this.ResponseFileProperties = @{}

        # COMMON PARAMS
        if($this.ParentInstance -eq $null) { Write-Error "Server missing ParentInstance reference"; return }
        $this.ParentInstance.ResponseCommon.GetEnumerator() | ForEach-Object { $this.ResponseFileProperties[$_.Key] = $_.Value }

        # ROLE SPECIFIC PARAMS
        if ($this.Role -contains [RelativityServerRole]::Agent)
        {
            $this.SetProperty("INSTALLAGENTS", "1")
            $this.SetProperty("DEFAULTAGENTS", "0")
        }

        if ($this.Role -contains [RelativityServerRole]::Analytics)
        {
            # None
        }

        if ($this.Role -contains [RelativityServerRole]::DistributedSql)
        {
            $this.SetProperty("INSTALLDISTRIBUTEDDATABASE", "1")
            $this.SetProperty("DISTRIBUTEDSQLINSTANCE", $this.Name)
        }

        if ($this.Role -contains [RelativityServerRole]::PrimarySql)
        {
            $this.SetProperty("INSTALLPRIMARYDATABASE", "1")
        }

        if ($this.Role -contains [RelativityServerRole]::SecretStore)
        {
            # None
        }

        if ($this.Role -contains [RelativityServerRole]::ServiceBus)
        {
            $this.SetProperty("INSTALLSERVICEBUS", "1")
            $this.ParentInstance.ResponseMessageBroker.GetEnumerator() | ForEach-Object { $this.ResponseFileProperties[$_.Key] = $_.Value }
        }

        if ($this.Role -contains [RelativityServerRole]::Web)
        {
            $this.SetProperty("INSTALLWEB", "1")
            $this.SetProperty("ENABLEWINAUTH", "0")            
        }

        if ($this.Role -contains [RelativityServerRole]::Worker)
        {
            $this.SetProperty("INSTALLWORKER", "1")
            $this.ParentInstance.ResponseINV.GetEnumerator() | ForEach-Object { $this.ResponseFileProperties[$_.Key] = $_.Value }
        }

        if ($this.Role -contains [RelativityServerRole]::WorkerManager)
        {
            $this.SetProperty("INSTALLQUEUEMANAGER", "1")
            $this.ParentInstance.ResponseINV.GetEnumerator() | ForEach-Object { $this.ResponseFileProperties[$_.Key] = $_.Value }
        }
    }
}