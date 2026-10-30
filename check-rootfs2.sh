#!/bin/bash
echo "=== rootfs/overlayfs 内容 ==="
ls /var/lib/docker/rootfs/overlayfs 2>/dev/null | head -5
echo "条目数: $(ls /var/lib/docker/rootfs/overlayfs 2>/dev/null | wc -l)"
echo
echo "=== 是否是挂载点 ==="
mount | grep 'docker/rootfs' | head -5
echo
echo "=== 悬空卷大小 ==="
total=0
for v in $(docker volume ls -f dangling=true -q); do
  sz=$(du -sm "/var/lib/docker/volumes/$v/_data" 2>/dev/null | cut -f1)
  sz=${sz:-0}
  total=$((total+sz))
  echo "  ${sz}MB  $v"
done
echo "悬空卷合计: ${total}MB"
echo
echo "=== 未使用卷(含具名)总大小 ==="
docker volume prune -a --dry-run 2>/dev/null || echo "(无 dry-run 支持)"
