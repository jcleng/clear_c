@echo off
set LOG=%~dp0cleanup-vhd.log
del /f /q "%LOG%" 2>nul
echo === kill stuck diskpart === >> "%LOG%"
taskkill /F /IM diskpart.exe >> "%LOG%" 2>&1
timeout /t 2 /nobreak >nul
echo === list vdisks === >> "%LOG%"
(
echo list vdisk
echo exit
) > "%~dp0lv.txt"
diskpart /s "%~dp0lv.txt" >> "%LOG%" 2>&1
echo === detach by selecting file === >> "%LOG%"
(
echo select vdisk file="C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx"
echo detach vdisk noerr
echo exit
) > "%~dp0dv.txt"
diskpart /s "%~dp0dv.txt" >> "%LOG%" 2>&1
echo === get-disk === >> "%LOG%"
powershell -NoProfile -Command "Get-Disk | Select-Object Number,FriendlyName,OperationalStatus | Format-Table -AutoSize | Out-String" >> "%LOG%" 2>&1
