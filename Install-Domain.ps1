
param(
    [securestring]$dsrmPassword,
    [securestring]$localPassword,
    [string]$domainName,
    [string]$username,
    [boolean]$dnsExists
)

Start-Transcript -Path "C:\transcripts\transcript0.txt" -NoClobber

Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PassThru | New-Partition -DriveLetter E -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'data' -Confirm:$false
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

Restart-NetAdapter -Name "Ethernet"

Start-Sleep -Seconds 60

ping "ad.pgzr.io"

if ($dnsExists) {
    Install-ADDSDomainController -Credential (New-Object System.Management.Automation.PSCredential $username, $localPassword) -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -DomainName $domainName -InstallDNS -SafeModeAdministratorPassword $dsrmPassword -Confirm:$false
} else {
    Install-ADDSForest -DomainName $domainName -DatabasePath 'E:\NTDS' -LogPath 'E:\Logs' -SysvolPath 'E:\SYSVOL' -SafeModeAdministratorPassword $dsrmPassword -InstallDNS -Confirm:$false
}

