Clear-Host
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
Write-Output "`nOperating System"
$ProductName = @{
	Name = "Product Name"
	Expression = {$_.Caption}
}
$InstallDate = @{
	Name = "Install Date"
	Expression={$_.InstallDate.Tostring().Split("")[0]}
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
Write-Output "`nRegistered apps list"
(Get-Itemproperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName | Sort-Object
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
($Searcher.QueryHistory(0, $historyCount) | Where-Object -FilterScript {$_.Title -like "*KB*"} | Select-Object $KB, $Date -Unique | Format-Table | Out-String).Trim()
Write-Output "`nBIOS"
$Version = @{
	Name = "Version"
	Expression = {$_.Name}
}
(Get-CimInstance -ClassName CIM_BIOSElement | Select-Object -Property Manufacturer, $Version | Format-Table | Out-String).Trim()
Write-Output "`nMotherboard"
(Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -Property Manufacturer, Product | Format-Table | Out-String).Trim()
Write-Output "`nCPU"
$Cores = @{
	Name = "Cores"
	Expression = {$_.NumberOfCores}
}
$L3CacheSize = @{
	Name = "L3, MB"
	Expression = {$_.L3CacheSize / 1024}
}
$Threads = @{
	Name = "Threads"
	Expression = {$_.NumberOfLogicalProcessors}
}
(Get-CimInstance -ClassName CIM_Processor | Select-Object -Property Name, $Cores, $L3CacheSize, $Threads | Format-Table | Out-String).Trim()
Write-Output "`nRAM"
$Speed = @{
	Name = "Speed, MHz"
	Expression = {$_.Configuredclockspeed}
}
$Capacity = @{
	Name = "Capacity, GB"
	Expression = {$_.Capacity / 1GB}
}
(Get-CimInstance -ClassName CIM_PhysicalMemory | Select-Object -Property Manufacturer, PartNumber, $Speed, $Capacity | Format-Table | Out-String).Trim()
Write-Output "`nPhysical disks"
$Model = @{
	Name = "Model"
	Expression = {$_.FriendlyName}
}
$MediaType = @{
	Name = "Drive type"
	Expression = {$_.MediaType}
}
$Size = @{
	Name = "Size, GB"
	Expression = {[math]::round($_.Size / 1GB, 2)}
}
$BusType = @{
	Name = "Bus type"
	Expression = {$_.BusType}
}
(Get-PhysicalDisk | Select-Object -Property $Model, $MediaType, $BusType, $Size | Format-Table | Out-String).Trim()
Write-Output "`nLogical drives"
$Name = @{
	Name = "Name"
	Expression = {$_.DeviceID}
}
enum DriveType
{
	RemovableDrive	=	2
	HardDrive		=	3
}
$Type = @{
	Name = "Drive Type"
	Expression = {[System.Enum]::GetName([DriveType],$_.DriveType)}
}
$Size = @{
	Name = "Size, GB"
	Expression = {[math]::round($_.Size/1GB, 2)}
}
$FreeSpace = @{
	Name = "FreeSpace, GB"
	Expression = {[math]::round($_.FreeSpace/1GB, 2)}
}
(Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object -FilterScript {$_.DriveType -ne 4} | Select-Object -Property $Name, $Type, $Size, $FreeSpace | Format-Table | Out-String).Trim()
Write-Output "`nMapped disks"
(Get-SmbMapping | Select-Object -Property LocalPath, RemotePath | Format-Table | Out-String).Trim()
Write-Output "`nVideo сontrollers"
$Caption = @{
	Name = "Model"
	Expression = {$_.Caption}
}
$VRAM = @{
	Name = "VRAM, GB"
	Expression = {[math]::round($_.AdapterRAM/1GB)}
}
(Get-CimInstance -ClassName CIM_VideoController | Select-Object -Property $Caption, $VRAM | Format-Table | Out-String).Trim()
Write-Output "`nDefault IP gateway"
(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration).DefaultIPGateway
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
