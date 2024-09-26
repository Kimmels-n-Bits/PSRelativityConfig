class Plan : Task
{
    <#
        .DESCRIPTION
            Acts as an orchestrator to [Task] and [Plan] Objects

        .FUNCTIONALITY
            Using Run() will iterate over $Tasks, track run status, and float results up.
            Overriding Final() can customize return results.

        .PARAMETER Hostnames
            List of hostnames to execute $Tasks against

        .PARAMETER Tasks
            List of [Task] or [Plan] objects to Run()

        .PARAMETER MonitorPolling
            Intervals in seconds to check on running jobs
    #>
    [System.Collections.Generic.List[String]]$Hostnames = @()
    [System.Collections.Generic.List[Task]]$Tasks = @()
    hidden [Int32]$MonitorPolling = 3

    Plan() {}

    [System.Object]Run()
    {
        $_timer = [System.Diagnostics.Stopwatch]::StartNew()
        $this.Status = 20

        $this.UpdateOutput(2, $($this.Async ? "[$($this.Name)]`tStarting Async Run" : "[$($this.Name)]`tStarting Sync Run"))
        $this.UpdateProgress($this.WriteProgressActivity, "Starting...")

        $this.Tasks | ForEach-Object {
            if ($_ -is [Plan])
            {
                $this.UpdateOutput(2, "[$($this.Name)]`tRunning $($_.Name)")
                $this.UpdateProgress($this.WriteProgressActivity, "[$($this.Name)] Running $($_.Name)")
                $_.Run()
            }
            else
            {
                $_host = $this.HostCheck($_.Hostname)
                if ($_host.isLive)
                {
                    $this.UpdateOutput(1, "[$($this.Name)]`tRunning $($_.Name) on $($_.Hostname)")
                    $this.UpdateProgress($this.WriteProgressActivity, "[$($this.Name)] Running $($_.Name) on $($_.Hostname)")

                    $_.IsLocal = $_host.IsLocal
                    $_.Async = $this.Async
                    $_.Run()
                }
                else
                {
                    $this.UpdateOutput(0, "[$($this.Name)]`tSkipped $($_.Name) on $($_.Hostname)")
                    $this.UpdateProgress($this.WriteProgressActivity, "[$($this.Name)] Skipped $($_.Name) on $($_.Hostname)")
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
                        [System.Object]$r = (Receive-Job -Job $_.Job)
                        $this.Result += $r
                        $_.Result = $r
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
        $_timer.Stop()
        $this.Runtime = $this.TimeFormat($_timer.Elapsed)
        return $this.Result
    }

    [void]UpdateProgress([String]$activity, [String]$status)
    {
        if (($script:OutputProgress) -and ($this.WriteProgress))
        {
            if (-not $this.WriteProgressActivity) # Default Activity
            {
                $_m1 = "[$($this.Name)] Async Run"
                $_m2 = "[$($this.Name)] Sync Run"
                $this.WriteProgressActivity = $($this.Async ? $_m1 : $_m2)
                $activity = $this.WriteProgressActivity
            }
            Write-Progress -Id $this.WriteProgressID -Activity $activity -Status $status -PercentComplete $this.Progress()
        }
    }

    [void]UpdateOutput([Int32]$style, [String]$message)
    {
        if ($script:OutputLog)
        {
            <#TODO WRITE TO LOG FILE #>
        }

        if ($script:OutputCLI)
        {
            switch ($style) {
                0 { Write-Host $message -ForegroundColor Red }
                1 { Write-Host $message }
                2 { Write-Host $message -ForegroundColor Cyan }
                Default { Write-Host $message }
            }
            
        }
    }

    [void]MonitorTasks()
    {
        <# Status Updates for asynchronous tasks occur here, since they dont update themselves. #>
        $this.UpdateOutput(2, "[$($this.Name)]`tWaiting for Job completion...")

        while ($this.Status -eq 20)
        {
            $_flag0 = $false
            $_flag10 = $false
            $_flag20 = $false

            $this.UpdateProgress($this.WriteProgressActivity, "[$($this.Name)] Waiting for Job completion...")

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

                $this.UpdateOutput(2, "[$($this.Name)]`tExited with status '$($this.Status)'`n")
                $this.UpdateProgress($this.WriteProgressActivity, "[$($this.Name)] Exited with status '$($this.Status)'")
            }
        }
    }
}