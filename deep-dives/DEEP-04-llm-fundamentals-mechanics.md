# DEEP MECHANICS · LLM Fundamentals

> Level 2 — what a transformer actually does token-by-token: attention,
> parameters, context window, temperature/sampling, and why LLMs hallucinate.

---

## 0. The precise mental model
An LLM is a **next-token predictor**: given a sequence of tokens, it outputs a **probability distribution over the vocabulary** for the next token, samples one, appends it, and repeats (**autoregression**). All "reasoning" is emergent from this one operation at scale. The magic is the **transformer** architecture + **self-attention**, which lets every token weigh every other token to build context-aware representations.

---

## 1. Tokens & embeddings
- **Tokenization** — text is split into **tokens** (subword units, ~4 chars/token in English) via BPE. The model never sees characters; it sees token IDs.
- **Embedding** — each token ID maps to a **vector** (learned). Similar meanings → nearby vectors. Position is added via **positional encoding** (transformers have no inherent order).

## 2. Self-attention — the core mechanism
For each token, attention computes **Query, Key, Value** vectors. The token's Query is dot-producted with every other token's Key → **attention scores** (softmax-normalized) → weighted sum of Values. Result: each token's representation is a **context-aware blend** of all relevant tokens.
- **Multi-head** = many attention computations in parallel, each learning different relationships (syntax, coreference, etc.).
- Complexity is **O(n²)** in sequence length → why long context is expensive (§4).

## 3. Parameters & layers
- **Parameters** = the learned weights (billions). More params ≈ more capacity/knowledge (and cost).
- Stacked **transformer blocks** (attention + feed-forward + residual + normalization) refine representations layer by layer. The final layer projects to vocab logits.

## 4. Context window — the working memory
The **context window** = max tokens (input + output) the model can attend to at once. Everything the model "knows" for this call must fit here. Bigger window = more context but **O(n²)** attention cost + more $ per call. When exceeded, you truncate/summarize/RAG.

## 5. Sampling & temperature — controlling output
The model outputs logits → softmax → probabilities. How you pick the next token:
- **Temperature** — scales the distribution. Low (0–0.3) = deterministic/focused; high (0.8–1.2) = creative/random. T=0 ≈ greedy (always top token).
- **Top-p (nucleus)** — sample from the smallest set of tokens whose cumulative probability ≥ p.
- **Top-k** — sample from the top k tokens.
- For factual/extraction → low temp. For brainstorming → higher.

## 6. Why LLMs hallucinate
The model optimizes for **plausible next tokens**, not truth. It has no built-in fact-checker and its knowledge is **frozen at training cutoff**. When uncertain it still produces confident-sounding text. Mitigations: **RAG** (ground in retrieved facts), lower temperature, ask for citations, and evaluation/guardrails.

## 7. Training stages (context)
- **Pre-training** — predict next token on massive corpus → base model (knowledge).
- **Instruction tuning / SFT** — fine-tune on instruction→response pairs → follows instructions.
- **RLHF/DPO** — align to human preferences (helpful, harmless).

## 8. The hard follow-ups (with answers)
1. **"What does an LLM fundamentally do?"** → predict the next token from a probability distribution, autoregressively. (§0)
2. **"Explain attention."** → Q·K scores → softmax → weighted sum of V; each token attends to all others. (§2)
3. **"Why is long context expensive?"** → attention is O(n²) in sequence length. (§2,4)
4. **"What does temperature do?"** → scales the output distribution's randomness; low=deterministic, high=creative. (§5)
5. **"Why do LLMs hallucinate?"** → trained for plausibility not truth, frozen knowledge → RAG/low-temp/citations. (§6)
6. **"Context window meaning?"** → max input+output tokens attended at once; overflow → truncate/summarize/RAG. (§4)

## 9. One-screen recall
- **LLM = autoregressive next-token predictor** over a vocab distribution.
- **Tokens** (subwords) → **embeddings** + **positional encoding**.
- **Self-attention**: Q·K→softmax→weighted V; **multi-head**; **O(n²)**.
- **Params** (billions) in stacked transformer blocks → vocab logits.
- **Context window** = input+output token budget = working memory.
- **Sampling**: **temperature** (randomness), **top-p/top-k**. Low temp = factual.
- **Hallucination** = plausibility over truth + frozen knowledge → RAG, low temp, citations.
- **Training**: pre-train → SFT/instruction → RLHF/DPO.

> Next: GenAI Fundamentals.
