function New-Instance
{
    <#
        .DESCRIPTION
            Returns a Hydrated [Instance] object from a json source

        .FUNCTIONALITY
            $json will be used if both params were supplied
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