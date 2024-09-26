class Task
{
    <#
        .DESCRIPTION
            [Task] Objects represent a single unit of work that will always execute as a job.

        .FUNCTIONALITY
            Can be executed directly using Run(), but is best used as a member of a [Plan].
    #>
    [System.Collections.Generic.List[System.Object]]$Arguments = @()
    [Boolean]$Async = $false
    [PSCredential]$Credentials
    [System.Collections.Generic.List[String]]$Errors = @()
    [String]$Hostname
    hidden [Boolean]$IsLocal = $false
    [System.Management.Automation.Job]$Job
    [String] $Name = $this.GetType().Name
    [System.Object[]]$Result = @()
    hidden [System.Object] $ScriptBlock
    [String]$SessionName
    [TaskStatus]$Status = 30
    [String]$Runtime = "0"
    [Boolean]$WriteProgress             # enable to allow this object to write ProgressBar
    [Int32]$WriteProgressID = 0
    [String]$WriteProgressActivity

    Init() {}

    [System.Object]Run()
    {
        $_timer = [System.Diagnostics.Stopwatch]::StartNew()
        $this.Status = 20

        try {
            if ($this.IsLocal)
            {
                $this.Job = Start-Job -ScriptBlock $this.ScriptBlock -ArgumentList $this.Arguments
            }
            else
            {
                if ($this.SessionName -eq "") {
                    $this.Job = Invoke-Command -AsJob -ComputerName $this.Hostname -ScriptBlock $this.ScriptBlock -ArgumentList $this.Arguments
                }
                else {
                    $this.Job = Invoke-Command -AsJob -ComputerName $this.Hostname -ConfigurationName $this.SessionName -ScriptBlock $this.ScriptBlock -ArgumentList $this.Arguments
                }
            }

            if(-not $this.Async)
            {
                Wait-Job -Job $this.Job
                $this.Result += (Receive-Job -Job $this.Job)
                $this.Status = 1
            }
        }
        catch {
            $this.Status = 0
        }

        $this.Final()
        $_timer.Stop()
        $this.Runtime = $this.TimeFormat($_timer.Elapsed)
        return $this.Result
    }

    #region TODO Event Handling **NOT IMPLEMENTED YET*
    [void]Event([EventAction]$event, [Task]$task)
    {
        if ($event = 'Failed') {
            $this.Failed()
        }
        if ($event = 'Completed')
        {
            $this.Completed()
        }
        if ($event = 'Started')
        {
            $this.Started()
        }
        if ($event = 'Cancelled')
        {
            $this.Cancelled()
        }
    }

    [void]Failed() {}
    [void]Completed() {}
    [void]Started() {}
    [void]Cancelled() {}
    #endregion
    
    [PSCustomObject]HostCheck($name)
    {
        $h = [PSCustomObject]@{
            IsLocal = $false
            IsLive = $false
            IPAddress = "0.0.0.0"
            Latency = "-1"
        }

        try
        {
            $t = Test-Connection -TargetName $name -Count 1 -IPv4 -TimeoutSeconds 1
            if ($t -eq $null) { throw "Host not reachable." }
        }
        catch
        {
            return $h #host failed
        }

        $h.isLocal = $name -eq $env:COMPUTERNAME
        $h.isLive = $true
        $h.IPAddress = $t.Address
        $h.Latency = $t.Latency

        return $h
    }

    hidden [String]TimeFormat([TimeSpan]$elapsed)
    {
        $_time = "{0:D2}:{1:D2}:{2:D2}.{3:D3}" -f `
            $elapsed.Hours, `
            $elapsed.Minutes, `
            $elapsed.Seconds, `
            $elapsed.Milliseconds
        
        return $_time
    }

    [Int32]Progress()
    {
        $_scores = @()
        if ($this.GetType().BaseType -eq "Task")
        {
            if ([Int32]$this.Status -eq 1) { $_scores += 100 }
            else { $_scores += 0 } 
        }
        else
        {
            $this.Tasks | ForEach-Object {
                if ([Int32]$_.Status -eq 1) { $_scores += 100 }
                elseif ([Int32]$_.Status -eq 10) { $_scores += $_.Progress() }
                else { $_scores += 0 }
            }
        }

        return $([Int32]($_scores | Measure-Object -Average | Select-Object -ExpandProperty Average))
    }
    
    Final()
    {
        # OVERRIDE to customize $this.result property, and float upward
    }
}