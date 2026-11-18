#!/usr/bin/env bash
# usage: ./run.sh <path to a nuxt/nuxt checkout> [port]
set -u

here="$(cd "$(dirname "$0")" && pwd)"
nuxt="${1:?pass the path to a nuxt/nuxt checkout}"
port="${2:-3102}"
pg="${nuxt:?}/playground"
log="$(mktemp)"

for dir in pages components plugins; do
  if [ -e "${pg:?}/app/${dir:?}" ]; then
    echo "playground/app/$dir already exists, stopping so nothing is overwritten" >&2
    exit 1
  fi
done

restore() {
  lsof -ti ":$port" | xargs kill 2>/dev/null
  rm -r "${pg:?}/app/pages" "${pg:?}/app/components" "${pg:?}/app/plugins" 2>/dev/null
  git -C "$nuxt" checkout -- playground/app/app.vue playground/nuxt.config.ts
}
trap restore EXIT

cp -R "$here/app/." "$pg/app/"
cp "$here/nuxt.config.ts" "$pg/nuxt.config.ts"

(cd "$nuxt" && pnpm play --port "$port" > "$log" 2>&1 &)
for _ in $(seq 1 60); do
  sleep 3
  grep -qE "Local:|ERROR" "$log" && break
done
sleep 4

for route in none plugin early late; do
  out="$(curl -s -i -m 90 -H 'User-Agent: Mozilla/5.0' "localhost:$port/$route")"
  printf "/%-7s status=%s set-cookie=%s payload-sent=%s\n" "$route" \
    "$(printf '%s' "$out" | head -1 | cut -d' ' -f2)" \
    "$(printf '%s' "$out" | grep -ci '^set-cookie')" \
    "$(printf '%s' "$out" | grep -c __NUXT_DATA__)"
done

sleep 3
echo
sed -E 's/\x1b\[[0-9;]*m//g' "$log" | grep -E "NUXT_E7012|NUXT_E8002|NUXT_E8009|^╰▶ fix: Set the cookie"
exit 0
