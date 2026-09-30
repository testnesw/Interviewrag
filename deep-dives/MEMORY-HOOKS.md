# 🧠 Memory Hooks & Analogies (Fast Recall)

> Under pressure you don't recall paragraphs — you recall **anchors**. Each hook below
> pulls back a whole topic. Say the analogy out loud; it's your "oh right!" trigger.

---

## How to use
- Learn the **hook first**, then the detail hangs off it.
- In the interview: recall the analogy → it unlocks the mechanics → then you add your story.
- These are *triggers*, not scripts. One vivid image per topic.

---

## 🔤 Big-picture acronyms

**System design → "C-R-A-T-E-O"** (say: *"crate-oh"*)
**C**larify · **R**equirements · **A**rchitecture · **T**rade-offs · **E**dge/failure · **O**bserve/operate.
> Mnemonic: *pack your design into a **CRATE-O**.*

**RAG pipeline → "CERG-R"** — **C**hunk · **E**mbed · **R**etrieve · **G**round · **R**erank(optional).
> Say: *"Chunk, Embed, Retrieve, Ground."*

**RLHF stages → "SRP"** — **S**FT → **R**eward model → **P**PO.
> *"**S**tudy, **R**ank, **P**ractice."*

**QLoRA innovations → "NDP"** — **N**F4 · **D**ouble quant · **P**aged optimizers.
> *"**N**ever **D**rop **P**erformance."*

**LoRA knobs → "r-α-t"** — **r**ank, **α**lpha (scaling), **t**arget modules.

---

## 🎯 One-line analogies (the money list)

| Topic | Hook / analogy |
|---|---|
| **Attention (Q,K,V)** | **Dating app**: Query = what you want, Key = what each person offers, Value = their actual info. Best match gets most attention. |
| **KV-cache** | **Sticky notes of the past** — don't re-read the whole book each word; keep notes so you only add the new line. |
| **MHA → GQA → MLA** | **Carpool lanes**: MHA = everyone own car (big), MQA = one shared bus (cramped), **GQA = carpool groups** (just right). |
| **RoPE** | **Clock hands** — position = angle; two times' *difference* is what matters (relative distance). |
| **MoE** | **Hospital of specialists** — a receptionist (router) sends you to 2 relevant doctors, not all of them. Huge staff, small visit. |
| **Temperature** | **Spice level** — low = plain/predictable, high = wild/creative. |
| **Top-p (nucleus)** | **Buffet by fullness** — keep adding dishes until you hit 90% full, then choose. |
| **Embeddings** | **GPS coordinates for meaning** — similar meaning = nearby points. |
| **Vector search (HNSW)** | **Friend-of-a-friend** — hop through a social graph to find the closest match fast. |
| **Reranking** | **Resume shortlist → real interview** — cheap filter first, expensive judge second. |
| **RAG** | **Open-book exam** — model doesn't memorize, it looks up the right page first. |
| **Chunking** | **Cutting a pizza** — too big = won't fit, too small = lose the topping context. |
| **GraphRAG** | **Detective's corkboard** — connects entities with strings to answer "how are these related?" |
| **Fine-tuning vs RAG** | **Teach a skill (fine-tune) vs give a reference book (RAG).** Style → tune; facts → RAG. |
| **LoRA** | **Sticky tabs on a textbook** — don't rewrite the book, add small notes ($\Delta W = BA$). |
| **Quantization** | **JPEG compression for weights** — fewer bits, mostly looks the same. |
| **Distillation** | **Apprentice learning from a master** — student copies the teacher's instincts (soft labels). |
| **RLHF** | **Training a dog** — reward good answers, the KL leash stops it going feral. |
| **DPO** | **Skip the middleman** — learn straight from "this one's better" pairs, no reward model. |
| **Agent (ReAct)** | **Think → Act → Observe, repeat** — like a detective: reason, check a clue, reason again. |
| **Agentic memory** | **A person's memory** — scratchpad (working), diary (episodic), knowledge (semantic), habits (procedural). |
| **MCP** | **USB-C for AI tools** — one standard plug so any tool connects to any model. |
| **Function calling** | **Model orders from a menu** — it picks the tool + fills the form; you cook it. |
| **Guardrails** | **Bumpers in bowling** — keep the output out of the gutter. |
| **Prompt injection** | **Social engineering for LLMs** — "ignore your boss, listen to me." Treat input as untrusted. |
| **Multimodal/VLM** | **Giving the LLM eyes** — a translator turns the image into words it can read. |
| **Diffusion** | **Sculptor removing noise** — start with a marble block of static, chip away until an image appears. |
| **Speculative decoding** | **Intern drafts, boss approves** — small model guesses ahead, big model checks in bulk. |
| **KV-cache = why long context is pricey** | **Bigger whiteboard = more to hold** — memory grows with every token you keep. |
| **Lost in the middle** | **You remember the start & end of a movie, not the middle.** Put key info at edges. |
| **Private endpoint** | **Private driveway** — traffic never touches the public road (internet). |
| **Managed identity** | **Building badge, not a password** — Azure proves who you are, no secret to leak. |
| **Observability (traces)** | **Flight recorder** — every step logged so you can replay the crash. |

---

## 🔗 Topic-connection chains (how they link)

**The GenAI value chain (say it as one sentence):**
> *"Tokenize → embed → **attention** builds meaning → decode picks words; if it needs facts, **RAG**; if it needs skill, **fine-tune**; to act, **agent + tools**; to be safe, **guardrails**; to run it, **LLMOps**."*

**Cost/latency chain:**
> *"Too slow/expensive? → **quantize** the model → **KV-cache/GQA** the memory → **speculative decoding** the speed → **caching/routing** the requests → **MoE** for capacity-per-FLOP."*

**RAG quality chain:**
> *"Bad answers? → better **chunking** → better **embeddings** → **rerank** → tighten context (**lost-in-middle**) → measure with **RAGAS**."*

**Security chain:**
> *"Secure it → **private endpoint** (network) + **managed identity** (no secrets) + **Key Vault** (secrets) + **guardrails/injection defense** (content) + **RBAC/PIM** (access)."*

---

## 🧷 Number anchors (memorize these exact figures)

| Fact | Number |
|---|---|
| Mixtral MoE total / active | **47B / 13B** |
| Typical LoRA rank (r) | **8–64** |
| QLoRA base precision | **4-bit (NF4)** |
| Top-p common value | **0.9** |
| Temperature: factual vs creative | **~0 vs ~0.7–1.0** |
| Diffusion steps (normal vs distilled) | **20–50 vs 1–4** |
| Attention complexity | **O(n²)** |

> A single number said confidently ("Mixtral is 47B total but only 13B active") signals real depth.

---

## ✅ Will this help my success? — yes, here's the honest take
- **Hooks fight blanking** — stress kills recall; an anchor image survives it.
- **Analogies signal mastery** — explaining MoE as "a hospital of specialists" shows you *understand*, not memorized.
- **Chains show architecture thinking** — linking topics ("too slow? → quantize → KV-cache → spec-decoding") is exactly what senior interviews reward.
- **Numbers = credibility** — one precise figure beats a paragraph of hand-waving.

**But:** hooks are the *doorway*, not the room. Use them to trigger recall, then deliver the **real mechanics + your story**. Memorizing only the analogy = caught on the first "why?".

> Reader tip: open via START-HERE.bat → http://localhost:8080/deep-dives/index.html
