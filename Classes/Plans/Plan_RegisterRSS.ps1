class Plan_RegisterRSS : Plan
{
    <#
        .DESCRIPTION
            Cycles through Relativity Secret Stores to handle host registrations
    #>
    [System.Collections.Generic.List[Server]]$SecretStores = @()
    [System.Collections.Generic.List[String]]$HostsToRegister = @()
    [Action]$Action 


    Plan_RegisterRSS($secretStores, $hostnames, [Action]$action, $session, $async)
    {
        $this.SecretStores = $secretStores
        $this.HostsToRegister = $hostnames
        $this.Action = $action
        $this.SessionName = $session
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        Foreach ($server in $this.SecretStores) {
            switch ([Int32]$this.Action) {
                3 {
                    Write-Host "Action: Remove"
                }
                4 {
                    Write-Host $_.Name
                    $t = [Task_RegisterRSS]::new($server.Name, $this.HostsToRegister)
                    $this.Tasks.Add($t)
                }
                6 {
                    Write-Host "Action: Read"
                }
                default {
                    Write-Host "No Action"
                    $t = $null
                }
            }
            
        }
    }

    <#
    Final()
    {

    }
    #>
}