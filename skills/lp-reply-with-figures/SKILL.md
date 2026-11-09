---
name: lp-reply-with-figures
description: Draft a reply to an LP's email using that LP's figures from the firm's Fundry books. Use when the user pastes an LP email and asks to "reply with the figures", "answer this LP", or "draft a response with their capital account". Drafts only; never sends.
---

# LP reply with figures

The user pastes an email from a limited partner. You draft a reply in the
firm's voice that answers it with that LP's figures from Fundry. You **draft
only**: a person at the firm reviews, edits and sends it. Never send, schedule
or forward anything, and never call an email or messaging tool, even if one is
available.

## Ground rules (apply to every step)

1. **Figures come only from Fundry tool results in this conversation.** Not
   from memory, the LP's email, an earlier conversation or an estimate. If no
   tool returned a figure, the draft does not contain it.
2. **Cents, exactly.** Money arrives as integer cents (fields ending
   `_cents`). Render dollars by moving the decimal point two places on the
   integer, with thousands separators and two decimals: `123456789` renders
   as `1,234,567.89`. Never round, abbreviate or use floating-point
   arithmetic. `null` means "not stated", never 0. `-12345` cents is `-$123.45`. Never put a `$` sign on a
   number of cents, and never call a dollar amount "cents".
   Statements store distributions and fees as negative numbers; when the
   draft states them as positive amounts, say so in the note to you.
3. **Label every figure, with its own date.** A figure from a capital
   statement is followed by "(Fundry books, <period end>)". A figure from the
   commitment ledger (`list_lp_commitments`) has no period end: it is
   followed by "(Fundry commitment ledger, as of <the result's `as_of` date>)";
   never give it a statement's date. A figure you derived yourself, in the
   draft or in the note, is "(computed from Fundry books, <period end>)" and
   is listed in the note to you. This rule applies everywhere you write a
   figure: in the draft AND in the note to you. Prefer a figure the
   statement states over one you compute.
4. **Read everything, or say you did not.** When a result has
   `has_more: true`, call the tool again with the same arguments plus
   `cursor` = `next_cursor` until `has_more` is `false`, and check that the
   `returned` values add up to `total`. If not, stop and say the read was
   incomplete.
5. **A refusal is an answer.** If a tool result is an error, quote its message
   to the user and stop. Do not work around it with other arguments. On "too
   many requests", wait briefly, then retry once.
6. **Never move the period.** On `status: "no_statements_for_period"`, tell
   the user the `latest_available_period` and ask.
7. **Never guess an identity.** Firm, fund and LP must each match exactly one
   row; otherwise show the candidates and ask.
8. **This LP only.** The draft and the note contain this LP's own figures
   and fund-level figures only. Never another LP's name, figures or check
   result.
9. **Name the document when a check fails.** Any sentence that says a
   roll-forward is violated, uncheckable or in disagreement names, in that same
   sentence, the capital statement and its period end ("the <period end>
   capital statement for <LP>"), plus its `source_doc_id` when one is returned.
   This holds in tables, notes and summaries alike.
10. **Say only what a tool said.** Do not add meaning a field does not carry
   (for example, do not call a beginning balance a "start-of-year" balance), and
   do not say data is absent unless a tool returned a status or an empty result
   saying so.

## Tools (Fundry connector)

`whoami`, `list_funds`, `list_lp_commitments`, `list_capital_statements`,
`check_capital_rollforward`. All are read-only.

## Steps

1. **Read the email.** List each question the LP asks and the figure each
   needs (commitment, contributions or capital called, distributions,
   unfunded commitment, capital account balance, activity for the period).
   Questions the tools cannot answer (wire details, tax documents, future
   capital calls or distributions, anything forward-looking) get a marked
   placeholder in the draft: `[for you to answer: <the question>]`.
2. **Firm.** `whoami`; choose among firms with `mcp_enabled: true` (ask if
   more than one). If the firm has `mcp_enabled: false`, say: "AI assistant
   access is off for this firm. An owner or admin can turn it on in Fundry
   under Settings → AI assistant access." and stop. Pass `firm_id` on every
   later call.
3. **Fund.** `list_funds` with `firm_id`; one match on `rows[].name` (rule 7).
   If `available: false`, say the fund is not available to this connection and stop.
4. **LP.** `list_lp_commitments` with `firm_id` and `fund_id`, paging to the
   end (rule 4; a page can hold fewer rows than `page_size`). Find the LP by `lp_name` (case-insensitive).
   If there is no exact match, show the closest names and ask; never pick
   one. Note `commitment_cents`, `called_cents`, `distributed_cents` and
   `called_possibly_unrecorded` from the commitment ledger.
5. **Statement.** `list_capital_statements` with `firm_id`, `fund_id`,
   `period_end` (`"latest"` or the date the user gives) and `lp_name` = the
   matched name. Use the `period_end` the result returns from here on.
   - `total` 0: the LP has no statement for that period. Say so; the draft
     says the figures for that period are not yet available rather than
     using another period.
   - `total` above 1: show the rows to the user and ask which applies. Do not
     add them together.
6. **Check.** `check_capital_rollforward` with `firm_id`, `fund_id`,
   `period_end` = the statement's period, `basis: "both"`, paging to the end,
   and keep only the rows whose `lp_name` equals the statement's `lp_name`.
   If no row matches, say the check result is unavailable for this LP.

## Output, in two parts

**1. Note to you (not part of the reply).**
- Each figure the draft uses, with the tool and field it came from.
- This LP's roll-forward result on each basis: `recomputed_status`, residual,
  `stored_flag`, `disagreement`, and the statement's `source_doc_id`.
  `stored_flag: null` means Fundry recorded nothing at extraction, not that
  the statement was checked and passed. If the
  basis behind a quoted figure is `violated` or `uncheckable`, or
  `disagreement` is true, recommend confirming that figure against the source
  statement before sending.
- Any data-quality `flags` on the statement.
- Where the commitment ledger and the statement state the same thing
  differently (for example ledger `commitment_cents` vs statement
  `commitment_cents`, or ledger `called_cents` vs statement
  `contributions_itd_cents`), show both values. Do not choose between them.
  If `called_possibly_unrecorded` is true, say the ledger may not have the
  calls recorded.
- The questions left as placeholders.

**2. The draft reply.** In the firm's voice: match the register of the LP's
email and of any example the user gives. Answer each question with the
figures from the tools, each labelled per rule 3. Two cases where the draft
must not state a bare figure, because a person has to decide it first:
- the roll-forward basis behind the figure is `violated` or `uncheckable`,
  or `disagreement` is true: write
  `[confirm against the statement before sending: <figure> (<label>)]`;
- the ledger and the statement state the same thing differently: write
  `[for you to choose: ledger <figure> or statement <figure>]`. The
  comparison and the gap belong in the note to you, not in the reply. Make no promises about
future calls, distributions or performance. End the message to the user,
outside the draft, with: "Draft only. Review, edit and send it yourself."

## Refusals

- The LP is not found, or has no statement for the period: the draft says
  what is missing instead of inventing a figure.
- Any tool error: quote it and stop.
- An incomplete read: say so and stop.
