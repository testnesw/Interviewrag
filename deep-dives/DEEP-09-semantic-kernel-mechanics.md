# DEEP MECHANICS · Semantic Kernel

> Level 2 — how SK actually orchestrates: the kernel, plugins/functions,
> automatic function calling, filters, planners, and memory — plus where SK fits
> vs LangChain and the failure modes interviewers probe.

---

## 0. The precise mental model
Semantic Kernel is Microsoft's **orchestration SDK** (.NET-first, also Python/Java) that sits between your app and the LLM. Its core job: register **capabilities as functions** (native code + prompt templates), expose them to the model via **function calling**, and run an **automatic invocation loop** where the model picks functions, SK executes them, and feeds results back — with **filters** for cross-cutting concerns (security, logging, retries) and **memory** for context. Think "**a DI-friendly, enterprise agent runtime**."

---

## 1. The Kernel — the orchestration container

The **Kernel** is the central object (like a DI container for AI). It holds:
- **AI service connectors** (Azure OpenAI chat/embeddings, registered with Managed Identity — no keys).
- **Plugins** (collections of functions the model can call).
- **Filters** (interceptors around function/prompt invocation).
- Configuration, logging, telemetry.

Your app resolves the kernel (often via .NET DI), then either invokes a function directly or runs a chat completion where the kernel **auto-invokes** the right functions. The kernel is what makes SK feel native to enterprise .NET apps.

---

## 2. Functions & plugins — the two kinds

A **plugin** = a named group of **functions**. Two function types:
- **Native functions** — regular C#/Python methods annotated (`[KernelFunction]` / `@kernel_function`) with a **description**. The description is *prompt* — the model reads it to decide when to call. Used for real actions: DB queries, API calls, math, tool integrations.
- **Prompt functions (semantic functions)** — a **templated prompt** (with input variables) that calls the LLM. Used for LLM tasks: summarize, classify, extract, rewrite. Defined inline or as `.prompt` files with config (model, temperature).

Both are exposed to the model through the **same function-calling interface** — the model doesn't care whether a function is code or a prompt; it just sees a callable capability with a schema.

**Deep follow-up: "What's the difference between a native and a prompt function, and why does it matter?"**
A native function runs *your code* (deterministic action, e.g., `getInventory`); a prompt function runs *an LLM call* (a language task, e.g., `summarize`). Mixing them lets the model chain "call code → feed result into an LLM prompt → act again." The uniform interface is what enables composition.

---

## 3. Automatic function calling — the loop SK runs for you

When you set `FunctionChoiceBehavior.Auto()` (Python: `auto`), SK runs this loop under the hood:
```
1. Send chat history + all registered function schemas to the model
2. Model returns tool_calls (which functions + JSON args)
3. SK VALIDATES args, runs FILTERS, EXECUTES the native/prompt functions
4. SK appends results to the chat history
5. Call the model again → repeat until the model returns a final answer
   (bounded by a max auto-invoke count)
```
This is the **same ReAct/tool-calling machinery** as a hand-rolled agent — SK just implements the loop, argument marshaling, and result plumbing so you don't. This is why SK is an "agent runtime."

**Deep follow-up: "Is SK doing anything magical, or is it just function calling?"**
It's function calling + the orchestration loop + marshaling + filters + memory, productized. The model still only *emits* calls; SK executes them. No magic — but it saves you building the loop, schema generation from your method signatures, and the cross-cutting plumbing.

---

## 4. Filters — the enterprise cross-cutting layer (the differentiator)

**Filters** are interceptors (middleware) around invocation — the feature that makes SK "enterprise":
- **Function Invocation Filter** — wraps every function call: log, time, authorize, retry, catch exceptions, **block disallowed calls**, modify args/results.
- **Prompt Render Filter** — runs before a prompt is sent: inspect/rewrite the final prompt, **PII redaction**, injection checks.
- **Auto Function Invocation Filter** — wraps the auto-calling loop: can **terminate early**, enforce limits, or veto a tool call.

**Why they matter:** in a regulated enterprise you need **guardrails, audit, and control** around every LLM/tool interaction. Filters give you a single, testable place to enforce security/observability without polluting business logic — like ASP.NET middleware for AI.

**Deep follow-up: "How would you stop the model from calling a dangerous function or leaking PII?"**
A **function invocation filter** to authorize/deny calls (least privilege, allow-list), and a **prompt render filter** to redact PII before the prompt is sent and inspect for injection. Centralized, auditable, outside the business code.

---

## 5. Planners — and why they're now de-emphasized

**Planners** historically took a goal and had the LLM **generate a multi-step plan** composing available functions (e.g., Sequential/Stepwise planner). Powerful but **unpredictable** (the LLM might produce an invalid or unsafe plan) and token-heavy.

**Current guidance:** for production, prefer **automatic function calling** (the model decides one step at a time, grounded in results) or **explicit orchestration** (you code the workflow) over free-form planners — more control, reliability, and lower cost. Know planners exist, but signal that you'd use them sparingly.

**Deep follow-up: "Would you use a planner in production?"**
Rarely — I prefer automatic function calling or explicit orchestration for predictability and cost control. Planners are useful for exploratory/dynamic tasks but are hard to guarantee in a regulated production system.

---

## 6. Memory & RAG in SK
- **Embeddings connector + a vector store** (Azure AI Search, etc.) via SK's memory/vector abstractions → SK can retrieve relevant context (RAG) and inject it.
- **Chat history** object manages the conversation window; you summarize/trim to fit tokens.
- SK's **connectors** abstract the vector DB so you can swap stores.

---

## 7. Where SK fits vs alternatives
| | **Semantic Kernel** | **LangChain** | **AutoGen** |
|---|---|---|---|
| Focus | enterprise orchestration SDK | huge Python ecosystem | multi-agent conversations |
| Lang | **.NET-first** + Py/Java | Python-first (JS too) | Python |
| Strength | DI, filters, Azure-native, typed | integrations, rapid proto | agent-to-agent patterns |
| Pick when | MS-centric prod, .NET, governance | Python, many integrations | complex multi-agent |

**Note (2025+):** Microsoft has been converging SK with the **Agent Framework / AutoGen** lineage into a unified agent stack — SK is the enterprise-grade, production-hardened path.

---

## 8. The hard follow-up questions (with answers)
1. **"What is the Kernel?"** → the orchestration container (DI-like) holding AI connectors, plugins/functions, filters, config — the composition root for AI. (§1)
2. **"Native vs prompt function?"** → native = your code (deterministic action); prompt = templated LLM call (language task); uniform interface enables chaining. (§2)
3. **"Walk automatic function calling."** → send history+schemas → model emits tool_calls → SK validates+filters+executes → append results → loop until final (bounded). (§3)
4. **"How is SK different from raw function calling?"** → same core loop, but SK adds schema generation, marshaling, **filters**, memory, DI — productized orchestration. (§3)
5. **"Enforce security/PII/audit around AI calls — how?"** → **filters** (function-invocation authz/deny + prompt-render redaction/injection checks) — centralized guardrails. (§4)
6. **"Use planners in prod?"** → sparingly; prefer auto function calling / explicit orchestration for predictability + cost. (§5)
7. **"SK vs LangChain?"** → SK for MS-centric .NET enterprise with governance; LangChain for Python ecosystem/integrations. (§7)
8. **"How does SK avoid storing keys?"** → AI connectors use **Managed Identity** (`DefaultAzureCredential`) to Azure OpenAI — keyless. (§1)

---

## 9. One-screen deep-recall sheet
- **SK = enterprise orchestration SDK** (.NET-first) between app and LLM; "DI container + agent runtime."
- **Kernel** = container holding **AI connectors (Managed Identity, keyless)** + **plugins/functions** + **filters** + config.
- **Functions**: **native** (your code, deterministic actions) + **prompt/semantic** (templated LLM calls); exposed uniformly via **function calling** → composable.
- **Automatic function calling** = SK runs the ReAct-style loop: schemas→model tool_calls→**validate+filter+execute**→append→repeat (bounded). Model emits, SK executes.
- **Filters** (the enterprise differentiator, like middleware): **function-invocation** (authz/deny/retry/log), **prompt-render** (PII redaction/injection), **auto-invocation** (limit/terminate). Centralized guardrails + audit.
- **Planners**: LLM-generated multi-step plans — powerful but unpredictable → **de-emphasized**; prefer auto function calling / explicit orchestration in prod.
- **Memory/RAG**: embeddings connector + vector store abstraction; chat-history window management.
- **vs LangChain**: SK = MS-centric .NET + governance/typed; LangChain = Python ecosystem. Converging with Agent Framework/AutoGen.

---

> Next: **Event-Driven Architecture**.
