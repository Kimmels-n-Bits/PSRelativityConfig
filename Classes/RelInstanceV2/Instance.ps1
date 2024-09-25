class Instance
{
    <#
        .DESCRIPTION
            Holds Instance specific data on a Relativity Instance
        
        .EXAMPLE
            
    #>
    Hidden [CredentialPack]$CredPack = [CredentialPack]::new()
    [String] $Name
    [System.Collections.Generic.List[Server]] $Servers = @()
    [PathTable] $Paths = [PathTable]::new()


    [String]ToJson()
    {
        # Create a working object to scrub data with
        $_obj = [PSCustomObject]@{
            Name = $this.Name
            Paths = [PSCustomObject]::new()
            Servers = [System.Collections.Generic.List[PSCustomObject]]::new()
        }

        # Paths to PSCustomObject
        $_obj.Paths = $this.Paths | Select-Object -Property *

        # Strip + Scrub unserializable [Server] properties
        $this.Servers | ForEach-Object {
            $_server = [PSCustomObject]@{
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

        if ($jsonObj.Paths.CAAT) { $this.Paths.CAAT = $jsonObj.Paths.CAAT }
        if ($jsonObj.Paths.SecretStore) { $this.Paths.SecretStore = $jsonObj.Paths.SecretStore }
        if ($jsonObj.Paths.Relativity) { $this.Paths.Relativity = $jsonObj.Paths.Relativity }
        if ($jsonObj.Paths.Invariant) { $this.Paths.Invariant = $jsonObj.Paths.Invariant }
        if ($jsonObj.Paths.NIST) { $this.Paths.NIST = $jsonObj.Paths.NIST }
        if ($jsonObj.Paths.CAATStage) { $this.Paths.CAATStage = $jsonObj.Paths.CAATStage }
        if ($jsonObj.Paths.SecretStoreStage) { $this.Paths.SecretStoreStage = $jsonObj.Paths.SecretStoreStage }
        if ($jsonObj.Paths.RelativityStage) { $this.Paths.RelativityStage = $jsonObj.Paths.RelativityStage }
        if ($jsonObj.Paths.ResponseCommon) { $this.Paths.ResponseCommon = $jsonObj.Paths.ResponseCommon }
        if ($jsonObj.Paths.ResponseINV) { $this.Paths.ResponseINV = $jsonObj.Paths.ResponseINV }
        if ($jsonObj.Paths.ResponseRMQ) { $this.Paths.ResponseRMQ = $jsonObj.Paths.ResponseRMQ }
        if ($jsonObj.Paths.InvariantStage) { $this.Paths.InvariantStage = $jsonObj.Paths.InvariantStage }
        if ($jsonObj.Paths.NISTPackageStage) { $this.Paths.NISTPackageStage = $jsonObj.Paths.NISTPackageStage }
        if ($jsonObj.Paths.SxS) { $this.Paths.SxS = $jsonObj.Paths.SxS }


        $jsonObj.Servers | ForEach-Object {
            $_server = [Server]@{
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
}