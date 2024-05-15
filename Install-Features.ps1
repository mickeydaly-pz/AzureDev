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
Restart-NetAdapter -Name "Ethernet"


.\Install-AD.ps1 -dsrmPassword $dsrmPassword -localPassword $localPassword -domainName $domainName -backupDC $backupDC -username $username