
param(
    [securestring]$dsrmPassword,
    [securestring]$localPassword,
    [string]$domainName,
    [string]$username,
    [boolean]$backupDC
)

if ($backupDC) {
    Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential $username, $localPassword) -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -DomainName $domainName -InstallDNS -SafeModeAdministratorPassword $dsrmPassword -Confirm:$false
} 
else {
    Install-ADDSForest -DomainName $domainName -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -SafeModeAdministratorPassword $dsrmPassword -InstallDNS -Confirm:$false
    Set-DnsServerForwarder -IPAddress @("8.8.8.8", "8.8.4.4") -UseRootHint:$true -PassThru -Confirm:$false
}