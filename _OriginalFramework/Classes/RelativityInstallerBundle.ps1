enum Installer
{
    SecretStore
    Relativity
    Invariant
    NISTPackage
}

class RelativityInstallerBundle
{
    [ValidateNotNullOrEmpty()]
    [String] $SecretStore
    [ValidateNotNullOrEmpty()]
    [String] $SecretStoreMD5Hash
    [ValidateNotNullOrEmpty()]
    [String] $Relativity
    [ValidateNotNullOrEmpty()]
    [String] $RelativityMD5Hash
    [ValidateNotNullOrEmpty()]
    [String] $Invariant
    [ValidateNotNullOrEmpty()]
    [String] $InvariantMD5Hash
    [ValidateNotNullOrEmpty()]
    [String] $NISTPackage
    [ValidateNotNullOrEmpty()]
    [String] $NISTPackageMD5Hash

    static [Hashtable] $ValidHashes = @{
        [Installer]::SecretStore = @(
            "EDCC84F7A1972308257528C99DDC1A55"
        )
        [Installer]::Relativity = @(
            "A944DB9A333503F4EA734FD352FF037B"
        )
        [Installer]::Invariant = @(
            "229118291F3E855F84AF57506B863A22"
        )
        [Installer]::NISTPackage = @(
            "B5BC8510922B9EFAA4EB437C889ACA57"
        )
    }

    RelativityInstallerBundle([String] $secretStore, [String] $relativity, [String] $invariant, [String] $nistPackage)
    {
        $this.SecretStore = $secretStore
        $this.SecretStoreMD5Hash = $this.ValidateInstallationFile($secretStore, [Installer]::SecretStore)
        $this.Relativity = $relativity
        $this.RelativityMD5Hash = $this.ValidateInstallationFile($relativity, [Installer]::Relativity)
        $this.Invariant = $invariant
        $this.InvariantMD5Hash = $this.ValidateInstallationFile($invariant, [Installer]::Invariant)
        $this.NISTPackage = $nistPackage
        $this.NISTPackageMD5Hash = $this.ValidateInstallationFile($nistPackage, [Installer]::NISTPackage)
    }

    [String] ValidateInstallationFile([String] $path, [Installer] $installer)
    {
        Write-Verbose "Validating $($path) is a UNC path."
        if (-not (([System.Uri]::New($path)).IsUnc))
        {
            throw "The path '$($path)' is not a valid UNC path."
        }

        Write-Verbose "Validating $($path) exists."
        if (-not (Test-Path -Path $path -PathType Leaf))
        {
            throw "The file '$($path)' does not exist."
        }

        Write-Verbose "Validating $($path) MD5 hash value."
        $FileHash = (Get-FileHash -Path $path -Algorithm MD5).Hash
        if (-not ([RelativityInstallerBundle]::ValidHashes[$installer] -contains $FileHash))
        {
            throw "The MD5 hash value for the file at '$($path)' does not match any valid hash for the installer type '$($installer.ToString())."
        }

        return $FileHash
    }
}