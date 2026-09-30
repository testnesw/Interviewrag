# DEEP MECHANICS · Azure OpenAI Service

> Level 2 — the internals interviewers actually probe: tokens, throughput math,
> throttling behavior, PTU vs PAYG sizing, streaming, deployment/quota mechanics,
> and the security/latency questions that separate a user from an architect.

---

## 0. The precise mental model
Azure OpenAI is a **regional, deployment-based** wrapper over OpenAI models where **you deploy a model into your resource** and get an endpoint. Every request is metered in **tokens**, rate-limited by **TPM (tokens-per-minute)** and **RPM (requests-per-minute)** quotas, and served either **pay-as-you-go (shared, best-effort)** or via **PTU (Provisioned Throughput Units — reserved, deterministic latency)**. The architect's job is capacity math, throttle-handling, and keeping the data plane private.

---

## 1. Tokens — the unit that governs everything

**What a token actually is:** a subword unit from **byte-pair encoding (BPE)**. The tokenizer merges frequent byte pairs into single tokens. Rule of thumb: **~4 characters ≈ 1 token** in English; ~750 words ≈ 1000 tokens. Code, JSON, and non-English are *less* efficient (more tokens per character).

**Why it matters mechanically:**
- You pay **per token**, separately for **input (prompt)** and **output (completion)** — output is usually 2–4× the input price.
- The **context window** is a hard ceiling on `input + output` tokens (e.g., 128K for GPT-4o). Exceed it → request rejected, not truncated silently.
- **Latency scales with output tokens** — generation is autoregressive (one token at a time), so a 2000-token answer takes ~2000 sequential forward passes. Input tokens are processed in parallel (prefill) and cost latency too but sub-linearly.

**Deep follow-up: "Why is the first token slow but the rest fast?"**
Two phases: **prefill** (the model processes the entire prompt in one parallel pass to build the KV-cache → this is **TTFT**, time-to-first-token, and grows with *prompt* length) then **decode** (generate tokens one by one, each reusing the cached attention → steady inter-token latency). Long prompts hurt TTFT; long outputs hurt total time. **This is why prompt size and output size have different latency profiles** — a key answer.

---

## 2. Throughput math — TPM, RPM, and how quota is enforced

**The two limits (both apply):**
- **TPM** — tokens per minute (counts input + a *estimated* max output).
- **RPM** — requests per minute (roughly TPM/6 by Azure's default derivation).

**How throttling actually works:** Azure meters usage in **short sliding windows (per-second/10-second buckets)**, not one clean per-minute reset. So you can be throttled even "under" your per-minute number if you **burst**. Exceed the window → **HTTP 429** with a **`Retry-After`** header telling you how long to wait.

**The correct client behavior (say this exactly):**
1. Respect **`Retry-After`** — don't blind-retry.
2. **Exponential backoff + jitter** to avoid synchronized retry storms.
3. **Cap in-flight concurrency** (a semaphore) so you shape load *before* hitting 429s.
4. **Spread across deployments/regions** (load balance) for headroom.

**Capacity estimation (be able to do this live):**
```
Users: 100k, 10 queries/user/day = 1,000,000 queries/day
Avg 1,500 input + 500 output = 2,000 tokens/query
Daily tokens = 2.0B ; per-minute avg = 2.0B / 1440 ≈ 1.39M TPM avg
Peak (×5) ≈ 6.9M TPM  → you must provision/quotas or PTUs to cover PEAK, not avg
```
**The trap:** people size for average and get throttled at peak. Always size to **peak TPM**, then decide PTU vs PAYG-with-backoff.

---

## 3. PTU vs Pay-as-you-go — the real tradeoff

| | **Pay-as-you-go (PAYG)** | **PTU (Provisioned Throughput)** |
|---|---|---|
| Capacity | shared pool, best-effort | **reserved, dedicated compute** |
| Latency | variable (noisy neighbors) | **deterministic, low, consistent** |
| Throttling | 429s under contention | none up to your provisioned rate |
| Billing | per token consumed | **fixed hourly per PTU** (pay even if idle) |
| Best for | spiky/low/dev traffic | steady, high, latency-sensitive prod |

**What a PTU physically buys:** a slice of reserved model-serving capacity measured in throughput (tokens/min it can sustain). Because it's dedicated, there's **no queueing behind other tenants** → predictable TTFT and inter-token latency. Azure gives calculators mapping PTUs → supported TPM for a given model + prompt/output shape.

**The architect pattern:** **PTU for baseline steady load + PAYG "spillover"** for bursts (route overflow to a PAYG deployment). You get predictable latency on the base and elasticity on the peak without over-buying PTUs. Reserve PTUs for a term for discount.

**Deep follow-up: "PTU is idle at night — is that waste?"**
Yes — you pay hourly regardless. Options: **reduce PTU count off-peak** (reservations permitting), or size PTU to the *daily sustained* load and let PAYG absorb peaks. This is a genuine FinOps tradeoff, not a free lunch.

---

## 4. Deployment & quota mechanics (the stuff people get wrong)

- A **model deployment** = (model + version + capacity) inside a **regional** resource. The deployment name (not the model name) is what your code calls.
- **Quota is per-region, per-subscription, per-model-family** and is a *ceiling you allocate TPM from* across deployments. Two deployments in a region share the region's quota.
- **Model versions** matter: pinning a version gives reproducibility; "auto-update to default" can silently change behavior — **pin in production**.
- **Regional availability differs per model** — a model/version may exist in East US 2 but not West Europe. This drives your multi-region and DR design (you can't fail over to a region that lacks the model).
- **Data residency**: your prompts/completions are processed in the deployment's region; abuse-monitoring data handling and "no training on your data" are contractual guarantees to know for regulated customers.

---

## 5. Streaming — how and why

**Mechanism:** with `stream=true`, the service emits **server-sent events (SSE)**, one chunk per generated token(s), as decode proceeds. The client renders incrementally.

**Why it matters:** total generation of a long answer is seconds; streaming drops **perceived** latency to TTFT (often <1s). No throughput saving — same tokens — purely UX + the ability to cancel early (stop generating → stop paying for the rest).

**Architecture impact:** your backend must stream end-to-end (FastAPI `StreamingResponse` / ASP.NET `IAsyncEnumerable` / SignalR). A buffering proxy or gateway that waits for the full response **kills** the benefit — check APIM/ingress buffering settings.

---

## 6. Load balancing across deployments (multi-instance)

**Why:** single-deployment TPM is capped; latency-sensitive prod needs headroom + regional failover.

**Pattern (APIM as AI gateway):**
- Multiple AOAI deployments (multi-region and/or multiple PTU/PAYG).
- APIM policy distributes requests, **retries 429s on an alternate backend**, and enforces **per-consumer token limits** (so one client can't starve others).
- **Circuit-break** a region that's failing; route to healthy ones.
- Centralized **token metering + logging** for cost attribution.

**Deep follow-up: "How do you keep latency low while load balancing regions?"**
Prefer the **nearest healthy region** (latency-based routing at Front Door), keep PTU in the primary for deterministic latency, and only spill to a farther region under pressure — accept the extra RTT as the failover cost.

---

## 7. Security internals (the keyless data plane)

- **Managed Identity + RBAC**, not keys. The role is **`Cognitive Services OpenAI User`** (inference) or `...Contributor` (manage deployments). The pod/app gets an Entra token (audience = cognitive services) via `DefaultAzureCredential`; **no secret to leak or rotate**.
- **Private Endpoint** puts the AOAI endpoint on a **private IP** in your VNet; set **`publicNetworkAccess = Disabled`** so the public data plane is off. **Private DNS zone** (`privatelink.openai.azure.com`) must resolve the endpoint to the private IP — forget this and clients silently hit the public path or fail.
- **Content filters** run on input and output (hate/violence/self-harm/sexual, plus jailbreak detection) — configurable severity; can be tuned/exempted with approval.
- **Customer-managed keys (CMK)** for encryption at rest where compliance demands.

**Deep follow-up: "Request returns 403 with Managed Identity — what's wrong?"**
Usually the **role assignment is missing/at the wrong scope**, the **token audience** is wrong, or **replication lag** on a just-created role (wait a few minutes). Verify: role = OpenAI User, scope covers the resource, identity is the one the app actually uses.

---

## 8. The hard follow-up questions (with answers)

1. **"Break down the latency of a 1500-in / 500-out request."** → prefill of 1500 tokens (parallel, sets TTFT) + 500 sequential decode steps (inter-token latency × 500). Long prompt → slow first token; long output → slow overall. Streaming hides decode.
2. **"You're getting 429s at 70% of your per-minute quota — why?"** → sliding-window bucketing: bursts breach the short window even under the minute average. Fix: smooth with a concurrency semaphore + backoff, or add capacity.
3. **"Size PTU for 6M peak TPM, 1.4M sustained."** → PTU the **sustained** (~1.4M) for deterministic latency, spill peak to PAYG with backoff; or PTU the peak if latency SLA is strict everywhere (costlier). State the cost/latency tradeoff.
4. **"Design DR for AOAI."** → multi-region deployments (verify model availability per region), Front Door/APIM failover, replicate any state (index), keep quota/PTU in the secondary, test failover. RPO≈0 (stateless inference); RTO = failover time.
5. **"How do you attribute cost per team?"** → APIM subscription keys/JWT per consumer + token logging → per-consumer TPM dashboards + budgets; or separate deployments per team.
6. **"Why pin model version in prod?"** → auto-update can change outputs/behavior and break evals/prompts; pin + run eval before upgrading.
7. **"Prompt caching — what does it save?"** → Azure/OpenAI **prompt caching** reuses the prefill KV for repeated prompt prefixes → lower TTFT and discounted input tokens on the cached portion. Structure prompts with the stable part first.

---

## 9. One-screen deep-recall sheet
- **Tokens**: BPE subwords, ~4 chars/token; pay input+output separately; context window caps input+output.
- **Latency**: **prefill** (parallel, grows with prompt → TTFT) then **decode** (sequential, per output token). Long prompt = slow first token; long output = slow total. Stream to hide decode.
- **Limits**: **TPM + RPM**, enforced in **sliding sub-minute windows** → bursts get **429 + Retry-After**. Client: respect Retry-After, backoff+jitter, concurrency cap, spread deployments.
- **Sizing**: compute **peak** TPM (avg × peak factor), provision to peak.
- **PTU vs PAYG**: PTU = reserved, deterministic latency, fixed hourly (idle cost); PAYG = shared, 429-prone, per-token. Pattern: **PTU baseline + PAYG spillover**.
- **Deployment**: regional; quota per region/model-family; **pin versions**; model availability varies by region (drives DR).
- **Security**: Managed Identity + role **Cognitive Services OpenAI User**, **Private Endpoint** + `publicNetworkAccess=Disabled` + Private DNS; content filters; CMK.
- **Gateway (APIM)**: load balance, retry 429 to alt backend, per-consumer token limits, central metering.
- **403 debugging**: role/scope/audience/propagation.

---

> Next deep-mechanics topic (your order): **Azure Architecture**.
