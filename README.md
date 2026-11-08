# Fundry CFO

Connect Claude, Claude Code or Codex to your firm's Fundry books, read-only,
and use three skills built for a fund CFO:

| Skill | Ask for | You get |
| --- | --- | --- |
| `quarterly-lp-pack` | "Build the Q2 LP pack for <fund>" | A draft pack: fund summary, one capital-account row per LP, and a Checks section that recomputes every LP's capital roll-forward, with sources for every call |
| `lp-reply-with-figures` | Paste an LP's email: "reply with their figures" | A draft reply quoting only that LP's figures, each marked "(Fundry books, <period end>)", plus a note on anything to confirm first |
| `manco-variance-brief` | "How did the management company run against budget in <period>?" | A one-page brief of budget vs actual from the approved P&L, significant categories first |

Every figure comes from a Fundry tool call, in exact cents, labelled
**BOOKS** (read from your books) or **COMPUTED** (recomputed or derived). When
a read is incomplete or a tool refuses, the skill says so and stops instead
of guessing. The skills draft; a person at your firm reviews and sends.
Nothing is ever sent for you.

## Before you connect

An owner or admin of your firm turns on **AI assistant access** in Fundry
(Settings → AI assistant access) and confirms that the firm uses a business
AI plan whose terms, as the firm has reviewed them, exclude training on your
data (for example Claude Team or Enterprise, the Claude API, or an OpenAI
business plan; personal plans do not qualify). Fundry records this
confirmation; it does not check your AI provider's terms. Until access is on,
every request is refused.

Each person then connects their own assistant and approves it on Fundry's
consent page. The assistant acts as that person and sees only what they can
see in Fundry.

## Install

The server URL is `https://www.fundryai.com/api/mcp`. Client IDs are listed in
[CLIENT_IDS.md](CLIENT_IDS.md).

### Claude Code

```sh
claude plugin marketplace add ckpark123/fundry-cfo
claude plugin install fundry-cfo@fundry
```

Or, inside Claude Code: `/plugin marketplace add ckpark123/fundry-cfo`, then
`/plugin install fundry-cfo@fundry`. The plugin carries the server URL and
sign-in settings. Run `/mcp`, choose **fundry**, sign in to Fundry and approve
the connection.

### Claude (claude.ai, Team or Enterprise)

An owner of your Claude organization adds the connector once:

1. Settings → Connectors → **Add custom connector**.
2. Name: `Fundry`. URL: `https://www.fundryai.com/api/mcp`.
3. Advanced settings → OAuth Client ID: `b4bb45ad-7e0c-4523-bb7d-4d5aaddfa4eb`.

Each member then clicks **Connect** on the Fundry connector and approves it
on Fundry's page. To use the skills in Claude, upload the folders under
`skills/` as skills in your Claude settings, or ask Claude to follow a skill
file's steps.

### Codex

```sh
codex mcp add fundry --url https://www.fundryai.com/api/mcp --oauth-client-id c83c3735-7943-4ad7-a231-a3514526f4d8
```

Add this line at the top level of `~/.codex/config.toml`, because Fundry
accepts only the registered sign-in return address, which uses this port:

```toml
mcp_oauth_callback_port = 8977
```

Then run `codex mcp login fundry` and approve the connection on Fundry's
page. For the skills, run Codex from a clone of this repository: it reads
[AGENTS.md](AGENTS.md), which points it at the skill files.

## What the assistant can read

Seven read-only tools. Each answers in integer cents; `null` means your books
do not state the value.

| Tool | Returns |
| --- | --- |
| `whoami` | The Fundry user the connection acts as (email domain only), their firms, and which funds the connection can read |
| `list_funds` | The firm's funds with NAV, TVPI, DPI, RVPI, IRR and paid-in capital |
| `get_fund_summary` | One fund's commitments, contributions, unfunded and distributions from its latest capital statements, LP count, NAV and multiples |
| `list_lp_commitments` | One fund's LPs with commitment, called and distributed amounts, paged |
| `list_capital_statements` | Per-LP capital statements for one fund and period, paged |
| `check_capital_rollforward` | Each LP's roll-forward recomputed on an inception-to-date and year-to-date basis, compared with what Fundry recorded |
| `get_budget_variance` | The management company's budget vs actual for one period and entity |

The assistant cannot create, change or delete anything in Fundry. Investor
names and capital-account figures are returned; contact details, tax IDs,
bank details and document text never are. Fundry logs every tool call that
returns data before it reads anything, and also records refused calls. Details: <https://www.fundryai.com/security/mcp>.

## Disconnect or revoke

- **One assistant:** in Fundry, Settings → AI assistant access → your
  connected assistants → **Revoke**. Its next request is refused.
- **The whole firm:** an owner or admin turns AI assistant access off in the
  same place. It takes effect on the next request; turning it back on needs
  the confirmation again.
- **On your side:** Claude: remove or disconnect the Fundry connector.
  Claude Code: `claude plugin uninstall fundry-cfo@fundry`. Codex:
  `codex mcp logout fundry`, then `codex mcp remove fundry`.

## For maintainers

`scripts/disclosure-check.sh` runs on every push and fails on anything this
public repository must not contain; `tests/disclosure-check.test.sh` proves
it can fail. Run `scripts/disclosure-check.sh --release` before publishing.

## License

MIT. See [LICENSE](LICENSE).
