---
name: quarterly-lp-pack
description: Build or check the quarterly LP pack for one fund from the firm's Fundry books. Use when the user asks to "build the Q<N> LP pack for <fund>", "check the LP pack", or for a per-LP capital account summary with roll-forward checks for a period. Read-only; produces a draft for a person to review.
---

# Quarterly LP pack

You assemble a fund's quarterly LP pack from the firm's Fundry books: a fund
summary, one capital-account row per LP, and a Checks section that recomputes
every LP's capital roll-forward. Every figure comes from a Fundry tool call
made in this conversation. The pack is a **draft**: a person at the firm
reviews and approves it before any of it reaches an LP. You never send,
upload, email or share it.

## Ground rules (apply to every step)

1. **Figures come only from Fundry tool results in this conversation.** Not
   from memory, an earlier conversation, a pasted document or an estimate. If
   no tool returned a figure, write "not stated". Never write 0 for a value
   the tools returned as `null`.
2. **Cents, exactly.** Money arrives as integer cents (`unit: "cents"`, fields
   ending `_cents`). Render dollars by moving the decimal point two places on
   the integer, with thousands separators and exactly two decimals:
   `123456789` cents renders as `1,234,567.89`; `-5000` renders as
   `-50.00`. Do not round, abbreviate ("1.2M") or pass the value through
   floating-point arithmetic. Ratios (`tvpi`, `dpi`, `rvpi`, `irr`) are shown
   as returned. `-12345` cents is `-$123.45`. Never put a `$` sign on a
   number of cents, and never call a dollar amount "cents".
3. **Label every number.** **BOOKS** = read from the books (a tool result with
   `source: "books"`). **COMPUTED** = a recomputation or a number you derived
   (a tool result with `source: "computed"`, or anything you added up). Use a
   tool's total instead of your own sum whenever a tool returns one; if you
   must sum, label it COMPUTED and say how many values you summed.
4. **Read everything, or say you did not.** A result with `has_more: true` is
   incomplete. Call the same tool again with the same arguments plus
   `cursor` = the `next_cursor` you were given, until `has_more` is `false`.
   A page can hold fewer rows than `page_size`: Fundry keeps each result
   small enough for your assistant to read whole. Do not ask for a larger
   page. Then check that the `returned` values of all pages add up to `total`. If
   they do not, or any page fails, stop and tell the user the read was
   incomplete. Never present a partial list as complete and never fill gaps.
5. **A refusal is an answer.** If a tool result is an error, quote its message
   to the user and stop. Do not retry with a different firm, fund or period
   to get around it. The one exception: a "too many requests" message, where
   you wait briefly, then retry once.
6. **Never move the period.** If an exact `period_end` comes back with
   `status: "no_statements_for_period"`, tell the user the
   `latest_available_period` and ask what they want. Do not switch silently.
7. **Never guess an identity.** If a firm or fund name matches more than one
   row, or none, show the candidates and ask.
8. **Name the document when a check fails.** Any sentence that says a
   roll-forward is violated, uncheckable or in disagreement names, in that same
   sentence, the capital statement and its period end ("the <period end>
   capital statement for <LP>"), plus its `source_doc_id` when one is returned.
   This holds in tables, notes and summaries alike.
9. **Say only what a tool said.** Do not add meaning a field does not carry
   (for example, do not call a beginning balance a "start-of-year" balance), and
   do not say data is absent unless a tool returned a status or an empty result
   saying so.

## Tools (Fundry connector)

`whoami`, `list_funds`, `get_fund_summary`, `list_capital_statements`,
`check_capital_rollforward`. All are read-only.

## Steps

1. **Firm.** Call `whoami`. Use the firms in `firms` with `mcp_enabled: true`.
   If there is more than one and the user did not name one, ask which. If the
   firm the user means has `mcp_enabled: false`, say: "AI assistant access is
   off for this firm. An owner or admin can turn it on in Fundry under
   Settings → AI assistant access." and stop. If `has_more` is true and the
   firm is not listed, ask the user to name it exactly. Pass that firm's
   `firm_id` on every later call.
2. **Fund.** Call `list_funds` with `firm_id`. Match the user's fund name
   against `rows[].name` (case-insensitive). Exactly one match is required
   (rule 7). If the match has `available: false`, say the fund is not available to this connection and stop.
3. **Period.** Accept `"latest"` or a date `YYYY-MM-DD`. "Q1/Q2/Q3/Q4 YYYY"
   means the calendar quarter end (03-31, 06-30, 09-30, 12-31); if the user
   indicates a non-calendar fiscal year, ask for the date.
4. **Statements.** Call `list_capital_statements` with `firm_id`, `fund_id`,
   and `period_end`, paging to the end (rule 4). On
   `no_statements_for_period`, apply rule 6. Take the `period_end` the result
   returns as **the pack period** and use that exact date (never `"latest"`)
   in every later call, so all sections describe the same period.
5. **Summary.** Call `get_fund_summary` with `firm_id` and `fund_id`. Its
   statement figures are summed over the fund's latest statements, dated
   `statements_period_end`. Show them in the pack only if
   `statements_period_end` equals the pack period; otherwise show only NAV and
   the multiples (with their as-of dates) and note that the statement totals
   belong to a different period.
6. **Checks.** Call `check_capital_rollforward` with `firm_id`, `fund_id`,
   `period_end` = the pack period and `basis: "both"`, paging to the end
   (rule 4). The counts (`lps_checked_count`, `per_basis`,
   `disagreement_count`, `stored_check_recorded_count`,
   `stored_flags_unparseable_count`) already cover the whole period; the
   per-LP `rows` are what you page.
7. **Cross-check before writing.** Compare `lps_checked_count` with the
   statements `total` from step 4. If they differ, say so at the top of the
   Checks section.

## The pack

Write it in this order.

**Cover.** Fund name; pack period; the `as_of` timestamp of the reads; the
line "Draft prepared by an AI assistant from Fundry's books. A person at the
firm must review and approve it before it is shared with any LP."; the
BOOKS/COMPUTED legend; and, quoted verbatim, the entries in the
`check_capital_rollforward` result's `provenance` whose keys end in `_rule`
(the rule for when a residual counts as balanced). Do not restate or
paraphrase that rule.

**Fund summary** (BOOKS). Commitments, contributions to date, unfunded,
distributions year-to-date and to date, each with "stated by N of M
statements" from `stated_rows` (M = `statement_rows`); LP count; NAV with
`nav_as_of`; TVPI, DPI, RVPI, IRR with `multiples_as_of`. Apply step 5.

**Capital accounts** (BOOKS). One row per LP, in the order returned. Columns:
LP, beginning capital, contributions (quarter, year-to-date), distributions
(quarter, year-to-date), management fee (quarter), expenses (quarter),
realized gain/loss (quarter), unrealized gain/loss (quarter), carried interest
(quarter), ending capital, unfunded commitment, commitment. Put the
inception-to-date columns (`*_itd_cents`) in a second table. A total row, if
you add one, is COMPUTED with the count of LPs summed.

**Checks** (COMPUTED).
- Per basis (inception-to-date, year-to-date): the four counts from
  `per_basis` (balanced, balanced under an alternative hypothesis, violated,
  uncheckable), `lps_checked_count`, `disagreement_count`,
  `stored_check_recorded_count` and `stored_flags_unparseable_count`.
- `stored_flag` is the roll-forward result Fundry recorded when it extracted
  the statement: `true` a violation, `false` balanced only under an
  alternative reading, `null` nothing recorded. Fundry records a result only
  when its check finds something, so `null` does not mean the statement was
  checked and passed. A disagreement is counted only where something was
  recorded. If `stored_check_recorded_count` is 0, say that no extraction-time
  check was recorded for the period, so there was nothing to compare, rather
  than reporting 0 disagreements as agreement.
- A table of every LP where either basis is not `balanced`, or
  `disagreement` is true: LP, basis, `recomputed_status`, residual (dollars,
  from `residual_cents`), `hypothesis` or `uncheckable_reason`,
  `stored_flag`, the capital statement it checks (LP and period end) and
  `source_doc_id` (rule 8).
- Any data-quality `flags` returned on the statements in step 4, by LP.
- Say plainly that a flag is a question to check against the source
  statement, not a finding that the administrator is wrong: the figures are
  as extracted by Fundry, and the source statement decides whether a
  difference is the administrator's or Fundry's.
- Write "every roll-forward balances" only when `violated_count` and
  `uncheckable_count` are 0 on both bases AND `lps_checked_count` equals the
  statements total. Otherwise state the counts.
- This check recomputes each LP's statement. It is not a tie-out against the
  administrator's allocation: for that, upload the allocation workbook in
  Fundry.

**Sources.** One line per tool call: tool, firm and fund by name, period,
page number, `returned` of `total`, `has_more`, `as_of`.

## Refusals

Stop and say what is missing, without producing a partial pack, when:
- any tool call returns an error (quote the message);
- the period has no statements (rule 6);
- a paged read did not complete or its counts do not add up (rule 4).

Never assert a roll-forward result the tool did not return.

## Format

Markdown in the chat by default. Produce a spreadsheet (one sheet per section)
or a document only when the host can write files and the user asks for one,
and say which format you produced and where it is. The file is still a draft
for review.
