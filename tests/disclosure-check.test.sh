#!/usr/bin/env bash
# Proves the disclosure gate can fail: every seeded fixture must FAIL with its
# own rule name, a word on the private list must FAIL, the clean fixture and
# the real tree must PASS, and release mode must fail on an unfilled client-ID
# placeholder or a missing private list while allowing a client ID that
# CLIENT_IDS.md records.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gate="$here/../scripts/disclosure-check.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
bad=0

# A private list holding only a canary, so the test needs no real names.
canary_list="$tmp/private-words.txt"
printf 'zzcanaryname\n' > "$canary_list"

for f in "$here"/fixtures/violating/*.txt; do
  rule="$(basename "$f" .txt)"
  d="$tmp/$rule"; mkdir -p "$d"; cp "$f" "$d/"
  out="$(bash "$gate" --root "$d" --private-list "$canary_list")"; rc=$?
  if [ $rc -eq 1 ] && printf '%s\n' "$out" | grep -q "^FAIL $rule "; then
    echo "ok   fixture $rule fails"
  else
    echo "BAD  fixture $rule did not fail with rule $rule (exit $rc)"; bad=1
  fi
done

d="$tmp/private"; mkdir -p "$d"
printf 'Prepared for ZZCanaryName Capital.\n' > "$d/note.md"
out="$(bash "$gate" --root "$d" --private-list "$canary_list")"; rc=$?
if [ $rc -eq 1 ] && printf '%s\n' "$out" | grep -q "^FAIL private-word "; then
  echo "ok   a private-list word fails"
else echo "BAD  a private-list word did not fail (exit $rc)"; bad=1; fi

d="$tmp/clean"; mkdir -p "$d"; cp "$here"/fixtures/clean/* "$d/"
if bash "$gate" --root "$d" --private-list "$canary_list" >/dev/null; then echo "ok   clean fixture passes"; else echo "BAD  clean fixture failed"; bad=1; fi

if bash "$gate" >/dev/null; then echo "ok   repository tree passes"; else echo "BAD  repository tree fails"; bash "$gate"; bad=1; fi

# Release mode. The test UUID is assembled so this file holds no literal UUID.
z=00000000; fake_id="$z-0000-4000-8000-${z}0000"
d="$tmp/release"; mkdir -p "$d"
printf '{"clientId": "{{codex_client_id}}"}\n' > "$d/config.json"
git -C "$d" init -q -b main
git -C "$d" -c user.name=t -c user.email=t@users.noreply.example add -A
git -C "$d" -c user.name=t -c user.email=t@users.noreply.example commit -qm "fixture"
out="$(bash "$gate" --root "$d" --release --private-list "$canary_list")"; rc=$?
if [ $rc -eq 1 ] && printf '%s\n' "$out" | grep -q "^FAIL unfilled-client-id "; then
  echo "ok   release mode fails on an unfilled placeholder"
else echo "BAD  release mode did not fail on an unfilled placeholder"; bad=1; fi

printf '| Surface | Token | Client ID | Redirect URI |\n|---|---|---|---|\n| Codex | `{{codex_client_id}}` | `%s` | x |\n' "$fake_id" > "$d/CLIENT_IDS.md"
printf '{"clientId": "%s"}\n' "$fake_id" > "$d/config.json"
git -C "$d" -c user.name=t -c user.email=t@users.noreply.example add -A
git -C "$d" -c user.name=t -c user.email=t@users.noreply.example commit -qm "fill"
if bash "$gate" --root "$d" --release --private-list "$canary_list" >/dev/null; then echo "ok   release mode allows a recorded client ID"
else echo "BAD  release mode rejected a recorded client ID"; bash "$gate" --root "$d" --release --private-list "$canary_list"; bad=1; fi

out="$(bash "$gate" --root "$d" --release --private-list "$tmp/does-not-exist")"; rc=$?
if [ $rc -eq 1 ] && printf '%s\n' "$out" | grep -q "^FAIL private-list-missing "; then
  echo "ok   release mode fails without the private list"
else echo "BAD  release mode passed without the private list"; bad=1; fi

[ $bad -eq 0 ] && echo "disclosure-check tests: passed" || echo "disclosure-check tests: FAILED"
exit $bad
