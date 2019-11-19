#Requires -RunAsAdministrator

Clear-Host

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
(Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName | Sort-Object
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

#region BIOS
Write-Output "`nBIOS"
$Version = @{
	Name = "Version"
	Expression = {$_.Name}
}
(Get-CimInstance -ClassName CIM_BIOSElement | Select-Object -Property Manufacturer, $Version | Format-Table | Out-String).Trim()
#endregion BIOS

#region Motherboard
Write-Output "`nMotherboard"
(Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -Property Manufacturer, Product | Format-Table | Out-String).Trim()
#endregion Motherboard

#region CPU
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
#endregion CPU

#region RAM
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
#endregion RAM

#region Physical disks
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
	Expression = {[math]::round($_.Size/1GB, 2)}
}
$BusType = @{
	Name = "Bus type"
	Expression = {$_.BusType}
}
(Get-PhysicalDisk | Select-Object -Property $Model, $MediaType, $BusType, $Size | Format-Table | Out-String).Trim()
#endregion Physical disks

#region Logical drives
Write-Output "`nLogical drives"
$Name = @{
	Name = "Name"
	Expression = {$_.DeviceID}
}
enum DriveType
{
	RemovableDrive	=	2
	HardDrive	=	3
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
#endregion Logical drives

#region Mapped disks
Write-Output "`nMapped disks"
(Get-SmbMapping | Select-Object -Property LocalPath, RemotePath | Format-Table | Out-String).Trim()
#endregion Mapped disks

#region Video сontrollers
# Integrated graphics
IF ((Get-CimInstance -ClassName CIM_VideoController | Where-Object -FilterScript {$_.AdapterDACType -eq "Internal"}))
{
	$Caption = @{
		Name = "Model"
		Expression = {$_.Caption}
	}
	$VRAM = @{
		Name = "VRAM, GB"
		Expression = {[math]::round($_.AdapterRAM/1GB)}
	}
	Get-CimInstance -ClassName CIM_VideoController | Where-Object -FilterScript {$_.AdapterDACType -eq "Internal"} | Select-Object -Property $Caption, $VRAM
}
# Dedicated graphics
IF ((Get-CimInstance -ClassName CIM_VideoController | Where-Object -FilterScript {$_.AdapterDACType -ne "Internal"}))
{
	$qwMemorySize = (Get-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*" -Name HardwareInformation.qwMemorySize -ErrorAction SilentlyContinue)."HardwareInformation.qwMemorySize"
	$VRAM = [math]::round($qwMemorySize/1GB)
	Get-CimInstance -ClassName CIM_VideoController | Where-Object -FilterScript {$_.AdapterDACType -ne "Internal"} | ForEach-Object -Process {
		[PSCustomObject] @{
			Model = $_.Caption
			"VRAM, GB" = $VRAM
		}
	}
}
#endregion Video сontrollers

#region Default IP gateway
Write-Output "`nDefault IP gateway"
(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration).DefaultIPGateway
#endregion Default IP gateway

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
