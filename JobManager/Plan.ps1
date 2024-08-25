class Plan : Task
{
    [System.Collections.Generic.List[String]]$Hostnames = @()
    [System.Collections.Generic.List[Task]]$Tasks = @()
    hidden [Int32]$MonitorPolling = 3
    hidden [Int32]$TaskThrottle = 5

    Plan() {}

    [System.Object]Run()
    {
        $this.Status = 20
        $_m1 = "`n[$($this.Name)]`tStarting Async Run"
        $_m2 = "`n[$($this.Name)]`tStarting Sync Run"
        $this.Async ? $(Write-Host $_m1 -ForegroundColor Cyan) : $(Write-Host $_m2 -ForegroundColor Cyan)

        $this.Tasks | ForEach-Object {
            if ($_ -is [Plan])
            {
                Write-Host "[$($this.Name)]`tRunning $($_.Name)"
                $_.Run()
            }
            else
            {
                $_host = $this.HostCheck($_.Hostname)
                if ($_host.isLive)
                {
                    Write-Host "[$($this.Name)]`tRunning $($_.Name) on $($_.Hostname)"
                    $_.IsLocal = $_host.IsLocal
                    $_.Async = $this.Async
                    $_.Run()
                }
                else
                {
                    Write-Host "[$($this.Name)]`tSkipped $($_.Name) on $($_.Hostname)" -ForegroundColor Red
                    $_.Status = 10
                }
            }
        }

        $this.MonitorTasks()

        if($this.Async)
        {
            $this.Tasks | ForEach-Object {
                if($_ -is [Plan])
                {
                    $this.Result += $_.Result
                }
                else
                {
                    if ($_.Result.Count -gt 0) { $this.Result += $_.Result }
                    elseif ($_.Job -ne $null)
                    { 
                        $this.Result += (Receive-Job -Job $_.Job) 
                    }
                    else { $this.Result += "ASYNCTASKFAIL" }
                }
            }
        }
        else 
        {
            $this.Tasks | ForEach-Object {
                if ($_ -is [Plan]) { $this.Result += $_.Result }
                else
                {
                    if($_.Result -ne $null) { $this.Result += $_.Result }
                    else
                    {
                        $this.Result += "SYNCTASKFAIL"
                    }
                }
            }
        }

        $this.Final()
        return $this.Result
    }

    [void]MonitorTasks()
    {
        <# Status Updates for asynchronous tasks occur here, since they cant update themselves. #>
        if ($this.Status -eq 20) { Write-Host "`n[$($this.Name)]`tMonitoring..." -ForegroundColor Cyan }
        while ($this.Status -eq 20)
        {
            $_flag0 = $false
            $_flag10 = $false
            $_flag20 = $false
            foreach($t in $this.Tasks) {
                if ($t -is [Plan])
                {
                    if ([Int32]$t.Status -eq 20) { $_flag20 = $true; break }
                    if ([Int32]$t.Status -eq 0) { $_flag0 = $true }
                    if ([Int32]$t.Status -eq 10) { $_flag10 = $true }
                }
                else {
                    If([Int32]$t.Status -eq 10)
                    {
                        $_flag10 = $true # Check this first, in case it was cancelled from external operations.
                    }
                    else
                    {
                        $_state = $t.Job.State
                        if (($_state -eq 'Running') -or ($_state -eq 'NotStarted')) { $_flag20 = $true; break }
                        if ($_state -ne 'Completed') { $_flag0 = $true; $t.Status = 0 }
                        else { $t.Status = 1 }
                    }
                }
            }

            #TODO VERBOSE Write-Host "FLAGS:`t$($_flag0)`t$($_flag10)`t$($_flag20)"
            if ($_flag20) # Something is still running.
            {
                Start-Sleep -Seconds $this.MonitorPolling
            }
            else 
            {
                if($_flag0) { $this.Status = 0 }
                elseif($_flag10) { $this.Status = 10 }
                else { $this.Status = 1 }

                Write-Host "[$($this.Name)]`tExited with status '$($this.Status)'`n" -ForegroundColor Cyan
            }
        }
    }
}