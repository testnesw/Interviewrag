# LEVEL 3 · Mock Interview — Rapid-Fire Drills

> Cover the answer, say it out loud in **≤ 30 seconds**, then reveal. If you
> can't, go back to the Level 2 mechanics file. Answers are the crisp version an
> interviewer wants — not an essay.

---

## GenAI & RAG
1. **RAG in one sentence?** → Retrieve relevant chunks from a knowledge store and put them in the prompt so the LLM answers from grounded, current, private data instead of parametric memory.
2. **Why not just fine-tune instead of RAG?** → RAG for *fresh/large/changing knowledge* + citations + access control; fine-tune for *style/format/narrow behavior*, not facts.
3. **Hybrid search — why?** → BM25 (exact terms/IDs) + vector (semantics); reranker on top → best recall *and* precision. Pure vector misses literals.
4. **Stop hallucination?** → Grounding prompt ("answer only from context, else say you don't know") + citations + groundedness eval + Content Safety.
5. **Chunk size trade-off?** → Too big = diluted/expensive context; too small = lost meaning. ~300–500 tokens with overlap + keep headings.
6. **Temperature 0 vs 1?** → 0 = deterministic/factual (routing, extraction); higher = creative/diverse.
7. **Context window full — what do you do?** → Summarize/condense history, retrieve fewer/better chunks, drop low-relevance, or map-reduce.

## LLM mechanics
8. **What's an embedding?** → A vector where semantic similarity = geometric closeness; powers retrieval.
9. **Tokens?** → Sub-word units; models price + limit by tokens; ~4 chars ≈ 1 token (English).
10. **Function calling?** → Model returns a structured JSON call to a tool you defined; your code executes it and feeds the result back.
11. **MCP in one line?** → An open standard so LLMs connect to tools/data via a common protocol (a "USB-C for tools").

## Azure AI
12. **PTU vs PAYG?** → PTU = reserved throughput, predictable latency + cost for steady load; PAYG = per-token, spiky/dev.
13. **Handle AOAI 429?** → Retry w/ backoff+jitter → failover to another deployment/region; spread load; cache.
14. **Keep AOAI private?** → Private endpoint + Managed Identity + VNet; no public key exposure.

## Architecture & resilience
15. **Blue-green vs canary?** → Blue-green = instant 100% switch + instant rollback (2× infra); canary = gradual % with metric gates.
16. **Idempotency — why?** → At-least-once delivery + retries → duplicates; idempotent ops make reprocessing safe.
17. **CAP theorem?** → Under partition, choose consistency **or** availability. Most cloud systems pick AP + eventual consistency.
18. **Circuit breaker?** → Stop calling a failing dependency for a cooldown → fail fast, let it recover, avoid cascading failure.
19. **How get zero-downtime schema change with blue-green?** → Backward-compatible **expand-contract** migration so both versions work on one DB.
20. **Saga?** → Distributed transaction as local steps + **compensating actions** on failure (no 2PC).

## Security
21. **Managed Identity vs Service Principal?** → MI = Azure-managed, auto-rotated, no stored secret (preferred); SP = you manage the secret/cert.
22. **RBAC assignment = ?** → principal + role definition + scope; inherited down the scope hierarchy; additive, deny wins.
23. **PIM solves what?** → Standing admin access → JIT eligible-then-activate (MFA + approval + time limit) → zero standing privilege.
24. **Secret-zero problem?** → How does an app get its first secret? MI eliminates it — identity, not a secret.

## Kubernetes
25. **Pod vs Deployment?** → Pod = smallest runnable unit; Deployment = declarative controller managing ReplicaSets + rolling updates of pods.
26. **Service vs Ingress?** → Service = stable L4 access to pods; Ingress = L7 HTTP routing/TLS into the cluster.
27. **HPA vs Cluster Autoscaler?** → HPA scales *pods* on metrics; CA scales *nodes* when pods can't schedule.
28. **Liveness vs readiness probe?** → Liveness = restart if dead; readiness = remove from Service until ready to serve.

## Data & messaging
29. **SQL vs NoSQL choice?** → Relational/ACID/complex joins → SQL; scale/flexible schema/known access patterns → NoSQL.
30. **Service Bus vs Event Hubs vs Event Grid?** → SB = reliable ordered messaging (txn/DLQ); Event Hubs = high-volume streaming; Event Grid = reactive discrete events.
31. **N+1 query problem?** → Lazy-loading fires one query per parent in a loop → eager-load (join/selectin).

## Delivery
32. **Blue-green rollback speed?** → Instant — flip the router back to the old environment.
33. **GitOps in one line?** → Git = desired state; an in-cluster agent continuously reconciles actual to match (self-healing, auditable).
34. **CI vs CD?** → CI = build+test each commit into an artifact; CD = promote that same artifact through envs with gates ("build once, deploy many").

---

## How to drill
- **Round 1**: read question, answer aloud, self-score (got it / fuzzy / missed).
- **Round 2**: only the "fuzzy/missed" — reread their Level 2 file, redrill.
- **Round 3**: chain 3 related cards into a 2-minute mini-talk (e.g., 1→2→5 = "explain RAG design").

> Next L3: Mock Interview — Whiteboard Prompts.
