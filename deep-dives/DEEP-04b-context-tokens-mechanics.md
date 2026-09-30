# DEEP MECHANICS · Context Windows, Tokens & Quantization

> 🧠 **Hook:** *A whiteboard* — bigger holds more but costs more to keep; the **KV-cache** is what fills it, growing with every token.
>
> Level 2 — tokenization, context limits, the cost of long context, KV cache,
> and quantization for efficient inference.

---

## 0. The precise mental model
An LLM processes **tokens** within a fixed **context window** (input + output). Attention cost grows with sequence length, so **long context is expensive** and quality can degrade ("lost in the middle"). **Quantization** shrinks model weights to lower precision → smaller/faster/cheaper inference with minor quality loss. Together these govern **what you can feed a model and how efficiently it runs**.

---

## 1. Tokens & tokenization
- Text is split into **sub-word tokens** (BPE); ~4 chars ≈ 1 token (English), more for code/other languages.
- Models **price and limit** by tokens; both **input + output** count.
- Same string tokenizes differently per model (different tokenizers).

## 2. Context window
- Max tokens the model can attend to at once (e.g., 128k, 200k, 1M).
- **Input + output share** the budget → leave room for the completion.
- Bigger window ≠ always better: **"lost in the middle"** — models attend best to the **start and end**; mid-context facts can be missed → put key info at edges.

## 3. The cost of long context
- Self-attention is **~O(n²)** in sequence length → long prompts = more compute + latency + $.
- Stuffing everything in ("just use the 1M window") is wasteful + can reduce accuracy → prefer **retrieval (RAG)** to send only relevant chunks.
- **Prefix caching** offsets cost of repeated long prefixes (see prompt caching).

## 4. KV cache (inference mechanics)
- During generation, the model caches **keys/values** of past tokens so each new token doesn't recompute the whole sequence → speeds decoding.
- KV cache grows with context length → **memory** bottleneck for long contexts / many concurrent requests (drives serving cost).

## 5. Quantization (efficient inference)
- Represent weights (and sometimes activations) in **lower precision**: FP16 → **INT8 / INT4** (e.g., GPTQ, AWQ, bitsandbytes, GGUF).
- **Benefits**: smaller memory footprint, faster, cheaper, run larger models on smaller GPUs.
- **Cost**: small accuracy drop (usually minor at 8-bit; more at 4-bit).
- Mostly relevant for **self-hosted/open models**; managed APIs (AOAI) handle this for you.

## 6. Related efficiency levers
- **Distillation** (train a small model to mimic a big one), **flash attention** (faster exact attention), **speculative decoding** (draft model proposes tokens), **LoRA/QLoRA** (parameter-efficient fine-tuning on quantized base).

## 7. The hard follow-ups (with answers)
1. **"What's a token?"** → sub-word unit; models price/limit by tokens (~4 chars each). (§1)
2. **"Bigger context window — just use it all?"** → no: **O(n²)** cost + latency + **lost-in-the-middle**; use RAG to send only relevant text. (§2/§3)
3. **"Where to put critical info in a long prompt?"** → **start or end** (models attend best to edges). (§2)
4. **"What's the KV cache?"** → cached keys/values of prior tokens → faster decoding; grows with length → memory bottleneck. (§4)
5. **"What is quantization + trade-off?"** → lower-precision weights (INT8/INT4) → smaller/faster/cheaper, minor accuracy loss. (§5)
6. **"Run a big model on a small GPU?"** → quantize (4-bit) + LoRA/QLoRA. (§5/§6)
7. **"Speed up generation?"** → flash attention, speculative decoding, KV cache, quantization. (§4/§6)

## 8. One-screen recall
- **Tokens** (~4 chars) priced/limited; **input+output share** the **context window**.
- Long context = **O(n²)** cost + **lost-in-the-middle** → prefer **RAG**; put key info at **edges**.
- **KV cache** speeds decoding but grows with length → memory/serving bottleneck.
- **Quantization** (FP16→INT8/INT4: GPTQ/AWQ/GGUF) = smaller/faster/cheaper, minor accuracy loss (self-hosted).
- **Levers**: distillation, flash attention, speculative decoding, **LoRA/QLoRA** on quantized base.

> Next: back to the deep-dive index.
