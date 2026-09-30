# 13 · MCP (Model Context Protocol)

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
MCP is an **open standard that lets AI apps connect to tools and data in a uniform way** — like "USB-C for AI." Instead of custom integrations per tool, servers expose capabilities and any MCP-aware client (Copilot, Claude, agents) can use them.

## 2. Architect-Level Explanation
A client–server protocol (JSON-RPC over stdio or HTTP/SSE) standardizing how models access context:
- **Primitives**: **Tools** (callable functions), **Resources** (readable data/context), **Prompts** (reusable templates).
- **Roles**: **Host/Client** (the AI app) ↔ **MCP Server** (exposes tools/resources).
- **Transport**: stdio (local) or streamable HTTP/SSE (remote).
- **Value**: decouples model apps from integrations (N clients × M servers instead of N×M bespoke connectors); reusable, discoverable, governable.
- Enterprise concerns: auth (OAuth), least-privilege tool exposure, injection defense, and server governance.

## 3. Real Enterprise Use Case
A company builds one MCP server exposing Jira, Confluence, and internal APIs. Their Copilot, a custom agent, and IDE assistants all consume the same server — one integration, many clients, centrally governed and audited.

## 4. Architecture Diagram (ASCII)
```
   AI Hosts (Clients)                MCP Servers
   ┌─────────────┐   JSON-RPC   ┌──────────────────┐
   │ Copilot     │◄────────────►│ Jira server      │
   │ Custom agent│◄────────────►│ DB/Files server  │
   │ IDE assistant│◄───────────►│ Internal API srv │
   └─────────────┘  tools/       └──────────────────┘
                    resources/       │
                    prompts     backend systems (auth/OAuth)
```

## 5. Interview Questions
1. What problem does MCP solve?
2. Tools vs Resources vs Prompts?
3. MCP vs plain function calling?
4. How do you secure an MCP server in enterprise?
5. stdio vs HTTP transport — when each?

## 6. Strong Interview Answers
- **Problem**: "It kills the N×M integration problem. Any MCP client can use any MCP server, so tools/data are built once and reused across all AI apps — standardized, discoverable, governable."
- **Primitives**: "Tools are model-callable actions; Resources are readable context (files, records); Prompts are reusable templates the server offers. Together they cover 'do', 'read', and 'guide'."
- **vs function calling**: "Function calling is model-specific wiring inside one app; MCP standardizes and externalizes those tools so many apps share them over a protocol — interoperability and governance, not just calling."
- **Security**: "OAuth-based auth, least-privilege tool scopes, allow-listing servers, validating tool inputs (injection), audit logging, and running servers in controlled networks."
- **Transport**: "stdio for local/desktop tools; streamable HTTP/SSE for remote, multi-user, scalable servers."

## 7. Common Mistakes
- Exposing over-broad tools (excessive privilege).
- Trusting server/tool outputs blindly (injection).
- No auth on remote MCP servers.
- Treating MCP as a model feature vs an integration standard.

## 8. Trade-offs
| Aspect | MCP | Bespoke integration |
|--------|-----|---------------------|
| Reuse across apps | high | low |
| Standardization | high | none |
| Initial setup | protocol overhead | quick one-off |
| Governance | centralized | scattered |

## 9. Production Best Practices
- One well-governed server per domain; least-privilege tools.
- OAuth + audit + rate limits on remote servers.
- Validate/schema tool inputs; sandbox risky actions.
- Version tools/resources; document capabilities.
- Monitor usage and errors centrally.

## 10. Security Considerations
- Prompt injection via resources/tool outputs — treat as untrusted.
- Strong auth (OAuth) + scoped tokens per client.
- Network isolation (private endpoints) for internal servers.
- Full audit trail of tool invocations.

## 11. Cost Optimization
- Reuse one server across many clients (build once).
- Cache resource reads; paginate large resources.
- Keep tool schemas lean to reduce token overhead.

## 12. Troubleshooting Scenarios
- **Client can't see tools** → server capability advertisement/handshake.
- **Auth failures** → OAuth scopes/token audience.
- **Injection behavior** → validate/sanitize resource content, guardrails.
- **Latency** → transport choice, caching, server scaling.

## 13. Hands-on Example (Python MCP server)
```python
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("jira")

@mcp.tool()
def get_issue(key: str) -> dict:
    """Fetch a Jira issue by key."""
    return jira_client.issue(key)

if __name__ == "__main__":
    mcp.run()   # stdio transport
```

## 14. Terraform Example
```hcl
# Host a remote MCP server as a Container App with Managed Identity
resource "azurerm_container_app" "mcp" {
  name = "mcp-jira" resource_group_name = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode = "Single"
  identity { type = "SystemAssigned" }
  template { container { name = "mcp" image = "myacr.azurecr.io/mcp-jira:1.0"
    cpu = 0.5 memory = "1Gi" } }
}
```

## 15. Azure Example
Expose an internal MCP server via Azure API Management (OAuth, rate limiting, logging) in front of a Container App; clients (Copilot/agents) connect over HTTPS.

## 16. FastAPI / Python Example
```python
# Bridging: a FastAPI agent acting as an MCP client
from mcp import ClientSession
async def call_tool(name: str, args: dict):
    async with ClientSession(transport) as session:
        await session.initialize()
        return await session.call_tool(name, args)
```

## 17. AKS Example
Run MCP servers as Deployments in AKS behind an internal ingress; Workload Identity for backend auth; APIM/OAuth for client auth; scale with HPA per server.

## 18. How to Remember
**"USB-C for AI tools."** One standard plug; any AI app connects to any tool/data source.

## 19. Real-World Analogy
Power outlets with a universal standard: appliance makers (servers) and devices (clients) don't need custom wiring — plug in and it works, with the building's fuse box (auth/governance) controlling access.

## 20. One-Page Cheat Sheet
- **What**: open protocol standardizing AI ↔ tools/data ("USB-C for AI").
- **Primitives**: Tools (do), Resources (read), Prompts (guide).
- **Roles**: Host/Client ↔ MCP Server; transport stdio or HTTP/SSE.
- **Value**: solves N×M integrations; build once, reuse everywhere.
- **Secure**: OAuth, least-privilege tools, validate inputs, audit.
- **vs function calling**: interoperable/external standard vs in-app wiring.
