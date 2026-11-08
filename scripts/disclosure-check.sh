#!/usr/bin/env bash
# Disclosure gate for this public repository.
#
# Fails (exit 1) when any file in the tree contains something that must never
# be published here: internal issue numbers, UUIDs (other than the public OAuth
# client IDs recorded in CLIENT_IDS.md), schema vocabulary, internal paths,
# email addresses, real-looking dollar figures, environment variable names, or
# any word on the private word list.
#
# The private word list (names and terms that must never appear) is NOT in this
# repository: a list of names in a public repo, even hashed, confirms them. It
# is a plain-text file, one word or phrase per line, read from --private-list
# or, by default, ~/.config/fundry-cfo/private-words.txt. In CI it comes from a
# repository secret. Without it the name check is skipped with a notice, and
# --release refuses to pass.
#
# Output names the rule and file:line only, never the matched text, because CI
# logs of a public repository are public too.
#
# Usage:
#   scripts/disclosure-check.sh [--root DIR] [--release]
#     --root DIR   scan DIR instead of the repository root
#     --private-list FILE   private word list (default above)
#     --release    also fail on unfilled client-ID placeholders and on git
#                  history (author/committer emails, commit messages); run
#                  before the repository is made public
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
release=0
private_list="${HOME}/.config/fundry-cfo/private-words.txt"
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="$(cd "$2" && pwd)"; shift 2 ;;
    --release) release=1; shift ;;
    --private-list) private_list="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

PRIVATE_LIST="$private_list" RELEASE="$release" \
exec perl -e '
use strict; use warnings;
use File::Find;

my ($root) = @ARGV;
my $release = $ENV{RELEASE};

my @private;
my $have_private = 0;
if (open(my $ph, "<", $ENV{PRIVATE_LIST})) {
  $have_private = 1;
  while (<$ph>) { s/#.*//; s/^\s+|\s+$//g; push @private, qr/\b\Q$_\E\b/i if length; }
  close $ph;
}

# Public OAuth client IDs are allowed: the Client ID column of CLIENT_IDS.md.
my %allowed_uuid;
if (open(my $ch, "<", "$root/CLIENT_IDS.md")) {
  while (<$ch>) {
    next unless /^\|/;
    my @c = split /\|/;
    my $v = $c[3] // ""; $v =~ s/[\s`]//g;
    $allowed_uuid{lc $v} = 1 if $v =~ /^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/i;
  }
  close $ch;
}

my $uuid = qr/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i;
my @rules = (
  [ "issue-number",   qr/\bISSUE-\d+/i ],
  [ "sql-file",       qr/\.sql\b/i ],
  [ "source-path",    qr/(?:^|[^A-Za-z0-9_.-])src\//i ],
  [ "schema-word",    qr/\bmigrations?\b/i ],
  [ "schema-word",    qr/\bRLS\b/i ],
  [ "schema-word",    qr/\bpolic(?:y|ies)\b/i ],
  [ "threshold-word", qr/toleranc/i ],
  [ "internal-doc",   qr/handoff\//i ],
  [ "dollar-figure",  qr/\$[0-9]{1,3}(?:,[0-9]{3})+/ ],
  [ "env-var",        qr/\b[A-Z][A-Z0-9]+_[A-Z0-9_]*(?:URL|KEY|SECRET|TOKEN|ID|ROLE|REF|DSN|PASSWORD)\b/ ],
);
my $email = qr/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/;

my $fail = 0;
sub report { my ($rule, $where) = @_; print "FAIL $rule $where\n"; $fail = 1; }

sub scan_line {
  my ($line, $where) = @_;
  for my $r (@rules) { report($r->[0], $where) if $line =~ $r->[1]; }
  while ($line =~ /($uuid)/g) { report("uuid", $where) unless $allowed_uuid{lc $1}; }
  while ($line =~ /($email)/g) { my $e = $1; report("email", $where) unless $e =~ /noreply/i; }
  for my $p (@private) { if ($line =~ $p) { report("private-word", $where); last; } }
}

my @skip = ("scripts/disclosure-check.sh");
my @files;
find({ no_chdir => 1, wanted => sub {
  my $rel = $File::Find::name; $rel =~ s/^\Q$root\E\/?//;
  if (-d $_) {
    $File::Find::prune = 1 if $rel eq ".git" || $rel eq "tests/fixtures";
    return;
  }
  return if grep { $_ eq $rel } @skip;
  push @files, $rel;
}}, $root);

for my $rel (sort @files) {
  open(my $fh, "<", "$root/$rel") or do { report("unreadable", $rel); next };
  my $n = 0;
  while (my $line = <$fh>) {
    $n++;
    scan_line($line, "$rel:$n");
    if ($release && $rel ne "CLIENT_IDS.md" && $rel !~ m{^tests/} && $line =~ /\{\{[a-z_]+_client_id\}\}/) {
      report("unfilled-client-id", "$rel:$n");
    }
  }
  close $fh;
}

if ($release) {
  if (-d "$root/.git") {
    my @emails = `git -C "$root" log --format="%ae%n%ce"`;
    my %u; for my $e (@emails) { chomp $e; next if $u{$e}++;
      report("history-identity", "git log (author/committer email)") unless $e =~ /noreply/i; }
    my @shas = `git -C "$root" log --format=%H`;
    for my $sha (@shas) { chomp $sha;
      my $n = 0;
      for my $line (`git -C "$root" log -1 --format=%B $sha`) { $n++; scan_line($line, "commit " . substr($sha,0,9) . " message line $n"); }
    }
  } else { report("history-missing", "--release needs a git repository"); }
}

if (!$have_private) {
  if ($release) { report("private-list-missing", "release mode needs the private word list"); }
  else { print "notice: no private word list found; the private-name check was skipped\n"; }
}

if ($fail) { print "disclosure-check: FAILED\n"; exit 1; }
print "disclosure-check: passed (" . scalar(@files) . " files" . ($release ? ", release mode" : "") . ")\n";
exit 0;
' "$root"
