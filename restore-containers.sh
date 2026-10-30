#!/bin/bash
for n in mywork-chrome-1 mywork-phptest-1 mywork-redis-1 mcphub opencode mywork-node18-1; do
  state=$(docker inspect -f '{{.State.Status}}' "$n" 2>/dev/null)
  if [ "$state" = "running" ]; then
    echo "  $n 已在运行"
  else
    if docker start "$n" >/dev/null 2>&1; then echo "  已启动 $n"; else echo "  启动失败 $n ($state)"; fi
  fi
done
echo
echo "=== 最终运行中容器 ==="
docker ps --format '{{.Names}}' | sort
echo "总数: $(docker ps -q | wc -l)"
