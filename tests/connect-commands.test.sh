#!/usr/bin/env bash
# connect-commands.json is what Fundry's Settings page shows people to copy
# (Fundry vendors a copy of it). Every value in it must appear verbatim in
# README.md, and the server URL must be the one .mcp.json connects to, so the
# page, the README and the plugin cannot drift apart.
#
# The second half proves the check can fail: it runs the same check against a
# copy of the README with one value changed and expects a failure.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
json="$root/connect-commands.json"
command -v jq >/dev/null || { echo "BAD  jq is required"; exit 1; }
jq -e . "$json" >/dev/null || { echo "BAD  connect-commands.json is not valid JSON"; exit 1; }

check() { # $1 = README path; prints misses, returns non-zero on any miss
  local readme="$1" miss=0 v
  while IFS= read -r v; do
    if ! grep -qF -- "$v" "$readme"; then
      echo "MISS $v"; miss=1
    fi
  done < <(jq -r '.. | strings' "$json")
  return "$miss"
}

fail=0
n="$(jq -r '[.. | strings] | length' "$json")"
[ "$n" -ge 7 ] || { echo "BAD  expected at least 7 values, found $n"; fail=1; }
if check "$root/README.md"; then
  echo "ok   README.md carries all $n values"
else
  echo "BAD  README.md is missing values from connect-commands.json"; fail=1
fi

url="$(jq -r .server_url "$json")"
if jq -e --arg u "$url" '[.. | strings] | index($u)' "$root/.mcp.json" >/dev/null; then
  echo "ok   .mcp.json connects to $url"
else
  echo "BAD  .mcp.json does not connect to $url"; fail=1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sed 's/codex mcp login fundry/codex mcp login fundri/' "$root/README.md" > "$tmp/README.md"
if check "$tmp/README.md" >/dev/null; then
  echo "BAD  the check passed on a README with a changed command"; fail=1
else
  echo "ok   the check fails on a README with a changed command"
fi

exit "$fail"
