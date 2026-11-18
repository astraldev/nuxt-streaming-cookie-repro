#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/$1"
PORT=$2 node .output/server/index.mjs > run.log 2>&1 &
pid=$!; sleep 3
for r in none plugin plugin-slow early late; do
  curl -s -i -m 10 localhost:$2/$r > "run-$r.out"
  printf "%-12s set-cookie=%s payload-sent=%s\n" "/$r" \
    "$(grep -ci '^set-cookie' run-$r.out)" "$(grep -c __NUXT_DATA__ run-$r.out)"
done
kill $pid
grep -E "NUXT_E8009|ERR_HTTP_HEADERS_SENT" run.log | sort -u
exit 0
