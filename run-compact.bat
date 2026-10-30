@echo off
set LOG=%~dp0diskpart-result.log
del /f /q "%LOG%" 2>nul
(
echo select vdisk file="C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx"
echo attach vdisk readonly
echo compact vdisk
echo detach vdisk
echo exit
) > "%~dp0cp.txt"
diskpart /s "%~dp0cp.txt" >> "%LOG%" 2>&1
echo EXITCODE=%ERRORLEVEL% >> "%LOG%"
