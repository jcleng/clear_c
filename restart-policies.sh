#!/bin/bash
echo "=== 容器重启策略 ==="
docker ps -a --format '{{.Names}}\t{{.State}}\t{{.Label "restart"}}' 2>/dev/null
echo
echo "=== inspect restart policy ==="
for n in $(docker ps --format '{{.Names}}'); do
  pol=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$n" 2>/dev/null)
  echo "$n = $pol"
done
