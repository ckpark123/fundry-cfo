# OAuth client IDs

Fundry does not accept dynamic client registration. Each assistant connects
with a public OAuth client that Fundry registers in advance, and the sign-in
returns only to the exact redirect address registered for that client.

This table is the single place the client IDs are recorded. The other files
carry the token in the second column until the ID is filled in.

| Surface | Token | Client ID | Redirect URI |
| --- | --- | --- | --- |
| Claude Code (this plugin) | `{{claude_code_client_id}}` | `57459d6e-b837-4d4d-be9f-91a24dc1f0a1` | `http://localhost:8976/callback` |
| Codex | `{{codex_client_id}}` | `c83c3735-7943-4ad7-a231-a3514526f4d8` | `http://127.0.0.1:8977/callback/p6l42pqK4o_r` (see below) |
| Claude (claude.ai custom connector) | `{{claude_ai_client_id}}` | `b4bb45ad-7e0c-4523-bb7d-4d5aaddfa4eb` | `https://claude.ai/api/mcp/auth_callback` |

The Codex path segment is not chosen by Fundry. Codex appends it because the
authorization server does not advertise issuer identification (RFC 9207):
the first 9 bytes of SHA-256 over the exact server URL, base64url-encoded.
For `https://www.fundryai.com/api/mcp` it is `p6l42pqK4o_r`. If the server URL
ever changes, recompute it and re-register the redirect. Use the URL
that answers without a redirect (the bare `fundryai.com` redirects to
`www`, which changes this value):

```sh
node -e 'console.log(require("crypto").createHash("sha256").update(process.argv[1]).digest().subarray(0,9).toString("base64url"))' https://www.fundryai.com/api/mcp
```

Files that carry the tokens: `.mcp.json` (Claude Code), `README.md` (Codex
and Claude), `AGENTS.md` (Codex).

## Filling them in

1. Put each registered ID in the Client ID column above (keep the token
   column as is).
2. Run `scripts/fill-client-ids.sh`. It replaces every token whose row has an
   ID, in every file except this one.
3. Run `scripts/disclosure-check.sh --release`. It fails while any token is
   still unfilled. Client IDs recorded in this table are the only UUIDs the
   disclosure gate allows.
