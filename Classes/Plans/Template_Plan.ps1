<#
    .DESCRIPTION
        [Plan] objects orchestrate execution flows for other [Plan] or [Task] objects.

    .NOTES        
        1.  Set Class + Constructor Name(s)
        2.  Constructors should always call $this.Init()
        3.  Set Init()
                Place unique Initialization logic and execution flows here.
                Use $this.Tasks.ADD() with [Plan] or [Task] objects.
#>
class Template_Class : Plan
{
    Template_Class() { $this.Init() }
    Template_Class($hostnames, $myVar2)
    { 
        $this.Hostnames = $hostnames
        $this.MyVar2 = $myVar2
        $this.Init()
    }

    Init()
    {
        # Instantiate a [Plan] to execute first.
        $this.Tasks.Add([Plan_New_PSSession]::new($Hostnames, $Credentials, $SessionName))

        # Instantiate many [Task] objects to run next.
        $this.Hostnames | ForEach-Object {
            $t = [Task_HW_Info]::new($_)
            $this.Tasks.Add($t)
        }

        # Instantiate a [Plan] to execute last.
        $this.Tasks.Add([Plan_Remove_PSSession]::new($Hostnames, $Credentials, $SessionName))
    }

    <#  OVERRIDE - Use this method to customize the result returned to pipeline.
        By default, all Task results will be returned as an array.
        
    Final()
    {
        $this.Result = "Something"
    }
    #>
}