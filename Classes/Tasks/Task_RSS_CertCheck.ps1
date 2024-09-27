class Task_RSS_CertCheck : Task
{
    [String]$RSSName

    Task_RSS_CertCheck($hostname, $RSSName)
    {
        $this.Hostname = $hostname
        $this.RSSName = $RSSName
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @($this.RSSName)
    }    

    hidden $ScriptBlock = {
        param($rssName)
        
        # get-childProprty $rssName

        return $true
    }
}