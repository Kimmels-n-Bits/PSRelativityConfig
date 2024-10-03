function Convert-ToInstanceV2
{
    <# 
        .DESCRIPTION
            Interim function to bridge data model differences between RelInstance and RelInstanceV2.

        .EXAMPLE
            Typical usage will perform initial conversion.
            Optionally move on to intialize paths and server properties (like responsefile params)

                $RelInstance2 = Convert-ToInstanceV2 -instance $RelInstance

                $RelInstance2.Paths.ResponseCommon = ".\Public\Defaults\LVDSHDRELINS001\_Common.txt"
                $RelInstance2.Paths.ResponseRMQ = ".\Public\Defaults\LVDSHDRELINS001\RMQ.txt"
                $RelInstance2.Paths.ResponseINV = ".\Public\Defaults\LVDSHDRELINS001\Invariant.txt"
                
                $RelInstance2.Servers | ForEach-Object {
                    $_.InitResponseProperties()
                }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [RelativityInstance]$instance
    )

    [Instance]$InstanceV2 = New-Object Instance
    $InstanceV2.Name = $instance.Name

    $instance.Servers | ForEach-Object {
        [Server]$_server = New-Object Server
        $_server.Name = $_.Name
        $_server.ParentInstance = $InstanceV2
        $_server.Role.AddRange($_.Role)

        $InstanceV2.Servers.Add($_server)
    }

    return $InstanceV2
}