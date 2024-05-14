
param(
    [securestring]$dsrmPassword,
    [securestring]$localPassword,
    [string]$domainName,
    [string]$username,
    [boolean]$backupDC
)

Start-Transcript -Path "C:\transcripts\transcript0.txt" -NoClobber

Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PassThru | New-Partition -DriveLetter E -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'data' -Confirm:$false
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

$dnsExists = Resolve-DnsName -Name ad.pgzr.io

if ($backupDC) {
    while($dnsExists -eq $null) {
        Restart-NetAdapter -Name "Ethernet"
        Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential $username, $localPassword) -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -DomainName $domainName -InstallDNS -SafeModeAdministratorPassword $dsrmPassword -Confirm:$false
    }
} 
else {
    Install-ADDSForest -DomainName $domainName -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -SafeModeAdministratorPassword $dsrmPassword -InstallDNS -Confirm:$false
    Set-DnsServerForwarder -IPAddress @("8.8.8.8", "8.8.4.4") -UseRootHint:$true -PassThru -Confirm:$false
}

