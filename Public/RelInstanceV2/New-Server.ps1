function New-Server
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Generic.List[String]] $Names = @(),
        [ValidateNotNullOrEmpty()]
        [System.Collections.Generic.List[String]] $Roles = @()
    )

    [System.Collections.Generic.List[Server]]$ServerList = @()

    $Names | ForEach-Object {
        $_server = [Server]::New()
        $_server.name = $_
        
        foreach($role in $Roles)
        {
            try {
                $_server.Role.Add([RelativityServerRole]::Parse([RelativityServerRole], $role))
            }
            catch {
                # Skip             
            }
        }

        $ServerList.Add($_server)
    }
    
    return $ServerList
}