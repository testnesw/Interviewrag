# DEEP MECHANICS · Azure AI Foundry

> Level 2 — what Foundry (formerly Azure AI Studio) actually provides: hubs/
> projects, the model catalog, prompt flow, evaluation, content safety, and how
> it maps to the GenAI lifecycle.

---

## 0. The precise mental model
**Azure AI Foundry** is Microsoft's **end-to-end platform for building, evaluating, and operating GenAI apps** — the unified workspace that ties together model access (Azure OpenAI + open models), **RAG/data**, **orchestration (prompt flow)**, **evaluation**, **content safety**, and **deployment/monitoring**. Think **"the GenAI app factory"**: it wraps the whole LLMOps lifecycle in one governed environment.

---

## 1. Hubs & projects (the org structure)
- **Hub** — the top-level collaborative environment: shared **security, networking, connections (to Azure OpenAI, storage, Key Vault, AI Search), compute, and governance**. Set up once by platform team.
- **Project** — a workspace under a hub for a specific app/team; inherits the hub's config. Isolation + shared resources. This mirrors landing-zone thinking for AI.

## 2. Model catalog
A gallery of **thousands of models**: Azure OpenAI (GPT-4o, etc.), **open models** (Llama, Mistral, Phi), and Hugging Face. Deploy as:
- **Serverless API / Models-as-a-Service** — pay-per-token, no infra.
- **Managed compute** — dedicated endpoints for open models.
Lets you compare/benchmark and pick the right model per task/cost.

## 3. Prompt flow — the orchestration tool
**Prompt flow** = a visual + code tool to build LLM pipelines as a **DAG of nodes** (LLM calls, Python, prompt templates, tools, retrieval). Provides:
- Development + debugging of RAG/agent flows,
- **Batch runs + evaluation** against test datasets,
- Versioning and one-click **deployment** to an endpoint,
- Tracing of each node.
It's the "prompt-as-code + eval + deploy" workflow in one place.

## 4. RAG & data
Built-in RAG: connect data → chunk/embed → index into **Azure AI Search** → grounded chat ("add your data"). Foundry wires retrieval into flows and provides the vector index management.

## 5. Evaluation
Built-in **evaluators** (groundedness, relevance, coherence, fluency, similarity, safety/content harm) + custom + LLM-as-judge. Run eval on datasets, compare model/prompt versions, gate deployment — the eval harness (see Model Evaluation) as a managed feature.

## 6. Safety & governance
- **Azure AI Content Safety** integration (moderation, Prompt Shields, groundedness detection).
- **Azure OpenAI content filters** configurable per deployment.
- Managed identity + private networking + RBAC via the hub → enterprise governance.
- **Tracing/monitoring** via Application Insights for production observability.

## 7. How it maps to the lifecycle
```
Select model (catalog) → ground with data (RAG/AI Search) →
orchestrate (prompt flow) → evaluate (evaluators) →
add safety (content safety/filters) → deploy (endpoint) →
monitor (App Insights/tracing) → iterate
```
Foundry = the managed surface for that whole loop, governed by hub-level security.

## 8. The hard follow-ups (with answers)
1. **"What is AI Foundry?"** → unified platform for building/evaluating/operating GenAI: models, RAG, prompt flow, eval, safety, deploy, monitor. (§0)
2. **"Hub vs project?"** → hub = shared security/networking/connections/governance; project = app workspace inheriting it. (§1)
3. **"Deploy an open model?"** → model catalog → managed compute endpoint (or serverless MaaS for pay-per-token). (§2)
4. **"What's prompt flow?"** → DAG-based orchestration for LLM pipelines with batch eval, versioning, tracing, deploy. (§3)
5. **"Built-in evaluation?"** → groundedness/relevance/coherence/safety evaluators + LLM-judge, gate deployment. (§5)
6. **"How is governance handled?"** → hub-level managed identity, private networking, RBAC, content safety, App Insights. (§6)

## 9. One-screen recall
- **Azure AI Foundry** = end-to-end **GenAI app factory** (build→evaluate→operate).
- **Hub** (shared security/networking/connections/governance) → **Projects** (app workspaces inheriting it).
- **Model catalog**: Azure OpenAI + open (Llama/Mistral/Phi) + HF; deploy **serverless (MaaS)** or **managed compute**.
- **Prompt flow** = DAG orchestration of LLM/Python/retrieval nodes + **batch eval + versioning + tracing + deploy**.
- **RAG**: connect data → chunk/embed → **Azure AI Search** index → grounded chat.
- **Evaluation**: built-in evaluators (groundedness/relevance/coherence/safety) + LLM-judge, gate deploy.
- **Safety/governance**: Content Safety (Prompt Shields/groundedness), content filters, managed identity + private networking + RBAC, **App Insights** monitoring.

> Next: Batch B — ML/MLOps/Data.
