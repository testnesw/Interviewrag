# DEEP MECHANICS · GenAI Fundamentals

> Level 2 — the landscape: generative vs discriminative, model families,
> foundation models, modalities, and where each technique (prompting vs RAG vs
> fine-tuning) fits.

---

## 0. The precise mental model
**Generative AI** = models that **create new content** (text, image, audio, code) by learning the distribution of training data and sampling from it — vs **discriminative** models that just **classify/predict a label**. Modern GenAI runs on **foundation models**: huge pre-trained models adaptable to many tasks. The architect's job is choosing **how to adapt** them: prompting, RAG, fine-tuning, or agents — cheapest/simplest first.

---

## 1. Generative vs discriminative
- **Discriminative** — learns P(label | input): "is this spam?" Boundaries between classes.
- **Generative** — learns P(data) so it can **produce** samples: "write an email." GenAI = generative at scale.

## 2. Foundation models & modalities
- **Foundation model** — trained on broad data, adaptable to many downstream tasks (GPT, Llama, embeddings models).
- **Modalities**: text (LLMs), image (diffusion — DALL·E, Stable Diffusion), audio (Whisper/TTS), **multimodal** (GPT-4o: text+image+audio), embeddings (vectors for search).
- **Diffusion models** (images) work by learning to **denoise** — start from noise, iteratively remove it guided by the prompt.

## 3. The adaptation ladder — cheapest first (key architect framing)
```
1. Prompt engineering   → zero training; steer with instructions/examples
2. RAG                  → inject external/current knowledge at query time
3. Fine-tuning          → change behavior/style/format with training data
4. Agents/tools         → let the model act (call APIs, multi-step)
```
Start at the top; go lower only when the level above can't meet the need. Fine-tuning is **not** for adding fresh facts (that's RAG).

## 4. When to use what
- **Prompting** — general tasks, quick iteration.
- **RAG** — need current/proprietary facts, citations, reduce hallucination.
- **Fine-tuning** — consistent style/format/tone, narrow task, latency/cost (smaller model matching bigger one on your task).
- **Agents** — multi-step tasks needing tools/actions.

## 5. Key GenAI concepts
- **Prompt** — the input instruction/context. **Completion** — the output.
- **Zero/one/few-shot** — number of examples in the prompt.
- **Grounding** — providing factual context (RAG) so answers are anchored.
- **Emergent abilities** — capabilities (reasoning, translation) that appear only at scale.
- **Hallucination, context window, tokens** — see LLM fundamentals.

## 6. The hard follow-ups (with answers)
1. **"Generative vs discriminative?"** → generate new content (P(data)) vs classify (P(label|x)). (§1)
2. **"What's a foundation model?"** → broad pre-trained model adaptable to many tasks. (§2)
3. **"Add fresh company knowledge — fine-tune or RAG?"** → **RAG**; fine-tuning teaches behavior/style, not current facts. (§3)
4. **"How do image models work?"** → diffusion: iteratively denoise from noise guided by prompt. (§2)
5. **"Order of adaptation techniques?"** → prompt → RAG → fine-tune → agents; simplest first. (§3)

## 7. One-screen recall
- **GenAI = create content** (P(data), sample) vs **discriminative** (classify).
- **Foundation models** = broad pre-trained, adaptable. Modalities: text/image(diffusion)/audio/multimodal/embeddings.
- **Adaptation ladder (cheap→expensive)**: **prompt → RAG → fine-tune → agents**. Simplest that works.
- **RAG for facts, fine-tune for behavior/style.**
- Concepts: prompt/completion, zero/few-shot, grounding, emergent abilities.

> Next: Prompt Engineering.
