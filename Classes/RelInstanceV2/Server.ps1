class Server
{
    [String] $Name
    [System.Collections.Generic.List[RelativityServerRole]] $Role = @()
    [Hashtable] $ResponseFileProperties = @{}
    [System.Object] $ParentInstance


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

    InitProperties()
    {
        $this.ResponseFileProperties = @{}

        # COMMON
        if (Test-Path $this.ParentInstance.PathCommonDefaults)
        {
            Get-Content -Path $this.ParentInstance.PathCommonDefaults | ForEach-Object {
                $key, $value = $_ -split '='
                $this.SetProperty($key, $value)
            }
        }
        

        # ROLE SPECIFIC
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

            if (Test-Path $this.ParentInstance.PathRMQDefaults)
            {
                Get-Content -Path $this.ParentInstance.PathRMQDefaults | ForEach-Object {
                    $key, $value = $_ -split '='
                    $this.SetProperty($key, $value)
                }
            }
        }

        if ($this.Role -contains [RelativityServerRole]::Web)
        {
            $this.SetProperty("INSTALLWEB", "1")
            $this.SetProperty("ENABLEWINAUTH", "0")            
        }

        if ($this.Role -contains [RelativityServerRole]::Worker)
        {
            $this.SetProperty("INSTALLWORKER", "1")

            if (Test-Path $this.ParentInstance.PathRMQDefaults)
            {
                Get-Content -Path $this.ParentInstance.PathInvariantDefaults | ForEach-Object {
                    $key, $value = $_ -split '='
                    $this.SetProperty($key, $value)
                }
            }
        }

        if ($this.Role -contains [RelativityServerRole]::WorkerManager)
        {
            $this.SetProperty("INSTALLQUEUEMANAGER", "1")

            if (Test-Path $this.ParentInstance.PathRMQDefaults)
            {
                Get-Content -Path $this.ParentInstance.PathInvariantDefaults | ForEach-Object {
                    $key, $value = $_ -split '='
                    $this.SetProperty($key, $value)
                }
            }
        }
    }
}