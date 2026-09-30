# DEEP MECHANICS · MCP (Model Context Protocol)

> 🧠 **Hook:** *USB-C for AI tools* — one standard plug so any tool connects to any model.
>
> Level 2 — what MCP standardizes, its client-server architecture, primitives
> (tools/resources/prompts), transport, and why it matters vs ad-hoc function
> calling.

---

## 0. The precise mental model
**MCP** is an **open protocol (from Anthropic, now broadly adopted)** that standardizes **how AI applications connect to tools and data**. Think **"USB-C / LSP for AI"**: instead of every app writing bespoke integrations for every tool, an **MCP server** exposes capabilities in a standard way, and any **MCP client** (Claude Desktop, VS Code, your agent) can consume them. It decouples **tool providers** from **AI apps** → build a tool once, use it everywhere.

---

## 1. The problem it solves
Before MCP: every LLM app hand-codes each integration (GitHub, DB, filesystem) with its own schema/auth. **N apps × M tools = N×M** bespoke connectors. MCP makes it **N + M**: tools expose an MCP server once; apps speak MCP once.

## 2. Architecture — client/server
```
[Host app: IDE / agent]
   └─ MCP Client ──(JSON-RPC)── MCP Server ── actual tool/data
                                 (GitHub, DB, filesystem, API)
```
- **Host** — the AI app (e.g., VS Code, Claude Desktop).
- **Client** — lives in the host, maintains a 1:1 connection to a server.
- **Server** — exposes capabilities (a GitHub server, a Postgres server). Can be local (stdio) or remote (HTTP/SSE).
- **Protocol** — **JSON-RPC 2.0** messages.

## 3. The three primitives a server exposes
- **Tools** — **model-controlled** callable functions (actions): `create_issue`, `run_query`. The LLM decides to invoke them (like function calling, but standardized/discoverable).
- **Resources** — **app/data-controlled** context: files, records, docs the host can load into context (read-only data).
- **Prompts** — **user-controlled** reusable prompt templates/workflows the server offers.
This separation (who controls each) is core to MCP's design.

## 4. Transport & discovery
- **stdio** — local server as a subprocess (fast, local tools/filesystem).
- **HTTP + SSE / streamable HTTP** — remote servers.
- **Capability negotiation** — on connect, client and server exchange what they support; the client **discovers** available tools/resources dynamically (no hard-coding).

## 5. MCP vs plain function calling
Function calling = the model emitting a call your app must implement. **MCP standardizes the discovery, schema, and transport** so tools are **portable and reusable across apps** and can be **swapped/added without changing the app**. Function calling is the *mechanism*; MCP is the *interoperability standard* around it.

## 6. Security considerations (interviewers ask)
- Servers can execute powerful actions → **least privilege**, explicit user consent for tool use, sandboxing, auth on remote servers.
- **Untrusted servers/tools** and **indirect prompt injection** via resource content are real risks → validate, scope permissions, human-in-the-loop for high-impact actions.

## 7. The hard follow-ups (with answers)
1. **"What problem does MCP solve?"** → N×M bespoke integrations → N+M via a standard protocol. (§1)
2. **"MCP architecture?"** → host↔client↔server over JSON-RPC; servers wrap tools/data. (§2)
3. **"Three primitives?"** → **tools** (model-controlled actions), **resources** (data/context), **prompts** (templates). (§3)
4. **"MCP vs function calling?"** → function calling = mechanism; MCP = standard for discovery/schema/transport → portable, swappable tools. (§5)
5. **"Transports?"** → stdio (local subprocess) and HTTP/SSE (remote), with capability negotiation. (§4)
6. **"Security risks?"** → powerful actions + untrusted servers + indirect injection → least privilege, consent, sandbox, auth. (§6)

## 8. One-screen recall
- **MCP = open standard ("USB-C/LSP for AI")** connecting AI apps to tools/data → **N×M → N+M**.
- **Client/server** in a host, **JSON-RPC 2.0**; servers wrap GitHub/DB/filesystem/APIs.
- **Primitives**: **tools** (model-controlled actions) · **resources** (data/context, read-only) · **prompts** (user templates).
- **Transport**: **stdio** (local) / **HTTP+SSE** (remote); **capability negotiation** → dynamic discovery.
- **vs function calling**: FC = mechanism; MCP = interoperability standard → portable, swappable, discoverable tools.
- **Security**: least privilege, consent, sandboxing, auth; beware untrusted servers + indirect injection.

> Next: Function Calling.
