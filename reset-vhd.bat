@echo off
set LOG=%~dp0reset.log
del /f /q "%LOG%" 2>nul
(
echo select vdisk file="C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx"
echo detach vdisk
echo select vdisk file="C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx"
echo attach vdisk readonly
echo detail vdisk
echo detach vdisk
echo exit
) > "%~dp0rs.txt"
diskpart /s "%~dp0rs.txt" >> "%LOG%" 2>&1
echo ---- SECOND PASS ----
(
echo select vdisk file="C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx"
echo compact vdisk
echo exit
) >> "%~dp0rs2.txt" 2>&1
diskpart /s "%~dp0rs2.txt" >> "%LOG%" 2>&1
echo EXITCODE=%ERRORLEVEL% >> "%LOG%"
