
param(
    [securestring]$dsrmPassword,
    [securestring]$localPassword,
    [string]$domainName,
    [string]$username
)
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PassThru | New-Partition -DriveLetter E -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'data' -Confirm:$false
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

Restart-NetAdapter -Name "Ethernet"

Start-Sleep -Seconds 5t

$dnsExists = Resolve-DnsName -Name $domainName

if ($dnsExists) {
    Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential ($username, $localPassword)) -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -DomainName '$domainName' -InstallDNS -SafeModeAdministratorPassword $dsrmPassword -Confirm:$false
} else {
    Install-ADDSForest -DomainName ad.pgzr.io -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -SafeModeAdministratorPassword $dsrmPassword -InstallDNS -Confirm:$false
}