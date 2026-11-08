#!/usr/bin/env bash
# fill-client-ids.sh must fill the carrier files CLIENT_IDS.md names and touch
# nothing else: the disclosure gate's own tests keep the {{..._client_id}}
# tokens as fixtures, and filling them breaks the release-mode tests.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git -C "$root" archive HEAD | tar xf - -C "$tmp"
cp "$root/scripts/fill-client-ids.sh" "$tmp/scripts/fill-client-ids.sh"
# The committed carriers may already be filled; put the tokens back so the
# fill below starts from an unfilled tree whatever HEAD holds.
(cd "$tmp" && perl -e '
  my %map;
  open(my $fh, "<", "CLIENT_IDS.md") or die "CLIENT_IDS.md missing\n";
  while (<$fh>) {
    next unless /^\|/;
    my @c = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x =~ s/`//g; $x } split /\|/;
    my ($token, $id) = ($c[2] // "", $c[3] // "");
    next unless $token =~ /^\{\{[a-z_]+_client_id\}\}$/;
    next if $id eq "" || $id =~ /not registered/i;
    $map{$id} = $token;
  }
  for my $f (".mcp.json", "README.md", "AGENTS.md") {
    open(my $in, "<", $f) or next; local $/; my $s = <$in>; close $in;
    for my $id (keys %map) { my $q = quotemeta $id; $s =~ s/$q/$map{$id}/g; }
    open(my $out, ">", $f) or die; print $out $s; close $out;
  }
')
grep -q '{{codex_client_id}}' "$tmp/README.md" || { echo "BAD  setup: README.md has no codex token to fill"; exit 1; }
git -C "$tmp" init -q -b main
git -C "$tmp" -c user.name=t -c user.email=t@users.noreply.example add -A
git -C "$tmp" -c user.name=t -c user.email=t@users.noreply.example commit -qm base
z=00000000; fake="$z-0000-4000-8000-${z}0000"
perl -pi -e "s/^(\\| Codex \\| \`\\{\\{codex_client_id\\}\\}\` \\| )[^|]*\\|/\${1}\`$fake\` |/" "$tmp/CLIENT_IDS.md"
bash "$tmp/scripts/fill-client-ids.sh" >/dev/null
bad=0
changed="$(git -C "$tmp" diff --name-only | sort | tr '\n' ' ')"
for f in $changed; do
  case "$f" in .mcp.json|README.md|AGENTS.md|CLIENT_IDS.md) ;; *) echo "BAD  filled a non-carrier file: $f"; bad=1 ;; esac
done
if grep -q "$fake" "$tmp/README.md"; then echo "ok   README.md filled"; else echo "BAD  README.md not filled"; bad=1; fi
if grep -q '{{codex_client_id}}' "$tmp/tests/disclosure-check.test.sh"; then echo "ok   test fixtures keep their tokens"; else echo "BAD  test fixtures were filled"; bad=1; fi
[ $bad -eq 0 ] && echo "fill-client-ids tests: OK" || { echo "fill-client-ids tests: FAILED"; exit 1; }
