# Fundry CFO: instructions for Codex

This repository connects Codex to a firm's Fundry books through the Fundry
MCP server (`https://www.fundryai.com/api/mcp`) and describes three CFO tasks.
Codex reads this file when it runs in a clone of this repository.

## Connecting (once per machine)

```sh
codex mcp add fundry --url https://www.fundryai.com/api/mcp --oauth-client-id c83c3735-7943-4ad7-a231-a3514526f4d8
```

Add this line at the top level of `~/.codex/config.toml` (Fundry accepts only
the registered sign-in return address, which uses this port):

```toml
mcp_oauth_callback_port = 8977
```

Then sign in with `codex mcp login fundry` and approve the connection on
Fundry's page.

## The tasks

When the user asks for one of these, read the named file and follow it
exactly:

| The user asks to... | Follow |
| --- | --- |
| build or check the quarterly LP pack for a fund | `skills/quarterly-lp-pack/SKILL.md` |
| reply to an LP's email with that LP's figures | `skills/lp-reply-with-figures/SKILL.md` |
| brief how the management company ran against budget | `skills/manco-variance-brief/SKILL.md` |

## Rules for any use of the Fundry tools

- Every figure comes from a Fundry tool result in this session. If no tool
  returned it, say "not stated"; never estimate and never write 0 for `null`.
- Money is integer cents. Render dollars by moving the decimal point two
  places on the integer, two decimals, no rounding or abbreviation.
- Label each number BOOKS (read from the books) or COMPUTED (recomputed or
  derived), everywhere it appears, including notes and opening sentences.
- A sentence saying a roll-forward is violated, uncheckable or in
  disagreement names the capital statement and its period end in that
  sentence.
- Never add up some rows and present the sum as, or as part of, a tool's total;
  quote the tool's total.
- Say only what a tool said: no meaning a field does not carry, no claim that
  data is absent unless a tool said so.
- Page every result with `has_more: true` using `next_cursor` until it is
  `false`, and check that `returned` adds up to `total`. Otherwise say the
  read was incomplete and stop.
- A tool error is an answer: quote it and stop. Never work around it with
  other arguments.
- Anything meant for an LP is a draft. A person at the firm reviews and
  sends it. Never send, email or share anything.
- The tools are read-only. Nothing in Fundry can be changed from here.
