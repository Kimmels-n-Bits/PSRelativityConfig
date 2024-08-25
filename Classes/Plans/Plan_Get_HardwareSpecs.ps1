class Get_HardwareSpecs : Plan
{

    Get_HardwareSpecs($hostnames) { $this.Hostnames = $hostnames; $this.Init() }
    Get_HardwareSpecs($hostnames, $name, $async)
    {
        $this.Hostnames = $hostnames
        $this.Name = $name
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $this.Hostnames[0..4] | ForEach-Object {
            $this.Tasks.Add([Task_HW_Info]::new($_))
        }
    }

    Final()
    {
        $this.Tasks | ForEach-Object {
            $this.Result += $(Receive-Job -Job $_.Job)
        }
    }
}