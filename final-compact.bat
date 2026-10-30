@echo off
set VHD=C:\Users\jcleng\AppData\Local\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx
set LOG=%~dp0final-compact.log
del /f /q "%LOG%" 2>nul

echo === STEP1 detach === >> "%LOG%"
(
echo select vdisk file="%VHD%"
echo detach vdisk noerr
echo exit
) > "%~dp0s1.txt"
diskpart /s "%~dp0s1.txt" >> "%LOG%" 2>&1

echo === STEP2 attach readonly === >> "%LOG%"
(
echo select vdisk file="%VHD%"
echo attach vdisk readonly
echo exit
) > "%~dp0s2.txt"
diskpart /s "%~dp0s2.txt" >> "%LOG%" 2>&1

echo === STEP3 compact === >> "%LOG%"
(
echo select vdisk file="%VHD%"
echo compact vdisk
echo exit
) > "%~dp0s3.txt"
diskpart /s "%~dp0s3.txt" >> "%LOG%" 2>&1

echo === STEP4 detach === >> "%LOG%"
(
echo select vdisk file="%VHD%"
echo detach vdisk noerr
echo exit
) > "%~dp0s4.txt"
diskpart /s "%~dp0s4.txt" >> "%LOG%" 2>&1

echo === DONE === >> "%LOG%"
dir "%VHD%" >> "%LOG%" 2>&1
