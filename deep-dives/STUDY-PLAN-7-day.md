# 🗓️ 7-Day Interview Prep Schedule

> Goal: convert the deep-mechanics notes into **interview fluency**. Rule of the plan:
> **understand → say it out loud → attach a story**. Never memorize verbatim.

---

## How to use this plan
- **~2–3 hrs/day.** Each day = **Learn** (read + explain in your own words) → **Drill** (answer follow-ups out loud) → **Story** (attach one personal example).
- **The test for "I know this":** close the file and explain it to a rubber duck / phone voice memo. If you can re-derive the "why," you're safe under follow-ups.
- Mark each box as you go. Tick the **✅ self-check** only after you said it out loud without looking.
- End every day with **10 min** of the previous day's one-screen recalls (spaced repetition).

**Daily loop:** `Read → Explain aloud → Do the "hard follow-ups" section → Write 1 story → Recall yesterday`

---

## Day 1 — LLM & Transformer Internals
**Learn:** LLM fundamentals, tokens/context, attention & KV-cache (MHA/GQA/MLA), positional encodings/RoPE, MoE, decoding & sampling.
- [ ] 04-llm-fundamentals · DEEP-04f attention/KV-cache · DEEP-04g RoPE · DEEP-04h MoE · DEEP-04e decoding · DEEP-04b context/tokens
- [ ] **Drill aloud:** "Explain attention in 60s." "MHA vs GQA vs MLA?" "What does temperature do?" "Total vs active params in MoE?"
- [ ] **Story:** a time you dealt with token/cost/latency limits.
- ✅ Self-check: I can explain **KV-cache** and **why long context is expensive** without notes.

## Day 2 — Prompting, Quantization & Fine-Tuning
**Learn:** prompt engineering, structured outputs, quantization, fine-tuning methods, **LoRA/QLoRA (full)**, RLHF/DPO, distillation/compression.
- [ ] 05-prompt-engineering · DEEP-14b structured-outputs · DEEP-17b fine-tuning · DEEP-17c LoRA/QLoRA full · DEEP-17e RLHF/DPO · DEEP-17d distillation
- [ ] **Drill aloud:** "LoRA math + why B=0 init?" "QLoRA's 3 innovations?" "RLHF 3 stages + why the KL penalty?" "DPO vs RLHF?"
- [ ] **Story:** when you chose fine-tuning vs RAG vs prompting (and why).
- ✅ Self-check: I can derive **h = Wx + (α/r)·BAx** and explain **NF4 + double quant + paged optimizers**.

## Day 3 — RAG End-to-End
**Learn:** RAG architecture, chunking, embeddings, reranking, vector DBs/index types, GraphRAG, prompt caching, RAG evaluation.
- [ ] 06-rag-architecture · DEEP-07b embeddings · DEEP-08b reranking · DEEP-07c vector-index-types · DEEP-06b GraphRAG · DEEP-05b prompt-caching · DEEP-18b RAG-eval
- [ ] **Drill aloud:** "HNSW vs IVF vs PQ?" "Why rerank after retrieval?" "RAGAS metrics?" "Fix 'lost in the middle'?"
- [ ] **Story:** a RAG quality problem you diagnosed and fixed (recall/precision/grounding).
- ✅ Self-check: I can whiteboard a full **RAG pipeline** and name a failure mode at each stage.

## Day 4 — Agents
**Learn:** agentic AI, agent frameworks, LangGraph, multi-agent, agentic memory, function calling, MCP, model routing, agent evaluation.
- [ ] 11-agentic-ai · DEEP-11b frameworks · DEEP-10b LangGraph · DEEP-12-multi-agent · DEEP-11c memory · DEEP-14 function-calling · DEEP-13 MCP · DEEP-12b routing · DEEP-18c agent-eval
- [ ] **Drill aloud:** "ReAct loop?" "How does an agent remember across turns?" "Evaluate an agent — outcome vs trajectory?" "What is MCP?"
- [ ] **Story:** an agent/automation you designed — tools, guardrails, failure handling.
- ✅ Self-check: I can explain **memory types** + **why agents are hard to evaluate (pass^k)**.

## Day 5 — Azure AI Platform & Security
**Learn:** Azure OpenAI, AI Foundry, AI Search, safety, guardrails, prompt injection, responsible AI + identity/security basics (Entra, managed identity, Key Vault, private endpoint).
- [ ] 01-azure-openai · 02-ai-foundry · DEEP-08 AI-Search · DEEP-15 guardrails · DEEP-15b prompt-injection · 16-responsible-ai · 28-private-endpoint · 107-managed-identity · 108-key-vault
- [ ] **Drill aloud:** "Secure a GenAI app on Azure end-to-end?" "Defend against prompt injection?" "Private endpoint vs service endpoint?"
- [ ] **Story:** a security/compliance decision you made on a cloud project.
- ✅ Self-check: I can draw a **secure GenAI landing zone** (network + identity + data).

## Day 6 — Architecture, Ops & Multimodal
**Learn:** LLMOps/observability, evaluation benchmarks, cost optimization, inference optimization, multimodal/vision, diffusion, speech; WAF/HA/DR fundamentals.
- [ ] 19-llmops · DEEP-19b observability · DEEP-18d benchmarks · DEEP-04c inference-opt · 117-cost-optimization · DEEP-03b vision · DEEP-03c diffusion · DEEP-04d speech · 23-waf · 35-disaster-recovery
- [ ] **Drill aloud:** "How do you evaluate an LLM app in prod?" "Cut inference cost — levers?" "OCR vs native vision?"
- [ ] **Story:** how you monitored/optimized a system in production (cost, latency, quality).
- ✅ Self-check: I can list **LLMOps metrics** + name the right **benchmark** per capability.

## Day 7 — Mock Interviews & System Design
**Learn:** put it together. No new reading — **perform**.
- [ ] **Morning:** Level 3 rapid-fire drills (L3-07) — answer all out loud, timed.
- [ ] **Midday:** 2× Level 3 system-design scenarios (pick from L3-01…L3-06) using the **C-R-A-T-E-O** framework (L3-08) on a whiteboard/paper.
- [ ] **Afternoon:** full mock — have someone (or an AI) ask random "hard follow-ups" across all topics; you respond cold.
- [ ] **Evening:** review every ✅ you *couldn't* tick this week → targeted re-read.
- ✅ Self-check: I can run a **full system-design answer** (clarify → architecture → trade-offs → failure → operate) unprompted.

---

## C-R-A-T-E-O (system-design muscle memory)
**C**larify → **R**equirements (scale/SLA/cost) → **A**rchitecture → **T**rade-offs → **E**dge/failure cases → **O**bserve/Operate.

## The 3 habits that move you from 50% → 80–90%
1. **Explain, don't recite** — if you can't say it in your own words, you don't know it yet.
2. **Every topic gets a story** — "I did X, got Y result" beats theory every time.
3. **Rehearse the follow-up, not the answer** — interviewers score how you handle *"why?"* and *"what if it's 10×?"*.

## Daily spaced-repetition (10 min, non-negotiable)
- End of Day N → skim **one-screen recall** of Day N−1 and Day N−2.
- This is what makes it stick for the real interview.

> Reader tip: open this via START-HERE.bat → http://localhost:8080/deep-dives/index.html
