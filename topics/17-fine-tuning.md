# 17 · Fine-tuning

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Fine-tuning **further trains** a base model on your examples so it learns your style, format, or task — instead of instructing it every time via prompts.

## 2. Architect-Level Explanation
Adapting a pretrained model with supervised examples:
- **Types**: full fine-tune (all weights, costly), **PEFT/LoRA** (train small adapters — efficient, common), instruction tuning, **RLHF/DPO** (preference alignment).
- **Data**: high-quality prompt→completion pairs; quality > quantity; format matters.
- **When**: fix *behavior/style/format*, reduce prompt size, improve consistency, teach a narrow task — **not** to inject changing facts (use RAG).
- **On Azure**: AOAI fine-tuning (LoRA under the hood) or Azure ML for OSS models; deploy as a dedicated/serverless endpoint.
- Concerns: overfitting, catastrophic forgetting, data leakage, eval, staleness, and cost of retraining.

## 3. Real Enterprise Use Case
A support org fine-tunes gpt-4o-mini on 3k curated ticket→response pairs to enforce brand tone, structured JSON replies, and consistent policy language — cutting prompt length and improving consistency; facts still come via RAG.

## 4. Architecture Diagram (ASCII)
```
 Curated pairs (prompt→completion)
        │  validate/clean/split
        ▼
   Fine-tune (LoRA/PEFT) ─► candidate model
        │  evaluate vs base (golden set)
        ▼  pass?
   Deploy endpoint ─► serve   (facts via RAG, behavior via FT)
        │
   Monitor drift ─► periodic re-tune
```

## 5. Interview Questions
1. Fine-tuning vs RAG vs prompting — when each?
2. What is LoRA/PEFT and why prefer it?
3. How much/what data do you need?
4. Risks: overfitting, catastrophic forgetting?
5. How do you evaluate a fine-tuned model?

## 6. Strong Interview Answers
- **FT vs RAG vs prompt**: "Prompt first; RAG for facts/freshness/citations; fine-tune for *behavior, style, format, or a narrow skill*. Fine-tuning bakes in knowledge that goes stale, so don't use it for changing facts. Often FT (behavior) + RAG (facts) together."
- **LoRA/PEFT**: "Trains small low-rank adapters instead of all weights — far cheaper, faster, less memory, and swappable, with quality close to full fine-tuning for most tasks."
- **Data**: "A few hundred to a few thousand *high-quality, representative* pairs usually beat huge noisy sets. Diversity and correct formatting matter most; hold out an eval set."
- **Risks**: "Overfitting (memorizes, poor generalization) — mitigate with validation, early stopping, right data size; catastrophic forgetting (loses general ability) — mitigate with LoRA and mixed data."
- **Eval**: "Compare against the base model on a golden set with task metrics + safety; ship only if it wins and stays safe."

## 7. Common Mistakes
- Fine-tuning to add facts (use RAG).
- Small/noisy/unbalanced datasets.
- No held-out eval → overfitting unnoticed.
- Ignoring ongoing cost of re-tuning as needs change.

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| Prompt/RAG | flexible, current, cheap | prompt size/limits |
| Fine-tune | consistent behavior, shorter prompts | data+ops cost, staleness |
| Full FT | max adaptation | expensive, forgetting risk |
| LoRA | cheap, swappable | slightly less capacity |

## 9. Production Best Practices
- Start with prompt+RAG; fine-tune only when justified.
- Curate/validate data; hold out eval set.
- Prefer LoRA/PEFT; version datasets + models.
- Evaluate vs base before deploy; monitor drift.
- Automate a retraining pipeline (LLMOps).

## 10. Security Considerations
- Scrub PII/secrets from training data (leakage risk).
- Access control on datasets and model artifacts.
- Bias/harm evaluation post-tuning.
- Private endpoints for training data + endpoint.

## 11. Cost Optimization
- LoRA over full fine-tune; smaller base models.
- Fine-tune to shorten prompts (saves inference tokens).
- Serverless endpoint for spiky traffic; re-tune only when metrics drop.

## 12. Troubleshooting Scenarios
- **Overfitting** → more/diverse data, fewer epochs, early stopping.
- **Forgot general skills** → LoRA + mix general data.
- **No improvement** → data quality/format; maybe RAG was the real need.
- **Stale answers** → move facts to RAG, keep FT for behavior.

## 13. Hands-on Example (data format)
```jsonl
{"messages":[{"role":"system","content":"Brand tone."},
 {"role":"user","content":"Refund request"},
 {"role":"assistant","content":"{\"reply\":\"...\",\"action\":\"refund\"}"}]}
```

## 14. Terraform Example
```hcl
# Deploy the fine-tuned model as a dedicated AOAI deployment
resource "azurerm_cognitive_deployment" "ft" {
  name                 = "support-ft"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model { format = "OpenAI" name = "gpt-4o-mini-ft:custom" version = "1" }
  sku  { name = "Standard" capacity = 10 }
}
```

## 15. Azure Example
```bash
az cognitiveservices account deployment create -n myaoai -g rg-ai \
  --deployment-name support-ft --model-name <ft-model-id> \
  --model-format OpenAI --sku-name Standard --sku-capacity 10
```

## 16. FastAPI / Python Example
```python
# Upload data + create fine-tune job (AOAI)
f = client.files.create(file=open("train.jsonl","rb"), purpose="fine-tune")
job = client.fine_tuning.jobs.create(training_file=f.id,
        model="gpt-4o-mini-2024-07-18")
# later: deploy resulting job.fine_tuned_model
```

## 17. AKS Example
For OSS models, run LoRA training as a Kubernetes Job on GPU node pools in AKS; register the adapter in a model registry; serve via a scaled inference Deployment.

## 18. How to Remember
**"Teach behavior, not facts."** Fine-tune for *how* it responds; use RAG for *what* it knows.

## 19. Real-World Analogy
Sending an already-educated employee to a company onboarding course: they learn *your* tone, templates, and procedures — but for today's prices they still check the live system (RAG).

## 20. One-Page Cheat Sheet
- **What**: further-train a base model on your examples for behavior/style/format.
- **Use for**: consistency, tone, format, narrow skill, shorter prompts.
- **Not for**: changing facts → use RAG.
- **Method**: LoRA/PEFT (cheap, swappable) > full fine-tune.
- **Data**: small but high-quality/diverse; hold out eval set.
- **Risks**: overfitting, catastrophic forgetting → validation + LoRA + mixed data.
- **Combine**: fine-tune (behavior) + RAG (facts).
