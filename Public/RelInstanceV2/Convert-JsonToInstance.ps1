function Convert-JsonToInstance
{
    <#
        .DESCRIPTION
            Returns a Hydrated [Instance] object from a json source

        .FUNCTIONALITY
            $json will be used if both params were supplied

        .EXAMPLE
            $myInstance = Convert-JsonToInstance -Path "C:\archives\RelJson.txt"
    #>
    param (
        $Path,
        $Json
    )

    if($Path -and $Json) { Write-Warning "Path ignored when `$Json is present"}

    $instance = [Instance]::new()

    if($Json) { $instance.FromJson($Json) }
    elseif ($Path) { $instance.FromJsonFile($Path) }

    return $instance
}