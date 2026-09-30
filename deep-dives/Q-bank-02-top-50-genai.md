# Question Bank · Top 50 GenAI & LLM Architect Questions

> Deep, domain-focused. Architect-level answers. Say them aloud.

---

## Fundamentals (1–12)

**1. What is a Large Language Model?**
A transformer-based neural network trained on massive text to predict the next token; emergent abilities (reasoning, summarization, code) arise from scale. It's a probabilistic next-token predictor, not a knowledge database.

**2. Explain the transformer architecture briefly.**
Self-attention lets each token weigh all others in context; stacked attention + feed-forward layers with positional encoding. Attention is the breakthrough enabling parallel training and long-range context.

**3. What is tokenization?**
Text split into tokens (subword units) via BPE; the model operates on token IDs. Token count drives cost and context limits (~4 chars/token in English).

**4. What are embeddings?**
Dense vectors encoding semantic meaning; similar meanings are geometrically close. Used for retrieval, clustering, classification, dedup.

**5. Temperature vs top-p vs top-k?**
Temperature scales randomness; top-p (nucleus) samples the smallest token set summing to p; top-k limits to k tokens. Low temp for factual, higher for creative.

**6. What is the context window?**
Max tokens (prompt + history + retrieved + completion). Budget it: retrieve only relevant chunks, summarize history — don't dump everything.

**7. What causes hallucinations?**
The model fills gaps with plausible-but-wrong tokens when it lacks grounding. Mitigate with RAG grounding, "say I don't know," low temp, validation, citations.

**8. Prompt engineering techniques?**
Clear instructions, few-shot examples, role/system prompts, chain-of-thought, output format constraints, and separating instructions from data (injection defense).

**9. Zero-shot vs few-shot vs chain-of-thought?**
Zero-shot = instruction only; few-shot = examples in prompt; CoT = "think step by step" to improve reasoning on complex tasks.

**10. What is grounding?**
Anchoring responses in provided/retrieved factual context so answers are verifiable — the core of RAG and reduced hallucination.

**11. System vs user vs assistant messages?**
System sets behavior/rules; user is the query; assistant is model output. Keep untrusted user data out of the system role (injection safety).

**12. What are model parameters vs hyperparameters?**
Parameters = learned weights (fixed at inference); hyperparameters (temperature, max tokens, top-p) = inference-time controls you set.

---

## RAG (13–26)

**13. Explain the full RAG pipeline.**
Ingestion: load → chunk → embed → store in vector DB. Query: embed query → retrieve top-k (with filters) → augment prompt → generate → cite. Plus eval + cache.

**14. How do you choose chunk size and overlap?**
200–500 tokens with 10–20% overlap typically; tune via retrieval-quality eval. Too big = noise/cost, too small = lost context.

**15. What is hybrid search?**
Combine keyword (BM25) + vector (semantic) search, often with reranking, to catch both exact terms and semantic matches — Azure AI Search supports this natively.

**16. What is reranking?**
A second-stage model reorders retrieved candidates by relevance to the query, improving precision of the top-k fed to the LLM.

**17. How do you improve retrieval quality?**
Better chunking, hybrid search + rerank, query rewriting/expansion, metadata filters, embedding model choice, and semantic ranker; measure with recall/precision.

**18. RAG vs fine-tuning vs long-context?**
RAG for changing knowledge (cheap, citable, updatable); fine-tuning for behavior/format; long-context for whole-doc tasks but costly/slower. Combine as needed.

**19. How do you handle citations/attribution?**
Return source metadata with retrieved chunks and have the model cite chunk IDs; verify citations post-generation (groundedness check).

**20. What is semantic caching?**
Cache answers keyed by embedding similarity of the query; near-duplicate questions hit cache, cutting tokens and latency. Manage staleness with TTL/versioning.

**21. How do you secure RAG for multi-tenant data?**
Apply tenant/user security filters at retrieval (index filters / per-tenant indexes / row-level), enforced by the app — never rely on the prompt or model for isolation.

**22. How do you keep the index fresh?**
Async ingestion pipeline triggered on source changes (event-driven), incremental indexing, and re-embedding on model changes; track index version.

**23. What is chunking by structure vs fixed size?**
Structure-aware chunking (by heading/section/paragraph) preserves semantics better than blind fixed-size splits; use document structure when available.

**24. How do you evaluate a RAG system?**
Metrics: context relevance, groundedness/faithfulness, answer relevance; LLM-as-judge + human review on a curated golden set; track in CI.

**25. Why might RAG still hallucinate?**
Poor retrieval (wrong/no context), model ignoring context, or over-long context diluting signal. Fix retrieval quality + strict grounding instructions + eval.

**26. Design RAG for 10M documents.**
Scalable vector store (AI Search) with partitioning, batch async embedding pipeline, hybrid + rerank retrieval, semantic cache, metadata filters, and cost controls (model routing).

---

## Agents & Orchestration (27–38)

**27. What is an AI agent?**
An LLM that reasons, plans, calls tools, observes results, and loops toward a goal with memory — autonomous multi-step behavior vs single completion.

**28. Explain the ReAct pattern.**
Interleave Reasoning ("thought") and Acting (tool call) then Observing results, repeating until the goal is met — grounds reasoning in tool feedback.

**29. What is function/tool calling?**
The model outputs a structured call (name + args) matching a schema; your code executes and returns results for the model to use. Enables actions + grounding.

**30. When multi-agent vs single agent?**
Multi-agent when the task decomposes into specialized roles needing separation (planner/researcher/coder/critic). It adds coordination cost — avoid unless complexity demands it.

**31. Multi-agent patterns?**
Sequential pipeline, hierarchical (orchestrator + workers), group chat/debate, and blackboard. Pick by task structure and control needs.

**32. What is MCP?**
Model Context Protocol — open standard so agents connect to tools/data via servers exposing Tools, Resources, Prompts; M×N integrations become M+N ("USB-C for AI").

**33. How do you give agents memory?**
Short-term (conversation buffer/summary) + long-term (vector store of past interactions/facts) retrieved as needed; manage context budget.

**34. How do you keep agents safe/bounded?**
Least-privilege tools, human-in-the-loop for high-impact actions, step/iteration limits, output validation, sandboxing, and guardrails against prompt injection.

**35. Semantic Kernel vs LangChain vs AutoGen?**
SK: enterprise .NET/Python, plugins + planners, Azure-native. LangChain: Python-first, huge ecosystem. AutoGen: multi-agent conversations. Choose by stack + use case.

**36. What are planners in Semantic Kernel?**
Components that dynamically compose available functions/plugins into a plan to achieve a goal (though explicit orchestration is often preferred for control).

**37. How do you handle tool failures in an agent?**
Retries with backoff, fallbacks, timeouts, and reasoning over errors (feed the error back so the agent adapts) plus max-iteration guards.

**38. Agent observability?**
Trace every reasoning step + tool call + token usage; log decisions; monitor loop length, tool error rates, cost per task — essential for debugging non-determinism.

---

## Production, Security & Ops (39–50)

**39. How do you productionize a GenAI app on Azure?**
Azure OpenAI (PE, MI) + AI Search + orchestrator (AKS/Container Apps), APIM AI gateway (rate/token limits, load balance), semantic cache, OTel + token metrics, eval + guardrails, IaC.

**40. How do you defend against prompt injection?**
Separate system/user content, input/output filtering, least-privilege tools, don't execute model output blindly, validate/sanitize, and monitor. Treat all user/retrieved text as untrusted.

**41. How do you control GenAI cost?**
Semantic caching, model routing (small model for easy queries), prompt compression, max-token caps, PTUs for steady load, and per-request token monitoring + budgets.

**42. PTU vs PAYG for Azure OpenAI?**
PTUs = reserved throughput, predictable latency for steady high load; PAYG = variable/low load. Baseline on PTU + burst on PAYG.

**43. How do you load-balance across AOAI deployments?**
APIM as AI gateway distributing across multiple regional deployments/PTUs with retry on 429s and health-aware routing.

**44. How do you handle rate limits / 429s?**
Retry with exponential backoff + jitter, spread across deployments (APIM), queue/throttle client-side, and provision PTUs for guaranteed throughput.

**45. Responsible AI controls?**
Content filters (hate/violence/self-harm/sexual), groundedness checks, PII redaction, jailbreak detection, transparency/citations, human oversight, and fairness evaluation.

**46. How do you evaluate models before deploying?**
Task-specific benchmarks + curated golden sets, LLM-as-judge + human eval on quality/safety/groundedness, A/B tests, and cost/latency comparison. Continuous eval in CI (LLMOps).

**47. What is LLMOps?**
Operationalizing LLM apps: prompt/version management, evaluation pipelines, monitoring (quality/cost/drift), CI/CD for prompts + models, and feedback loops.

**48. How do you monitor GenAI quality in production?**
Online feedback (thumbs/edits), groundedness sampling, drift detection, token/cost/latency metrics, and periodic re-eval against golden sets.

**49. Streaming architecture for chat?**
Stream tokens via SSE/WebSockets/SignalR to cut perceived latency (time-to-first-token); orchestrator streams from AOAI to client; handle partial failures.

**50. Design an enterprise GenAI assistant end-to-end.**
Front Door/APIM (auth, token limits) → stateless orchestrator (HPA) → semantic cache → hybrid retrieval (AI Search, PE, tenant filters) → AOAI (PE, MI) → streaming → guardrails → OTel + token/cost metrics → eval loop → multi-zone HA, multi-region DR, model routing for cost.

---

## Practice Tips
- For every RAG/agent question, be ready to **draw the pipeline**.
- Always tie answers to **cost, security, and evaluation** — that's the architect lens.
- Know the **Azure-native mapping**: AOAI, AI Search, APIM (AI gateway), Semantic Kernel, Managed Identity, private endpoints.

---

> Next: Top 50 Kubernetes.
