# DEEP MECHANICS · Decoding & Sampling

> 🧠 **Hook:** *Spice level* — temperature low = plain/predictable, high = wild/creative. **Top-p** = pile your plate to 90% full, then pick.
>
> Level 2 — how the model picks the next token: temperature, top-p/top-k,
> penalties, greedy vs sampling, and the knobs you set in the API.

---

## 0. The precise mental model
At each step the model outputs a **probability distribution over the whole vocabulary** (via a softmax over logits). **Decoding** is the strategy for turning that distribution into the next token. The knobs (**temperature, top-p, top-k, penalties**) reshape or truncate the distribution *before* sampling — controlling the **randomness/creativity vs determinism** trade-off. This is inference-time only; it doesn't change the weights.

---

## 1. Logits → probabilities
- Model → **logits** (raw scores per vocab token) → **softmax** → probabilities.
- Decoding then either takes the top token or **samples** from this distribution.

## 2. Greedy & beam search
- **Greedy**: always pick the argmax token. Deterministic, but repetitive/bland and can miss a better overall sequence.
- **Beam search**: keep the top-$k$ partial sequences, expand, keep best by total probability. Better for **closed-ended** tasks (translation); tends to be dull/repetitive for open-ended chat → rarely used for creative LLM chat.

## 3. Temperature (the main dial)
- Divides logits by $T$ **before** softmax: $p_i = \text{softmax}(z_i / T)$.
- **T < 1** → sharper distribution → more deterministic/focused. **T → 0** ≈ greedy.
- **T > 1** → flatter → more random/creative/diverse.
- Rule of thumb: factual/extraction/code → **low (0–0.3)**; brainstorming/creative → **high (0.7–1.0+)**.

## 4. Top-k and Top-p (nucleus) truncation
- **Top-k**: keep only the **k** highest-probability tokens, renormalize, sample. Fixed count.
- **Top-p (nucleus)**: keep the **smallest set whose cumulative probability ≥ p** (e.g., 0.9), then sample. **Adaptive** — few tokens when confident, more when uncertain → generally preferred over top-k.
- Usually you tune **either** temperature **or** top-p, not both aggressively.
- **Min-p** (newer): keep tokens above a fraction of the top token's prob → robust at high temperature.

## 5. Penalties (anti-repetition)
- **Frequency penalty**: lowers a token's logit proportional to how often it already appeared → reduces verbatim repetition.
- **Presence penalty**: flat penalty once a token appeared at all → encourages new topics.
- **Repetition penalty**: multiplicative variant. Too high → incoherent/avoids necessary words.

## 6. Determinism & other knobs
- **Seed**: with fixed seed + same params you get (near-)reproducible output; still not 100% guaranteed across hardware/batching (floating-point + non-deterministic kernels).
- **Stop sequences**: strings that halt generation.
- **max_tokens / logit_bias**: cap length / hand-tune specific token likelihoods.
- **logprobs**: return token probabilities → useful for confidence, routing, eval.
- **Structured/constrained decoding**: mask invalid tokens so output must match a grammar/JSON schema (see Structured Outputs).

## 7. The hard follow-ups (with answers)
1. **"What does temperature actually do?"** → scales logits **before softmax** ($z/T$); low = sharp/deterministic, high = flat/random. (§3)
2. **"Top-k vs top-p?"** → top-k = fixed N tokens; **top-p = adaptive** smallest set reaching cumulative p → preferred. (§4)
3. **"Temperature 0 — deterministic?"** → ≈ greedy, but not 100% reproducible across hardware/batching without a seed. (§3/§6)
4. **"Frequency vs presence penalty?"** → frequency scales with count; presence = flat once-seen → new topics. (§5)
5. **"Why not beam search for chat?"** → dull/repetitive for open-ended; better for translation/closed tasks. (§2)
6. **"Settings for factual extraction?"** → **low temp (~0)**, maybe top-p low → deterministic. (§3)
7. **"Force valid JSON at decode time?"** → **constrained/structured decoding** (token masking to a grammar). (§6)
8. **"Get a confidence signal?"** → **logprobs** of generated tokens. (§6)

## 8. One-screen recall
- Model → **logits → softmax → distribution**; decoding picks the next token.
- **Greedy** (argmax, deterministic/bland); **beam** (closed-ended tasks, not chat).
- **Temperature**: logits/$T$ before softmax → low = focused, high = creative.
- **Top-k** (fixed N) vs **Top-p / nucleus** (adaptive cumulative p → preferred); **min-p** robust at high T.
- **Penalties**: frequency (by count) / presence (flat) → anti-repetition.
- **Seed** (reproducibility), **stop sequences**, **max_tokens**, **logit_bias**, **logprobs** (confidence), **constrained decoding** (JSON/grammar).
- Factual → low temp; creative → high temp; tune temp **or** top-p.

> Next: back to the deep-dive index.
