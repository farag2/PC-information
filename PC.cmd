@echo off
chcp 65001
del "%computername%_%username%.txt" /f /q
whoami > "%computername%_%username%.txt"
echo. >> "%computername%_%username%.txt"
WMIC /APPEND:"%computername%_%username%.txt" OS get Caption,OSArchitecture,Version /Format:table
WMIC /APPEND:"%computername%_%username%.txt" BIOS Get Manufacturer,Name /Format:table
WMIC /APPEND:"%computername%_%username%.txt" Baseboard Get Product,Manufacturer /Format:table
WMIC /APPEND:"%computername%_%username%.txt" CPU Get Name,NumberOfCores,NumberOfLogicalProcessors /Format:table
WMIC /APPEND:"%computername%_%username%.txt" Memorychip Get Manufacturer,Capacity,Speed,PartNumber /Format:table
WMIC /APPEND:"%computername%_%username%.txt" Diskdrive Get Model,Size /Format:table
WMIC /APPEND:"%computername%_%username%.txt" Path Win32_VideoController get Caption,VideoModeDescription /Format:table
WMIC /APPEND:"%computername%_%username%.txt" netuse get Name /Format:table
pause
