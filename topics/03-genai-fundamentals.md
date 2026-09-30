# 03 · Generative AI Fundamentals

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Generative AI creates **new content** — text, images, code, audio — instead of just classifying or predicting labels. It learns patterns from massive data and generates plausible new outputs.

## 2. Architect-Level Explanation
GenAI is built on **foundation models** (large neural nets, mostly Transformers) trained self-supervised on broad data, then adapted via prompting, RAG, or fine-tuning.
- **Modalities**: text (LLMs), image (diffusion), multimodal (vision+text), audio, code.
- **Core mechanics**: tokenization → embeddings → attention → next-token prediction (autoregressive) or denoising (diffusion).
- **Adaptation ladder**: prompt → few-shot → RAG → fine-tune → pretrain (cost/effort increases downward).
- Architect concerns: grounding, hallucination, cost/latency (tokens), safety, evaluation, and data governance.

## 3. Real Enterprise Use Case
A telecom deploys GenAI across the value chain: customer-support copilot (text), marketing image generation (diffusion), code assistant for engineers, and call-summarization (audio→text→summary) — all governed centrally.

## 4. Architecture Diagram (ASCII)
```
   Data ─► Pretrain ─► Foundation Model
                              │
         ┌──────────┬─────────┼──────────┬───────────┐
     Prompting   Few-shot    RAG      Fine-tune   Distillation
         └──────────┴─────────┴──────────┴───────────┘
                              ▼
               Governed App (safety + eval + cost)
```

## 5. Interview Questions
1. Discriminative vs generative models?
2. Adaptation options and when to use each?
3. Why do LLMs hallucinate?
4. Foundation model vs traditional ML model?
5. How do you choose a modality/model for a use case?

## 6. Strong Interview Answers
- **Disc vs gen**: "Discriminative models learn P(y|x) to classify; generative models learn to produce new samples (P(x) or next-token). GenAI generates content, which is why grounding and evaluation matter more."
- **Adaptation**: "Start cheapest: prompt → few-shot → RAG for facts → fine-tune for behavior/format → pretrain only at frontier scale. Most enterprise value is prompt + RAG."
- **Hallucination**: "Models predict plausible tokens, not truth; without grounding they fill gaps confidently. Mitigate with RAG, citations, and 'I don't know' behavior."
- **Model choice**: "Match modality, quality bar, latency, context length, and cost; benchmark on your own eval set, not leaderboards."

## 7. Common Mistakes
- Fine-tuning to add facts (use RAG instead).
- Chasing the biggest model when a small one suffices.
- No evaluation → subjective 'looks good' shipping.
- Ignoring token cost/latency at scale.

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| Prompt/RAG | fast, cheap, current | prompt/retrieval limits |
| Fine-tune | consistent behavior | data + ops cost, staleness |
| Bigger model | quality | cost/latency |

## 9. Production Best Practices
- Golden eval set + automated metrics.
- Grounding + guardrails by default.
- Token/cost observability per feature.
- Start small model, escalate only if eval demands.

## 10. Security Considerations
- Data governance for training/RAG data (PII, licensing).
- Prompt-injection and jailbreak defenses.
- Output safety (Content Safety) + human-in-loop for high risk.

## 11. Cost Optimization
- Right-size model; cache; compress context.
- Batch and stream; use mini/distilled models for cheap paths.

## 12. Troubleshooting Scenarios
- **Inconsistent output** → lower temperature, structure with schema/function calling.
- **Wrong facts** → add/repair RAG grounding.
- **Slow/expensive** → smaller model, fewer tokens, caching.

## 13. Hands-on Example
```python
# Deterministic-ish generation
client.chat.completions.create(model="gpt-4o", temperature=0.2,
  messages=[{"role":"user","content":"List 3 GenAI modalities"}])
```

## 14. Terraform Example
```hcl
# Provision the model deployment used by GenAI apps
resource "azurerm_cognitive_deployment" "embed" {
  name                 = "text-embedding-3-large"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model { format = "OpenAI" name = "text-embedding-3-large" version = "1" }
  sku  { name = "Standard" capacity = 50 }
}
```

## 15. Azure Example
```bash
az cognitiveservices account list-models -n myaoai -g rg-ai -o table
```

## 16. FastAPI / Python Example
```python
from fastapi import FastAPI
app = FastAPI()

@app.post("/generate")
def generate(prompt: str):
    r = client.chat.completions.create(model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}], temperature=0.3)
    return {"text": r.choices[0].message.content,
            "tokens": r.usage.total_tokens}
```

## 17. AKS Example
Host generation microservices in AKS; scale on request latency with HPA, route heavy vs cheap prompts to different model deployments.

## 18. How to Remember
**"Predict the next piece."** Text = next token, image = denoise to next clearer step — generation is repeated prediction.

## 19. Real-World Analogy
A jazz musician who learned thousands of songs — they improvise new music that fits the style, not copy an existing track.

## 20. One-Page Cheat Sheet
- **What**: models that create new content via learned patterns.
- **Base**: Transformers, tokens→embeddings→attention→next-token.
- **Adapt**: prompt → few-shot → RAG → fine-tune → pretrain.
- **Risks**: hallucination, cost/latency, safety.
- **Fix facts with RAG, behavior with fine-tune.**
- **Always evaluate on your own golden set.**
