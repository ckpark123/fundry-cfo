# Changelog

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
