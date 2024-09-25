function New-Instance{
    param(
        [ValidateNotNullOrEmpty()]
        $JSON,
        [ValidateNotNullOrEmpty()]
        $File
    )

    $newInstance = [Instance]::new()

    if (($JSON) -and ($File))
    {
        $newInstance.FromJson($JSON)
    }
    elseif($JSON)
    {
        $newInstance.FromJson($JSON)
    }
    elseif($File)
    {
        $newInstance.FromJsonFile($File) 
    }


    return $newInstance
}