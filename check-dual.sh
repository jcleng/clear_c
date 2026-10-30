#!/bin/bash
echo "=== docker info 存储驱动 ==="
docker info 2>/dev/null | grep -iE 'storage driver|docker root|containerd|snapshotter|backing'
echo
echo "=== /var/lib/docker 明细 ==="
du -sh /var/lib/docker/* 2>/dev/null | sort -rh | head -12
echo
echo "=== overlay2 层数量 ==="
ls /var/lib/docker/overlay2 2>/dev/null | wc -l
echo
echo "=== 镜像实际总大小 ==="
docker images --format '{{.Size}}' | sort -h | tail -1
echo "镜像数量: $(docker images -q | wc -l)"
echo
echo "=== 是否有重复镜像ID ==="
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | sort -k2 | head -40
