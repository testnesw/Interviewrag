# DEEP MECHANICS · Model Routing & Cascading

> Level 2 — routing requests to the right model by difficulty/cost, cascades,
> and the quality/cost/latency trade-off.

---

## 0. The precise mental model
Not every request needs your most expensive model. **Model routing** sends each query to the **cheapest model that can handle it** — a small/fast model for easy queries, a frontier model for hard ones. **Cascading** is a specific pattern: try the cheap model first, **escalate only if its answer is low-confidence**. Both optimize the **cost × quality × latency** triangle at scale.

---

## 1. Why route
- Frontier models are 10–50× the cost/latency of small ones; **most production queries are easy**.
- Routing can cut cost dramatically (often 50–80%) while keeping quality near frontier — you pay for the big model only when needed.

## 2. Routing strategies
- **Predictive routing** (router decides *before* calling): a classifier/small LLM predicts difficulty/category → picks the model. Fast, one call, but router can mis-predict.
- **Cascading** (try then escalate): call cheap model → **judge confidence** → if low, escalate to a bigger model. Higher quality guarantee, but escalated requests pay **twice** (cheap + expensive).
- **Rule/feature-based**: route by task type, prompt length, required tools, language, or tier of the calling customer.
- **Semantic routing**: embed the query → route by similarity to known categories (e.g., to a specialized model/prompt).

## 3. The confidence signal (for cascades)
- How to decide "escalate"? — model **logprobs/self-reported confidence**, a **verifier/judge** model, answer-consistency (self-consistency samples disagree → hard), or task-specific checks (did it refuse / say "I'm not sure").
- Calibration matters: a mis-calibrated confidence either wastes escalations or ships bad answers.

## 4. Where it fits in an architecture
- Sits in the **orchestrator / gateway** (ties to the LLM Gateway design): the router is a policy in front of multiple model deployments.
- Combine with **semantic cache** (skip models entirely for repeats) and **prompt caching** (cheapen the calls that remain).
- Also route across **modalities/providers** (e.g., cheap open model self-hosted vs AOAI frontier).

## 5. Trade-offs
- **Predictive**: lowest latency/cost (one call) but bounded by router accuracy.
- **Cascade**: best quality safety net but extra latency + double cost on escalations → tune the escalation threshold to your quality SLO.
- Adds **complexity** (a router to build, monitor, and evaluate) → justify with volume.
- Router itself must be **evaluated** (routing accuracy, cost saved, quality retained).

## 6. Tooling / patterns
- **RouteLLM**, **Martian**, framework routers, or a custom small-LLM/classifier.
- **LLM-as-judge** for cascade confidence; **model garden** of tiered deployments (nano/mini/frontier).

## 7. The hard follow-ups (with answers)
1. **"Why route models?"** → most queries are easy → use the **cheapest capable model**, pay for frontier only when needed → big cost cut. (§1)
2. **"Predictive routing vs cascading?"** → predict-then-call (one call, router may err) vs try-cheap-then-escalate-on-low-confidence (quality safety net, double cost on escalation). (§2)
3. **"How decide to escalate?"** → confidence signal: logprobs, judge model, self-consistency, refusal detection — must be **calibrated**. (§3)
4. **"Where does the router live?"** → orchestrator/gateway policy in front of tiered deployments; combine with caching. (§4)
5. **"Downside of cascades?"** → escalated requests pay twice + added latency → tune threshold to SLO. (§5)
6. **"How do you know routing works?"** → evaluate routing accuracy, cost saved, quality retained vs always-frontier. (§5)

## 8. One-screen recall
- **Route each query to the cheapest capable model** → cut cost 50–80% near frontier quality.
- **Predictive** (classify → pick model, one call) vs **Cascade** (cheap → **escalate on low confidence**, double cost).
- **Confidence**: logprobs / judge / self-consistency / refusal → must be **calibrated**.
- Lives in **gateway/orchestrator**; combine with **semantic + prompt caching**; can route across providers/modalities.
- **Trade-off**: predictive = cheapest/fastest (router error); cascade = quality net (extra latency/cost) → tune threshold.
- Evaluate the router (accuracy, cost saved, quality retained). Tools: RouteLLM/Martian/custom.

> Next: Agentic Memory Architectures.
