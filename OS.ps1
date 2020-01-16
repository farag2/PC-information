#region User
Write-Output User
$PCName = @{
	Name = "Computer name"
	Expression = {$_.Name}
}
$Domain = @{
	Name = "Domain"
	Expression = {$_.Domain}
}
$UserName = @{
	Name = "User Name"
	Expression = {$_.UserName}
}
(Get-CimInstance –ClassName CIM_ComputerSystem | Select-Object -Property $PCName, $Domain, $UserName | Format-Table | Out-String).Trim()

Write-Output "`nLocal Users"
(Get-LocalUser | Out-String).Trim()

Write-Output "`nGroup Membership"
Get-ADPrincipalGroupMembership $env:USERNAME | Select-Object -Property Name
#endregion User

#region Operating System
Write-Output "`nOperating System"
$ProductName = @{
	Name = "Product Name"
	Expression = {$_.Caption}
}
$InstallDate = @{
	Name = "Install Date"
	Expression=  {$_.InstallDate.Tostring().Split("")[0]}
}
$Arch = @{
	Name = "Architecture"
	Expression = {$_.OSArchitecture}
}
$a = Get-CimInstance -ClassName CIM_OperatingSystem | Select-Object -Property $ProductName, $InstallDate, $Arch
$Build = @{
	Name = "Build"
	Expression = {"$($_.CurrentMajorVersionNumber).$($_.CurrentMinorVersionNumber).$($_.CurrentBuild).$($_.UBR)"}
}
$b = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows nt\CurrentVersion" | Select-Object -Property $Build
([PSCustomObject] @{
	"Product Name" = $a."Product Name"
	Build = $b.Build
	"Install Date" = $a."Install Date"
	Architecture = $a.Architecture
} | Out-String).Trim()
#endregion Operating System

#region Registered apps
Write-Output "`nRegistered apps"
(Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName | Sort-Object
#endregion Registered apps

#region Updates
Write-Output "`nInstalled updates supplied by CBS"
$HotFixID = @{
	Name = "KB ID"
	Expression = {$_.HotFixID}
}
$InstalledOn = @{
	Name = "Installed on"
	Expression = {$_.InstalledOn.Tostring().Split("")[0]}
}
(Get-HotFix | Select-Object -Property $HotFixID, $InstalledOn -Unique | Format-Table | Out-String).Trim()

Write-Output "`nInstalled updates supplied by MSI/WU"
$Session = New-Object -ComObject "Microsoft.Update.Session"
$Searcher = $Session.CreateUpdateSearcher()
$historyCount = $Searcher.GetTotalHistoryCount()
$KB = @{
	Name = "KB ID"
	Expression = {[regex]::Match($_.Title,"(KB[0-9]{6,7})").Value}
}
$Date = @{
	Name = "Installed on"
	Expression = {$_.Date.Tostring().Split("")[0]}
}
($Searcher.QueryHistory(0, $historyCount) | Where-Object -FilterScript {$_.Title -like "*KB*" -and $_.ResultCode -eq 2} | Select-Object $KB, $Date | Format-Table | Out-String).Trim()
#endregion Updates

#region Mapped disks
Write-Output "`nMapped disks"
(Get-SmbMapping | Select-Object -Property LocalPath, RemotePath | Format-Table | Out-String).Trim()
#endregion Mapped disks

#region Network
Write-Output "`nDefault IP gateway"
(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration).DefaultIPGateway
#endregion Network

#region Windows Defender threats
Write-Output "`nWindows Defender threats"
enum ThreatStatusID
{
	Unknown = 0
	Detected = 1
	Cleaned = 2
	Quarantined = 3
	Removed = 4
	Allowed = 5
	Blocked = 6
	QuarantineFailed = 102
	RemoveFailed = 103
	AllowFailed = 104
	Abondoned = 105
	BlockedFailed = 107
}
(Get-MpThreatDetection | ForEach-Object -Process {
	[PSCustomObject] @{
		"Detected Threats Paths" = $_.Resources
		"ThreatID" = $_.ThreatID
		"Status" = [System.Enum]::GetName([ThreatStatusID],$_.ThreatStatusID)
		"Detection Time" = $_.InitialDetectionTime
	}
} | Sort-Object ThreatID -Unique | Format-Table -AutoSize -Wrap | Out-String).Trim()
#endregion Windows Defender threats

#region Windows Defender settings
Write-Output "`nWindows Defender settings"
(Get-MpPreference | ForEach-Object -Process {
	[PSCustomObject] @{
		"Excluded IDs" = $_.ThreatIDDefaultAction_Ids | Out-String
		"Excluded Process" = $_.ExclusionProcess | Out-String
		"Controlled Folder Access" = $_.EnableControlledFolderAccess | Out-String
		"Controlled Folder Access Protected Folders" = $_.ControlledFolderAccessProtectedFolders | Out-String
		"Controlled Folder Access Allowed Applications" = $_.ControlledFolderAccessAllowedApplications | Out-String
		"Excluded Extensions" = $_.ExclusionExtension | Out-String
		"Excluded Paths" = $_.ExclusionPath | Out-String
	}
} | Format-List | Out-String).Trim()
#endregion Windows Defender settings
