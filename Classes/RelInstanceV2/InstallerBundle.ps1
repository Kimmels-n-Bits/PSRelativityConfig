<# enable after original RelInstance is phased out
#TODO is this needed?
enum Installer
{
    SecretStore
    Relativity
    Invariant
    NISTPackage
}
#>

class InstallerBundle
{
    <#
        .DESCRIPTION
            Holds paths for files sources and installation paths
    #>
    [ValidateNotNullOrEmpty()]
    [String] $CAAT
    [ValidateNotNullOrEmpty()]
    [String] $SecretStore
    [ValidateNotNullOrEmpty()]
    [String] $Relativity
    [ValidateNotNullOrEmpty()]
    [String] $Invariant
    [ValidateNotNullOrEmpty()]
    [String] $NIST
    [ValidateNotNullOrEmpty()]
    [String] $CAATStage = "C:\RelInstall\CAAT\"
    [ValidateNotNullOrEmpty()]
    [String] $SecretStoreStage = "C:\RelInstall\RSS\"
    [ValidateNotNullOrEmpty()]
    [String] $RelativityStage = "C:\RelInstall\Relativity\"
    [ValidateNotNullOrEmpty()]
    [String] $InvariantStage = "C:\RelInstall\Invariant\"
    [ValidateNotNullOrEmpty()]
    [String] $NISTPackageStage = "C:\RelInstall\Nist\"
    [ValidateNotNullOrEmpty()]
    [String] $SxS = "D:\Sources\sxs"
    

    InstallerBundle() {}
    InstallerBundle([String] $secretStore, [String] $relativity, [String] $invariant, [String] $nistPackage)
    {
        $this.SecretStore = $secretStore
        $this.Relativity = $relativity
        $this.Invariant = $invariant
        $this.NIST = $nistPackage
    }
}