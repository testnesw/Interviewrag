# Question Bank · Top 100 Most-Asked Azure GenAI Architect Interview Questions

> Each question has a **crisp architect-level answer**. Say them out loud.
> Grouped by domain. Mnemonics referenced from the deep-dives.

---

## A. GenAI & LLM (1–20)

**1. What is Retrieval-Augmented Generation (RAG) and why use it?**
Inject relevant retrieved context into the prompt so the LLM answers from *your* data. It reduces hallucination, gives current/private knowledge without retraining, and enables citations. Flow: chunk → embed → vector store → retrieve top-k → augment prompt → generate.

**2. RAG vs fine-tuning — when each?**
RAG for **knowledge** that changes often (facts, docs) — cheaper, updatable, citable. Fine-tuning for **behavior/format/style/tone** or narrow tasks. Often combine: fine-tune style + RAG for facts.

**3. How do you reduce hallucinations?**
Ground with RAG, instruct "answer only from context / say I don't know," lower temperature, add citations, validate outputs (guardrails), and evaluate with groundedness metrics.

**4. Explain embeddings and vector search.**
Text → high-dimensional vector capturing semantic meaning; similar meaning ⇒ close vectors (cosine/dot). Vector DB uses ANN indexes (HNSW) for fast nearest-neighbor retrieval.

**5. How do you choose chunk size?**
Balance context vs precision: too big = noise + cost, too small = lost context. Typically 200–500 tokens with overlap; tune by retrieval quality evaluation.

**6. What is temperature / top-p?**
Sampling controls: temperature scales randomness (0 = deterministic, high = creative); top-p (nucleus) samples from the smallest set of tokens summing to probability p. Low for factual, higher for creative.

**7. How do you control token cost in GenAI?**
Semantic/prompt caching, model routing (cheap model for easy queries), prompt compression, cap max tokens, smaller models where adequate, PTUs for steady load, and monitor tokens/request.

**8. What is prompt injection and how do you defend?**
Malicious input overrides instructions. Defend with input/output filtering, separating system vs user content, least-privilege tools, output validation, and not executing model output blindly.

**9. Function calling / tools — what and why?**
The model returns a structured call to an external function/API; your code executes and returns results. Enables actions and grounding beyond the model's knowledge.

**10. What is MCP (Model Context Protocol)?**
An open standard ("USB-C for AI") standardizing how models connect to tools/data via servers exposing **Tools, Resources, Prompts** — turns M×N integrations into M+N.

**11. What is an AI agent?**
An LLM that **reasons, plans, uses tools, and acts in a loop** (e.g., ReAct: reason→act→observe) toward a goal, with memory — vs a single-shot completion.

**12. Multi-agent architecture — when?**
When a task decomposes into specialized roles (planner, researcher, coder, reviewer). Adds coordination overhead — use only when a single agent can't handle complexity.

**13. How do you evaluate a GenAI system?**
Offline: groundedness, relevance, coherence, task success on a curated set (LLM-as-judge + human). Online: user feedback, deflection, latency, cost. Continuous eval in CI.

**14. Semantic Kernel vs LangChain?**
SK is Microsoft's enterprise-focused, .NET/Python SDK with plugins + planners, strong Azure integration. LangChain is Python-first with a huge ecosystem. Choose by stack + ecosystem needs.

**15. How do you secure Azure OpenAI?**
Managed Identity (no keys), private endpoints, Key Vault, RBAC (Cognitive Services OpenAI User), content filters, network isolation, and logging.

**16. What are guardrails / responsible AI controls?**
Content filters, groundedness checks, PII redaction, jailbreak/prompt-injection defense, and human-in-the-loop for high-stakes — plus fairness/transparency per Responsible AI.

**17. Streaming responses — why and how?**
Stream tokens as generated to cut perceived latency; via SSE/WebSockets/SignalR. Improves UX for long generations.

**18. How does context window affect design?**
It caps prompt + history + retrieved context. Manage with retrieval (only relevant chunks), summarization of history, and windowing — don't dump everything.

**19. PTU vs pay-as-you-go for Azure OpenAI?**
PTUs (Provisioned Throughput Units) give reserved, predictable throughput/latency for steady high load; PAYG for variable/low load. Mix: PTU baseline + PAYG burst.

**20. Design a RAG chatbot over enterprise docs.**
Ingestion (chunk→embed→AI Search index) + query (retrieve top-k with security filters → augment → AOAI → cite), semantic cache, Managed Identity + private endpoints, OTel + token metrics, eval loop.

---

## B. System Design & Architecture (21–40)

**21. Walk your system-design process.**
Clarify (functional + non-functional) → estimate scale → APIs → data model → high-level design → deep-dive bottleneck → -ilities → tradeoffs. (C-E-A-D-H-D-I-T)

**22. Explain CAP theorem.**
Under a network partition you choose Consistency **or** Availability. Pick per data type: strong for money, eventual for feeds.

**23. SQL vs NoSQL?**
SQL for relations, ACID, complex queries; NoSQL for scale, flexible schema, high write throughput, denormalized access. Decide by access patterns and consistency needs.

**24. How do you scale a read-heavy system?**
Cache (Redis/CDN), read replicas, denormalize/precompute, CQRS. Watch cache hit rate and thundering herd.

**25. How do you scale a write-heavy system?**
Shard/partition by a load-spreading key, async ingestion via queue, write-optimized store; avoid hot partitions.

**26. Strong vs eventual consistency?**
Strong: every read sees latest write (payments/inventory). Eventual: replicas converge (feeds/recommendations) — higher availability/scale.

**27. What is a distributed monolith and how to avoid it?**
Microservices coupled by shared DB, joint deploys, or chatty sync — cost of distribution without benefits. Avoid via clear contracts, DB-per-service, async decoupling.

**28. Explain the Saga pattern.**
Distributed transaction as local transactions with compensating actions on failure, coordinated by orchestration or choreography over events; idempotent consumers + outbox.

**29. Circuit breaker and bulkhead?**
Circuit breaker stops calling a failing dependency (fail fast, recover). Bulkhead isolates resource pools so one failure doesn't exhaust everything. Both prevent cascading failures.

**30. Idempotency — why and how?**
Safe retries without duplicates. Use idempotency keys, dedupe tables, and idempotent operations — essential with at-least-once messaging.

**31. Sync vs async communication?**
Sync (REST/gRPC) for immediate queries; async (events/queues) for decoupling, resilience, spike absorption. Prefer async between services where latency allows.

**32. How do you design for HA (99.9 vs 99.99)?**
Redundancy across zones, stateless services, health checks, resilience patterns. Higher SLA ⇒ multi-region active-active, remove every SPOF, tighter automation.

**33. Design for RTO/RPO?**
Define per criticality → pick pattern: backup-restore (loose), active-passive (minutes), active-active (near-zero). Geo-replicate data; automate failover (Front Door); drill.

**34. What is CQRS?**
Separate read and write models/paths so each scales and optimizes independently; often paired with event sourcing. Adds complexity — use when read/write needs diverge.

**35. Event-driven architecture tradeoffs?**
Pros: decoupling, scalability, resilience. Cons: eventual consistency, harder debugging/tracing, ordering/duplication concerns.

**36. How do you handle a hot partition?**
Choose a higher-cardinality partition key, add a suffix/hash, cache the hot key, or spread load with consistent hashing.

**37. API Gateway responsibilities?**
Single entry: routing, authn/authz, rate limiting, aggregation, TLS, versioning, observability — offloads cross-cutting concerns from services.

**38. Service mesh — what and why?**
Sidecar-based layer for mTLS, retries, traffic shaping, and observability between services without app code changes (Istio/Linkerd).

**39. When NOT to use microservices?**
Small teams/simple apps, strong global consistency needs, immature ops. Start with a modular monolith; split on bounded contexts when justified.

**40. How do you keep cost bounded at scale?**
Cache, autoscale, scale-to-zero, storage tiering, reserved capacity/PTUs, model routing, tagging + budgets. Design cost in from day one — architecture drives ~80% of cost.

---

## C. Azure Platform & Networking (41–60)

**41. Explain Azure Landing Zones / CAF.**
Cloud Adoption Framework's opinionated, IaC-deployed foundation: management-group hierarchy, policies, identity, networking, security baselines — governance at scale. (Enterprise-scale ALZ.)

**42. Hub-and-spoke topology?**
Central hub VNet (shared services: firewall, gateways, DNS) peered to spoke VNets (workloads). Centralizes security/connectivity, isolates workloads.

**43. Private Endpoint vs Service Endpoint?**
Private Endpoint gives a service a **private IP in your VNet** (traffic stays private, works cross-region/on-prem). Service Endpoint keeps traffic on the backbone but the resource keeps a public IP. Prefer private endpoints for PaaS.

**44. NSG vs Azure Firewall?**
NSG = stateful L3/L4 allow/deny rules on subnets/NICs. Azure Firewall = managed L3–L7 firewall with FQDN filtering, threat intel, centralized egress control. Use both (defense in depth).

**45. How do you prevent data exfiltration?**
Azure Firewall FQDN filtering + forced tunneling, private endpoints, NSGs, deny public access, and DNS control. (F-D-N: Firewall, DNS, Network policy.)

**46. Front Door vs Application Gateway vs Load Balancer?**
Front Door = global L7 (CDN, WAF, anycast, multi-region failover). App Gateway = regional L7 (WAF, path routing). Load Balancer = regional L4. Layer them.

**47. How does Azure Front Door provide DR?**
Global anycast + health probes route to the nearest healthy region; priority-based failover gives active-passive or active-active multi-region.

**48. APIM in a GenAI architecture?**
AI gateway: auth, rate/token limiting, load-balancing across AOAI instances/PTUs, caching, and observability in front of models. (Token limit, Load balance, Key vault-less via MI, Monitor.)

**49. What is Managed Identity?**
Azure-managed identity for a resource to get Entra tokens with **no secrets**; system-assigned (tied to resource) or user-assigned (shared). Use everywhere to avoid keys.

**50. Explain RBAC and least privilege.**
Role assignments (role + scope + principal) grant minimum needed permissions; scope at the narrowest level (resource > RG > sub). Prefer built-in roles; audit regularly.

**51. What is PIM?**
Privileged Identity Management: just-in-time, time-bound, approval-based elevation for privileged roles — reduces standing admin access.

**52. Key Vault best practices?**
Store secrets/keys/certs; access via Managed Identity + RBAC; enable soft-delete/purge protection; rotate; private endpoint; audit logs. (R-S-P-P.)

**53. Zero Trust principles?**
Verify explicitly, least privilege, assume breach. Applied: strong identity (Entra + MFA/Conditional Access), micro-segmentation, mTLS, continuous monitoring. (V-L-A.)

**54. ExpressRoute vs VPN?**
ExpressRoute = private, dedicated, high-bandwidth on-prem connectivity (no internet). VPN = encrypted over internet, cheaper, lower SLA. ExpressRoute for enterprise/hybrid.

**55. How do you secure a GenAI workload network end-to-end?**
Private endpoints on AOAI/Search/Storage, hub-spoke + Azure Firewall egress control, NSGs, no public data plane, Managed Identity, Key Vault — defense in depth.

**56. Defender for Cloud / Sentinel roles?**
Defender for Cloud = CSPM + workload protection (posture, recommendations, threat detection). Sentinel = cloud SIEM/SOAR (correlation, hunting, automated response).

**57. How do you enforce governance at scale?**
Azure Policy (audit/deny/deployIfNotExists), management groups, blueprints/ALZ, tagging enforcement — policy-as-code via IaC. (D-A-D effects.)

**58. Multi-region strategy for Azure OpenAI?**
Deploy in multiple regions, load-balance/fail over via APIM/Front Door, replicate the search index, plan capacity/PTUs per region, handle regional model availability.

**59. How do you isolate multi-tenant data?**
Per-tenant filters at retrieval/data layer (row-level, index filters, or separate indexes), tenant-scoped identities, and strict authz — never trust the model for isolation.

**60. Cost optimization on Azure (FinOps)?**
Right-size, autoscale, reserved instances/savings plans, spot for interruptible, storage tiering, tagging + budgets + Cost Management, kill idle. Inform→optimize→operate.

---

## D. Containers, Kubernetes & Docker (61–75)

**61. Explain Kubernetes core objects.**
Pod (smallest unit), Deployment (declarative replicas + rollout), ReplicaSet, Service (stable networking/LB), Ingress (L7 routing), ConfigMap/Secret, Namespace. Declarative desired state reconciled by controllers.

**62. How does K8s self-heal?**
Controllers continuously reconcile actual vs desired state — restart failed pods, reschedule on node loss, maintain replica count. (Declare, don't do.)

**63. HPA vs Cluster Autoscaler vs KEDA?**
HPA scales **pods** on metrics (CPU/custom); Cluster Autoscaler scales **nodes**; KEDA scales on **event sources** (queue depth) incl. scale-to-zero.

**64. Requests vs limits?**
Requests = guaranteed/scheduled amount; limits = hard cap. Set both to protect nodes; missing requests → poor scheduling; low limits → OOMKills/throttling.

**65. Liveness vs readiness probes?**
Liveness restarts a hung container; readiness gates traffic until ready. Wrong liveness config causes restart loops.

**66. How do you secure AKS?**
Managed Identity/Workload Identity, network policies, private cluster, RBAC, Azure Policy/Gatekeeper, secrets in Key Vault (CSI), image scanning, non-root, mTLS via mesh.

**67. Rolling update vs blue-green vs canary?**
Rolling = gradual pod replacement (default); blue-green = switch traffic between two full envs; canary = shift a small % first. Trade risk vs cost/complexity.

**68. What is Helm?**
Kubernetes package manager: templated, versioned, parameterized manifests (charts) for repeatable releases and rollbacks.

**69. Docker image optimization?**
Multi-stage builds, small base (distroless/alpine), layer ordering for cache, .dockerignore, no secrets in layers, pin versions (not `latest`), non-root user. (S-N-P-S.)

**70. Why is `latest` tag dangerous?**
Non-deterministic — different pulls get different images, breaking reproducibility and rollbacks. Pin explicit versions/digests.

**71. How do containers achieve isolation?**
Linux namespaces (process/network/mount isolation) + cgroups (resource limits) — share the host kernel (lighter than VMs, weaker isolation).

**72. Pod-to-pod networking?**
Flat network — every pod gets an IP, all pods can reach each other by default; restrict with **network policies**. Services provide stable virtual IPs + DNS.

**73. How do you do zero-downtime deploys on AKS?**
Rolling update with readiness probes + PodDisruptionBudgets + graceful shutdown (preStop/SIGTERM handling) + surge settings.

**74. AKS cost optimization?**
Right-size + requests/limits, cluster autoscaler, spot node pools for interruptible, bin-packing, scale-to-zero (KEDA), reserved instances, remove idle namespaces.

**75. Service mesh on AKS — when?**
When you need mTLS, fine-grained traffic control, and uniform observability across many services — otherwise it's overhead.

---

## E. IaC, DevOps & CI/CD (76–90)

**76. What is Infrastructure as Code and why Terraform?**
Declarative, versioned, reviewable infrastructure. Terraform is cloud-agnostic, has state + plan/apply, and a rich provider ecosystem.

**77. Explain Terraform state and remote backend.**
State maps config to real resources; store remotely (Azure Storage) with **locking** (blob lease) to prevent concurrent corruption; never commit state (has secrets).

**78. plan vs apply?**
`plan` shows the diff (create/update/destroy) for review; `apply` executes it. Always plan → review → apply; gate applies in CI.

**79. How do you manage multiple environments in Terraform?**
Workspaces or (better) separate state per env + reusable modules with per-env variable files; isolate prod state and pipelines.

**80. What are Terraform modules?**
Reusable, parameterized packages of resources — DRY, consistent, versioned building blocks.

**81. How do you handle secrets in IaC/CI?**
Never hardcode: Key Vault + Managed Identity, pipeline secret stores, OIDC for cloud auth; mark variables sensitive; keep state secure.

**82. OIDC federation vs stored secrets in CI/CD?**
OIDC gives short-lived, workload-federated tokens (no long-lived cloud secrets to leak/rotate) — the modern best practice for GitHub Actions/Azure DevOps → Azure.

**83. GitHub Actions building blocks?**
Workflow → Jobs → Steps → Actions, triggered by events; runners execute; use OIDC to Azure, environments for approvals, reusable workflows. (W-J-S-A.)

**84. Azure DevOps pipeline structure?**
Pipeline → Stages → Jobs → Steps/Tasks; triggers, environments with approvals/gates, service connections (OIDC), artifacts. (B-R-P-A-T / S-J-S.)

**85. Blue-green vs canary in CD?**
Blue-green swaps environments for instant rollback; canary releases to a subset with metric gates before full rollout. Choose by risk tolerance and infra cost.

**86. How do you gate production deploys?**
Manual approvals + automated gates (tests, security scans, health/quality checks), environment protection rules, and progressive delivery. (A-H-B-R.)

**87. What is GitOps?**
Git as the single source of truth for declarative infra/app state; an agent (Argo/Flux) continuously reconciles the cluster to Git — auditable, revertible.

**88. How do you shift security left?**
SAST/DAST, dependency + IaC scanning, secret scanning, container image scanning in the pipeline; fail builds on critical findings; policy-as-code.

**89. How do you achieve safe, frequent deploys?**
Trunk-based dev, automated tests, feature flags, progressive delivery (canary), fast rollback, observability + error-budget-driven release gating.

**90. Rollback strategy?**
Immutable versioned artifacts/images + IaC + blue-green/keep previous revision; automate rollback on failed health checks; practice it.

---

## F. Observability, Reliability & Behavioral (91–100)

**91. Three pillars of observability?**
Metrics (aggregate trends), logs (discrete events), traces (request path). Unified in App Insights/Log Analytics; correlate via IDs.

**92. What is OpenTelemetry?**
Vendor-neutral standard/SDK for generating metrics, logs, and traces; export to any backend (App Insights) — avoids lock-in, enables distributed tracing.

**93. Golden signals / SLI-SLO-error budget?**
Golden signals: latency, traffic, errors, saturation. SLI = measured indicator; SLO = target; error budget = allowed unreliability that gates release velocity.

**94. How do you debug a latency spike across services?**
Distributed tracing with correlation IDs to find the slow hop; check downstream throttling (AOAI 429s), cache hit rate, hot partition, saturation metrics.

**95. How do you monitor a GenAI system specifically?**
Token usage/cost per request, cache hit rate, retrieval quality/groundedness, latency (incl. streaming TTFT), error/throttle rates, plus standard golden signals.

**96. How do you approach a system you've never seen in production incident?**
Stabilize (mitigate/rollback) → observe (dashboards/traces/logs) → isolate the failing component → fix root cause → blameless postmortem + prevention.

**97. How do you handle disagreement with a stakeholder on architecture?**
Anchor on requirements + data + tradeoffs, present options with costs/risks, seek the business objective, and document the decision (ADR) — disagree and commit.

**98. How do you make a build-vs-buy / technology choice?**
Weigh requirements, TCO, team skills, ecosystem, lock-in, time-to-market, and risk; prototype if uncertain; prefer boring, proven tech unless differentiation demands otherwise.

**99. Describe designing a system end-to-end (STAR).**
Situation/Task (business need + constraints), Action (framework: requirements→scale→design→-ilities→tradeoffs, key decisions), Result (SLA met, cost saved, delivered) — quantify.

**100. What makes a good architect (vs senior engineer)?**
Thinks in tradeoffs and business outcomes, communicates and aligns teams, designs for the -ilities and cost, says no to over-engineering, and owns decisions with documented rationale.

---

## How to Practice
- **Cover the answer**, read the question, answer aloud, then compare.
- **Group drilling**: do one section (20 Qs) per day.
- For design questions, always **narrate the framework**: C-E-A-D-H-D-I-T + the -ilities.
- **Weakest domains first** — track which you fumble.

---

> Next: domain-specific Top 50 banks (GenAI, Kubernetes, Python, .NET Core, Terraform, Azure Architecture).
