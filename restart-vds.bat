@echo off
set LOG=%~dp0vds-restart.log
del /f /q "%LOG%" 2>nul
echo === stop vds === >> "%LOG%"
net stop vds >> "%LOG%" 2>&1
timeout /t 3 /nobreak >nul
echo === start vds === >> "%LOG%"
net start vds >> "%LOG%" 2>&1
timeout /t 3 /nobreak >nul
echo === list vdisk === >> "%LOG%"
(
echo list vdisk
echo exit
) > "%~dp0lv2.txt"
diskpart /s "%~dp0lv2.txt" >> "%LOG%" 2>&1
