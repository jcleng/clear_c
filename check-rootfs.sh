#!/bin/bash
echo "=== /var/lib/docker/rootfs 明细 ==="
du -sh /var/lib/docker/rootfs/* 2>/dev/null | sort -rh | head -15
echo "  条目数: $(ls /var/lib/docker/rootfs 2>/dev/null | wc -l)"
echo
echo "=== /var/lib/docker/volumes 明细 ==="
du -sh /var/lib/docker/volumes/* 2>/dev/null | sort -rh | head -15
echo
echo "=== 卷列表 ==="
docker volume ls 2>&1 | head -20
echo
echo "=== 未使用卷 ==="
docker volume ls -f dangling=true 2>&1 | head -20
