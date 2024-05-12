
param(
    [securestring]$dsrmPassword,
    [securestring]$localPassword,
    [string]$domainName,
    [string]$username
)
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PassThru | New-Partition -DriveLetter E -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'data' -Confirm:$false
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

Restart-NetAdapter -Name "Ethernet"

$dnsExists = Resolve-DnsName -Name $domainName

if ($dnsExists) {
    
} else {
    Install-ADDSForest -DomainName $domainName -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -SafeModeAdministratorPassword $dsrmPassword -InstallDNS -Confirm:$false
}