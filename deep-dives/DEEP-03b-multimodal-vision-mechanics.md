# DEEP MECHANICS · Multimodal & Vision Models

> Level 2 — how LLMs "see", vision encoders + projection, multimodal RAG, OCR
> vs native vision, and use cases.

---

## 0. The precise mental model
A multimodal LLM (VLM) processes **images (and audio/video) alongside text** in the **same context**. The trick: a **vision encoder** turns an image into a sequence of **embeddings (visual tokens)** that are **projected into the LLM's token space**, so the language model attends to image and text tokens together. The LLM reasons over both as one sequence.

---

## 1. Architecture (how an LLM "sees")
```
Image → Vision Encoder (e.g., ViT/CLIP) → image embeddings
      → Projection / adapter (MLP or cross-attn) → visual tokens in LLM space
Text  → text tokens
      → LLM attends over [visual tokens + text tokens] → output
```
- **Vision encoder**: a Vision Transformer splits the image into **patches** → patch embeddings (like tokens for pixels).
- **Projection layer** (the bridge): maps vision embeddings into the LLM's embedding space (LLaVA-style MLP, or Flamingo-style **cross-attention**).
- Often only the projection (and optionally the LLM via LoRA) is trained → reuse a pretrained vision encoder + LLM.

## 2. Image tokens & cost
- An image becomes **many tokens** (resolution-dependent; high-res "detail" mode = far more) → **images are token-expensive** in the context window.
- Tiling high-res images into patches multiplies tokens → watch cost/latency; downscale when detail isn't needed.

## 3. Native vision vs OCR pipeline (common design question)
- **OCR pipeline**: extract text from the image first (Document Intelligence/OCR) → feed text to the LLM. Best for **dense documents**, precise text, layout/tables, auditability, cheaper.
- **Native vision**: send the image to a VLM → understands **layout + visuals + text holistically**, handles charts/diagrams/handwriting/photos, no brittle OCR step.
- **Choose**: structured document extraction at scale → OCR (+ maybe VLM for hard cases); visual understanding / mixed content / charts → native vision. Often **combine**.

## 4. Multimodal RAG
- **Options**:
  - **Caption/describe images → embed the text** → standard text retrieval (simple, lossy).
  - **Multimodal embeddings** (CLIP-style: text + image in one space) → retrieve images by text query and vice versa.
  - **VLM over retrieved images**: retrieve relevant pages/figures → pass images directly to a VLM to answer.
- For documents: retrieve page images/regions → VLM reads them → grounded answer with visual citations.

## 5. Capabilities & tasks
- Image Q&A, document understanding, chart/diagram reasoning, UI/screenshot understanding (agents that "see" a screen), OCR, captioning, visual grounding (bounding boxes), video understanding (sampled frames).

## 6. Limitations & cautions
- **Hallucination on fine detail** (small text, exact counts, precise spatial relations).
- **Token cost** for high-res; **resolution limits** (may miss tiny details → crop/zoom strategies).
- Safety: images can carry **prompt injection** (text embedded in an image) → treat visual content as untrusted (see prompt injection).
- Evaluation is harder (visual grounding correctness).

## 7. The hard follow-ups (with answers)
1. **"How does an LLM process an image?"** → vision encoder (ViT) → image embeddings → **projection into LLM token space** → attend jointly with text. (§1)
2. **"What does the projection layer do?"** → bridges vision embeddings into the LLM's embedding space (MLP or cross-attention). (§1)
3. **"Why are images expensive?"** → each image = **many tokens** (resolution-dependent, tiled) → high context cost. (§2)
4. **"OCR vs native vision for documents?"** → OCR for dense text/tables/audit/cost; native vision for layout+visuals+charts; often combine. (§3)
5. **"Do multimodal RAG?"** → caption→text embed, or **multimodal (CLIP) embeddings**, or retrieve images → **VLM** answers. (§4)
6. **"Main limitation?"** → hallucination on fine detail + resolution/token limits; visual prompt injection. (§6)
7. **"Agent that sees a screen?"** → VLM over screenshots for UI understanding/grounding. (§5)

## 8. One-screen recall
- **VLM**: **vision encoder (ViT/CLIP)** → image embeddings → **projection into LLM space** → LLM attends over **visual + text tokens** jointly.
- Images = **many tokens** (resolution/tiling) → expensive; downscale when possible.
- **OCR pipeline** (dense text/tables/cheap/audit) vs **native vision** (layout/charts/holistic) → often combine.
- **Multimodal RAG**: caption→embed, **CLIP multimodal embeddings**, or retrieve images → VLM reads.
- **Uses**: doc understanding, chart/UI/screenshot reasoning, captioning, grounding, video.
- **Cautions**: fine-detail hallucination, resolution limits, **image-borne prompt injection**.

> Next: back to the deep-dive index.
