# Deep Dive · GenAI Fundamentals

> Phase 1 (Highest ROI) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Generative AI is a class of machine learning models — primarily **Large Language Models (LLMs)** built on the **transformer** architecture — that **generate new content** (text, code, images, audio) by predicting the most probable next token given a context. Unlike traditional discriminative ML that *classifies or predicts a label*, GenAI *produces novel output*. In the enterprise, we consume it as a **managed service (Azure OpenAI)**, ground it on our own data via **RAG**, orchestrate it with frameworks (**Semantic Kernel**), and wrap it in **guardrails, identity, and observability** to make it safe, accurate, and production-grade.

---

## 2. Architect-Level Explanation
GenAI systems are **probabilistic, stateless, token-based inference engines**. As an architect you don't train foundation models — you **compose systems around them**:
- **Model layer**: foundation models (GPT-4o, GPT-4.1, o-series reasoning models, embeddings) exposed as APIs.
- **Grounding layer**: your data via **retrieval (RAG)**, tools/functions, and structured context.
- **Orchestration layer**: prompt construction, chaining, agents, memory, function calling (Semantic Kernel / LangChain).
- **Governance layer**: content safety, prompt-injection defense, PII handling, responsible-AI, evaluation.
- **Platform layer**: identity (Entra ID + Managed Identity), networking (Private Endpoints), quota/capacity (PTUs), observability, cost control.

The core mental model: **an LLM is a stateless function `f(prompt) → probability distribution over next tokens`**, sampled to produce text. Everything else (memory, knowledge, actions, safety) is **architecture you build around** that function.

---

## 3. Why It Exists
- **Problem before**: extracting knowledge, generating language, or reasoning over unstructured text required bespoke NLP models per task (classification, NER, summarization) — expensive, brittle, narrow.
- **Breakthrough**: the **transformer** (2017, "Attention Is All You Need") + **scale** (data + parameters + compute) produced **general-purpose** models that do many tasks zero/few-shot with one model.
- **Why enterprises adopt it**: collapse many NLP pipelines into one API; unlock unstructured data (80% of enterprise data); accelerate developers, support, knowledge work; build copilots and agents.
- **Why managed (Azure OpenAI) exists**: enterprises need the models **with** compliance, data privacy (your prompts aren't used to train), regional residency, identity, SLAs, and networking — not a public consumer endpoint.

---

## 4. Internal Working
**Pipeline: text → tokens → embeddings → transformer layers → output distribution → sampling → text.**

1. **Tokenization**: text split into **tokens** (subword units, ~4 chars/token via BPE). Billing + context limits are in tokens.
2. **Embeddings**: each token mapped to a high-dimensional vector; **positional encoding** adds order.
3. **Transformer blocks (stacked)**: each has
   - **Self-attention**: every token attends to every other token, weighting relevance (Q·K·V). This captures context/relationships — the key innovation.
   - **Feed-forward network** + residual connections + layer norm.
4. **Output head**: final layer produces a **probability distribution over the vocabulary** for the next token.
5. **Sampling / decoding**: pick the next token using **temperature** (randomness), **top-p / top-k** (nucleus sampling). Loop autoregressively until stop token / max tokens.
6. **Context window**: the max tokens (input + output) the model can attend to (e.g., 128K). Stateless — the *entire* conversation is re-sent each call.
7. **Training phases** (background): **pretraining** (predict next token on internet-scale corpus) → **supervised fine-tuning** → **RLHF/DPO** (align to human preferences).

Key properties that flow from this: **stateless**, **probabilistic** (same prompt can vary), **hallucination-prone** (optimizes plausibility, not truth), **context-limited**, **token-costed**.

---

## 5. Enterprise Use Case
A global bank builds an **internal knowledge copilot**: employees ask natural-language questions about policies, products, and procedures. GenAI (Azure OpenAI GPT-4o) is grounded on the bank's document corpus via **RAG over Azure AI Search**, secured with **Entra ID** (per-user auth), guarded by **Content Safety + prompt-injection filters**, and monitored for cost/quality. It replaces slow intranet search and reduces support tickets — while keeping all data inside the bank's Azure tenant.

---

## 6. Real Production Architecture
```
   User (Entra ID auth)
        │  HTTPS
        ▼
   Front Door (WAF) ─► APIM (rate limit, token quota, routing, auth)
        │
        ▼
   Orchestrator API (FastAPI / .NET on AKS or Container Apps)
   │   ├─ Prompt construction + templating
   │   ├─ Guardrails: input validation, prompt-injection filter, PII scrub
   │   ├─ RAG: embed query → Azure AI Search (hybrid + semantic rerank) → context
   │   ├─ Semantic Kernel: function calling / tools / memory
   │   └─ Content Safety (input + output)
        │  Managed Identity (no keys)
        ▼
   Azure OpenAI (Private Endpoint) — GPT-4o + text-embedding-3-large
        │
        ▼
   Observability: App Insights + OpenTelemetry (tokens, latency, cost, quality)
   Data plane: Key Vault (secrets) · Storage/Cosmos (chat history) · Log Analytics
```

---

## 7. Security Best Practices
- **Identity, not keys**: Managed Identity + Entra ID; disable local API keys where possible.
- **Network isolation**: Private Endpoints for Azure OpenAI + AI Search; no public egress.
- **Prompt-injection defense**: treat retrieved/third-party content as untrusted; instruction hierarchy, delimiters, output validation.
- **Content Safety**: Azure AI Content Safety on both input and output (hate/violence/self-harm/sexual + jailbreak detection).
- **PII/data protection**: scrub/redact PII before sending; classify data; honor residency.
- **Least privilege**: RBAC on the resource (Cognitive Services OpenAI User vs Contributor).
- **Auditability**: log prompts/responses (with PII controls) for investigation + compliance.
- **Abuse monitoring & data privacy**: Azure OpenAI doesn't use your data to train; understand the abuse-monitoring opt-out for sensitive workloads.

---

## 8. Scaling Strategy
- **PTU (Provisioned Throughput Units)** for predictable high-volume, low-latency workloads; **PayGo (TPM quota)** for spiky/dev.
- **Multiple deployments/regions** + load balancing (APIM/Front Door) to pool quota and beat per-region TPM limits.
- **Token efficiency**: shrink prompts, cache system prompts, trim RAG context — tokens are the scaling unit.
- **Caching**: semantic cache for repeated queries; prompt caching for shared prefixes.
- **Async + streaming**: stream tokens to reduce perceived latency; async orchestrator for concurrency.
- **Backpressure**: queue + retry with exponential backoff on 429s; graceful degradation.

---

## 9. High Availability Strategy
- **Multi-region deployments** of Azure OpenAI behind APIM/Front Door with health-based routing + failover.
- **Retry with backoff** on throttling/transient errors; circuit breakers.
- **Model fallback chain** (e.g., GPT-4o → GPT-4o-mini) when primary is throttled.
- **Stateless orchestrator** (scale-out on AKS/Container Apps, multi-zone) — state externalized to Cosmos/Redis.
- **Zone-redundant** dependencies (AI Search, storage, Key Vault).

---

## 10. Disaster Recovery Strategy
- **RTO/RPO**: define per workload; chat history in geo-redundant Cosmos/Storage (RPO≈seconds/minutes).
- **Multi-region active-active or active-passive** for Azure OpenAI + AI Search; replicate the **search index** and **embeddings** to the secondary region.
- **IaC (Terraform)** to redeploy the whole stack in a new region quickly.
- **Backups**: index rebuild pipeline, prompt/config in Git, secrets in Key Vault (geo-replicated).
- **DR drills**: test failover of model endpoint + index; validate quota exists in the secondary region.

---

## 11. Cost Optimization Strategy
- **Model right-sizing**: use GPT-4o-mini / smaller models for simple tasks; reserve premium models for hard tasks (**model routing/cascade**).
- **Token discipline**: prompt compression, concise system prompts, cap `max_tokens`, trim RAG chunks.
- **Caching**: semantic + prompt caching to avoid repeat inference.
- **PTU vs PayGo**: PTUs for steady high volume (predictable cost); PayGo for variable.
- **RAG over fine-tuning** when knowledge changes often (cheaper than retraining).
- **Batch API** for non-real-time workloads (discounted).
- **FinOps**: tag, monitor tokens/cost per feature, set budgets + alerts, track **cost per request / per user**.

---

## 12. Common Production Challenges
- **Hallucinations** → ground with RAG, cite sources, evaluate, add "I don't know" behavior.
- **Prompt injection / jailbreaks** → untrusted-content handling + Content Safety.
- **Non-determinism** → temperature control, evaluation harness, regression testing of prompts.
- **Latency** → streaming, smaller models, caching, PTUs.
- **Cost blowups** → token monitoring, caps, routing.
- **Context-window limits** → chunking, summarization, retrieval instead of stuffing.
- **Quota/429s** → multi-deployment, backoff, PTUs.
- **Evaluation** → "how do we know it's good?" — build eval datasets + LLM-as-judge + human review.

---

## 13. Monitoring and Observability
- **Metrics**: tokens (in/out), cost, latency (TTFT + total), throughput, 429 rate, error rate, cache hit rate.
- **Quality**: groundedness, relevance, coherence (Azure AI evaluation / LLM-as-judge), user feedback (thumbs).
- **Tracing**: OpenTelemetry GenAI semantic conventions — trace prompt → retrieval → model → response across the chain.
- **Tools**: Application Insights, Log Analytics, Azure OpenAI metrics, Azure AI Foundry tracing/evaluations.
- **Alerts**: cost budget, latency SLO breach, throttling spikes, safety-filter triggers.

---

## 14. Troubleshooting Scenarios
- **Answers are wrong/made-up** → check retrieval quality (are the right chunks returned?), grounding prompt, temperature; add citations + eval.
- **Slow responses** → measure TTFT; enable streaming; smaller model; check RAG search latency; consider PTUs.
- **429 Too Many Requests** → PayGo quota exhausted; add backoff, multi-region, or PTUs.
- **Inconsistent outputs** → lower temperature, pin model version, add output schema/validation.
- **High cost spike** → find token-heavy feature; compress prompts/context; route to mini model; cache.
- **Injection succeeded** → tighten untrusted-content handling, delimiters, Content Safety jailbreak filter.
- **Model version drift** → pin deployment version; test before auto-upgrade.

---

## 15. Tradeoffs
| Decision | Pro | Con |
|---|---|---|
| RAG vs Fine-tuning | fresh data, cheaper, cited | retrieval complexity, latency |
| PTU vs PayGo | predictable perf/cost | commitment, may waste if idle |
| Large vs small model | quality/reasoning | cost + latency |
| High vs low temperature | creativity | less determinism |
| Managed (AOAI) vs self-host OSS | compliance, no ops | less control, cost per token |
| More context | richer answers | cost + latency + "lost in middle" |

---

## 16. When NOT to Use It
- **Deterministic/exact** computation (math, totals, rules) — use code/DB, not an LLM.
- **Simple pattern tasks** solvable by regex/classic ML at lower cost/latency.
- **Zero-tolerance-for-error** decisions without human review (medical/legal/financial final calls).
- **No data governance** — sending sensitive data before classification/guardrails.
- **Real-time ultra-low-latency** (<50ms) hard requirements.
- **When explainability is legally mandated** and the model can't provide it.

---

## 17. Comparison with Alternatives
| Approach | Best for | vs GenAI |
|---|---|---|
| Traditional ML (classification) | structured, labeled, narrow tasks | cheaper/faster/deterministic but narrow |
| Rules engines | deterministic policy | precise but brittle, no NLU |
| Classic NLP pipelines | specific tasks (NER) | one model per task vs one general model |
| Search (keyword) | lookup | no synthesis/generation |
| **GenAI + RAG** | synthesis over unstructured knowledge | flexible, general, but probabilistic + costlier |

---

## 18. Interview Questions
1. What is a transformer and why did it enable GenAI?
2. Explain tokens, embeddings, and the context window.
3. What is temperature / top-p and when do you change them?
4. Why do LLMs hallucinate and how do you mitigate it?
5. RAG vs fine-tuning — when each?
6. How is Azure OpenAI different from OpenAI's public API?
7. How do you make a GenAI system production-grade (security, scale, cost)?
8. PTU vs PayGo?
9. How do you evaluate a GenAI application?
10. How do you defend against prompt injection?

---

## 19. Strong Interview Answers
- **Transformer**: "The transformer replaced sequential RNNs with **self-attention**, letting every token attend to every other token in parallel — capturing long-range context and enabling massive scale on GPUs. That scale + attention is what produced general-purpose language models."
- **Hallucination**: "LLMs optimize for the *most plausible* next token, not truth — they have no built-in fact store. I mitigate with **RAG grounding + citations**, lower temperature, evaluation (groundedness scoring), and explicit 'answer only from context, else say you don't know' instructions."
- **RAG vs fine-tuning**: "**RAG** injects knowledge at inference from a retrievable store — best when data changes often, needs citations, or is large. **Fine-tuning** changes model behavior/format/tone — best for style, structure, or narrow tasks, not for fresh facts. Often I combine: fine-tune for format, RAG for knowledge."
- **AOAI vs OpenAI**: "Azure OpenAI gives the same models with **enterprise controls**: Entra ID + Managed Identity, Private Endpoints, regional residency, no training on your data, SLAs, content safety, and Azure billing/compliance — essential for regulated enterprises."
- **Production-grade**: "Wrap the model with **identity (MI + Entra), network isolation (Private Endpoints), guardrails (Content Safety + injection defense), grounding (RAG), orchestration (Semantic Kernel), observability (OTel: tokens/latency/cost/quality), and cost control (routing + caching + PTUs)** — the model is 10% of the system."

---

## 20. Architecture Diagrams
**Conceptual layers**
```
┌───────────────────────────────────────────────┐
│ Governance: Content Safety · RAI · Eval · Audit│
├───────────────────────────────────────────────┤
│ Orchestration: prompts · chains · agents · tools│
├───────────────────────────────────────────────┤
│ Grounding: RAG (embeddings + vector search)     │
├───────────────────────────────────────────────┤
│ Model: LLM + embeddings (Azure OpenAI)          │
├───────────────────────────────────────────────┤
│ Platform: identity · network · quota · observ.  │
└───────────────────────────────────────────────┘
```
**Inference flow**
```
prompt → tokenize → embed → [transformer × N: self-attention + FFN]
      → next-token distribution → sample(temp/top-p) → token → (loop) → text
```

---

## 21. Real Project Example
**Support-ticket copilot** for a SaaS company: agents ask "how do I resolve error X for plan Y?". The system embeds the query, retrieves from a **hybrid Azure AI Search** index of docs + past tickets, builds a grounded prompt, calls **GPT-4o**, runs **Content Safety** on the output, streams the answer with citations, and logs tokens/cost/quality. Result: 40% faster ticket resolution, measured via eval + CSAT, at a controlled cost-per-ticket with GPT-4o-mini routing for easy cases.

---

## 22. Whiteboard Design Question
> "Design an enterprise ChatGPT-style assistant grounded on 10M internal documents for 50k employees, with per-user security and a $X/month budget."

Expected: ingestion + chunking + embeddings pipeline → vector index (AI Search) → orchestrator (RAG + Semantic Kernel) → Azure OpenAI (PTU) → guardrails → identity (Entra per-user + document-level security trimming) → observability + FinOps → multi-region HA/DR. Discuss chunking strategy, hybrid search + reranking, security trimming, caching, model routing, and evaluation.

---

## 23. Design Review Questions
- How do you enforce **document-level authorization** so users only see what they're allowed to?
- What's your **evaluation** strategy and regression gate for prompt/model changes?
- How do you handle **prompt injection** from retrieved content?
- What's the **fallback** when Azure OpenAI is throttled or down?
- How do you keep the **index fresh** and what's the reindex cost/latency?
- What are your **cost-per-request** and **latency SLOs**, and how are they monitored?
- How do you pin/upgrade **model versions** safely?

---

## 24. Hands-on Example
```python
# Minimal grounded call with Managed Identity (no keys)
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

token_provider = get_bearer_token_provider(
    DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default")
client = AzureOpenAI(
    azure_endpoint="https://my-aoai.openai.azure.com",
    azure_ad_token_provider=token_provider,
    api_version="2024-10-21")

context = retrieve_chunks(user_query)   # RAG step (vector search)
resp = client.chat.completions.create(
    model="gpt-4o",                      # deployment name
    temperature=0.2,
    max_tokens=500,
    messages=[
        {"role": "system", "content": "Answer ONLY from the context. If unknown, say so. Cite sources."},
        {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {user_query}"},
    ])
print(resp.choices[0].message.content)
```

---

## 25. Terraform Example
```hcl
resource "azurerm_cognitive_account" "aoai" {
  name                  = "my-aoai"
  location              = "eastus"
  resource_group_name   = var.rg
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "my-aoai"
  public_network_access_enabled = false          # private only
  identity { type = "SystemAssigned" }
}

resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model  { format = "OpenAI"  name = "gpt-4o"  version = "2024-08-06" }
  sku    { name = "Standard"  capacity = 50 }     # TPM (thousands)
}

resource "azurerm_private_endpoint" "aoai_pe" {
  name                = "aoai-pe"
  location            = "eastus"
  resource_group_name = var.rg
  subnet_id           = var.subnet_id
  private_service_connection {
    name                           = "aoai-psc"
    private_connection_resource_id = azurerm_cognitive_account.aoai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }
}
```

---

## 26. Azure Example
```bash
# Create Azure OpenAI, deploy a model, assign RBAC (no keys), grant Managed Identity access
az cognitiveservices account create -n my-aoai -g rg --kind OpenAI --sku S0 \
  -l eastus --custom-domain my-aoai --yes

az cognitiveservices account deployment create -n my-aoai -g rg \
  --deployment-name gpt-4o --model-name gpt-4o --model-version 2024-08-06 \
  --model-format OpenAI --sku-name Standard --sku-capacity 50

# Grant the app's Managed Identity data-plane access (least privilege)
az role assignment create --assignee <app-mi-object-id> \
  --role "Cognitive Services OpenAI User" \
  --scope /subscriptions/<sub>/resourceGroups/rg/providers/Microsoft.CognitiveServices/accounts/my-aoai
```

---

## 27. Code Example
```python
# Streaming + token/cost observability wrapper (async)
import time
async def ask(client, query, context):
    t0 = time.perf_counter()
    stream = await client.chat.completions.create(
        model="gpt-4o", stream=True, temperature=0.2, max_tokens=600,
        messages=[
            {"role":"system","content":"Ground answers in context; cite; else say unknown."},
            {"role":"user","content":f"{context}\n\nQ: {query}"}])
    text, ttft = "", None
    async for chunk in stream:
        delta = chunk.choices[0].delta.content or ""
        if delta and ttft is None: ttft = time.perf_counter() - t0   # time-to-first-token
        text += delta
    emit_metrics(ttft=ttft, total=time.perf_counter()-t0, out_chars=len(text))
    return text
```

---

## 28. Things Architects Must Remember
- **The model is ~10% of the system** — value + risk live in grounding, guardrails, identity, observability, and cost control.
- **LLMs are stateless, probabilistic, token-costed** — design memory, determinism, and budgets explicitly.
- **Tokens are the unit** of cost, latency, and context — optimize relentlessly.
- **Ground, don't trust** — RAG + citations + evaluation beat "the model knows".
- **Treat retrieved/user content as untrusted** (prompt injection is the new XSS).
- **Identity + Private Endpoints + Content Safety** are non-negotiable in enterprises.
- **Evaluate continuously** — you can't improve what you don't measure (groundedness/relevance).
- **Right-size models + cache + route** — biggest cost levers.

---

## 29. Mnemonics and Memory Tricks
- **"G-R-O-U-N-D"** for production GenAI: **G**uardrails, **R**etrieval (RAG), **O**bservability, **U**ser identity, **N**etwork isolation, **D**ollars (cost control).
- **"TEA-CS"** pipeline: **T**okenize → **E**mbed → **A**ttention → **C**omplete → **S**ample.
- **Hallucination cure = "GCE"**: **G**round, **C**ite, **E**valuate.
- **"The 3 P's of an LLM"**: **P**robabilistic, **P**rompt-driven, **P**er-token-priced.
- **RAG vs fine-tune**: *"Facts → RAG, Form → Fine-tune."*

---

## 30. One-Page Interview Revision Sheet
- **What**: transformer-based models that **generate** content by predicting next tokens; consumed as managed APIs (Azure OpenAI).
- **Internals**: tokenize → embed → self-attention layers → next-token distribution → sample (temperature/top-p). **Stateless, probabilistic, token-costed, context-limited.**
- **Why**: one general model replaces many narrow NLP pipelines; unlocks unstructured data.
- **Architect layers**: Model → Grounding (RAG) → Orchestration (Semantic Kernel) → Governance (safety/RAI/eval) → Platform (identity/network/quota/observability).
- **Security**: Managed Identity + Entra, Private Endpoints, Content Safety, injection defense, PII scrubbing, RBAC.
- **Scale**: PTU vs PayGo, multi-region, token efficiency, caching, streaming, backoff on 429.
- **HA/DR**: multi-region + retry + fallback model; replicate index/embeddings; IaC redeploy.
- **Cost**: model routing (mini vs premium), token compression, caching, RAG-over-fine-tune, batch API, FinOps tagging.
- **Evaluate**: groundedness/relevance/coherence + human feedback; regression-gate prompt changes.
- **Remember**: *Facts→RAG, Form→Fine-tune*; *model is 10% of the system*; *tokens are everything*; **G-R-O-U-N-D**.
- **When NOT**: deterministic math/rules, ultra-low latency, zero-error-without-review, ungoverned sensitive data.
