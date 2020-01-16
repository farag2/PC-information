#Requires -RunAsAdministrator

Clear-Host

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
