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

class PathTable
{
    <#
        .DESCRIPTION
            Holds paths for file sources and installation paths
    #>
    [String] $CAAT
    [String] $CAATStage = "C:\RelInstall\CAAT\"
    [String] $Invariant
    [String] $InvariantStage = "C:\RelInstall\Invariant\"
    [String] $NIST
    [String] $NISTPackageStage = "C:\RelInstall\Nist\"
    [String] $Relativity
    [String] $RelativityStage = "C:\RelInstall\Relativity\"
    [String] $SecretStore
    [String] $SecretStoreStage = "C:\RelInstall\RSS\"
    [String] $SxS = "D:\Sources\SxS"
    

    PathTable() {}
    PathTable([String] $secretStore, [String] $relativity, [String] $invariant, [String] $nistPackage)
    {
        $this.SecretStore = $secretStore
        $this.Relativity = $relativity
        $this.Invariant = $invariant
        $this.NIST = $nistPackage
    }
}