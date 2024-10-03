class Instance
{
    <#
        .DESCRIPTION
            Holds Instance specific data on a Relativity Instance

        .FUNCTIONALITY
            Set Response File Defaults
            $keyValuePairs can accept a Value or a path to a list of ; delimited key=value pairs

                SetResponseCommon([String]$keyValuePairs, [Boolean]$isFilePath)
                SetResponseINV([String]$keyValuePairs, [Boolean]$isFilePath)
                SetResponseMessageBroker([String]$keyValuePairs, [Boolean]$isFilePath)
        
        .EXAMPLE
            [Instance]$myInstance = New-Object Instance
            $myInstance.Name = $instance.Name

            $myInstance.CredPack.ADun = "myDomainUser@company.com"
            $myInstance.CredPack.ADpw = 'xxxxxxxxx'
            $myInstance.CredPack.EDDSDBOPASSWORD = 'xxxxxxxx'
            $myInstance.CredPack.SERVICEUSERNAME = 'OASISDISCOVERY\svclvdshdrel'
            $myInstance.CredPack.SERVICEPASSWORD = 'xxxxxxxxx'
            $myInstance.CredPack.RMQun = "relativity"
            $myInstance.CredPack.RMQpw = "xxxxxxx"

            $myInstance.SetResponseCommon(".\Public\Defaults\LVDSHDRELINS001\_Common.txt", $true)
            $myInstance.SetResponseMessageBroker(".\Public\Defaults\LVDSHDRELINS001\RMQ.txt", $true)
            $myInstance.SetResponseINV(".\Public\Defaults\LVDSHDRELINS001\Invariant.txt", $true)

            
    #>
    Hidden [CredentialPack]$CredPack = [CredentialPack]::new()
    [String] $Name
    [PathTable] $Paths = [PathTable]::new()
    [Hashtable] $ResponseCommon = @{}
    [Hashtable] $ResponseINV = @{}
    [Hashtable] $ResponseMessageBroker = @{}
    [System.Collections.Generic.List[Server]] $Servers = @()


    #Region Response File Utility
    [Hashtable]ResponseStringToHash([String]$keyValuePairs, [Boolean]$isFilePath)
    {
        [Hashtable]$_hash = @{}
        if($isFilePath)
        {
            # Process from text file
            if (Test-Path $keyValuePairs)
            {
                Get-Content -Path $keyValuePairs | ForEach-Object {
                    $key, $value = $_ -split '='
                    $_hash[$key] = $value
                }
            }
            else {
                Write-Error "Path to Response File Default is invalid."
            }
        }
        else
        {
            # Process ; delimited string
            $keyValuePairs = $keyValuePairs -replace "`r?`n", ";"
            $pairs = $keyValuePairs -split ';'
            foreach ($pair in $pairs)
            {
                if ($pair -match '(.+)=(.*)')
                {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
        
                    $_hash[$key] = $value
                }
            }
        }

        return $_hash
    }
    SetResponseCommon([String]$keyValuePairs, [Boolean]$isFilePath) { $this.ResponseCommon = $this.ResponseStringToHash($keyValuePairs, $isFilePath) }
    SetResponseINV([String]$keyValuePairs, [Boolean]$isFilePath) { $this.ResponseINV = $this.ResponseStringToHash($keyValuePairs, $isFilePath) }
    SetResponseMessageBroker([String]$keyValuePairs, [Boolean]$isFilePath) { $this.ResponseMessageBroker = $this.ResponseStringToHash($keyValuePairs, $isFilePath) }
    #endregion

    #Region JSON Utility
    [String]ToJson()
    {
        # Create a working object to scrub data with
        $_obj = [PSCustomObject]@{
            Name = $this.Name
            Paths = [PSCustomObject]::new()
            ResponseCommon = $this.ResponseCommon
            ResponseINV =  $this.ResponseINV
            ResponseMessageBroker =  $this.ResponseMessageBroker
            Servers = [System.Collections.Generic.List[PSCustomObject]]::new()
        }

        # Paths to PSCustomObject
        $_obj.Paths = $this.Paths | Select-Object -Property *

        # Strip + Scrub unserializable [Server] properties
        $this.Servers | ForEach-Object {
            $_server = [PSCustomObject]@{
                Install = $_.Install
                Name = $_.Name
                ResponseFileProperties = $_.ResponseFileProperties
                Role = [System.Collections.Generic.List[String]]::new()
            }

            $_.Role | ForEach-Object { $_server.Role.Add([String]$_) }

            $_obj.Servers.Add($_server)
        }

        $json = $_obj | ConvertTo-Json -Depth 5

        return $json
    }

    FromJsonFile($path)
    {
        $json = Get-Content -Path $path -Raw
        $this.FromJson($json)
    }
    FromJson($json)
    {
        try {
            $jsonObj = $json | ConvertFrom-Json
            Write-Warning "Importing will use the json exactly, and will not validate Response Params."
        }
        catch {
            throw "Invalid JSON format: $($_.Exception.Message)"
        }
        
        if ($jsonObj.Name) { $this.Name = $jsonObj.Name }

        # Response Defaults
        foreach ($property in $jsonObj.ResponseCommon.PSObject.Properties)
        {
            $this.ResponseCommon[$property.Name] = $property.Value
        }
        foreach ($property in $jsonObj.ResponseINV.PSObject.Properties)
        {
            $this.ResponseINV[$property.Name] = $property.Value
        }
        foreach ($property in $jsonObj.ResponseMessageBroker.PSObject.Properties)
        {
            $this.ResponseMessageBroker[$property.Name] = $property.Value
        }

        # Paths
        if ($jsonObj.Paths.CAAT) { $this.Paths.CAAT = $jsonObj.Paths.CAAT }
        if ($jsonObj.Paths.SecretStore) { $this.Paths.SecretStore = $jsonObj.Paths.SecretStore }
        if ($jsonObj.Paths.Relativity) { $this.Paths.Relativity = $jsonObj.Paths.Relativity }
        if ($jsonObj.Paths.Invariant) { $this.Paths.Invariant = $jsonObj.Paths.Invariant }
        if ($jsonObj.Paths.NIST) { $this.Paths.NIST = $jsonObj.Paths.NIST }
        if ($jsonObj.Paths.CAATStage) { $this.Paths.CAATStage = $jsonObj.Paths.CAATStage }
        if ($jsonObj.Paths.SecretStoreStage) { $this.Paths.SecretStoreStage = $jsonObj.Paths.SecretStoreStage }
        if ($jsonObj.Paths.RelativityStage) { $this.Paths.RelativityStage = $jsonObj.Paths.RelativityStage }
        if ($jsonObj.Paths.InvariantStage) { $this.Paths.InvariantStage = $jsonObj.Paths.InvariantStage }
        if ($jsonObj.Paths.NISTPackageStage) { $this.Paths.NISTPackageStage = $jsonObj.Paths.NISTPackageStage }
        if ($jsonObj.Paths.SxS) { $this.Paths.SxS = $jsonObj.Paths.SxS }

        # Servers
        $jsonObj.Servers | ForEach-Object {
            $_server = [Server]@{
                Install = $_.Install
                Name = $_.Name
            }

            foreach ($property in $_.ResponseFileProperties.PSObject.Properties)
            {
                $_server.ResponseFileProperties[$property.Name] = $property.Value
            }

            $_.Role | ForEach-Object {
                $_server.Role.Add([RelativityServerRole]::Parse([RelativityServerRole], $_))
            }

            $this.Servers.Add($_server)
        }
    }
    #Endregion
}