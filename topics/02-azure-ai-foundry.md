# 02 · Azure AI Foundry

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Azure AI Foundry is the **one place to build, test, deploy, and manage AI apps** on Azure. Think of it as the "studio + factory" for LLM apps — model catalog, playground, prompt flow, evaluation, and deployment in a single portal/SDK.

## 2. Architect-Level Explanation
Foundry provides a **project-based control plane** over the AI lifecycle:
- **Hub + Projects**: a Hub holds shared resources (connections, compute, storage, Key Vault, security); Projects are workspaces inheriting from it.
- **Model catalog**: OpenAI, Meta Llama, Mistral, Phi, Cohere, plus MaaS (Models-as-a-Service) serverless endpoints.
- **Prompt Flow**: DAG-based orchestration for LLM pipelines (RAG, tools) with tracing/evaluation.
- **Evaluation**: built-in metrics (groundedness, relevance, coherence, safety) + custom evaluators.
- **Connections**: managed links to AOAI, AI Search, storage — secured via Managed Identity.
- Governance layer over deployment (content safety, quotas, tracing to App Insights).

## 3. Real Enterprise Use Case
A pharma company standardizes GenAI development: central Hub with governed connections to AOAI + AI Search, each product team gets a Project, builds RAG pipelines in Prompt Flow, runs groundedness/safety evaluations gated in CI before promoting endpoints to prod.

## 4. Architecture Diagram (ASCII)
```
                 Azure AI Foundry Hub
        (shared: connections, compute, Key Vault, storage)
                 │            │             │
            Project A     Project B     Project C
                 │
   Model Catalog ─► Prompt Flow (DAG) ─► Evaluation ─► Deploy Endpoint
        │               │                    │
      AOAI          AI Search          App Insights (trace)
```

## 5. Interview Questions
1. Hub vs Project — how do you structure them for an enterprise?
2. When do you use Foundry vs building with raw SDKs?
3. How does Foundry help govern GenAI at scale?
4. What is Prompt Flow and why use it over custom code?
5. How do MaaS/serverless model endpoints differ from AOAI deployments?

## 6. Strong Interview Answers
- **Hub/Project**: "One Hub per business unit for shared security/connections/cost boundary; a Project per app/team so they inherit governance but stay isolated. This mirrors landing-zone thinking for AI."
- **Foundry vs SDK**: "Foundry accelerates with catalog, evaluation, tracing, and governance out of the box; raw SDKs give max control. I use Foundry for standardization/evaluation and drop to SDK for custom runtime — they're complementary."
- **Governance**: "Central connections via Managed Identity, content safety, quota, and evaluation gates — so every project ships measured, safe endpoints, not ad-hoc scripts."
- **Prompt Flow**: "A traceable DAG of LLM/tool/python nodes with built-in evaluation and versioning — reproducible pipelines vs untracked notebooks."

## 7. Common Mistakes
- One giant Hub for the whole org (blast radius, cost mixing).
- Skipping evaluation → shipping unmeasured quality.
- Hardcoding keys in connections instead of Managed Identity.
- Treating Prompt Flow demos as production without CI/eval gates.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Foundry Prompt Flow | fast, traceable, eval built-in | less runtime control |
| Raw SDK app | full control | build eval/governance yourself |
| MaaS serverless | no infra, pay-per-token | less tuning than dedicated |

## 9. Production Best Practices
- Hub-per-BU, Project-per-app; least-privilege RBAC.
- Evaluation gates (groundedness/safety) in CI/CD.
- Trace everything to App Insights; version prompts/flows.
- Managed Identity connections; private networking.

## 10. Security Considerations
- Managed Identity for all connections; no keys.
- Private endpoints for Hub storage/Key Vault/AOAI/Search.
- Content Safety + prompt-injection evaluation.
- RBAC isolation between projects; data residency per region.

## 11. Cost Optimization
- Serverless MaaS for spiky/low volume; dedicated for steady.
- Reuse shared compute at Hub; shut down idle compute.
- Evaluate with smaller models; cache eval datasets.

## 12. Troubleshooting Scenarios
- **Connection auth fails** → Managed Identity role assignment on target resource.
- **Flow errors** → check node trace in Prompt Flow run.
- **Low eval scores** → retrieval/grounding issue upstream (see RAG topic).

## 13. Hands-on Example
```bash
az ml workspace create --kind hub -n ai-hub -g rg-ai
az ml workspace create --kind project -n proj-copilot --hub-id <hub-id> -g rg-ai
```

## 14. Terraform Example
```hcl
resource "azurerm_ai_foundry" "hub" {
  name                = "ai-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  storage_account_id  = azurerm_storage_account.sa.id
  key_vault_id        = azurerm_key_vault.kv.id
  identity { type = "SystemAssigned" }
}

resource "azurerm_ai_foundry_project" "proj" {
  name               = "proj-copilot"
  location           = azurerm_ai_foundry.hub.location
  ai_services_hub_id = azurerm_ai_foundry.hub.id
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```bash
az ml connection create --file aoai-connection.yml \
  --workspace-name proj-copilot -g rg-ai   # Managed Identity based
```

## 16. FastAPI / Python Example
```python
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

project = AIProjectClient.from_connection_string(
    conn_str="<project-connection-string>", credential=DefaultAzureCredential())
chat = project.inference.get_chat_completions_client()
r = chat.complete(model="gpt-4o",
    messages=[{"role": "user", "content": "Summarize Foundry"}])
```

## 17. AKS Example
Foundry-deployed endpoints are called from AKS microservices via Workload Identity; the Hub's private endpoints keep traffic on the VNet.

## 18. How to Remember
**"The AI app factory."** Catalog (raw materials) → Prompt Flow (assembly) → Evaluation (QA) → Deploy (shipping).

## 19. Real-World Analogy
A film studio: shared sound stages and equipment (Hub), individual movie sets (Projects), a script pipeline (Prompt Flow), and test screenings (Evaluation) before release.

## 20. One-Page Cheat Sheet
- **What**: unified studio to build/eval/deploy/govern AI apps.
- **Structure**: Hub (shared) → Projects (apps).
- **Build**: Model Catalog + Prompt Flow (traceable DAG).
- **Quality**: built-in evaluation (groundedness/safety) as gates.
- **Secure**: Managed Identity connections + private endpoints.
- **Cost**: MaaS serverless for spiky, dedicated for steady.
