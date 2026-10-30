# C 盘空间清理脚本集（WSL2 / Docker）

2026-10-30 会话产物。目标是解决 **C 盘 162.63 GB 总量、仅剩 0.5 GB 可用**的紧急状况。

**结果：C 盘可用 0.5 GB → 27.46 GB，D 盘可用 67.28 GB → 86.15 GB，19 个运行中容器全部保留并恢复。**

---

## 一、背景与根因

C 盘占用分布中，单个文件 `%LOCALAPPDATA%\wsl\{ae08dae0-e82f-4489-b2e8-3af53ce51ad3}\ext4.vhdx`
占了 **104.67 GB**，而 WSL 内部实际只用了 **70 GB** —— 差了 34 GB。

原因是 WSL2 的虚拟磁盘（vhdx）**只增不减**：Linux 里删掉文件后，Windows 侧的 vhdx 不会自动缩小，
必须手动压缩才能把空间还给宿主。

WSL 内部的 70 GB 构成：

| 目录 | 占用 | 说明 |
|---|---|---|
| `/var/lib/containerd` | 35 GB | 镜像层快照 |
| `/var/lib/docker` | 35 GB | 数据卷 + 容器 |
| `/home` | 18 GB | 用户数据 |

其中 `/var/lib/docker/rootfs/overlayfs` 显示的 20 GB 是容器的 overlay **挂载点**，
其内容与 containerd 快照是同一份数据，`du` 会重复计算 —— 不是独立的 20 GB。

---

## 二、脚本清单

按执行顺序分组。**带 ⚠️ 的脚本会删除数据**，运行前请确认。

### 阶段 1：Docker 清理（在 WSL 内执行）

| 文件 | 作用 | 删除风险 |
|---|---|---|
| `clean-docker.sh` | 主清理：删 Dead 容器、已停止容器、悬空镜像、构建缓存、未使用网络 | ⚠️ 会删除已停止的容器 |
| `check-containerd.sh` | 只读诊断：`docker system df` 报错原因、快照目录大小 TOP20 | 无 |
| `check-dual.sh` | 只读诊断：确认 storage driver、`/var/lib/docker` 明细、是否有重复镜像 | 无 |
| `check-rootfs.sh` | 只读诊断：`rootfs/` 与 `volumes/` 明细、悬空卷列表 | 无 |
| `check-rootfs2.sh` | 只读诊断：确认 `rootfs/overlayfs` 是挂载点而非独立数据、逐个统计悬空卷大小 | 无 |
| `prune-volumes.sh` | 只删**匿名**悬空卷（64 位十六进制名），保留所有具名数据卷 | ⚠️ 删除匿名卷 |

**`prune-volumes.sh` 的关键设计**：用正则 `^[0-9a-f]{64}$` 区分匿名卷与具名卷，
只删前者。这样 `mywork_mysql_8`（6.7 GB 数据库）、`mywork_opencode_root` 等具名数据卷全部保留。

**在 WSL 内运行 .sh 脚本的方法**（PowerShell 里 `$(...)` 会被吞掉，所以统一走脚本文件）：

```powershell
$p = "C:\Users\jcleng\AppData\Roaming\Croli\chat-sessions\2026-10-30\03d7defacf224f0c808a1ad84da574b1\clean-docker.sh"
$unix = (wsl.exe -d Ubuntu-24.04 -u root --exec wslpath -a "$p" 2>&1).Trim()
wsl.exe -d Ubuntu-24.04 -u root --exec bash "$unix"
```

### 阶段 2：宿主缓存清理（在 Windows 上执行）

| 文件 | 作用 | 删除风险 |
|---|---|---|
| `clean-host-cache.ps1` | 清 npm 缓存、pip 缓存、用户 Temp、回收站，并报告释放量 | ⚠️ 清缓存（可重建） |

实测效果：npm 1694.5 MB → 7.2 MB，pip 162.6 MB → 0，回收站 32.3 MB → 0，共释放 1.84 GB。

**运行方式**（注意用 `powershell.exe` 而非 `pwsh`，本机没装 PowerShell 7）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\...\clean-host-cache.ps1"
```

安全措施：清 Temp 时用 `Where-Object { $_.Name -ne 'codeg-acp' }` 跳过了本会话自己的临时目录；
其他程序占用的文件因 `-ErrorAction SilentlyContinue` 自动跳过。**未触碰 Downloads 目录。**

### 阶段 3：容器状态记录（关 WSL 前必做）

| 文件 | 作用 |
|---|---|
| `restart-policies.sh` | 列出所有容器的 `RestartPolicy` |
| `record-containers.sh` | 导出 `restart=no` 的容器名单（关机后不会自动恢复）+ 全部容器与镜像对照 |
| `containers-backup.txt` | 上面脚本的输出存档 —— **UTF-16LE 编码**，`Get-Content` 可读，普通编辑器可能显示乱码 |

实测发现 19 个运行中容器里有 **6 个是 `restart=no`**，WSL 重启后不会自动拉起，必须手动恢复：

```
mywork-chrome-1  mywork-phptest-1  mywork-redis-1  mcphub  opencode  mywork-node18-1
```

其余 13 个是 `unless-stopped` / `always`，会自动恢复。

### 阶段 4：vhdx 压缩

这是**最能回收空间的一步**（25 GB），也是最麻烦的一步。踩了两个坑，所以留下了一堆中间文件。

| 文件 | 作用 | 结果 |
|---|---|---|
| `compact.txt` | 最简单的 diskpart 脚本：attach readonly → compact → detach | ❌ 失败，需管理员权限但没提权 |
| `run-compact.bat` | 提权包装器，把 diskpart 输出写进 `diskpart-result.log` | ❌ 失败（VDS 错误） |
| `detail-vhd.bat` | 提权查询 `detail vdisk`，输出到 `det.log` | ✅ 诊断出状态卡在「正在压缩」 |
| `reset-vhd.bat` | 尝试 detach/attach 复位后重试压缩 | ❌ 失败 |
| `cleanup-vhd.bat` | 提权 `taskkill` 卡住的 diskpart，再尝试 detach | ❌ 失败 |
| `restart-vds.bat` | **重启 Virtual Disk 服务**，把状态从「正在压缩」复位为「未打开已连接内容」 | ✅ 关键解锁 |
| `final-compact.bat` | **最终成功版**：detach → attach readonly → compact → detach，全部提权 | ✅ 释放 25 GB |

**中间产物**（`dt.txt` `det.log` `rs.txt` `rs2.txt` `reset.log` `lv.txt` `dv.txt` `cleanup-vhd.log`
`lv2.txt` `vds-restart.log` `cp.txt` `diskpart-result.log` `s1.txt`~`s4.txt` `final-compact.log`）：
都是上面这些 .bat 自动生成的 diskpart 命令脚本和日志，**可以安全删除**。

运行 `final-compact.bat` 的方式（会弹 UAC）：

```powershell
$bat = "C:\...\final-compact.bat"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c","`"$bat`"" -Verb RunAs -Wait -WindowStyle Hidden
Get-Content "C:\...\final-compact.log"
```

### 阶段 5：恢复

| 文件 | 作用 |
|---|---|
| `restore-containers.sh` | 启动那 6 个 `restart=no` 的容器（已在运行则跳过），并输出最终容器总数 |

---

## 三、踩过的坑

### 1. `wsl --manage --set-sparse true` 不可用

微软**全局禁用**了稀疏 VHD（提示"由于潜在的数据损坏，目前已禁用稀疏 VHD 支持"）。
`--allow-unsafe` 可以强制，但不建议。改用 `diskpart compact vdisk`。

### 2. diskpart 卡在「正在压缩」

第一次 compact 失败后，虚拟磁盘停留在「正在压缩」状态，此后 `detach` 和 `compact` 都报
"压缩虚拟磁盘时，无法执行请求的操作"。卡住的状态由 **VDS 服务**持有，`taskkill` 掉 diskpart 也没用。

解法：`net stop vds` + `net start vds`（需管理员）。重启后状态变为「未打开已连接内容」，
再走标准的 detach → attach readonly → compact → detach 流程即可成功。

### 3. WSL 关不掉，会自动重启

`wsl --shutdown` 后 8 秒内 WSL 又变成 Running。原因是 **VS Code 的 Remote-WSL** 有两个
`.vscode-server` 进程在守着（`wsl.exe -d Ubuntu-24.04 -e /home/jcleng/.vscode-server/...`）。

解法：`wsl --shutdown --force`，并先用 `wsl.exe --list --running` 确认已停，
再用 `[System.IO.File]::Open($vhd,'Open','ReadWrite','None')` 验证文件确实没被占用，才能开始压缩。

### 4. 沙箱临时目录被挤掉

C 盘剩 0.5 GB 时，harness 的 workspace-write 沙箱启动失败：
`Runner failure: windows-acl-run: --temp is not an existing directory: ...\dsh-8cKONA`。
需要 `danger-full-access` 才能继续排查。所以本次会话后半程都跑在 full-access 下。

### 5. PowerShell 吞掉 `$(...)`

在 `wsl bash -c "..."` 里写 `$(...)` 会被 PowerShell 先求值。凡是含循环/命令替换的
逻辑，一律写成 `.sh` 文件再通过 `wslpath` 传路径执行。

---

## 四、数据安全边界

**删除的：**
- 12 个 `Dead` 状态僵尸容器
- 3 个已停止容器（`verify-swoole`、`mywork-chrome_tinyfilemanager-1`、`codeserver`）
- 悬空镜像、构建缓存、13 个匿名悬空卷
- 卡在 `Installing` 状态的 `ext4` 发行版（`D:\linux\ext4`，18.88 GB）
- npm / pip 缓存、回收站

**保留的：**
- 全部 19 个运行中容器及其镜像
- 全部具名数据卷，包括 `mywork_mysql_8`（6.7 GB）、`mywork_opencode_root`（2.3 GB）、
  `mywork_mysql_data_tucao2`（946 MB）、`workbuddy2api_mysql_8`（608 MB）等
- 32 个镜像全部保留
- `Downloads` 目录、用户文档

---

## 五、后续建议

### 1. 限制 vhdx 上限

`detail vdisk` 显示虚拟大小是 **1024 GB** —— 意味着它能一路涨到把 C 盘吃光再次触发本次事故。
建议压到 300 GB：

```powershell
wsl --shutdown
wsl --manage Ubuntu-24.04 --resize 300GB
```

只能缩小到当前已用容量之上，且必须关 WSL。

### 2. 定期压缩

删除 WSL 内大量文件后，手动执行 `final-compact.bat` 即可回收。完整流程：

```powershell
wsl --shutdown --force
# 确认无 vmmemWSL 进程、vhdx 未被占用
Start-Process cmd.exe -ArgumentList "/c","`"C:\...\final-compact.bat`"" -Verb RunAs -Wait
```

### 3. 给 `restart=no` 的容器改策略

那 6 个容器每次重启 WSL 都要手动拉起，建议改成 `unless-stopped`：

```bash
docker update --restart unless-stopped mywork-chrome-1 mywork-phptest-1 mywork-redis-1 mcphub opencode mywork-node18-1
```

### 4. containerd 快照损坏的隐患

`docker system df` 一直报错：

```
failed to calculate image disk usage: lstat .../snapshots/707/fs: no such file or directory
```

说明快照 707 的元数据残留但目录已丢失。目前被正在使用的层掩盖，不影响 `docker ps` / `docker start`。
如果将来 Docker 行为异常，可考虑重建：

```bash
docker system prune -af     # ⚠️ 删除所有未使用镜像，需重新拉取
```

### 5. `.wslconfig` 限制资源

`C:\Users\jcleng\.wslconfig`（目前不存在）：

```ini
[wsl2]
memory=16GB
swap=4GB
```

---

## 六、清理本目录

这些脚本是一次性运维产物。`README.md` 建议保留作为记录，其余可删。
如果想再来一次干净的清理流程，只需要保留：

`clean-docker.sh`、`clean-host-cache.ps1`、`record-containers.sh`、
`restore-containers.sh`、`final-compact.bat`

其余诊断脚本、中间 `.txt`/`.log`、各失败的 .bat 都可以删除。
