#!/bin/bash
echo "=== docker system df (重试) ==="
docker system df 2>&1
echo
echo "=== containerd 快照目录大小 TOP ==="
du -sh /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots 2>/dev/null
echo
echo "=== 快照目录数量 ==="
ls /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots 2>/dev/null | wc -l
echo
echo "=== 最大的 20 个快照 ==="
du -sh /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/*/ 2>/dev/null | sort -rh | head -20
echo
echo "=== containerd 各子目录 ==="
du -sh /var/lib/containerd/* 2>/dev/null | sort -rh | head
