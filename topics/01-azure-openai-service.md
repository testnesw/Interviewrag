# 01 · Azure OpenAI Service

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Azure OpenAI Service gives you OpenAI models (GPT-4o, GPT-4.1, o-series, embeddings, DALL·E) hosted **inside Azure**, so you call them with your Azure identity, network, and compliance controls instead of the public OpenAI API.

## 2. Architect-Level Explanation
It is a **managed inference plane** exposed as an Azure resource. Key architectural properties:
- **Deployment model**: you create *deployments* (a model + version + capacity in TPM/PTU) inside an AOAI resource scoped to a region.
- **Capacity types**: Pay-as-you-go (TPM quota) vs **Provisioned Throughput Units (PTU)** for guaranteed latency/throughput.
- **Data plane isolation**: data is not used to train models; supports Private Endpoint + Managed Identity + Customer-Managed Keys.
- **Control plane**: ARM/Terraform for governance; **content filtering** and **abuse monitoring** run as a policy layer.
- Integrates with **Azure AI Search** (RAG), **Content Safety**, and **AI Foundry** for orchestration/evaluation.

## 3. Real Enterprise Use Case
A bank builds an internal "knowledge copilot" for 40k employees. AOAI (GPT-4o) with PTU for predictable latency, private-endpoint-only networking, Entra ID auth, and RAG over policy documents in Azure AI Search. Content filtering + logging to meet regulatory audit.

## 4. Architecture Diagram (ASCII)
```
        Entra ID (OAuth)                 Private DNS
              │                               │
   User ─► App (FastAPI) ─► Private Endpoint ─► Azure OpenAI
              │                                   │  (GPT-4o / embeddings, PTU)
              │                                   ▼
              └──► Azure AI Search ◄── embeddings ┘
                     (vector + hybrid)
        Logs ─► Log Analytics / App Insights   Keys ─► Key Vault (CMK)
```

## 5. Interview Questions
1. PTU vs pay-as-you-go — when do you choose each?
2. How do you secure AOAI end-to-end in a regulated enterprise?
3. How do you handle regional quota limits and DR for AOAI?
4. How does content filtering work and can you tune it?
5. How do you get predictable latency under load?

## 6. Strong Interview Answers
- **PTU vs PAYG**: "PAYG (TPM quota) is elastic and cheapest for spiky/low volume; PTU reserves dedicated capacity giving deterministic latency and throughput — I use PTU for customer-facing SLAs and PAYG for internal/batch. Often a hybrid: PTU baseline + PAYG spillover."
- **Security**: "Private Endpoints only (disable public network), Managed Identity instead of keys, CMK in Key Vault, diagnostic logs to Log Analytics, and Content Safety + abuse monitoring. RBAC via `Cognitive Services OpenAI User/Contributor`."
- **DR**: "Multi-region deployments behind APIM or a load-balancing gateway; replicate the AI Search index; use retry with regional failover. Watch that model/version availability differs per region."

## 7. Common Mistakes
- Using API keys instead of Managed Identity.
- Assuming a model version exists in every region.
- No token/cost budgeting → runaway spend.
- Ignoring TPM rate-limit (429) handling with backoff.
- Treating PTU as elastic (it's reserved capacity).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| PTU | Deterministic latency | Pay for reserved capacity |
| PAYG | Elastic, cheap at low volume | Throttling, variable latency |
| Public OpenAI | Fastest model access | No Azure compliance/network controls |

## 9. Production Best Practices
- Put **APIM** in front for throttling, keyless auth, token metering, multi-region routing.
- Implement **retry + exponential backoff** on 429/500.
- Version-pin model deployments; test before auto-upgrade.
- Central **prompt + cost telemetry** (tokens in/out per request).
- Separate deployments per environment (dev/test/prod).

## 10. Security Considerations
- Disable public access; Private Endpoint + Private DNS.
- Managed Identity + RBAC least privilege.
- CMK encryption, Key Vault for any secrets.
- Log prompts/responses carefully (PII redaction before storage).
- Enforce Content Safety (jailbreak/prompt-injection filters).

## 11. Cost Optimization
- Use smaller/cheaper models (gpt-4o-mini) where quality allows.
- Cache frequent responses; use **prompt caching**.
- Trim context (RAG top-k tuning) to cut input tokens.
- PTU only for sustained high volume; PAYG otherwise.
- Batch embeddings; monitor tokens per feature.

## 12. Troubleshooting Scenarios
- **429 TooManyRequests** → raise TPM quota / add PTU / backoff.
- **High latency** → move to PTU, reduce max_tokens, region proximity.
- **Content filter blocks** → inspect `content_filter_results`, adjust severity policy.
- **401/403** → check Managed Identity role assignment propagation.

## 13. Hands-on Example (REST)
```bash
curl https://myaoai.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-10-21 \
  -H "Authorization: Bearer $(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Explain PTU in one line"}],"max_tokens":100}'
```

## 14. Terraform Example
```hcl
resource "azurerm_cognitive_account" "aoai" {
  name                  = "myaoai"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "myaoai"
  public_network_access_enabled = false
  identity { type = "SystemAssigned" }
}

resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model { format = "OpenAI" name = "gpt-4o" version = "2024-08-06" }
  sku  { name = "Standard" capacity = 20 }   # 20 = 20K TPM
}
```

## 15. Azure Example (CLI)
```bash
az cognitiveservices account create -n myaoai -g rg-ai \
  --kind OpenAI --sku S0 -l eastus --custom-domain myaoai --yes
az cognitiveservices account deployment create -n myaoai -g rg-ai \
  --deployment-name gpt-4o --model-name gpt-4o --model-version 2024-08-06 \
  --model-format OpenAI --sku-capacity 20 --sku-name Standard
```

## 16. FastAPI / Python Example
```python
from fastapi import FastAPI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

app = FastAPI()
token = get_bearer_token_provider(DefaultAzureCredential(),
        "https://cognitiveservices.azure.com/.default")
client = AzureOpenAI(azure_endpoint="https://myaoai.openai.azure.com",
        azure_ad_token_provider=token, api_version="2024-10-21")

@app.post("/ask")
def ask(q: str):
    r = client.chat.completions.create(model="gpt-4o",
        messages=[{"role": "user", "content": q}], max_tokens=300)
    return {"answer": r.choices[0].message.content}
```

## 17. AKS Example
Run the FastAPI app in AKS using **Workload Identity** so pods call AOAI with no keys:
```yaml
serviceAccountName: aoai-sa   # federated to a Managed Identity with
                              # "Cognitive Services OpenAI User" role
```

## 18. How to Remember
**"OpenAI wrapped in Azure's coat"** — same models, plus Azure's identity, network, and compliance coat over them.

## 19. Real-World Analogy
Public OpenAI is eating at a food truck; Azure OpenAI is the same chef cooking inside your company's secured cafeteria — same food, your rules, your security guard at the door.

## 20. One-Page Cheat Sheet
- **What**: OpenAI models as an Azure resource.
- **Capacity**: TPM (PAYG) vs PTU (reserved).
- **Secure**: Private Endpoint + Managed Identity + CMK + Content Safety.
- **Scale/latency**: PTU + APIM + retry/backoff + multi-region.
- **Cost**: smaller models, caching, trim context, right capacity type.
- **RAG**: pair with Azure AI Search (embeddings + hybrid search).
- **Gotcha**: model versions differ per region; handle 429s.
