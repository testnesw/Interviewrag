# 09 · Semantic Kernel

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Semantic Kernel (SK) is a **Microsoft SDK to build AI apps and agents**. It connects LLMs to your code ("functions"/plugins), memory, and planning — so the model can *do things*, not just chat.

## 2. Architect-Level Explanation
An orchestration framework (C#, Python, Java) with:
- **Kernel**: the DI container wiring models, plugins, memory, and services.
- **Plugins/Functions**: native (code) + prompt (semantic) functions the LLM can call.
- **Function calling / Planners**: model chooses functions; **automatic function calling** replaces older planners.
- **Agents & Agent Framework**: build single/multi-agent systems (ChatCompletion, Azure AI Agent).
- **Memory/connectors**: vector stores (AI Search, Qdrant, Redis) for RAG.
- Enterprise-grade: telemetry (OpenTelemetry), filters (guardrails), DI, testability.

## 3. Real Enterprise Use Case
An insurer builds a claims agent in SK: plugins for policy lookup (SQL), document search (AI Search), and payout calculation (native code). The LLM orchestrates them via automatic function calling; filters enforce guardrails; traces flow to App Insights.

## 4. Architecture Diagram (ASCII)
```
              ┌──────── Kernel (DI) ────────┐
   User ─►    │  LLM (AOAI) + function calling│
              │        │                      │
              │   Plugins/Functions           │
              │   ├ native (code/SQL/API)     │
              │   ├ prompt (semantic)         │
              │   └ memory (AI Search vector) │
              │   Filters (guardrails) + Telemetry
              └───────────────────────────────┘
                        ▼
                 Grounded action + answer
```

## 5. Interview Questions
1. What problem does Semantic Kernel solve?
2. Native vs semantic (prompt) functions?
3. SK vs LangChain?
4. How does automatic function calling work (vs old planners)?
5. How do you add guardrails and observability in SK?

## 6. Strong Interview Answers
- **Problem**: "SK is the glue between LLMs and enterprise code — it lets the model call typed functions, use memory/RAG, and orchestrate multi-step tasks, with DI, telemetry, and filters suited to production .NET/Python shops."
- **Function types**: "Native functions are code (deterministic actions/integrations); semantic functions are prompt templates. The LLM composes both."
- **SK vs LangChain**: "SK is enterprise/Microsoft-aligned (strong C# story, DI, filters, Azure integration); LangChain has a larger Python ecosystem and more prebuilt integrations. I pick SK for .NET/Azure-centric, governed apps."
- **Function calling**: "The model returns which function+args to call; SK executes and loops the result back — automatic function calling handles this iteratively, replacing brittle hand-written planners."
- **Guardrails/observability**: "Function/prompt **filters** intercept calls for validation/PII/policy; OpenTelemetry emits traces/metrics to App Insights."

## 7. Common Mistakes
- Overusing planners/agents where a simple function call suffices.
- No filters → unguarded tool execution.
- Ignoring token/cost from multi-step loops.
- Treating semantic functions as deterministic.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Agent/auto-calling | flexible, powerful | non-deterministic, costlier |
| Fixed code flow | predictable, cheap | less adaptive |
| SK | enterprise/.NET fit | smaller ecosystem than LangChain |

## 9. Production Best Practices
- Keep functions small, typed, idempotent.
- Add filters for validation, guardrails, PII.
- Cap function-calling iterations; budget tokens.
- Emit OpenTelemetry; version prompts/plugins.
- Unit-test native functions independently.

## 10. Security Considerations
- Validate all model-chosen function args (injection).
- Least-privilege on what functions can do.
- Filters to block unsafe tool calls/outputs.
- Managed Identity for downstream Azure calls.

## 11. Cost Optimization
- Limit auto-calling loops and context growth.
- Use smaller models for routing/tool selection.
- Cache function results and RAG lookups.

## 12. Troubleshooting Scenarios
- **Model won't call function** → improve function descriptions/schemas.
- **Infinite tool loops** → cap iterations, add termination.
- **Wrong args** → tighten parameter types + validation filter.
- **No traces** → enable OpenTelemetry exporter to App Insights.

## 13. Hands-on Example (C#)
```csharp
var kernel = Kernel.CreateBuilder()
  .AddAzureOpenAIChatCompletion("gpt-4o", endpoint, credential)
  .Build();
kernel.ImportPluginFromType<PolicyPlugin>();
var settings = new AzureOpenAIPromptExecutionSettings {
  FunctionChoiceBehavior = FunctionChoiceBehavior.Auto() };
var res = await kernel.InvokePromptAsync("Find claim 123 status", new(settings));
```

## 14. Terraform Example
```hcl
# SK apps rely on AOAI + AI Search; provision both
resource "azurerm_cognitive_deployment" "chat" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model { format = "OpenAI" name = "gpt-4o" version = "2024-08-06" }
  sku  { name = "Standard" capacity = 20 }
}
```

## 15. Azure Example
Deploy the SK app as an Azure Container App / App Service with Managed Identity granted `Cognitive Services OpenAI User` and `Search Index Data Reader`.

## 16. FastAPI / Python Example
```python
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

kernel = sk.Kernel()
kernel.add_service(AzureChatCompletion(service_id="chat",
    deployment_name="gpt-4o", endpoint=EP, ad_token_provider=token))
kernel.add_plugin(PolicyPlugin(), plugin_name="policy")

@app.post("/agent")
async def agent(q: str):
    return str(await kernel.invoke_prompt(q))  # auto function calling
```

## 17. AKS Example
Run SK microservices in AKS with Workload Identity; each agent is a Deployment, scaled by HPA; plugins call Azure services with no secrets.

## 18. How to Remember
**"LLM + your functions, wired by a kernel."** SK turns the model into an orchestrator of your code.

## 19. Real-World Analogy
A capable executive assistant (LLM) with a toolbox of company tools (plugins) and a memory (vector store) — SK is the office wiring that lets them actually get work done, safely and traceably.

## 20. One-Page Cheat Sheet
- **What**: MS SDK to orchestrate LLMs + code + memory + agents.
- **Core**: Kernel (DI), plugins (native+semantic), function calling, memory.
- **Prod**: filters (guardrails), OpenTelemetry, capped loops, typed functions.
- **vs LangChain**: enterprise/.NET/Azure fit vs bigger Python ecosystem.
- **Secure**: validate args, least privilege, Managed Identity.
- **Cost**: limit loops, small routing models, cache.
