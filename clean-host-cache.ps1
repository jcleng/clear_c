$ErrorActionPreference = 'SilentlyContinue'
$before = (New-Object System.IO.DriveInfo 'C').AvailableFreeSpace

function Get-DirMB($p) {
  if (-not (Test-Path -LiteralPath $p)) { return 0 }
  $s = (Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  return [math]::Round($s/1MB, 1)
}

Write-Output "=== npm 缓存 ==="
$n = Get-DirMB "$env:LOCALAPPDATA\npm-cache"
npm.cmd cache clean --force 2>&1 | Select-Object -Last 3
Write-Output ("  {0} MB -> {1} MB" -f $n, (Get-DirMB "$env:LOCALAPPDATA\npm-cache"))

Write-Output "=== pip 缓存 ==="
$p = Get-DirMB "$env:LOCALAPPDATA\pip\Cache"
if (Test-Path -LiteralPath "$env:LOCALAPPDATA\pip\Cache") {
  Remove-Item -LiteralPath "$env:LOCALAPPDATA\pip\Cache" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output ("  {0} MB -> {1} MB" -f $p, (Get-DirMB "$env:LOCALAPPDATA\pip\Cache"))

Write-Output "=== 用户 Temp（跳过占用中的文件）==="
$t = Get-DirMB "$env:LOCALAPPDATA\Temp"
Get-ChildItem -LiteralPath "$env:LOCALAPPDATA\Temp" -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne 'codeg-acp' } |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Output ("  {0} MB -> {1} MB" -f $t, (Get-DirMB "$env:LOCALAPPDATA\Temp"))

Write-Output "=== 回收站 ==="
$r = Get-DirMB "C:\`$Recycle.Bin"
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Output ("  {0} MB -> {1} MB" -f $r, (Get-DirMB "C:\`$Recycle.Bin"))

Write-Output ""
$after = (New-Object System.IO.DriveInfo 'C').AvailableFreeSpace
Write-Output ("可用空间: {0:N2} GB -> {1:N2} GB  (释放 {2:N2} GB)" -f ($before/1GB), ($after/1GB), (($after-$before)/1GB))
