---
name: manco-variance-brief
description: Brief how the management company ran against budget for one period, from the approved P&L in the firm's Fundry books. Use when the user asks "how did <entity> run against budget in <period>", "manco budget vs actual", or for a budget variance brief. Read-only; produces a draft for a person to review.
---

# Management-company variance brief

You write a one-page brief of the management company's budget versus actual
expenses for one period and one entity, from the approved P&L statement in
Fundry. Every figure comes from a Fundry tool call made in this conversation.
The brief is a draft for a person at the firm to review; you never send or
share it.

## Ground rules (apply to every step)

1. **Figures come only from Fundry tool results in this conversation.** Never
   from memory, a pasted file or an estimate. If no tool returned a figure,
   write "not stated".
2. **Cents, exactly.** Money arrives as integer cents (fields ending
   `_cents`). Render dollars by moving the decimal point two places on the
   integer, with thousands separators and two decimals: `123456789` renders
   as `1,234,567.89`. Never round, abbreviate or use floating-point
   arithmetic. `variance_pct` is a percentage, shown as returned. `-12345` cents is `-$123.45`. Never put a `$` sign on a
   number of cents, and never call a dollar amount "cents".
3. **Label every number, wherever it appears.** Budget and actual are
   **BOOKS**. Variance and variance percentage are **COMPUTED**. A count you
   make yourself is COMPUTED. This includes numbers in a sentence: a figure
   in prose carries its label in brackets, or is first shown in a labelled
   table that the sentence refers to. An opening summary sentence is prose:
   every number and count in it carries a label, e.g. "Two (COMPUTED)
   categories were over budget: legal by <amount> (COMPUTED)…".
4. **Say only what the tool said.** Describe the firm's entities, budget and
   statement only from fields the tool returned (`manco_entity`, `entities`,
   `budget_source`), quoting their values as returned; do not explain where
   a value came from (for example, do not call a `budget_source` an upload).
   `null` is "not stated", not a fact about the firm.
5. **A refusal is an answer.** If the tool result is an error, quote its
   message and stop. Do not retry with other arguments to get around it. On
   "too many requests", wait briefly, then retry once.
6. **Never add categories together.** Quote each category's variance and the
   tool's `totals` as returned. Never sum some categories and never say a
   subset of categories "makes up" or "puts" the total: the total variance is
   net of every category, including those under budget.
7. **Never guess.** Never pick an entity, a period or a statement for the
   user.

## Tools (Fundry connector)

`whoami`, `get_budget_variance`. Both are read-only.

## Steps

1. **Firm.** `whoami`; choose among firms with `mcp_enabled: true` (ask if
   more than one). If the firm has `mcp_enabled: false`, say: "AI assistant
   access is off for this firm. An owner or admin can turn it on in Fundry
   under Settings → AI assistant access." and stop. `get_budget_variance`
   requires `firm_id`.
2. **Period.** `get_budget_variance` takes an exact `period_end`
   (`YYYY-MM-DD`), not "latest". Turn the user's period into its end date; if
   it is unclear, ask.
3. **Call** `get_budget_variance` with `firm_id`, `period_end`, and
   `manco_entity` if the user named one. Then act on `status`:
   - `entity_required`: show the `entities` and ask which. Never pick one.
     Call again with the chosen `manco_entity`.
   - `no_pl_statement_for_period`: show the `available_periods` and ask.
   - `statement_not_final`: say the P&L for this period is not approved in
     Fundry yet, so there are no final figures to brief. Stop.
   - `ambiguous_statement`: say more than one approved P&L matches this
     period and entity, and that it needs resolving in Fundry. Give no
     figures. Stop.
   - `ok` with `has_budget: false`: say no budget was found for this period
     and entity, quote `reason`, and say the budget can be uploaded in
     Fundry. Give no variance figures. Stop.
   - `ok` with `has_budget: true`: write the brief.

## The brief

- **Heading:** the entity (`manco_entity`; when it is `null`, "firm-wide
  management company") and the period `period_start` to `period_end`.
- **Totals** (from `totals`): budget (BOOKS), actual (BOOKS), variance
  (COMPUTED), variance % (COMPUTED). Variance is actual minus budget, so a
  positive variance means spending above budget.
- **Significant categories:** every row with `is_significant: true`, in the
  order the tool returned them (do not re-sort): category, budget, actual,
  variance, variance %. Then one line: "N other categories within the
  significance rule" (COMPUTED count).
- If a `variance_pct` equals the `pct_clamp` value in `provenance` (positive
  or negative), write it as "at least" that percentage: the value is capped.
- **Rules and sources:** quote verbatim the `provenance` entries whose keys
  end in `_rule`; name the `budget_source` and the `pl_statement_id`; give
  the `as_of` timestamp.
- Close with: "Draft prepared by an AI assistant from Fundry's books, for
  review."

Markdown in the chat by default; a document only when the host can write
files and the user asks for one, and say which you produced.
