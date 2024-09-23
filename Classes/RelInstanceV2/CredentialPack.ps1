class CredentialPack
{
    <#
        .DESCRIPTION
            Stores Credentials for various components.
    #>

    [String]$ADMIN_EMAIL            # For PSQ New Installs
    [String]$ADMIN_PASSWORD
    [String]$SERVICEACCOUNT_EMAIL   # For PSQ New Installs
    [String]$SERVICEACCOUNT_PASSWORD
    [String]$ADun                   # user for PSSession and remote execution
    [String]$ADpw
    [String]$EDDSDBOPASSWORD
    [String]$SERVICEUSERNAME        # domain\user to run the service
    [String]$SERVICEPASSWORD
    [String]$SQLUSERNAME            # not needed with winauth=1
    [String]$SQLPASSWORD
    [String]$SHAREDACCESSKEY        # RMQ account used for svcbus
    [String]$SHAREDACCESSKEYNAME



    [PSCredential] CreateCredential([string]$username, [string]$password) {
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        return New-Object System.Management.Automation.PSCredential ($username, $securePassword)
    }

    [PSCredential] ADCredential() {
        if(($this.ADun -eq "") -or ($this.ADpw -eq ""))
        {
            throw "ADun or ADpw are missing"
        }
        return $this.CreateCredential($this.ADun, $this.ADpw)
    }
}