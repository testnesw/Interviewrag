# 04 · LLM Fundamentals

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
An LLM (Large Language Model) predicts the **next word (token)** over and over to produce fluent text. Trained on huge text corpora, it can answer, summarize, translate, and code.

## 2. Architect-Level Explanation
- **Transformer** architecture: self-attention lets each token attend to others; decoder-only models (GPT) are autoregressive.
- **Tokens**: text split into subword tokens; cost/latency/context are measured in tokens.
- **Context window**: max tokens (input+output) the model can attend to (e.g., 128k).
- **Sampling params**: temperature, top_p, max_tokens, frequency/presence penalties.
- **Training stages**: pretraining → supervised fine-tuning → RLHF/DPO (alignment).
- **Inference concerns**: KV-cache, batching, latency (TTFT + tokens/sec), quantization.

## 3. Real Enterprise Use Case
A legal firm uses a long-context LLM to review 200-page contracts: full document fits in context, structured JSON output via function calling, temperature 0 for consistency, with citations back to clauses.

## 4. Architecture Diagram (ASCII)
```
 Prompt ─► Tokenizer ─► [Embeddings] ─► Transformer layers (attention)
                                             │
                              next-token probability distribution
                                             │  (sample: temp/top_p)
                                        append token ─► loop ─► Output
   Context window bounds total tokens (input + output)
```

## 5. Interview Questions
1. What is the context window and why does it matter?
2. Temperature vs top_p?
3. Pretraining vs fine-tuning vs RLHF?
4. Why are tokens important for cost and design?
5. How do you get deterministic, structured output?

## 6. Strong Interview Answers
- **Context window**: "It's the max tokens the model can consider at once; it bounds RAG context, chat history, and output. Exceeding it truncates or errors — so I manage history and retrieval budget carefully."
- **Temp vs top_p**: "Temperature scales randomness; top_p (nucleus) limits sampling to the top cumulative-probability mass. Lower both for deterministic/factual tasks, raise for creative ones. Tune one, not both."
- **Stages**: "Pretraining learns language broadly; SFT teaches instruction following; RLHF/DPO aligns to human preferences and safety."
- **Structured output**: "temperature 0 + function calling / JSON schema (structured outputs) to force valid, parseable results."

## 7. Common Mistakes
- Assuming bigger context = free (cost/latency scale with tokens).
- Setting high temperature for factual tasks.
- Parsing free-text instead of using structured outputs.
- Ignoring tokenization when estimating cost.

## 8. Trade-offs
| Lever | Higher | Lower |
|-------|--------|-------|
| temperature | creative, varied | deterministic |
| context used | more info | cost/latency↑ |
| model size | quality | cost/latency↑ |

## 9. Production Best Practices
- Cap max_tokens; manage conversation history (summarize/trim).
- Use structured outputs for machine-readable results.
- Pin model versions; regression-test on upgrades.
- Stream tokens for better perceived latency.

## 10. Security Considerations
- Treat all input (and retrieved text) as untrusted (prompt injection).
- Redact PII before logging prompts/outputs.
- Guardrail outputs for unsafe content.

## 11. Cost Optimization
- Trim prompts/history; smaller/mini models where possible.
- Prompt caching for repeated system prompts.
- Batch embeddings; stream to reduce timeouts.

## 12. Troubleshooting Scenarios
- **Truncated output** → raise max_tokens or reduce input.
- **Random answers** → lower temperature/top_p.
- **Context length error** → summarize history / reduce top-k.
- **Invalid JSON** → use structured outputs / function calling.

## 13. Hands-on Example
```python
r = client.chat.completions.create(model="gpt-4o", temperature=0,
    response_format={"type": "json_object"},
    messages=[{"role":"user","content":"Return {\"lang\":..} for: bonjour"}])
```

## 14. Terraform Example
```hcl
resource "azurerm_cognitive_deployment" "gpt" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model { format = "OpenAI" name = "gpt-4o" version = "2024-08-06" }
  sku  { name = "Standard" capacity = 30 }
}
```

## 15. Azure Example
```bash
# Inspect token usage via response.usage in logs; set quota per deployment
az cognitiveservices account deployment show -n myaoai -g rg-ai \
  --deployment-name gpt-4o
```

## 16. FastAPI / Python Example
```python
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4o")

@app.post("/estimate")
def estimate(text: str):
    return {"input_tokens": len(enc.encode(text))}
```

## 17. AKS Example
Run a token-metering sidecar/middleware in AKS pods to log tokens per request to Prometheus for cost dashboards and rate limiting.

## 18. How to Remember
**"Autocomplete on steroids."** It just keeps predicting the next token — everything else is prompting and plumbing.

## 19. Real-World Analogy
A world-class improv actor: given a scene setup (prompt), they continue it convincingly word by word — brilliant, but they'll confidently make things up if you don't give them the facts.

## 20. One-Page Cheat Sheet
- **Core**: Transformer, next-token prediction, tokens = cost/latency unit.
- **Context window**: bounds input+output; manage history/RAG budget.
- **Params**: temp/top_p (randomness), max_tokens (length).
- **Stages**: pretrain → SFT → RLHF/DPO.
- **Determinism**: temp 0 + structured outputs/function calling.
- **Security**: input is untrusted (prompt injection), redact PII.
