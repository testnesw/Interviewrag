# Deep Dive · Semantic Kernel

> Phase 1 (Highest ROI) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Semantic Kernel (SK) is **Microsoft's open-source orchestration SDK** for building enterprise AI applications and agents. It sits **between your app and the LLM**, giving you a clean way to combine **prompts, native code functions (plugins), memory, planning, and function calling** into production workflows. Think of it as the **"AI orchestration layer"** — the kernel is a dependency-injection container that connects models, plugins, and services. It's **enterprise-first** (C#, Python, Java), model-agnostic, and designed to slot into existing Microsoft stacks with telemetry, DI, and security built in. Its role in GenAI architecture is the **orchestration layer** (the same slot LangChain fills), but with a Microsoft/enterprise flavor.

---

## 2. Architect-Level Explanation
SK's core abstraction is the **Kernel** — a lightweight container that holds:
- **AI services**: chat/completion, embeddings (Azure OpenAI, OpenAI, others) — model-agnostic connectors.
- **Plugins**: collections of **functions** the model can call. Two kinds:
  - **Native functions**: real C#/Python methods (call APIs, DBs, business logic).
  - **Prompt functions** (semantic functions): parameterized prompt templates treated as callable functions.
- **Memory**: embeddings + vector stores for semantic recall (RAG).
- **Planners / function calling**: let the LLM **choose and chain functions** automatically to satisfy a goal (agentic behavior).
- **Filters & telemetry**: cross-cutting hooks for security, logging, and responsible AI.

Architecturally, SK is the **orchestration/composition layer**: it decouples your app from a specific model, standardizes how prompts + code + data combine, and provides the **agent runtime** (via the newer Agent Framework). The value is **enterprise integration** — DI, .NET-native, OpenTelemetry, filters for governance — not raw model power.

---

## 3. Why It Exists
- **Problem before**: teams hand-wired prompt strings, HTTP calls to the model, ad-hoc function calling, and bespoke memory — brittle, untestable, not enterprise-grade.
- **Why not just call the API?**: raw API calls don't give you plugin composition, planning, memory, DI, telemetry, or model portability.
- **Why not only LangChain?**: LangChain is Python-first and community-driven; **enterprises on .NET/Java** needed a **first-party, supported, DI-friendly** orchestration SDK with Microsoft's security/telemetry conventions.
- **Why enterprises adopt it**: it fits naturally into existing **ASP.NET / Azure** apps, gives a **stable, supported** orchestration layer, and unifies prompts + native code + agents behind clean abstractions with governance hooks.

---

## 4. Internal Working
**Flow: build kernel → register services + plugins → invoke (with auto function calling) → filters/telemetry wrap everything.**

1. **Kernel construction**: register AI service connectors (e.g., Azure OpenAI chat) + plugins into the DI container.
2. **Plugins/functions**: each function has a **name, description, and typed parameters** — the description is what the LLM reads to decide when to call it (like MCP/function calling).
3. **Invocation**: you send a prompt/chat history. With **automatic function calling** enabled, SK:
   - sends the prompt + function schemas to the model,
   - if the model requests a function, SK **executes the native/prompt function**, feeds the result back, and loops until the model returns a final answer (an agent loop).
4. **Prompt templating**: prompts support variables, and can call other functions inline.
5. **Memory**: text is embedded and stored/retrieved from a vector store for RAG-style grounding.
6. **Filters**: **function-invocation filters** and **prompt-render filters** intercept calls for auth, PII scrubbing, content safety, logging (cross-cutting concerns).
7. **Telemetry**: emits **OpenTelemetry** traces/metrics (tokens, latency) out of the box.
8. **Agent Framework**: higher-level agents (ChatCompletionAgent, Azure AI Agent) + multi-agent orchestration built on the kernel.

Key property: SK **mediates** model↔tools, so **governance and observability are centralized** in filters/telemetry.

---

## 5. Enterprise Use Case
A manufacturer builds an **operations copilot** on ASP.NET Core with SK. Native plugins wrap the ERP API, the maintenance-ticket system, and an inventory DB; a prompt function summarizes work orders; **memory** provides RAG over equipment manuals via Azure AI Search. With **automatic function calling**, an engineer asks "why is line 3 down and what parts do I need?" — SK orchestrates: retrieve manual (memory) → call telemetry plugin → check inventory plugin → draft answer. **Filters** enforce Entra-based authorization per plugin and scrub PII from logs; **OpenTelemetry** feeds App Insights for cost/latency.

---

## 6. Real Production Architecture
```
   User (Entra ID) ─► Front Door(WAF) ─► APIM (authN, token quota)
        │
        ▼
   ASP.NET Core / FastAPI app  ── hosts ──►  Semantic Kernel
   │   Kernel (DI container)
   │    ├─ AI Service: Azure OpenAI (chat + embeddings) [Managed Identity]
   │    ├─ Plugins (native): ERP API · Tickets · Inventory (scoped MI each)
   │    ├─ Prompt functions: summarize, classify, draft
   │    ├─ Memory: embeddings → Azure AI Search (RAG)
   │    ├─ Auto function calling (agent loop)
   │    └─ Filters: authZ · PII scrub · Content Safety · logging
        │  Managed Identity (no keys)
        ▼
   Azure OpenAI (Private Endpoint)  +  Azure AI Search (Private Endpoint)
        │
        ▼
   Observability: OpenTelemetry ─► App Insights (tokens, latency, cost, traces)
   Secrets: Key Vault · Audit: Log Analytics
```

---

## 7. Security Best Practices
- **Managed Identity** to Azure OpenAI / Search — no API keys; secrets (if any) in **Key Vault**.
- **Function-invocation filters as a policy layer**: enforce Entra-based authorization *before* a plugin runs; block/redact based on user role.
- **Least privilege per plugin**: each native plugin's backend credential scoped to only what it needs.
- **Treat model-selected function args and tool/memory results as untrusted** — validate args in native functions; SK is a prompt-injection surface like any function-calling system.
- **Content Safety** via filters on inputs and outputs; **PII scrubbing** in prompt-render/logging filters.
- **Human-in-the-loop** for high-impact plugin actions (gate in a filter).
- **Private Endpoints** for AOAI + Search; **audit** every function invocation with correlation IDs.

---

## 8. Scaling Strategy
- **SK is stateless per request** (kernel is cheap to build; state = chat history you pass in) → scale the host app horizontally (HPA on AKS / Container Apps).
- **Keep conversation state external** (Redis/Cosmos), not in memory.
- **Model capacity**: PTUs for steady load, Pay-as-you-go for burst; **route** cheap models for simple functions, premium for planning.
- **Cap auto-function-calling iterations** (like agent step limits) to bound cost/latency.
- **Cache** prompt-function results and embeddings/RAG where safe.

---

## 9. High Availability Strategy
- **Multi-replica, multi-AZ** host behind a load balancer.
- **Multi-region Azure OpenAI** with retry + failover; SK connectors support custom retry/backoff (429 handling).
- **Circuit breakers/timeouts** in native plugins wrapping downstream systems.
- **Graceful degradation**: skip an unavailable plugin, return partial + escalate, rather than fail the whole request.

---

## 10. Disaster Recovery Strategy
- **Externalized state** (chat history, memory index) replicated → resume in secondary region.
- **IaC (Terraform/Bicep)** to redeploy app + AOAI + Search quickly.
- **Replicate the vector index/embeddings**; version prompt templates and plugins in source control for consistent recovery.
- **Runbooks** for AOAI region failover and connector re-pointing; define RTO/RPO.

---

## 11. Cost Optimization Strategy
- **Cap function-calling loop iterations** — runaway auto-invocation is the top cost risk (same as agents).
- **Model routing**: small/cheap model for routine prompt functions; premium only for planning/hard tasks.
- **Token discipline**: trim chat history (summarize), retrieve top-k only, keep plugin outputs small before feeding back.
- **Cache** deterministic prompt-function results and RAG retrievals.
- **FinOps**: OpenTelemetry token metrics → cost dashboards; tag by app/tenant; alert on anomalies.

---

## 12. Common Production Challenges
- **Runaway auto-function-calling loops** → iteration caps + budgets.
- **Model picks wrong/nonexistent function** → sharpen function names/descriptions/schemas; add examples.
- **Prompt injection** via memory/plugin results hijacking function choice → validate + filters + human gates.
- **Version churn**: SK evolved fast (planners → Agent Framework) → pin versions, follow migration guidance.
- **Context bloat** from long histories → summarize/trim.
- **Latency** from multi-hop function calls → parallelize independent plugins, stream responses.
- **Testing non-determinism** → filters + eval harness with replay.

---

## 13. Monitoring and Observability
- **Built-in OpenTelemetry**: traces per function invocation, token usage, latency, model calls → App Insights.
- **KPIs**: functions-called-per-request, function error rate, tokens/cost per request, p95 latency, loop-iteration counts.
- **Quality evals**: groundedness/relevance/goal completion; gate prompt/plugin changes on them.
- **Security signals**: filter blocks (authZ/PII/Content Safety), injection triggers.
- **Alerts**: iteration-cap hits, cost anomalies, plugin failure spikes.

---

## 14. Troubleshooting Scenarios
- **Function never called** → weak description/schema or auto-calling disabled; improve metadata, verify settings.
- **Wrong function/args** → tighten parameter typing/descriptions; add few-shot; validate in native code.
- **Loop won't stop / high cost** → set max iterations; inspect traces for repeated calls.
- **AuthZ leak (plugin ran for wrong user)** → move the check into a function-invocation filter, not inside the plugin only.
- **429s / throttling** → configure retry/backoff on the connector; add PTUs or multi-region.
- **PII in logs** → add/verify prompt-render + logging filters that scrub before emit.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| SK vs raw API | composition, memory, agents, telemetry | learning curve, abstraction |
| SK vs LangChain | enterprise/.NET, supported, DI | smaller ecosystem than LC (Python) |
| Auto function calling | agentic, flexible | cost/latency/non-determinism |
| Prompt functions | reusable, testable | still probabilistic |
| Filters everywhere | central governance | added complexity |

---

## 16. When NOT to use it
- **A single prompt call** with no tools/memory → just call the model API; SK is overkill.
- **Heavy Python-only, community-plugin-driven** projects where LangChain/LlamaIndex ecosystem fits better.
- **Ultra-simple prototypes** where the abstraction slows you down.
- **Non-.NET shops with no need for Microsoft-first tooling** and a strong existing Python stack — evaluate LangChain/LlamaIndex.
- **Pure RAG with no orchestration** → a thin retrieval + prompt layer may be simpler.

---

## 17. Comparison with Alternatives
| Framework | Primary langs | Strength | Best for |
|-----------|---------------|----------|----------|
| **Semantic Kernel** | C#, Python, Java | enterprise, DI, telemetry, MS-first | .NET/Azure enterprise apps + agents |
| LangChain | Python (JS) | huge ecosystem, integrations | fast Python prototyping, many connectors |
| LlamaIndex | Python | data/RAG-centric | advanced retrieval/indexing |
| AutoGen | Python | multi-agent research | complex multi-agent experiments |
| Raw SDK (openai) | any | minimal, full control | simple single-call apps |

> Note: Microsoft is converging **Semantic Kernel + AutoGen** into a unified **Agent Framework** — SK is the enterprise-supported path.

---

## 18. Interview Questions
1. What is Semantic Kernel and where does it sit in a GenAI architecture?
2. Native functions vs prompt (semantic) functions — difference and when to use each?
3. How does automatic function calling work, and how do you keep it safe/cheap?
4. What are filters, and why are they architecturally important?
5. Semantic Kernel vs LangChain — when do you pick which?
6. How does SK handle memory / RAG?
7. How do you secure plugins in an enterprise SK app?
8. How do you add observability and cost control?
9. What's the Agent Framework and how does SK relate to AutoGen?
10. How do you make an SK app HA and DR-ready?

---

## 19. Strong Interview Answers
- **What/where**: "SK is Microsoft's open-source orchestration SDK — the layer between my app and the model. The kernel is a DI container holding AI services, plugins, memory, and function calling. It's the same architectural slot as LangChain but enterprise-first for .NET/Azure with built-in telemetry and governance filters."
- **Native vs prompt functions**: "Native functions are real code — call APIs, DBs, business logic. Prompt functions are parameterized prompt templates treated as callable units. I use native for actions/integration, prompt functions for reusable LLM tasks like summarize/classify. The model can chain both via function calling."
- **Filters**: "Filters are cross-cutting interceptors around function invocation and prompt rendering. They're where I centralize authorization, PII scrubbing, Content Safety, and logging — so governance isn't scattered across plugins. That's the enterprise selling point."
- **SK vs LangChain**: "LangChain for Python-first, fast prototyping with a massive connector ecosystem. SK for enterprise .NET/Azure apps needing first-party support, DI, and telemetry conventions. I choose by team stack and support requirements, not hype."
- **Safe auto-calling**: "It's an agent loop, so same rules: cap iterations, validate model-chosen args, gate high-impact plugins with human approval in a filter, and treat memory/plugin outputs as untrusted to defend against injection."

---

## 20. Architecture Diagrams
**Kernel composition:**
```
        ┌──────────────── Kernel (DI) ────────────────┐
Prompt ─►│ AI Service (Azure OpenAI)                   │─► Answer
         │ Plugins: [native fns] [prompt fns]          │
         │ Memory (embeddings → vector store / RAG)    │
         │ Auto function calling (loop)                │
         │ Filters: authZ · PII · Content Safety · log │
         └─────────────────────────────────────────────┘
```
**Auto function-calling loop:**
```
Prompt+schemas ─► LLM ─► (function call?) ─► SK executes fn ─► result
      ▲                                                        │
      └──────────────── feed back, loop (capped) ◄─────────────┘
                         └► final answer
```

---

## 21. Real Project Example
**Insurance claims copilot (.NET).** Built on ASP.NET Core + SK. Native plugins wrap the policy API, fraud-scoring service, and claims DB; prompt functions classify claim type and draft decisions; memory does RAG over policy documents in Azure AI Search. Auto function calling orchestrates the multi-step flow. A **function-invocation filter** enforces Entra role checks and routes any high-value claim to a human approval step; another filter scrubs PII before logging. OpenTelemetry streams token/latency/cost to App Insights. Outcome: faster claims handling, centralized governance, full audit — all within the existing .NET/Azure estate.

---

## 22. Whiteboard Design Question
> *"Design an enterprise copilot on Semantic Kernel that answers questions and takes actions across three internal systems, at scale."*

Cover: host (ASP.NET/FastAPI) + kernel with Azure OpenAI connector (Managed Identity) → native plugins per system (scoped MI each) + prompt functions → memory/RAG via Azure AI Search → auto function calling with iteration caps → filters for authZ/PII/Content Safety/human-gates → external state (Redis) for scale → OpenTelemetry → App Insights → HA (multi-region AOAI, retries) + DR (IaC, replicated index) → cost (model routing, token trim, caps). State trade-offs (SK vs LangChain, auto-calling cost) explicitly.

---

## 23. Design Review Questions
- Which capabilities are **native functions** vs **prompt functions**, and why?
- Is **automatic function calling** on, and what's the **iteration cap**?
- Where do **authZ, PII, and Content Safety** live? (Answer: filters.)
- How is each plugin's backend credential **scoped**?
- How do you defend against **prompt injection** via memory/plugin outputs?
- Where is **conversation state** stored for horizontal scale?
- What's the **observability + cost** story (OpenTelemetry → App Insights)?
- **SK version** pinned? Migration plan to the Agent Framework?

---

## 24. Hands-on Example
```csharp
// C#: build a kernel, add a native plugin, enable auto function calling
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.OpenAI;

var builder = Kernel.CreateBuilder();
builder.AddAzureOpenAIChatCompletion(
    deploymentName: "gpt-4o",
    endpoint: cfg["AOAI:Endpoint"],
    credentials: new DefaultAzureCredential());   // Managed Identity, no keys
builder.Plugins.AddFromType<InventoryPlugin>();    // native plugin
var kernel = builder.Build();

var settings = new OpenAIPromptExecutionSettings {
    ToolCallBehavior = ToolCallBehavior.AutoInvokeKernelFunctions   // agent loop
};
var result = await kernel.InvokePromptAsync(
    "Do we have part X-42 in stock, and what's its status?", new(settings));

public sealed class InventoryPlugin {
    [KernelFunction, Description("Get stock count for a part number.")]  // model reads this
    public int GetStock([Description("Part number")] string partNo)
        => _db.StockFor(partNo);   // validate args; scoped, least-privilege backend
}
```

---

## 25. Terraform Example
```hcl
# Host the SK app on Container Apps with system-assigned identity + scoped AOAI access
resource "azurerm_container_app" "sk_copilot" {
  name                         = "sk-copilot"
  resource_group_name          = var.rg
  container_app_environment_id = var.cae_id
  revision_mode                = "Single"
  identity { type = "SystemAssigned" }

  template {
    min_replicas = 2
    max_replicas = 15
    container {
      name   = "copilot"
      image  = "${var.acr}/sk-copilot:2.1.0"          # pinned SK app version
      cpu    = 1.0
      memory = "2Gi"
      env { name = "AOAI__Endpoint"        value = var.aoai_endpoint }
      env { name = "MaxFunctionCallIters"  value = "5" }   # cap the loop
    }
  }
  ingress { external_enabled = true target_port = 8080
            traffic_weight { percentage = 100 latest_revision = true } }
}

# Least-privilege: app identity may only *use* Azure OpenAI
resource "azurerm_role_assignment" "sk_aoai" {
  scope                = var.aoai_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_container_app.sk_copilot.identity[0].principal_id
}
```

---

## 26. Azure Example
```bash
# Deploy the SK copilot and grant its Managed Identity data-plane access to AOAI + Search
az containerapp create -n sk-copilot -g rg \
  --environment cae --image myacr.azurecr.io/sk-copilot:2.1.0 \
  --system-assigned --min-replicas 2 --max-replicas 15 \
  --env-vars AOAI__Endpoint=$AOAI MaxFunctionCallIters=5

MI=$(az containerapp show -n sk-copilot -g rg --query identity.principalId -o tsv)
az role assignment create --assignee $MI --role "Cognitive Services OpenAI User" \
  --scope $(az cognitiveservices account show -n my-aoai -g rg --query id -o tsv)
az role assignment create --assignee $MI --role "Search Index Data Reader" \
  --scope $(az search service show -n my-search -g rg --query id -o tsv)
```

---

## 27. Code Example
```python
# Python: a function-invocation filter enforcing authZ + human gate on high-impact plugins
from semantic_kernel.filters import FunctionInvocationContext

HIGH_IMPACT = {"IssueRefund", "DeleteRecord"}

async def governance_filter(context: FunctionInvocationContext, next):
    user = context.arguments.get("user_ctx")
    if not is_authorized(user, context.function.name):          # authZ before execution
        context.result = "Denied: not authorized"
        return
    if context.function.name in HIGH_IMPACT:
        if not await request_human_approval(context.function.name, context.arguments):
            context.result = "Rejected by reviewer"
            return
    await next(context)                                          # proceed
    audit_log(context.function.name, user)                       # full audit trail

kernel.add_function_invocation_filter(governance_filter)
```

---

## 28. Things Architects Must Remember
- **SK is the orchestration layer** — the DI container wiring models + plugins + memory + agents.
- **Two function types**: **native** (code/actions) vs **prompt** (templated LLM tasks) — the model can chain both.
- **Filters are the governance seam** — put authZ, PII, Content Safety, and human gates there, centrally.
- **Auto function calling is an agent loop** — cap iterations, validate args, gate high-impact actions.
- **Enterprise-first vs LangChain** — pick by stack (.NET/Azure + support) not hype.
- **Model-agnostic** via connectors — don't hard-couple to one model.
- **OpenTelemetry is built in** — use it for cost/latency/quality from day one.
- **Converging into the Agent Framework** (SK + AutoGen) — pin versions, plan migration.

---

## 29. Mnemonics and Memory Tricks
- **"Kernel = engine block"**: services (fuel), plugins (parts), memory (fuel tank), filters (safety systems).
- **"N-P" functions**: **N**ative (code) vs **P**rompt (template).
- **Governance = "A-P-C-H"** in filters: **A**uthZ, **P**II, **C**ontent Safety, **H**uman gate.
- **SK vs LangChain**: *".NET & supported → SK; Python & ecosystem → LangChain."*
- **Auto-calling safety**: *"Cap the loop, validate the args, gate the risky."*

---

## 30. One-Page Interview Revision Sheet
- **What**: Microsoft's open-source **orchestration SDK** (C#/Python/Java); kernel = DI container for AI.
- **Holds**: AI services (model-agnostic connectors) · plugins (native + prompt functions) · memory (RAG) · function calling (agent loop) · filters · telemetry.
- **Why**: enterprise-first orchestration for .NET/Azure — supported, DI-friendly, OpenTelemetry + governance built in.
- **Security**: Managed Identity, **filters** for authZ/PII/Content Safety/human-gates, least-privilege plugins, untrusted tool/memory outputs (injection), Private Endpoints, audit.
- **Scale**: stateless per request + HPA, external state, model routing, cap function-call iterations, cache.
- **HA/DR**: multi-region AOAI + retries, circuit breakers, IaC redeploy, replicated index, RTO/RPO.
- **Cost**: cap loops, route models, trim tokens/history, cache, OpenTelemetry cost dashboards.
- **vs LangChain**: SK = enterprise/.NET/supported; LangChain = Python/ecosystem/prototyping.
- **When NOT**: single prompt call, Python-only ecosystem-heavy work, ultra-simple prototypes.
- **Remember**: *orchestration layer*, *native vs prompt functions*, *filters = governance seam*, *auto-calling = agent loop → cap it*, converging into the **Agent Framework**.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Position Semantic Kernel in a full GenAI architecture — what layer is it, and what does it replace?
2. Native vs prompt functions: give a concrete example of each and why you'd choose it.
3. Walk through automatic function calling end-to-end. Where are the cost and safety risks?
4. What are filters, and why are they the single most important enterprise feature of SK?
5. A stakeholder asks "why SK instead of LangChain?" Give a decision framework, not a preference.
6. How does SK do memory/RAG, and how do you keep retrieved content from hijacking function choice?
7. Design plugin authorization so an action runs only for entitled users — where does the check live?
8. Your SK app's token cost spiked — auto function calling is looping. How did you prevent it, and how do you diagnose it?
9. How do you make an SK-based copilot HA across two regions with a defined RPO?
10. What is the Agent Framework, how does SK relate to AutoGen, and what does that mean for a new build today?

---

> 🎉 **Phase 1 (Highest ROI) complete!** Next up: **Phase 2 — AKS, Kubernetes, Docker, FastAPI, Python Architecture.** Say **continue** to start Phase 2 with AKS.
