# 10 · LangChain

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
LangChain is a popular **Python/JS framework** for building LLM apps — chains, RAG, agents, and tools — with lots of ready-made integrations so you don't write everything from scratch.

## 2. Architect-Level Explanation
A composable framework centered on **LCEL (LangChain Expression Language)**:
- **Runnables/LCEL**: pipe components (`prompt | llm | parser`) with streaming, batching, async, retries.
- **Retrieval**: loaders, splitters, embeddings, vector stores, retrievers (for RAG).
- **Agents/Tools**: tool-calling agents; **LangGraph** for stateful, cyclic, multi-agent workflows.
- **Memory**: conversation/state management.
- **LangSmith**: tracing, evaluation, monitoring.
- Architect view: great for rapid prototyping and rich integrations; production needs care around versioning, observability, and controlling agent non-determinism.

## 3. Real Enterprise Use Case
A SaaS company builds a support agent with LangGraph: nodes for retrieve → grade docs → generate → escalate, with state and conditional edges. AI Search as retriever, AOAI as LLM, LangSmith for eval/tracing before release.

## 4. Architecture Diagram (ASCII)
```
 Loader ─► Splitter ─► Embeddings ─► Vector Store
                                         │ retriever
 Query ─►  prompt | llm | parser  (LCEL chain)
                    │
             LangGraph (stateful nodes + edges)
             retrieve ─► grade ─► generate ─► escalate?
                    │
             LangSmith (trace + eval)
```

## 5. Interview Questions
1. What is LCEL and why does it matter?
2. Chains vs agents vs LangGraph?
3. LangChain vs Semantic Kernel?
4. How do you make LangChain apps production-ready?
5. How do you evaluate/observe LangChain apps?

## 6. Strong Interview Answers
- **LCEL**: "A declarative way to compose runnables with built-in streaming, async, batching, retries, and fallbacks — turns ad-hoc glue code into composable, testable pipelines."
- **Chains vs agents vs graph**: "Chains are fixed DAGs (predictable); agents let the LLM choose tools dynamically (flexible, non-deterministic); LangGraph adds explicit state, cycles, and control — best for reliable multi-step/multi-agent flows."
- **vs SK**: "LangChain has the largest integration ecosystem and Python-first velocity; SK is stronger for enterprise .NET/Azure with DI and filters. Choose by stack and governance needs."
- **Production**: "Pin versions, wrap with retries/fallbacks/timeouts, add LangSmith tracing + eval, constrain agents (max steps, allowed tools), and cache."
- **Eval/observe**: "LangSmith for traces, datasets, and automated evaluators (correctness, groundedness) gated in CI."

## 7. Common Mistakes
- Free-roaming agents in prod (loops, cost, unpredictability).
- Chasing abstractions that hide token/cost.
- No version pinning (LangChain evolves fast).
- Skipping evaluation/tracing.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| LangChain | huge ecosystem, fast | abstraction churn, versioning |
| LangGraph | controllable agents | more design effort |
| Raw SDK | full control | build integrations yourself |

## 9. Production Best Practices
- Prefer LangGraph for stateful/agentic reliability.
- Constrain agents: max steps, tool allowlist, timeouts.
- LangSmith tracing + eval in CI.
- Pin dependency versions; regression test.
- Add retries/fallbacks/caching via LCEL.

## 10. Security Considerations
- Validate tool inputs (prompt injection via retrieved text).
- Sandbox/limit tool capabilities (esp. code/exec tools).
- Redact PII in traces; secure vector store access.

## 11. Cost Optimization
- Cap agent steps and context growth.
- Cache retrievals/LLM calls; smaller models for routing.
- Batch embeddings; tune retriever top-k.

## 12. Troubleshooting Scenarios
- **Agent loops** → LangGraph with step limits/termination.
- **Poor RAG** → inspect retriever output, fix splitter/embeddings.
- **Breaking upgrades** → pin versions, read migration notes.
- **No visibility** → enable LangSmith tracing.

## 13. Hands-on Example (LCEL)
```python
chain = prompt | llm | StrOutputParser()
chain.invoke({"question": "What is LCEL?"})
```

## 14. Terraform Example
```hcl
# Backing services for LangChain RAG
resource "azurerm_search_service" "s" {
  name = "lc-search" resource_group_name = azurerm_resource_group.rg.name
  location = "eastus" sku = "standard" identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
Deploy on Azure Container Apps; use `AzureChatOpenAI`/`AzureAISearchRetriever` with Managed Identity; secrets (LangSmith key) in Key Vault.

## 16. FastAPI / Python Example
```python
from langchain_openai import AzureChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = AzureChatOpenAI(azure_deployment="gpt-4o", api_version="2024-10-21")
prompt = ChatPromptTemplate.from_template(
    "Answer only from context.\n{context}\nQ: {question}")
chain = prompt | llm | StrOutputParser()

@app.post("/ask")
def ask(question: str):
    ctx = retriever.invoke(question)
    return {"answer": chain.invoke({"context": ctx, "question": question})}
```

## 17. AKS Example
Deploy a LangGraph agent service as a Deployment in AKS; each node calls AOAI/AI Search via Workload Identity; scale with HPA; store checkpoints in Redis/Cosmos.

## 18. How to Remember
**"Lego for LLM apps."** Snap together prompts, models, retrievers, and tools with LCEL; LangGraph adds the moving parts.

## 19. Real-World Analogy
An assembly line kit: pre-made stations (loaders, retrievers, models) you connect with a conveyor (LCEL); LangGraph is when the line can loop back and make decisions.

## 20. One-Page Cheat Sheet
- **What**: Python/JS framework for LLM apps (chains, RAG, agents).
- **Core**: LCEL runnables (`prompt | llm | parser`), retrievers, LangGraph.
- **Prod**: LangGraph + constrained agents + LangSmith eval/tracing + version pinning.
- **vs SK**: bigger ecosystem/Python vs enterprise .NET/Azure.
- **Secure**: validate tool inputs, sandbox tools, redact traces.
- **Cost**: cap steps, cache, small routing models.
