#!/usr/bin/env bash
# usage: ./check.sh <app-dir> <port>
set -e
cd "$(dirname "$0")/$1"
PORT=$2 node .output/server/index.mjs > run.log 2>&1 &
pid=$!; sleep 3
for r in none early late; do
  curl -s -i -m 10 localhost:$2/$r > /tmp/out-$r.txt
  printf "%-6s set-cookie=%s payload-sent=%s\n" "/$r" \
    "$(grep -ci '^set-cookie' /tmp/out-$r.txt)" "$(grep -c __NUXT_DATA__ /tmp/out-$r.txt)"
done
kill $pid
grep -E "NUXT_E8009|ERR_HTTP_HEADERS_SENT" run.log | sort -u || true
