@echo off
set LOG=%~dp0det.log
del /f /q "%LOG%" 2>nul
(
echo select vdisk file="C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx"
echo detail vdisk
echo exit
) > "%~dp0dt.txt"
diskpart /s "%~dp0dt.txt" >> "%LOG%" 2>&1
