# 112 · Microsoft Sentinel

> Domain: Security & Identity · Level: Principal Security / Identity Architect

## 1. Beginner Explanation
Microsoft Sentinel is a **cloud security operations platform (SIEM)**. It collects security logs from across your environment, uses analytics and AI to detect threats, alerts your security team, and helps them investigate and respond — a central "command center" for security.

## 2. Architect-Level Explanation
A cloud-native **SIEM + SOAR** built on Log Analytics:
- **SIEM**: **Security Information and Event Management** — ingest, normalize, correlate, and analyze security data at scale to detect threats.
- **SOAR**: **Security Orchestration, Automation and Response** — **playbooks** (Logic Apps) automate response (isolate host, disable user, create ticket).
- **Data ingestion**: **data connectors** (Entra ID, Defender, Azure activity, M365, AWS/GCP, firewalls, syslog/CEF, Codeless Connector) into a **Log Analytics workspace**; **KQL** is the query language.
- **Detection**: **analytics rules** (scheduled KQL, near-real-time, Microsoft/ML) → **incidents**; **UEBA** (user/entity behavior analytics); **Fusion** (ML multi-stage attack correlation); anomaly detection.
- **Threat intelligence**: TI feeds + indicators for matching.
- **Investigation**: **incidents** group related alerts + entities; investigation graph; **hunting** (proactive KQL queries) + notebooks; entity pages.
- **Response**: automation rules + playbooks (SOAR); integrates with **Defender XDR** (unified in the Defender portal).
- **Content**: solutions/content hub (packaged connectors + rules + workbooks + playbooks); **workbooks** for dashboards.
- **Cost model**: pay per GB ingested/retained → data collection + tiering (basic/analytics/archive) matters.
- **Zero Trust**: the detection + response layer aggregating signals (identity, endpoint, cloud, network).

## 3. Real Enterprise Use Case
A SOC runs Microsoft Sentinel: connectors ingest Entra sign-ins, Defender for Cloud/Endpoint alerts, M365, firewall, and AWS logs; **analytics rules** + **Fusion** + **UEBA** detect multi-stage attacks and impossible-travel; alerts become **incidents** with an investigation graph; **playbooks** auto-disable compromised users and isolate hosts; analysts **hunt** proactively with KQL; **workbooks** dashboard posture — 24/7 detection + automated response across the enterprise.

## 4. Architecture Diagram (ASCII)
```
   Data Connectors ─► Log Analytics workspace (KQL)
   ┌──────────┬─────────┬─────────┬────────┬──────────┐
   Entra ID   Defender  M365      Firewall AWS/GCP/syslog
        │ analytics rules (KQL/ML) + Fusion + UEBA + TI
        ▼
   ALERTS ─► INCIDENTS (entities + investigation graph)
        │ hunting (proactive KQL) · notebooks
        ▼  SOAR
   Automation rules + Playbooks (Logic Apps): disable user · isolate host · ticket
   Unified with Defender XDR | Cost = GB ingested (basic/analytics/archive tiers)
```

## 5. Interview Questions
1. What is Sentinel (SIEM vs SOAR)?
2. How does data get in, and what is KQL?
3. Analytics rules, incidents, Fusion, UEBA?
4. What is hunting vs detection?
5. How do you manage Sentinel cost?

## 6. Strong Interview Answers
- **SIEM/SOAR**: "Sentinel is a cloud-native **SIEM** (collect + correlate + detect across all security data) plus **SOAR** (automate response via playbooks). It's the SOC's central platform for detection, investigation, and response, built on Log Analytics and scaling elastically without managing SIEM infrastructure."
- **Ingestion/KQL**: "**Data connectors** pull logs from Entra, Defender, M365, Azure, multi-cloud, firewalls, and syslog/CEF into a Log Analytics workspace. Analysts query and build detections with **KQL** (Kusto Query Language) — powerful for filtering, aggregating, and correlating large log volumes."
- **Rules/incidents/Fusion/UEBA**: "**Analytics rules** (scheduled KQL, near-real-time, or ML) generate alerts that group into **incidents** with related entities. **Fusion** uses ML to correlate low-fidelity signals into high-fidelity multi-stage attack incidents. **UEBA** baselines user/entity behavior to flag anomalies like impossible travel or unusual access."
- **Hunting vs detection**: "Detection is automated (rules fire alerts). **Hunting** is proactive — analysts run KQL queries and notebooks to search for threats that haven't triggered alerts, based on hypotheses/TTPs (MITRE ATT&CK). Successful hunts become new detection rules."
- **Cost**: "Cost is driven by **GB ingested and retained**, so I filter/route noisy logs, use **basic/auxiliary logs** and **archive tiers** for low-value/high-volume data, keep only security-relevant logs in the analytics tier, set retention appropriately, and leverage commitment tiers — balancing coverage vs spend."

## 7. Common Mistakes
- Ingesting everything → runaway cost + noise.
- Alert fatigue (untuned rules, no incident grouping/automation).
- No SOAR playbooks → slow manual response.
- Missing key connectors (identity/endpoint) → blind spots.
- No hunting/threat intel → only reactive.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Ingest more data | better coverage | higher cost |
| Aggressive automation | fast response | risk of wrong action |
| Long retention | investigations/compliance | storage cost |

## 9. Production Best Practices
- Prioritize high-value connectors (identity, endpoint, cloud, Defender).
- Tune analytics rules; use Fusion/UEBA; group into incidents.
- SOAR playbooks for common responses (with guardrails/approval).
- Data tiering (basic/archive) + retention + commitment tiers for cost.
- Hunting + threat intel + MITRE mapping; workbooks for the SOC; content hub solutions.

## 10. Security Considerations
- RBAC on the workspace + Sentinel roles (Reader/Responder/Contributor).
- Protect the SIEM data (it's sensitive); private access; audit analyst actions.
- Guardrails on automated response (avoid destructive false positives).
- Integrate Defender XDR for unified identity/endpoint/cloud signals.

## 11. Cost Optimization
- Filter/route logs; **basic/auxiliary** + **archive** tiers for noisy data.
- Right retention per data type; commitment (capacity) tiers for volume discounts.
- Avoid duplicate ingestion; keep only security-relevant analytics-tier logs.

## 12. Troubleshooting Scenarios
- **Runaway cost** → over-ingestion; tier/filter logs, adjust retention.
- **No alerts for a source** → connector not configured / rule missing.
- **Alert fatigue** → tune thresholds, enable incident grouping + automation.
- **Slow queries** → optimize KQL / summarize / narrow time range.
- **Playbook didn't run** → automation rule/permissions (Logic App identity) misconfig.

## 13. Hands-on Example
```kql
// Analytics rule (KQL): detect impossible travel / brute-force sign-ins
SigninLogs
| where ResultType != 0
| summarize failures = count() by UserPrincipalName, IPAddress, bin(TimeGenerated, 10m)
| where failures > 20            // → generates an alert/incident
```

## 14. Terraform Example
```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name = "law-sentinel" resource_group_name = var.rg location = "eastus"
  sku = "PerGB2018" retention_in_days = 90
}
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}
resource "azurerm_sentinel_alert_rule_scheduled" "bruteforce" {
  name = "bruteforce" log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  display_name = "Brute force sign-ins" severity = "High"
  query = "SigninLogs | where ResultType != 0 | summarize c=count() by IPAddress | where c > 20"
  query_frequency = "PT10M" query_period = "PT10M" trigger_threshold = 0
}
```

## 15. Azure Example
```bash
# Enable a data connector (e.g., Entra ID sign-in/audit logs) into Sentinel
az sentinel data-connector create -g rg --workspace-name law-sentinel \
  --data-connector-id aad --kind AzureActiveDirectory
```

## 16. FastAPI / Python Example
```python
# Query Sentinel/Log Analytics from an app for a custom security dashboard
from azure.monitor.query import LogsQueryClient
from azure.identity import DefaultAzureCredential

def recent_incidents(workspace_id: str):
    client = LogsQueryClient(DefaultAzureCredential())   # Managed Identity
    kql = "SecurityIncident | where TimeGenerated > ago(24h) | project Title, Severity, Status"
    return client.query_workspace(workspace_id, kql, timespan=None).tables[0].rows
```

## 17. AKS Example
AKS diagnostic + audit logs, Defender for Containers alerts, and Falco/runtime signals flow into Sentinel via connectors/DCRs. Analytics rules detect suspicious `kubectl exec`, privileged pod creation, or crypto-mining; a **playbook** can cordon a node or disable a compromised service account — cluster threats correlated with identity + cloud signals in one SOC view.

## 18. How to Remember
**"Cloud SIEM + SOAR on Log Analytics; connectors → KQL → analytics rules → incidents (Fusion/UEBA); hunt proactively; playbooks automate response; cost = GB ingested (tier it)."**

## 19. Real-World Analogy
A city's 911 command center: sensors and cameras everywhere feed in reports (connectors), dispatchers use smart systems to spot real emergencies among the noise (analytics/Fusion/UEBA), group related calls into one incident, and automatically dispatch responders with standard procedures (playbooks/SOAR). Detectives also proactively investigate patterns before crimes are reported (hunting).

## 20. One-Page Cheat Sheet
- **What**: cloud-native **SIEM** (detect) + **SOAR** (automate response) on Log Analytics.
- **Ingest**: **data connectors** (Entra/Defender/M365/multi-cloud/syslog) → workspace; query with **KQL**.
- **Detect**: **analytics rules** → **incidents**; **Fusion** (ML multi-stage), **UEBA**, threat intel.
- **Investigate**: incidents + entities + graph; **hunting** (proactive KQL) + notebooks; MITRE ATT&CK.
- **Respond**: automation rules + **playbooks** (Logic Apps); unified with **Defender XDR**.
- **Cost**: GB ingested/retained → tier (basic/archive) + filter + commitment tiers.
