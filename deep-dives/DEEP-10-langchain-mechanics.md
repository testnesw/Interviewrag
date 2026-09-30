# DEEP MECHANICS · LangChain

> Level 2 — the abstractions (LCEL, chains, retrievers, agents, memory), how they
> compose, and when to use LangChain vs Semantic Kernel vs rolling your own.

---

## 0. The precise mental model
LangChain is a **Python-first framework for composing LLM applications** out of reusable building blocks: models, prompts, retrievers, tools, memory, and chains. Its core idea is **composition** — wire components into pipelines (via **LCEL**, the LangChain Expression Language) so data flows model→parser→retriever→model. It's the **"batteries-included, huge-integration-count"** option vs Semantic Kernel's enterprise/.NET focus.

---

## 1. The building blocks
- **Models** — LLMs / chat models / embeddings, behind a uniform interface (swap providers).
- **Prompt templates** — parameterized prompts with variables.
- **Output parsers** — coerce model text into structured objects (JSON, Pydantic).
- **Retrievers** — abstraction over a vector store to fetch relevant docs (RAG).
- **Tools** — callable functions the model can invoke.
- **Memory** — persist/summarize conversation state across turns.
- **Chains** — compositions of the above.

## 2. LCEL — how composition actually works
LCEL lets you pipe components with `|`:
```
chain = prompt | model | output_parser
chain.invoke({"question": "..."})
```
Everything implements a common **Runnable** interface (`invoke`, `batch`, `stream`, async) → you get streaming, batching, retries, and parallelism **for free**, and can swap any stage. A RAG chain:
```
{"context": retriever, "question": passthrough} | prompt | model | parser
```

## 3. RAG in LangChain
Pipeline: **DocumentLoader → TextSplitter → Embeddings → VectorStore → Retriever → prompt+model**. LangChain's value is the **enormous set of prebuilt loaders/splitters/vector-store integrations**, so you assemble RAG fast.

## 4. Agents & tools
LangChain agents run the **reason→act loop**: the model picks a tool, LangChain executes it, feeds the observation back, repeats (ReAct/tool-calling). **LangGraph** (the newer library) models agents as an explicit **graph/state machine** — nodes = steps, edges = transitions — giving controllable, cyclic, durable agent workflows (better than the old opaque AgentExecutor).

## 5. Memory
- **Buffer** — keep full history (until token limit).
- **Summary** — LLM-summarize old turns to save tokens.
- **Vector/entity memory** — retrieve relevant past context.
Memory manages the context-window budget across a conversation.

## 6. LangChain vs Semantic Kernel vs DIY
| | LangChain | Semantic Kernel | DIY |
|---|---|---|---|
| Lang | Python-first (JS too) | .NET-first | any |
| Strength | integrations, speed | enterprise, DI, filters, typed | full control, minimal deps |
| Weakness | abstraction churn, overhead | fewer integrations | you build everything |
| Pick | Python, many integrations, prototyping | MS/.NET prod, governance | simple/perf-critical, avoid lock-in |

**Deep follow-up: "Would you always use LangChain?"**
No. It accelerates prototyping and integration-heavy apps, but the abstractions add overhead and change frequently. For a simple RAG call or a perf-critical path I'd use the provider SDK directly; for MS-centric enterprise, Semantic Kernel.

## 7. The hard follow-ups (with answers)
1. **"What is LCEL and why?"** → pipe Runnables with `|`; free streaming/batch/retry/async, swappable stages. (§2)
2. **"Build RAG in LangChain?"** → loader→splitter→embeddings→vectorstore→retriever→prompt→model. (§3)
3. **"LangChain agents — how?"** → reason→act tool loop; LangGraph = explicit state-machine graph for control. (§4)
4. **"Memory options?"** → buffer / summary / vector; manage token budget. (§5)
5. **"LangChain vs SK?"** → Python ecosystem/integrations vs .NET enterprise/DI/filters. (§6)
6. **"Downside of LangChain?"** → abstraction overhead + churn; not always warranted. (§6)

## 8. One-screen recall
- LangChain = **Python-first LLM composition framework**; huge integration count.
- Blocks: models, prompt templates, **output parsers**, **retrievers**, tools, **memory**, chains.
- **LCEL**: `prompt | model | parser`; common **Runnable** interface → free stream/batch/retry/async, swappable.
- **RAG**: loader→splitter→embeddings→vectorstore→retriever→prompt→model.
- **Agents**: ReAct tool loop; **LangGraph** = explicit graph/state-machine for durable controllable agents.
- **Memory**: buffer / summary / vector → token-budget management.
- **vs SK** (Python/integrations vs .NET/enterprise/filters); **DIY** when simple/perf-critical.

> Next: Multi-Agent Architecture.
