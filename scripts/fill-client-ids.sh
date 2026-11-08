#!/usr/bin/env bash
# Replace each {{..._client_id}} token with the ID recorded for it in
# CLIENT_IDS.md, in the carrier files that CLIENT_IDS.md names and no others
# (the disclosure gate's tests keep the tokens as fixtures). Rows still marked
# "not registered yet" are left alone.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
perl -e '
  my %map;
  open(my $fh, "<", "CLIENT_IDS.md") or die "CLIENT_IDS.md missing\n";
  while (<$fh>) {
    next unless /^\|/;
    my @c = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x =~ s/`//g; $x } split /\|/;
    my ($token, $id) = ($c[2] // "", $c[3] // "");
    next unless $token =~ /^\{\{[a-z_]+_client_id\}\}$/;
    next if $id eq "" || $id =~ /not registered/i;
    die "client ID for $token has unexpected characters\n" unless $id =~ /^[A-Za-z0-9._-]+$/;
    $map{$token} = $id;
  }
  close $fh;
  my @files = (".mcp.json", "README.md", "AGENTS.md");
  for my $f (@files) {
    open(my $in, "<", $f) or next; local $/; my $s = <$in>; close $in;
    my $orig = $s;
    for my $t (keys %map) { my $q = quotemeta $t; $s =~ s/$q/$map{$t}/g; }
    next if $s eq $orig;
    open(my $out, ">", $f) or die "cannot write $f\n"; print $out $s; close $out;
    print "filled $f\n";
  }
  print "no rows have an ID yet\n" unless %map;
'
