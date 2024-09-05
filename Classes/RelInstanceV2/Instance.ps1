class Instance
{
    <#
        .DESCRIPTION
            Holds Instance specific data on a Relativity Instance
        
        .EXAMPLE
            
    #>
    [String] $Name
    [System.Collections.Generic.List[Server]] $Servers = @()
    #[InstallerBundle] $InstallerBundle
    [String] $PathCommonDefaults
    [String] $PathInstallDirectory
    [String] $PathRMQDefaults
    [String] $PathInvariantDefaults

    [String]ToJson()
    {
        # Create a working object to scrub data with
        $_obj = [PSCustomObject]@{
            Name = $this.Name
            PathCommonDefaults = $this.PathCommonDefaults
            PathInstallDirectory = $this.PathInstallDirectory
            PathRMQDefaults = $this.PathRMQDefaults
            PathInvariantDefaults = $this.PathInvariantDefaults
            Servers = [System.Collections.Generic.List[PSCustomObject]]::new()
        }

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
            $reconstitutedObj = $json | ConvertFrom-Json
            Write-Warning "Importing will use the json exactly, and will not validate Response Params."
        }
        catch {
            throw "Invalid JSON format: $($_.Exception.Message)"
        }
        

        $this.Name = $reconstitutedObj.Name
        $this.PathCommonDefaults = $reconstitutedObj.PathCommonDefaults
        $this.PathInstallDirectory = $reconstitutedObj.PathInstallDirectory
        $this.PathRMQDefaults = $reconstitutedObj.PathRMQDefaults
        $this.PathInvariantDefaults = $reconstitutedObj.PathInvariantDefaults

        $reconstitutedObj.Servers | ForEach-Object {
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