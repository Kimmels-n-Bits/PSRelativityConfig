function Invoke-RelativityInstall
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String]$CopyTo,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String]$ExtractTo,
        #[Parameter(Mandatory = $true)]
        #[ValidateNotNull()]
        #[RelativityInstance] $Instance,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String]$Source,
        [Switch]$StageOnly
    )

    #region $hostnames SELENIUM + CARBON        TESTDATA
    $Hostnames = @("LVDSHDRELAGT001", "LVDSHDRELAGT002", "LVDSHDRELANA001", "LVDSHDRELANA002", "LVDSHDRELCAG001", "LVDSHDRELDGM001", "LVDSHDRELDGM002", "LVDSHDRELDGM003", "LVDSHDRELDSQ001", "LVDSHDRELDTS001", "LVDSHDRELESQ001", "LVDSHDRELLSY001", 
        "LVDSHDRELMSG001", "LVDSHDRELMSG002", "LVDSHDRELMSG003", "LVDSHDRELPDF001", "LVDSHDRELPQM001", "LVDSHDRELPSQ001", "LVDSHDRELREX001", "LVDSHDRELSCS001", "LVDSHDRELWEB001", "LVDSHDRELWEB002", "LVDSHDRELWRK001", "LVDSHDRELWRK002", "LVDSHDRELWRK003", 
        "LVDSHDRELWRK004", "LVDSHDRELWRK005", "LVDOASRELAGT001", "LVDOASRELAGT002", "LVDOASRELAGT003", "LVDOASRELAGT004", "LVDOASRELANA001", "LVDOASRELANA002", "LVDOASRELCAG001", "LVDOASRELDGD001", "LVDOASRELDGM001", "LVDOASRELDSQ001", "LVDOASRELESQ001", 
        "LVDOASRELMSG001", "LVDOASRELMSG002", "LVDOASRELMSG003", "LVDOASRELPQM001", "LVDOASRELPSQ001", "LVDOASRELSCS001", "LVDOASRELWEB001", "LVDOASRELWEB002", "LVDOASRELWRK001", "LVDOASRELWRK002", "LVDOASRELWRK003", "LVDOASRELWRK005", "LVDOASRELWRK006", 
        "LVDOASRELWRK007", "LVDOASRELWRK008", "LVDOASRELWRK009", "LVDOASRELWRK010", "LVDOASRELWRK011", "LVDOASRELWRK016", "LVDOASRELWRK019", "LVDOASRELWRK020", "LVDOASRELWRK023", "LVDOASRELWRK026", "LVDOASRELWRK030", "LVDOASRELWRK033", "LVDOASRELWRK034", 
        "LVDOASRELWRK035", "LVDOASRELWRK038", "LVDOASRELWRK040")

    . .\temp~.ps1
    #endregion

    $Task = [Plan_New_PSSession]::new($Hostnames, $Creds, $true)
    $Task.WriteProgressActivity = "Creating New Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 1
    $_session = $Task.Run()

    $Task = [Plan_CopyFiles]::new($Hostnames[0..4], $_session, $Source, $CopyTo, $ExtractTo, $true, $true)
    $Task.WriteProgressActivity = "Staging Relativity Installation Files"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 2
    $_result = $Task.Run()

    $Task = [Plan_Remove_PSSession]::new($Hostnames, $_session, $true)
    $Task.WriteProgressActivity = "Removing Sessions"
    $Task.WriteProgress = $true; $Task.WriteProgressID = 3
    $_result = $Task.Run()


    Write-Host "Session Used: $_session"
}