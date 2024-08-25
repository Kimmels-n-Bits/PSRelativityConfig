#region Class Loads
. .\JobMan2\Enums.ps1
. .\JobMan2\Task.ps1
. .\JobMan2\Plan.ps1

. .\JobMan2\Tasks\Task_HW_Info.ps1
. .\JobMan2\Tasks\Task_New_PSSession.ps1
. .\JobMan2\Tasks\Task_Remove_PSSession.ps1
. .\JobMan2\Tasks\Task_Stage_Unzip.ps1
. .\JobMan2\Tasks\Task_Timer.ps1

. .\JobMan2\TaskPlans\Plan_New_StageFiles.ps1
. .\JobMan2\TaskPlans\Plan_New_PSSession.ps1
. .\JobMan2\TaskPlans\Plan_Remove_PSSession.ps1
. .\JobMan2\TaskPlans\Get_HardwareSpecs.ps1
. .\JobMan2\TaskPlans\Plan_StagingStress.ps1
. .\JobMan2\TaskPlans\Sim_Plan2.ps1
. .\JobMan2\TaskPlans\Sim_Plan1.ps1
#endregion

#region $hostnames SELENIUM + CARBON (QTY 67)
    $Hostnames = @("LVDSHDRELAGT001", "LVDSHDRELAGT002", "LVDSHDRELANA001", "LVDSHDRELANA002", "LVDSHDRELCAG001", "LVDSHDRELDGM001", "LVDSHDRELDGM002", "LVDSHDRELDGM003", "LVDSHDRELDSQ001", "LVDSHDRELDTS001", "LVDSHDRELESQ001", "LVDSHDRELLSY001", 
    "LVDSHDRELMSG001", "LVDSHDRELMSG002", "LVDSHDRELMSG003", "LVDSHDRELPDF001", "LVDSHDRELPQM001", "LVDSHDRELPSQ001", "LVDSHDRELREX001", "LVDSHDRELSCS001", "LVDSHDRELWEB001", "LVDSHDRELWEB002", "LVDSHDRELWRK001", "LVDSHDRELWRK002", "LVDSHDRELWRK003", 
    "LVDSHDRELWRK004", "LVDSHDRELWRK005", "LVDOASRELAGT001", "LVDOASRELAGT002", "LVDOASRELAGT003", "LVDOASRELAGT004", "LVDOASRELANA001", "LVDOASRELANA002", "LVDOASRELCAG001", "LVDOASRELDGD001", "LVDOASRELDGM001", "LVDOASRELDSQ001", "LVDOASRELESQ001", 
    "LVDOASRELMSG001", "LVDOASRELMSG002", "LVDOASRELMSG003", "LVDOASRELPQM001", "LVDOASRELPSQ001", "LVDOASRELSCS001", "LVDOASRELWEB001", "LVDOASRELWEB002", "LVDOASRELWRK001", "LVDOASRELWRK002", "LVDOASRELWRK003", "LVDOASRELWRK005", "LVDOASRELWRK006", 
    "LVDOASRELWRK007", "LVDOASRELWRK008", "LVDOASRELWRK009", "LVDOASRELWRK010", "LVDOASRELWRK011", "LVDOASRELWRK016", "LVDOASRELWRK019", "LVDOASRELWRK020", "LVDOASRELWRK023", "LVDOASRELWRK026", "LVDOASRELWRK030", "LVDOASRELWRK033", "LVDOASRELWRK034", 
    "LVDOASRELWRK035", "LVDOASRELWRK038", "LVDOASRELWRK040")
#endregion

#region set $creds
$un = "msolorio@oasisdiscovery.com"
$pw = ConvertTo-SecureString 'Nm9bez{7;[>$$LER29r)' -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential ($un, $pw)
#endregion

$SourcePath = "\\oasisdiscovery\dev\LVDSHDRELINS001\Staging\01\testData\Server 2023 GA Relativity Installation Files.zip"
$CopyToPath = "C:\sysprep\StressTest\"
$ExtractToPath = "C:\sysprep\StressTestTarget"

function Invoke-RelInstall
{
    $InstallRel = [Plan_StagingStress]::new($Hostnames, $Creds, $SourcePath, $CopyToPath, $ExtractToPath, $true)
    $results = $InstallRel.Run()

    Write-Host "Total Completion: $($InstallRel.Progress())" -ForegroundColor Yellow
    Write-Host "Closing Status: $($InstallRel.Status)" -ForegroundColor Yellow
    return $InstallRel
}

$r = Invoke-RelInstall