# Changelog

## 0.1.2

- Personal Claude plans (Pro or Max) are covered when each person who
  connects has turned off "Help improve Claude". The README's "Before you
  connect" and Claude sections say so; personal plans from other providers,
  including personal ChatGPT plans used with Codex, are still not covered.
- `manco-variance-brief`: when a period has no approved P&L but exactly one
  draft, Fundry now returns its figures with `actuals_final: false`. The
  skill labels the heading, every table and the close as draft, quotes
  `provenance.actuals`, and never calls the figures final.
  `statement_not_final` now means the P&L could not be read, and
  `ambiguous_statement` covers duplicate drafts as well as duplicate
  approved statements.
- `connect-commands.json` lists the connect commands Fundry's Settings page
  shows, and a test keeps it identical to the README.

## 0.1.1

- Skills no longer ask for 200 rows per page. Fundry now keeps each result
  small enough for the assistant to read whole, so a page can hold fewer rows
  than requested; the skills page to the end as before.
- The roll-forward check reports `stored_check_recorded_count`, and the
  skills explain that `stored_flag: null` means nothing was recorded at
  extraction, not a clean check.
- README: the Codex port setting now comes before `codex mcp add`, which
  starts sign-in immediately.

## 0.1.0

- First release: the Fundry connector for Claude Code, Codex and Claude, and
  three skills: `quarterly-lp-pack`, `lp-reply-with-figures`,
  `manco-variance-brief`.
