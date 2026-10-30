#!/bin/bash
echo "=== 删除匿名悬空卷（仅 64 位十六进制名，不含具名数据卷）==="
for v in $(docker volume ls -f dangling=true -q); do
  if [[ "$v" =~ ^[0-9a-f]{64}$ ]]; then
    docker volume rm "$v" >/dev/null 2>&1 && echo "  已删除 $v"
  fi
done
echo
echo "=== 保留的具名卷（数据卷，未删除）==="
docker volume ls -f dangling=true -q | grep -v -E '^[0-9a-f]{64}$' | head -30
echo
echo "=== 清理后 ==="
du -sh /var/lib/docker /var/lib/containerd 2>/dev/null
df -h / | tail -1
