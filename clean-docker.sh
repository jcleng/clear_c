#!/bin/bash
echo "=== 1. 删除 Dead 容器 ==="
for id in $(docker ps -a --filter status=dead -q); do
  if docker rm -f "$id" >/dev/null 2>&1; then echo "  已删除 $id"; fi
done
echo
echo "=== 2. 删除已停止容器 ==="
docker container prune -f 2>&1 | tail -2
echo
echo "=== 3. 清理悬空镜像 ==="
docker image prune -f 2>&1 | tail -2
echo
echo "=== 4. 清理构建缓存 ==="
docker builder prune -af 2>&1 | tail -2
echo
echo "=== 5. 清理未使用网络 ==="
docker network prune -f 2>&1 | tail -1
echo
echo "=== 清理后占用 ==="
du -sh /var/lib/docker /var/lib/containerd 2>/dev/null
echo
echo "=== 运行中容器 ==="
docker ps --format '{{.Names}}' | wc -l
