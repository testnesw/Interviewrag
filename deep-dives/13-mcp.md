# Deep Dive · MCP (Model Context Protocol)

> Phase 1 (Highest ROI) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
MCP (Model Context Protocol) is an **open standard** (introduced by Anthropic, now broadly adopted) that defines **how AI applications connect to tools, data, and context** — think of it as **"USB-C for AI."** Instead of writing bespoke integrations for every model + every tool, you expose capabilities once via an **MCP server**, and any **MCP-compatible client** (Claude, Copilot, your agent) can discover and use them over a standard protocol (JSON-RPC). It standardizes three primitives: **Tools** (actions), **Resources** (data/context), and **Prompts** (reusable templates) — decoupling *what an agent can do* from *which model or app uses it*.

---

## 2. Architect-Level Explanation
MCP is a **client-server protocol** that sits between AI hosts and capability providers:
- **Host**: the AI app the user interacts with (IDE, chatbot, agent runtime).
- **Client**: the MCP connector inside the host (one per server connection).
- **Server**: exposes **Tools**, **Resources**, and **Prompts** for a specific system (GitHub, a DB, Azure, a filesystem).
- **Transport**: JSON-RPC 2.0 over **stdio** (local) or **HTTP/SSE / streamable HTTP** (remote).

The architectural value is **standardization and decoupling**: without MCP you have an **M×N integration problem** (M models × N tools = bespoke glue everywhere). MCP turns it into **M+N** — each tool implements the server once, each host implements the client once. It's the **integration layer** of agentic architectures, analogous to how ODBC standardized DB access or LSP standardized editor↔language-server communication.

---

## 3. Why It Exists
- **Problem before**: every AI app hand-rolled tool/function integrations. Swapping models or adding a tool meant rewriting glue code; nothing was reusable or portable.
- **Function calling wasn't enough**: function calling is a *model capability* (emit a structured call), but there was **no standard for how tools are described, discovered, transported, or secured** across apps.
- **Breakthrough**: MCP defines a **common wire protocol + capability schema** so tools are **discoverable and portable** across any compliant host — write once, use everywhere.
- **Why enterprises adopt it**: build a **reusable catalog of internal MCP servers** (SharePoint, ServiceNow, SQL, internal APIs) that any copilot/agent can consume with consistent auth, governance, and audit — instead of N one-off integrations.

---

## 4. Internal Working
**Connection lifecycle:**
```
1. Host starts an MCP Client and connects to a Server (stdio or HTTP)
2. Handshake / initialize → exchange capabilities + protocol version
3. Discovery: client calls tools/list, resources/list, prompts/list
4. Use:
   - tools/call    → server executes an action, returns result
   - resources/read→ server returns data/context (files, rows, docs)
   - prompts/get   → server returns a filled prompt template
5. Server may send notifications (list changed, progress, logs)
6. Close / teardown
```
Core mechanics:
- **JSON-RPC 2.0** messages (request/response + notifications).
- **Three primitives**:
  - **Tools** = model-invokable **actions** (side effects) — e.g., `create_issue`, `run_query`.
  - **Resources** = **read-only context** identified by URI — e.g., `file://`, `db://table/row`.
  - **Prompts** = **user-selectable templates** the server offers (reusable, parameterized).
- **Transports**: **stdio** for local processes (fast, sandboxed); **HTTP + SSE / streamable HTTP** for remote/networked servers.
- **Capability negotiation**: client and server declare what they support at init.
- **Sampling** (optional): a server can ask the host's model to complete text — keeping the model in the host, not the server.

Key property: the **model never talks to tools directly** — the host mediates, so security/policy live in the host.

---

## 5. Enterprise Use Case
A bank builds a **catalog of internal MCP servers**: one for the policy document store (Resources), one for the core-banking API (Tools like `get_balance`, `flag_transaction`), one for ServiceNow (create/update tickets). Their internal **agent platform and developer copilots** all connect to these servers through MCP with **Entra ID auth and per-server RBAC**. Adding a new capability = ship one MCP server; every existing agent can use it immediately — no per-app integration work, and every call is centrally audited.

---

## 6. Real Production Architecture
```
   Host / Agent Runtime (Entra ID auth)          ┌─ Audit / OpenTelemetry
        │  (LLM stays in the host)                │
        ▼                                          │
   MCP Client(s) ── JSON-RPC (stdio | HTTP/SSE) ──►│
        │                                          │
        ├─► MCP Server: Docs      (Resources)  ─► SharePoint / Blob
        ├─► MCP Server: Database  (Tools/Res.) ─► Azure SQL (read models)
        ├─► MCP Server: ITSM      (Tools)      ─► ServiceNow (APIM)
        └─► MCP Server: Azure Ops (Tools)      ─► ARM / Graph (scoped MI)
        │
   Gateway (remote servers): APIM/Front Door + WAF + OAuth
   Secrets: Key Vault · Networking: Private Endpoints
```

---

## 7. Security Best Practices
- **The host is the trust boundary** — enforce authZ, tool allow-lists, and human approval in the host, not the server.
- **Authenticate every remote server** (OAuth 2.1 / Entra ID); MCP added a formal **auth spec** for HTTP transports — use it.
- **Least privilege per server**: each MCP server gets a scoped Managed Identity / credential for only its backend.
- **Treat tool results and resources as untrusted** — MCP is a prime **prompt-injection / "confused deputy"** surface; validate outputs and constrain follow-on tool calls.
- **Vet third-party servers** — a malicious/compromised server can exfiltrate context or return poisoned data. Pin versions, review code, run in sandboxes.
- **Isolate local (stdio) servers** — no ambient host/network access beyond what's needed.
- **Audit everything**: log every `tools/call` and `resources/read` with identity + correlation ID.
- **Tool-poisoning defense**: validate tool descriptions/schemas; don't blindly trust server-provided prompt text.

---

## 8. Scaling Strategy
- **Remote MCP servers as stateless microservices** → horizontal scale behind a load balancer / APIM (HTTP transport).
- **Connection pooling / reuse** in the host; cap concurrent server connections per session.
- **Cache** `tools/list` / `resources/list` (with change notifications to invalidate) to avoid rediscovery cost.
- **Rate-limit + quota** per server at the gateway to protect backends.
- **Separate hot vs cold servers**; scale independently based on call volume.

---

## 9. High Availability Strategy
- **Multiple replicas** of remote servers across AZs behind a health-checked LB / APIM.
- **Graceful degradation**: if one server is down, the host skips its tools and continues (don't fail the whole agent).
- **Circuit breakers + timeouts** on each server connection.
- **stdio servers**: supervised processes with auto-restart; the host handles reconnect.
- **Idempotent tool actions** so retries after a blip are safe.

---

## 10. Disaster Recovery Strategy
- **Remote servers deployed via IaC** (Terraform) → redeploy in a secondary region quickly.
- **Stateless servers** simplify DR; state lives in the backend systems (which have their own DR).
- **Version-pinned server images** in a geo-replicated registry (ACR) for consistent recovery.
- **Runbooks** to repoint host clients to secondary-region server endpoints.

---

## 11. Cost Optimization Strategy
- **Reuse over rebuild**: one MCP server replaces many bespoke integrations — the biggest savings is engineering time.
- **Cache discovery + resource reads** to cut redundant calls.
- **Scope resources tightly** — return only needed data to keep LLM context (tokens) small.
- **Right-size server compute** (Container Apps scale-to-zero for low-traffic servers).
- **Gateway rate limits** prevent runaway backend/API costs.

---

## 12. Common Production Challenges
- **Untrusted/malicious servers** (supply-chain risk) → vetting, pinning, sandboxing.
- **Tool poisoning / injection** via server-provided descriptions or results → validate + isolate.
- **Confused-deputy** issues: server acts with the host's privileges → strict per-server scoping.
- **Version/capability drift** between client and server → negotiate versions, test compatibility.
- **Auth complexity** for remote servers (OAuth flows, token passthrough) → use the standard auth spec.
- **Latency** from many round-trips (list + call) → cache discovery, batch where possible.
- **Over-exposing tools** → too many tools confuse the model and widen attack surface.

---

## 13. Monitoring and Observability
- **Trace each MCP call** (OpenTelemetry): server name, method (`tools/call`/`resources/read`), latency, success, tokens consumed downstream.
- **KPIs**: calls per server, error rate, p95 latency, auth failures, tool-usage distribution.
- **Security signals**: unexpected tools appearing (list-changed), spikes in resource reads, injection-filter triggers.
- **Audit log** of every action for compliance.
- **Alerts** on server down, error-rate spikes, unauthorized-access attempts.

---

## 14. Troubleshooting Scenarios
- **Client can't connect** → check transport (stdio path / HTTP URL), protocol version handshake, auth token.
- **Tools not showing** → server didn't advertise them or capability negotiation failed; call `tools/list` manually.
- **Tool call fails/hangs** → backend error or timeout; check server logs, add timeout + circuit breaker.
- **Model ignores a tool** → poor tool description/schema; improve naming and parameter docs.
- **Suspicious behavior after adding a server** → possible tool poisoning; audit the server's descriptions and outputs, sandbox it.
- **Auth 401 on remote server** → token scope/expiry; verify OAuth/Entra config and audience.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| MCP vs bespoke integration | reusable, portable, M+N | protocol overhead, maturity |
| Remote (HTTP) server | shareable, scalable | network/auth/latency |
| Local (stdio) server | fast, sandboxed | not shareable, per-host |
| Many tools exposed | more capability | model confusion, attack surface |
| Third-party servers | speed to value | supply-chain/security risk |

---

## 16. When NOT to use it
- **A single app with one or two fixed tools** → native function calling is simpler; MCP adds protocol overhead.
- **Ultra-low-latency inner loops** → the extra hop/round-trips may not be worth it.
- **You don't control/ trust the servers** and can't vet them → security risk outweighs convenience.
- **Purely deterministic pipelines** with no model-driven tool choice → use a plain SDK/workflow.
- **Very early prototype** where portability isn't yet a concern → start simple, adopt MCP as integrations multiply.

---

## 17. Comparison with Alternatives
| Approach | Standard? | Discovery | Portable across hosts | Best for |
|----------|-----------|-----------|----------------------|----------|
| Native function calling | No (per SDK) | Manual (you code schemas) | No | 1 app, few tools |
| Custom API glue | No | None | No | one-off integrations |
| Plugins (per-vendor) | Vendor-specific | Vendor registry | No | that vendor's ecosystem |
| **MCP** | **Yes (open)** | **Built-in (list)** | **Yes** | reusable tool/data catalog |
| LangChain tools | Framework-specific | Framework | Only within framework | LangChain apps |

---

## 18. Interview Questions
1. What problem does MCP solve, and why isn't function calling enough?
2. Explain the M×N → M+N integration argument.
3. What are MCP's three primitives and how do they differ?
4. Client vs Host vs Server — draw the architecture.
5. stdio vs HTTP/SSE transport — when each?
6. What are the main security risks of MCP and how do you mitigate them?
7. Where is the trust boundary in an MCP architecture?
8. How do you secure a remote MCP server in an enterprise?
9. How do you scale and make remote MCP servers highly available?
10. When would you NOT use MCP?

---

## 19. Strong Interview Answers
- **Why MCP**: "Function calling lets a model emit a structured call, but there was no standard for how tools are described, discovered, transported, or secured across apps. MCP standardizes that — one server, any compliant host — turning M×N bespoke integrations into M+N. It's USB-C for AI tools."
- **Primitives**: "Tools are model-invokable actions with side effects; Resources are read-only context by URI; Prompts are reusable templates the server offers. Actions vs data vs templates — different trust and UX handling for each."
- **Security**: "MCP is a prime injection and confused-deputy surface. The host is the trust boundary — I enforce authZ, allow-lists, and approvals there; authenticate remote servers with OAuth/Entra; scope each server's backend credential to least privilege; and treat all tool results and server-provided descriptions as untrusted, validating before use. Third-party servers are supply-chain risk, so I vet, pin, and sandbox."
- **Transport**: "stdio for local, sandboxed, low-latency servers bound to one host; HTTP/streamable for shared, scalable, networked servers behind a gateway with auth."
- **When not**: "One app with a couple of fixed tools — native function calling is simpler. MCP pays off when integrations multiply and need to be reused across many hosts."

---

## 20. Architecture Diagrams
**M×N vs M+N:**
```
Without MCP:  Models ─┬─┬─┬─ Tools   (every pair = custom glue = M×N)
With MCP:     Models ─► MCP ◄─ Tools  (each side once = M+N)
```
**Primitives:**
```
MCP Server
 ├─ Tools     → actions (side effects)   e.g., create_issue
 ├─ Resources → read-only context (URI)  e.g., file://policy.pdf
 └─ Prompts   → reusable templates       e.g., "summarize_ticket"
```

---

## 21. Real Project Example
**Developer copilot with internal MCP catalog.** The engineering org built MCP servers for GitHub, the internal service registry, Azure (scoped ARM ops), and the observability platform. Developers' IDE copilots connect to all four via MCP. A developer can ask the copilot to "find the failing service, open its runbook, and create a Jira ticket" — the copilot uses GitHub (Resources), observability (Tools), and Jira (Tools) servers through one protocol. New capability = one new server, instantly available to every developer, all calls audited centrally through APIM.

---

## 22. Whiteboard Design Question
> *"Design an enterprise MCP platform so any internal copilot/agent can safely use our systems (SharePoint, SQL, ServiceNow, internal APIs)."*

Cover: catalog of MCP servers (one per system) → transport choice (HTTP for shared, stdio for local) → gateway (APIM/Front Door + WAF + OAuth/Entra) → per-server least-privilege Managed Identity → host as trust boundary (allow-lists, approvals, injection filters) → discovery caching → observability/audit per call → HA (multi-replica + circuit breakers) + DR (IaC redeploy) → governance (server vetting, version pinning). Emphasize **decoupling** and **write-once reuse**.

---

## 23. Design Review Questions
- Which systems become **servers**, and what **primitives** (tools/resources/prompts) does each expose?
- **stdio or HTTP** per server, and why?
- How are **remote servers authenticated** and their backend creds **scoped**?
- Where do **allow-lists and approval gates** live (host)?
- How do you defend against **tool poisoning / injection / confused deputy**?
- How are **third-party servers vetted** and version-pinned?
- What's the **observability/audit** story per call?
- **HA/DR** for remote servers?

---

## 24. Hands-on Example
```python
# Minimal MCP server exposing one Tool and one Resource (Python SDK, FastMCP style)
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("orders-server")

@mcp.tool()
def get_order_status(order_id: str) -> str:
    """Return the status of an order by ID."""     # description matters — the model reads this
    return db_lookup_status(order_id)               # scoped, read-only backend call

@mcp.resource("orders://recent")
def recent_orders() -> str:
    """Read-only context: recent orders as text."""
    return format_orders(db_recent_orders(limit=20))

if __name__ == "__main__":
    mcp.run(transport="stdio")   # local, sandboxed; use "streamable-http" for remote
```

---

## 25. Terraform Example
```hcl
# Remote MCP server on Container Apps: scaled, private, scoped identity
resource "azurerm_container_app" "mcp_orders" {
  name                         = "mcp-orders-server"
  resource_group_name          = var.rg
  container_app_environment_id = var.cae_id
  revision_mode                = "Single"

  identity { type = "SystemAssigned" }

  template {
    min_replicas = 2                       # HA
    max_replicas = 10
    container {
      name   = "mcp-orders"
      image  = "${var.acr}/mcp-orders:1.4.0"   # version-pinned
      cpu    = 0.5
      memory = "1Gi"
      env { name = "TRANSPORT" value = "streamable-http" }
    }
  }
  ingress { external_enabled = false target_port = 8080     # internal only; expose via APIM
            traffic_weight { percentage = 100 latest_revision = true } }
}

# Least-privilege: this server can only read its own SQL database
resource "azurerm_role_assignment" "mcp_sql" {
  scope                = var.orders_sql_id
  role_definition_name = "SQL DB Contributor"
  principal_id         = azurerm_container_app.mcp_orders.identity[0].principal_id
}
```

---

## 26. Azure Example
```bash
# Publish a remote MCP server and front it with APIM (auth + rate limit)
az containerapp create -n mcp-orders-server -g rg \
  --environment cae --image myacr.azurecr.io/mcp-orders:1.4.0 \
  --system-assigned --min-replicas 2 --max-replicas 10 \
  --ingress internal --target-port 8080 --env-vars TRANSPORT=streamable-http

# Import as an API in APIM so hosts authenticate via Entra ID and get rate limiting/audit
az apim api create -g rg --service-name my-apim \
  --api-id mcp-orders --path mcp/orders --display-name "MCP Orders" \
  --service-url https://mcp-orders-server.internal:8080 --protocols https
```

---

## 27. Code Example
```python
# Host-side: connect to an MCP server, discover tools, enforce an allow-list, call one
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

ALLOWED = {"get_order_status"}   # host is the trust boundary

async def use_orders_server(url, token):
    async with streamablehttp_client(url, headers={"Authorization": f"Bearer {token}"}) as (r, w, _):
        async with ClientSession(r, w) as s:
            await s.initialize()                       # handshake + capability negotiation
            tools = await s.list_tools()               # discovery
            safe = [t for t in tools.tools if t.name in ALLOWED]   # allow-list guard
            result = await s.call_tool("get_order_status", {"order_id": "A-1001"})
            audit_log("mcp_call", server=url, tool="get_order_status")  # full audit
            return result.content
```

---

## 28. Things Architects Must Remember
- **MCP = "USB-C for AI"**: one standard so tools are **write-once, reuse-everywhere** (M+N, not M×N).
- **Three primitives**: **Tools** (actions), **Resources** (read-only data), **Prompts** (templates).
- **The host is the trust boundary** — authZ, allow-lists, approvals live there, not in the server.
- **Servers and their outputs are untrusted** — injection, tool-poisoning, confused-deputy are the top risks.
- **Least privilege per server** — each gets a narrowly scoped credential.
- **Third-party servers = supply-chain risk** — vet, pin, sandbox.
- **stdio = local/sandboxed; HTTP = shared/scalable behind a gateway with OAuth/Entra.**
- **It's an integration standard, not a model feature** — it complements (doesn't replace) function calling.

---

## 29. Mnemonics and Memory Tricks
- **"USB-C for AI"** — one connector, many devices.
- **"T-R-P"** = the three primitives: **T**ools, **R**esources, **P**rompts (Actions, Data, Templates).
- **"H-C-S"** = the roles: **H**ost, **C**lient, **S**erver.
- **"M+N not M×N"** — the whole reason MCP exists.
- **Security = "V-P-S"**: **V**et servers, **P**in versions, **S**andbox — and *host holds the keys*.

---

## 30. One-Page Interview Revision Sheet
- **What**: open standard (JSON-RPC) for connecting AI hosts to tools/data/context — "USB-C for AI."
- **Why**: turns M×N bespoke integrations into **M+N**; makes tools discoverable + portable across hosts.
- **Roles**: **Host** (AI app) → **Client** (connector) → **Server** (exposes capabilities to a backend).
- **Primitives**: **Tools** (actions), **Resources** (read-only context by URI), **Prompts** (templates).
- **Transport**: **stdio** (local/sandboxed) · **HTTP/SSE/streamable** (remote/scalable).
- **Security**: host = trust boundary; OAuth/Entra for remote servers; least-privilege per server; treat outputs as untrusted (injection/tool-poisoning/confused-deputy); vet+pin+sandbox third-party servers; audit every call.
- **Scale/HA**: stateless remote servers, multi-replica behind APIM, cache discovery, circuit breakers.
- **DR**: IaC redeploy, version-pinned images in geo-replicated ACR, repoint endpoints.
- **Cost**: reuse over rebuild, cache reads, scope resources to keep tokens small.
- **When NOT**: single app w/ few fixed tools, ultra-low latency, untrustable servers.
- **Remember**: *USB-C for AI*, **T-R-P**, **H-C-S**, *M+N not M×N*, *host holds the keys*.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Explain MCP to a skeptical staff engineer who says "we already have function calling."
2. Draw and label the Host / Client / Server architecture and the transport options.
3. Define Tools, Resources, and Prompts — and give a security reason to handle each differently.
4. Where is the trust boundary in MCP, and what security controls live there vs in the server?
5. A team wants to add three community MCP servers from GitHub. What's your review checklist?
6. Describe a tool-poisoning / confused-deputy attack via MCP and your mitigations.
7. When would you choose stdio over HTTP transport, with a concrete example each?
8. Design least-privilege auth for five remote MCP servers backing five different systems.
9. How do you make a fleet of remote MCP servers HA and DR-ready on Azure?
10. Give two concrete situations where adopting MCP would be the wrong call.

---

> Next Phase 1 topic: **Semantic Kernel** (last in Phase 1). Say **continue** to generate it.
