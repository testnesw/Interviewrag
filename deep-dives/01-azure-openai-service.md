# Deep Dive · Azure OpenAI Service

> Phase 1 (Highest ROI) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Azure OpenAI Service (AOAI) is Microsoft's **enterprise-grade managed hosting of OpenAI models** (GPT-4o, GPT-4.1, o-series reasoning models, embeddings, DALL·E, Whisper) delivered through Azure's control plane. You get the **same models as OpenAI** but with **Entra ID identity, Managed Identity, Private Endpoints, regional data residency, no training on your data, SLAs, RBAC, content safety, and Azure billing/compliance**. Architecturally you consume it as a **deployment** (a named model instance with a capacity allocation) via either **Pay-as-you-go (TPM quota)** or **Provisioned Throughput (PTUs)** for predictable latency/throughput.

---

## 2. Architect-Level Explanation
AOAI is a **regional, deployment-based inference service**. Key architectural constructs:
- **Resource (account)**: a Cognitive Services account of kind `OpenAI`, pinned to a region, with a **custom subdomain** (required for Entra auth + Private Link).
- **Deployment**: a named instance of a specific **model + version** with a **capacity** (TPM for Standard, or PTUs for Provisioned). Your code calls the *deployment name*, not the model directly.
- **Two throughput models**:
  - **Standard (PayGo)** — billed per token, governed by **TPM (tokens-per-minute) quota** + RPM; shared capacity; variable latency.
  - **Provisioned (PTU)** — reserved capacity units giving **predictable latency + throughput**; billed hourly (or via reservations); best for steady high volume.
  - **Global / Data Zone / Regional** deployment variants trade off residency vs capacity/price.
- **Data plane** = inference APIs (chat, embeddings, etc.); **control plane** = ARM (create resource/deployment, RBAC, networking).
- **Governance built-in**: content filters (configurable severity), abuse monitoring, RAI policies.
As an architect you design around **quota math, region strategy, PTU vs PayGo economics, multi-region HA, and private networking** — the model call itself is trivial.

---

## 3. Why It Exists
- **Enterprises can't use the public OpenAI API** for regulated data: no Entra identity, no private networking, unclear residency/compliance, data-handling concerns.
- **AOAI bridges that gap**: same frontier models + **Azure's enterprise fabric** — identity, RBAC, VNet/Private Link, compliance certifications (SOC/ISO/HIPAA/PCI), SLAs, and a commitment that **your prompts/completions are not used to train the models**.
- **Capacity governance**: enterprises need predictable throughput and cost — hence **PTUs** and quota management, which the raw API doesn't offer in the same way.
- **Unified platform**: integrates with Azure AI Search, Content Safety, AI Foundry, Managed Identity, Monitor — one governed ecosystem.

---

## 4. Internal Working
1. **Request path**: client → (Private Endpoint / public) → AOAI regional gateway → **auth** (Entra token *or* API key) → **quota/rate check** (TPM/RPM or PTU pool) → **content filter (input)** → model inference → **content filter (output)** → response (optionally **streamed** SSE).
2. **Deployment routing**: the `model` field in the request = your **deployment name**; AOAI maps it to the underlying model+version on the allocated capacity.
3. **Quota accounting (Standard)**: tokens counted per minute against **TPM**; exceeding returns **429** with `Retry-After`. RPM is derived (~6 RPM per 1K TPM).
4. **PTU capacity**: reserved compute slots process your tokens at a guaranteed rate; overflow queues/throttles rather than bursting.
5. **Content filtering**: Azure AI Content Safety classifiers score hate/sexual/violence/self-harm + jailbreak/prompt-shield; severity thresholds are configurable (with approval for relaxation).
6. **Model versioning**: deployments pin a **model version**; supports **auto-update** or pinned; retirement lifecycle applies.
7. **Networking**: custom subdomain enables **Private Endpoint** (Private Link) so traffic stays on the Microsoft backbone; public access can be disabled.

---

## 5. Enterprise Use Case
A healthcare provider deploys AOAI in a **HIPAA-compliant** setup: GPT-4o for a clinician documentation copilot, `text-embedding-3-large` for RAG over clinical guidelines. All access is via **Managed Identity + Entra**, **Private Endpoints only** (public disabled), **content filters** tuned for clinical context, and **PTUs** to guarantee low latency during peak clinic hours — with tokens/cost tracked per department for chargeback.

---

## 6. Real Production Architecture
```
   Client (Entra ID) → Front Door (WAF)
        ▼
   APIM  ── token-based rate limiting, subscription keys, routing, caching
        ▼  (Managed Identity, no keys)
   Orchestrator (AKS / Container Apps)
        │  load-balances across N AOAI deployments/regions (pool TPM/PTU)
        ├──────────────┬──────────────┐
        ▼              ▼              ▼
   AOAI East US    AOAI West US   AOAI Sweden   (each: Private Endpoint)
   (PTU primary)   (PTU/PayGo)    (PayGo burst)
        ▼
   Content Safety · Key Vault · Log Analytics / App Insights (tokens, latency, 429s, cost)
```

---

## 7. Security Best Practices
- **Entra ID + Managed Identity**; **disable local API keys** (`disableLocalAuth`) where possible.
- **RBAC least privilege**: `Cognitive Services OpenAI User` (call) vs `...Contributor` (manage) — don't hand out Contributor.
- **Private Endpoints**, `publicNetworkAccess = Disabled`; custom subdomain required.
- **Customer-Managed Keys (CMK)** for encryption-at-rest of stored data where required.
- **Content filtering** on input+output; **prompt shields** for injection/jailbreak.
- **Abuse-monitoring / data-privacy**: understand logging; request the **no-human-review / opt-out** for sensitive regulated data.
- **Diagnostic logging** to Log Analytics; audit who/what/when.
- **Network egress control** + Key Vault for any secrets; TLS everywhere.

---

## 8. Scaling Strategy
- **Quota math**: know your **TPM** ceiling per region; request increases early; spread deployments across regions to **pool quota**.
- **PTU for scale-with-predictability**; **PayGo for burst/dev**; hybrid: PTU baseline + PayGo spillover ("**spillover/burst**" pattern).
- **Multi-deployment load balancing** via APIM or SDK-level round-robin/least-latency; retry 429 to a sibling deployment.
- **Token efficiency**: compress prompts/context, cap `max_tokens`, reuse system prompts (**prompt caching** discounts repeated prefixes).
- **Streaming** to cut perceived latency; **Batch API** for async bulk (cheaper, off the real-time path).
- **Global/Data Zone deployments** to access larger shared capacity pools.

---

## 9. High Availability Strategy
- **Multi-region deployments** behind APIM/Front Door with **health + latency routing** and automatic failover.
- **Retry with exponential backoff + jitter** on 429/5xx; **circuit breaker** per endpoint.
- **Model fallback chain** (GPT-4o → GPT-4o-mini) under pressure.
- **Stateless orchestrator**, multi-zone, autoscaled; state in Cosmos/Redis.
- **Zone-redundant** dependencies (AI Search, Key Vault, storage).
- Respect the **SLA** (Provisioned has stronger guarantees than shared Standard).

---

## 10. Disaster Recovery Strategy
- **Active-active or active-passive** across paired regions; pre-provision **quota/PTUs in the secondary** (quota isn't automatic!).
- **IaC (Terraform/Bicep)** to redeploy accounts + deployments + Private Endpoints fast.
- **Replicate dependencies**: RAG index + embeddings, chat history (geo-redundant Cosmos/Storage).
- **Config in Git** (prompts, filter settings, deployment versions); secrets in geo-replicated Key Vault.
- **DR drills**: fail over endpoint routing; validate secondary capacity + content-filter parity; measure RTO/RPO.

---

## 11. Cost Optimization Strategy
- **Right-size the model**: GPT-4o-mini / smaller for easy tasks; premium only when needed (**model cascade/routing**).
- **PTU vs PayGo economics**: compute the **break-even TPM** — steady high volume → PTUs (+ **PTU reservations** for 1yr/3yr discounts); spiky → PayGo.
- **Token discipline**: shorter prompts/context, `max_tokens` caps, stop sequences.
- **Prompt caching** (repeated prefixes) + **semantic caching** (repeat queries).
- **Batch API** (~50% cheaper) for non-real-time jobs.
- **FinOps**: tag deployments, monitor **cost-per-request / per-feature / per-user**, budgets + alerts; kill idle deployments.

---

## 12. Common Production Challenges
- **429 throttling** → quota too low / single region; add regions, backoff, PTUs.
- **Latency spikes** on shared Standard → move hot paths to PTUs.
- **Quota not in DR region** → provision ahead.
- **Content filter false positives** blocking valid output → tune severity / request modification.
- **Model version retirement** → track lifecycle, test upgrades, pin versions.
- **Cost overruns** → token sprawl from RAG context; compress + route.
- **Regional capacity shortages** for newest models → use Global/Data Zone deployments.
- **Key sprawl** → switch to Managed Identity.

---

## 13. Monitoring and Observability
- **Azure Monitor metrics**: Processed/Generated Tokens, requests, **429 count**, latency, PTU utilization.
- **Diagnostic logs** → Log Analytics (KQL): per-deployment usage, errors, filter triggers.
- **App-level (OTel)**: tokens in/out, cost, TTFT + total latency, cache hit rate, model routing decisions, quality scores.
- **PTU utilization dashboards** (are you under/over-provisioned?).
- **Alerts**: 429 spike, latency SLO breach, budget threshold, PTU saturation, content-filter surge.

---

## 14. Troubleshooting Scenarios
- **`429 Too Many Requests`** → check TPM usage vs quota; add backoff + secondary deployment; consider PTUs.
- **`401/403`** → Entra token audience/role wrong; missing `OpenAI User` role or custom subdomain.
- **High latency** → shared Standard contention → PTU; enable streaming; smaller model; check region.
- **`content_filter` finish_reason** → output/input blocked; inspect categories; tune thresholds or rephrase.
- **`DeploymentNotFound`** → calling model name instead of *deployment* name.
- **Cost spike** → identify token-heavy deployment; compress prompts/context; route to mini.
- **Private Endpoint DNS fail** → private DNS zone `privatelink.openai.azure.com` misconfigured.

---

## 15. Tradeoffs
| Decision | Pro | Con |
|---|---|---|
| PTU | predictable latency/throughput, SLA | commitment, idle waste if under-utilized |
| PayGo (Standard) | elastic, pay-per-use | 429s, variable latency |
| Global deployment | more capacity, cheaper | data may leave region (residency) |
| Regional/Data Zone | residency control | less capacity, higher price |
| Managed Identity | no key sprawl | setup + token plumbing |
| Auto-update model | latest quality | behavior drift risk |

---

## 16. When NOT to Use It
- **Non-sensitive prototypes** where OpenAI public API is faster to start (though enterprises still prefer AOAI).
- **Ultra-cost-sensitive, simple tasks** better served by small OSS models self-hosted.
- **Fully offline/air-gapped** requirements AOAI can't meet.
- **Deterministic logic** (use code, not an LLM).
- **When a smaller managed model (e.g., Phi via AI Foundry) suffices** at lower cost.
- **Latency <50ms hard SLAs** — inference won't meet it.

---

## 17. Comparison with Alternatives
| Option | Identity/Net/Compliance | Models | Best for |
|---|---|---|---|
| **Azure OpenAI** | Entra, Private Link, Azure compliance | OpenAI frontier | regulated enterprise |
| OpenAI public API | API key only | OpenAI frontier (earliest) | consumer/startups |
| AWS Bedrock / Google Vertex | cloud-native equivalents | Anthropic/others | AWS/GCP shops |
| Azure AI Foundry model catalog | Azure fabric | OSS + Meta/Mistral/Phi | cost/OSS, custom |
| Self-hosted OSS (AKS + vLLM) | full control | Llama/Mistral | data sovereignty, high volume |

---

## 18. Interview Questions
1. How is Azure OpenAI different from OpenAI's API?
2. Explain deployments, TPM quota, and RPM.
3. PTU vs PayGo — how do you choose and compute break-even?
4. How do you scale beyond a single region's quota?
5. How do you secure AOAI (identity, network)?
6. How does content filtering work and how do you tune it?
7. Design multi-region HA/DR for AOAI (note quota gotcha).
8. How do you optimize AOAI cost?
9. How do you monitor tokens, latency, and PTU utilization?
10. How do you handle 429s in production?

---

## 19. Strong Interview Answers
- **AOAI vs OpenAI**: "Same models, enterprise wrapper: **Entra ID + Managed Identity, Private Link, regional residency, RBAC, SLAs, compliance certs, and no training on your data**. For regulated workloads that's the difference between usable and not."
- **PTU vs PayGo**: "PayGo bills per token under a **TPM quota** — elastic but subject to 429s and variable latency. **PTUs** reserve capacity for **predictable latency/throughput** and an SLA, billed hourly with reservation discounts. I compute the **break-even TPM**: steady, high, latency-sensitive traffic → PTUs (baseline) with PayGo spillover for bursts; spiky/dev → PayGo."
- **Scale beyond quota**: "Quota is **per-region, per-model**. I deploy the model in **multiple regions**, pool them behind APIM/SDK load balancing with **429-aware retry to siblings**, request quota increases early, and use **Global/Data Zone** deployments for larger shared pools — plus token compression and caching to reduce demand."
- **HA/DR gotcha**: "Multi-region behind APIM/Front Door with health routing and backoff. The classic trap: **quota/PTUs aren't automatically available in your DR region** — you must pre-provision capacity there and keep content-filter + deployment config in parity, validated by DR drills."
- **Cost**: "Model routing (mini vs premium), token discipline (`max_tokens`, prompt/context compression), **prompt + semantic caching**, **Batch API** for async, and **PTU reservations** for steady volume — all tracked with FinOps tagging and cost-per-request alerts."

---

## 20. Architecture Diagrams
**Deployment model**
```
Resource (kind=OpenAI, region, custom subdomain)
   ├── Deployment "gpt-4o"      → model gpt-4o v2024-08-06, 50 TPM (Standard)
   ├── Deployment "gpt-4o-ptu"  → model gpt-4o, 100 PTU (Provisioned)
   └── Deployment "embed"       → text-embedding-3-large, 120 TPM
Client calls deployment NAME → routed to model+capacity
```
**Request pipeline**
```
auth(Entra/key) → quota/PTU check → input filter → inference
   → output filter → (stream SSE) → response  [metrics/logs emitted]
```

---

## 21. Real Project Example
A retailer's **product-catalog copilot** runs GPT-4o on **PTUs (East US)** for steady daytime traffic with **PayGo (West US) spillover** for evening spikes, load-balanced by APIM with 429-aware retry. Embeddings power RAG over the catalog in AI Search. Private Endpoints, Managed Identity, and Content Safety enforce security; App Insights tracks cost-per-query and PTU utilization. Peak-season traffic tripled with **zero throttling** because PTU baseline + PayGo burst absorbed the load.

---

## 22. Whiteboard Design Question
> "Design Azure OpenAI capacity + networking for a copilot serving 20k concurrent users globally with 99.9% availability and strict EU data residency."

Expected: EU **Data Zone/regional** deployments for residency; **PTU baseline + PayGo spillover**; multi-region behind Front Door/APIM with health routing + 429 retry; Private Endpoints + Entra + MI; content safety; capacity math (TPM/PTU sizing from expected tokens/min); DR with pre-provisioned secondary quota; observability + FinOps. Discuss residency vs capacity trade-off of Global deployments.

---

## 23. Design Review Questions
- What's your **TPM/PTU sizing** calculation and headroom?
- Is **quota provisioned in the DR region**? Content-filter parity?
- **Public network disabled**? Private DNS zones correct?
- **Managed Identity** everywhere, local auth disabled?
- **Model version** pinned or auto-update? Upgrade test plan?
- **429 strategy**: backoff + multi-deployment failover?
- **Cost guardrails**: budgets, per-feature token tracking, caching?
- **Residency**: are Global deployments acceptable for this data class?

---

## 24. Hands-on Example
```python
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

tp = get_bearer_token_provider(DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default")
client = AzureOpenAI(azure_endpoint="https://my-aoai.openai.azure.com",
    azure_ad_token_provider=tp, api_version="2024-10-21")

r = client.chat.completions.create(
    model="gpt-4o",            # DEPLOYMENT name, not model name
    temperature=0.2, max_tokens=400,
    messages=[{"role":"user","content":"Summarize our refund policy."}])
print(r.choices[0].message.content)
print(r.usage.prompt_tokens, r.usage.completion_tokens)   # cost tracking
```

---

## 25. Terraform Example
```hcl
resource "azurerm_cognitive_account" "aoai" {
  name                          = "my-aoai"
  location                      = "eastus"
  resource_group_name           = var.rg
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = "my-aoai"
  public_network_access_enabled = false
  local_auth_enabled            = false          # force Entra ID
  identity { type = "SystemAssigned" }
}

resource "azurerm_cognitive_deployment" "gpt4o_ptu" {
  name                 = "gpt-4o-ptu"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model { format = "OpenAI" name = "gpt-4o" version = "2024-08-06" }
  sku   { name = "ProvisionedManaged" capacity = 100 }   # 100 PTU
}

resource "azurerm_role_assignment" "app" {
  scope                = azurerm_cognitive_account.aoai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.app_mi_principal_id
}
```

---

## 26. Azure Example
```bash
# Disable local auth, deploy PTU model, wire Private Endpoint
az cognitiveservices account create -n my-aoai -g rg --kind OpenAI --sku S0 \
  -l eastus --custom-domain my-aoai --yes
az resource update --ids $(az cognitiveservices account show -n my-aoai -g rg --query id -o tsv) \
  --set properties.disableLocalAuth=true properties.publicNetworkAccess=Disabled

az cognitiveservices account deployment create -n my-aoai -g rg \
  --deployment-name gpt-4o-ptu --model-name gpt-4o --model-version 2024-08-06 \
  --model-format OpenAI --sku-name ProvisionedManaged --sku-capacity 100

# Check quota/usage
az cognitiveservices usage list -l eastus -o table
```

---

## 27. Code Example
```python
# 429-aware multi-deployment load balancer with backoff
import random, asyncio
DEPLOYMENTS = ["aoai-eastus", "aoai-westus", "aoai-sweden"]

async def call_with_failover(build_client, messages, attempts=4):
    order = random.sample(DEPLOYMENTS, len(DEPLOYMENTS))
    for i in range(attempts):
        ep = order[i % len(order)]
        try:
            client = build_client(ep)
            return await client.chat.completions.create(
                model="gpt-4o", messages=messages, max_tokens=400)
        except RateLimitError:                 # 429 → try sibling deployment
            await asyncio.sleep(min(2 ** i + random.random(), 20))  # backoff+jitter
    raise RuntimeError("all AOAI deployments throttled")
```

---

## 28. Things Architects Must Remember
- **Quota is per-region, per-model** — plan multi-region pooling and **pre-provision DR capacity**.
- **You call the *deployment name*, not the model** — a top interview gotcha.
- **PTU = predictable, PayGo = elastic** — most enterprises run **PTU baseline + PayGo spillover**.
- **Custom subdomain is mandatory** for Entra auth + Private Link.
- **Global deployments trade residency for capacity/price** — check data classification.
- **Content filters can block valid output** — plan tuning + approvals.
- **Your data isn't used to train** — a key compliance selling point.
- **Model versions retire** — track lifecycle, pin + test upgrades.

---

## 29. Mnemonics and Memory Tricks
- **"D-Q-P-N"** core constructs: **D**eployment, **Q**uota (TPM), **P**TU, **N**etwork (Private Endpoint).
- **PTU vs PayGo**: *"PTU = Predictable Throughput Unit; PayGo = Pay-as-you-Go, but pay in 429s."*
- **Security "M-P-R"**: **M**anaged Identity, **P**rivate Endpoint, **R**BAC least privilege.
- **DR gotcha**: *"No quota in DR = no DR."*
- **Scale**: *"Baseline on PTU, burst on PayGo."*

---

## 30. One-Page Interview Revision Sheet
- **What**: managed OpenAI models on Azure with enterprise identity/network/compliance; **no training on your data**.
- **Constructs**: Resource (region + custom subdomain) → **Deployment** (model+version+capacity). Call the **deployment name**.
- **Throughput**: **Standard/PayGo** (TPM quota, elastic, 429-prone) vs **Provisioned/PTU** (reserved, predictable, SLA, reservations for discount). **Global/Data Zone/Regional** = capacity vs residency.
- **Security**: **Managed Identity + Entra**, disable local auth, **Private Endpoints** (`privatelink.openai.azure.com`), RBAC (`OpenAI User`), content filters, CMK.
- **Scale**: multi-region quota pooling, APIM load-balance, 429 backoff+failover, token compression, caching, Batch API, streaming.
- **HA/DR**: multi-region + health routing + fallback model; **pre-provision DR quota/PTUs**; IaC redeploy; replicate index/history.
- **Cost**: model routing, `max_tokens`, prompt/semantic caching, Batch API, **PTU reservations**, FinOps tagging (cost/request).
- **Monitor**: tokens, 429 count, latency, **PTU utilization**; alerts on throttling/budget/latency.
- **Remember**: *deployment name not model*; *quota is per-region*; *no DR quota = no DR*; **D-Q-P-N**; *PTU baseline + PayGo burst*.
