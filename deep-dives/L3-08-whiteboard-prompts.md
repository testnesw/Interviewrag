# LEVEL 3 · Mock Interview — Whiteboard Prompts & Delivery

> How to *perform* a design interview. A framework you can apply to any prompt,
> plus practice prompts with model outlines. Knowledge is Level 2; this is
> delivery.

---

## 0. The universal framework (memorize this)
**C-R-A-T-E-O** — drive every design interview through these 6 steps out loud:

1. **Clarify** — restate the problem; ask about scale, users, latency, constraints, compliance. (*Never start drawing immediately.*)
2. **Requirements** — split **functional** vs **non-functional** (the -ilities); call out **the killer constraint**.
3. **Architecture** — draw the high-level boxes + data flow (happy path first).
4. **Trade-offs** — justify each key choice with alternatives ("I'd use X over Y because…").
5. **Edge cases & failure** — scale bottlenecks, failure modes, security, cost.
6. **Observe/Operate** — monitoring, evaluation, rollout, iteration.

Say the step names as you go — it signals seniority and keeps you structured.

## 1. Delivery rules
- **Think out loud** — the interviewer scores your *reasoning*, not a perfect answer.
- **Drive the conversation** — propose, then check ("does that match your constraints?").
- **State assumptions** explicitly ("assuming ~5 QPS peak…").
- **Trade-offs, always** — there's no perfect design; name the cost of your choice.
- **Manage time** — breadth first (whole system), then depth where they probe.
- **It's OK to not know** — reason from principles: "I haven't used X, but I'd expect it to… because…".

## 2. Numbers worth knowing (back-of-envelope)
- 1 token ≈ 4 chars ≈ ¾ word. GPT-4o context ~128k tokens.
- Little's Law: concurrency = arrival rate × latency ($L=\lambda W$).
- p95/p99 matter more than average for UX.
- Rough: LLM call ~0.5–2s first token; retrieval ~200–400ms; cache hit ~5ms.
- 1M DAU ÷ 86,400s ≈ ~12 avg RPS → peak 10× ≈ 120 RPS → size for peak + headroom.

## 3. Practice prompt A — "Design a customer-support AI over our docs"
**Outline**: Clarify (languages, volume, permissions, deflection goal) → RAG platform (see L3-01): ingest+chunk+embed → **hybrid retrieve + rerank with ACL trimming** → grounded generate + cite → guardrails → log. Trade-offs: hybrid vs vector, PTU vs PAYG, chunk size. Failure: hallucination (grounding+eval), permission leak (retrieval trimming), cost (cache/route). Operate: groundedness eval + thumbs feedback.

## 4. Practice prompt B — "Our LLM feature is too slow and expensive at scale"
**Outline**: Clarify current numbers (latency, QPS, $/req, cache?). Diagnose: is it I/O-bound? scaling on wrong metric? no cache? Fixes (see L3-04): **streaming**, **semantic cache**, **model routing**, async + autoscale on concurrency, **PTU + PAYG**, token caps, trim context. Trade-off: cache staleness vs cost; cheaper model vs quality. Operate: first-token latency + cache-hit% + $/user dashboards.

## 5. Practice prompt C — "Make our GenAI platform compliant for a bank"
**Outline** (see L3-05): CAF landing zone + **Azure Policy** guardrails → hub-spoke + **private endpoints everywhere** + forced-tunnel egress → Entra + MI + PIM + RBAC → Key Vault/CMK + Content Safety → **audit every prompt/source** → Defender compliance dashboard + Sentinel. Killer point: "compliant by default via policy," "no data leaves the boundary."

## 6. Practice prompt D — "Stop prompt changes from silently breaking quality"
**Outline** (see L3-06): version prompts/models in Git + MLflow → **eval-as-CI-gate** on golden dataset (LLM-judge groundedness/safety/cost) → canary + online eval → prod monitoring + drift + feedback loop → dataset grows from failures. Killer point: "LLMs are non-deterministic → eval gate, not exact-match tests."

## 7. Practice prompt E — "Design an autonomous ops agent"
**Outline** (see L3-02): orchestrator-worker with specialized agents → tools via function calling/MCP (least privilege) → **human approval gate** for actions → loop/cost controls (max steps/budget) → prompt shields (untrusted tool output) → durable stateful orchestration → trace + audit every step. Killer point: "autonomy bounded by approval + guardrails + budgets."

## 8. Red flags to avoid
- Jumping to a solution before clarifying. · Ignoring non-functionals (security, cost, scale). · No trade-offs ("just use X"). · Hand-waving failure/edge cases. · Over-engineering a simple problem. · Not managing time (deep on one box, no full system).

## 9. One-screen recall
- **C-R-A-T-E-O**: Clarify → Requirements (func vs NFR + killer constraint) → Architecture (happy path) → **Trade-offs** → Edge/failure (scale/security/cost) → Observe/Operate.
- **Deliver**: think aloud, drive, state assumptions, always trade-offs, breadth→depth, principled when unsure.
- **Know the numbers** (tokens, Little's Law, p95, RPS math).
- **5 practice prompts** map to L3-01…06; each has a **killer point** to land.
- **Avoid**: solutioning early, skipping NFRs, no trade-offs, ignoring failure, over-engineering.

> End of Level 3. Loop back to Level 2 mechanics for any topic that felt shaky.
