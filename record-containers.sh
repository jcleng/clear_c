#!/bin/bash
# 记录 restart=no 的容器，供重启后手动拉起
echo "=== 需手动重启的容器 (restart=no) ==="
for n in $(docker ps --format '{{.Names}}'); do
  pol=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$n" 2>/dev/null)
  if [ "$pol" = "no" ]; then echo "$n"; fi
done
echo
echo "=== 全部运行中容器 (完整保留记录) ==="
docker ps --format '{{.Names}}|{{.Image}}' 2>/dev/null
