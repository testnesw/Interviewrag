# 111 · Microsoft Defender for Cloud

> Domain: Security & Identity · Level: Principal Security / Identity Architect

## 1. Beginner Explanation
Microsoft Defender for Cloud is a **security management tool for your cloud**. It continuously checks your Azure (and multi-cloud) resources for misconfigurations and threats, gives you a **secure score**, and recommends fixes — helping you find and close security gaps.

## 2. Architect-Level Explanation
A **CNAPP** (Cloud-Native Application Protection Platform) combining CSPM + CWPP:
- **CSPM (posture management)**: continuous assessment against security best practices + regulatory standards (Microsoft Cloud Security Benchmark, CIS, PCI, ISO, NIST); **Secure Score**; **recommendations**; **attack path analysis** + **cloud security graph** (Defender CSPM tier); agentless scanning.
- **CWPP (workload protection)**: threat detection for **servers** (Defender for Servers + MDE), **containers/AKS** (runtime + image/registry scanning + K8s posture), **databases** (SQL/Cosmos), **storage** (malware scan), **Key Vault**, **App Service**, **APIs**, **DevOps** (Defender for DevOps — code/IaC/secret scanning).
- **Multi-cloud + hybrid**: onboard AWS/GCP + on-prem via Arc.
- **Alerts + threat protection**: behavioral analytics, threat intelligence → security alerts; integrates with **Sentinel** (SIEM) and **XDR**.
- **Compliance dashboard**: map posture to regulatory frameworks; export evidence.
- **Governance**: assign recommendation owners + due dates; workflow automation (Logic Apps).
- **Tiers**: free CSPM (foundational) vs paid **Defender plans** per resource type (enhanced CWPP + advanced CSPM).
- **Zero Trust + shift-left**: posture (prevent) + runtime (detect) + DevOps (code-to-cloud).

## 3. Real Enterprise Use Case
An enterprise onboards all subscriptions (+ AWS via connector) to Defender for Cloud: **Secure Score** drives remediation with assigned owners; **Defender for Servers/Containers/SQL/Storage** provide runtime threat detection and image scanning for AKS; **Defender for DevOps** scans IaC + secrets in pipelines; the **compliance dashboard** tracks PCI/ISO; alerts stream to **Sentinel** for the SOC — continuous, measurable, multi-cloud security posture + protection.

## 4. Architecture Diagram (ASCII)
```
        Microsoft Defender for Cloud (CNAPP = CSPM + CWPP)
   ┌──────────────── CSPM (posture) ────────────────┐
   Secure Score · recommendations · compliance (CIS/PCI/ISO)
   attack path analysis + security graph (agentless scan)
   ├──────────────── CWPP (protection) ─────────────┤
   Servers(MDE) · Containers/AKS · SQL/Cosmos · Storage · Key Vault · APIs · DevOps
   Multi-cloud: AWS/GCP + on-prem (Arc)
   Alerts/threat intel ─► Microsoft Sentinel (SIEM/XDR) ─► SOC
```

## 5. Interview Questions
1. What is Defender for Cloud (CSPM vs CWPP / CNAPP)?
2. What is Secure Score and how do you use it?
3. Which Defender plans matter for AKS/containers?
4. What is attack path analysis?
5. How does it integrate with Sentinel and multi-cloud?

## 6. Strong Interview Answers
- **CNAPP**: "It's a Cloud-Native Application Protection Platform: **CSPM** manages posture — continuously assessing configs against benchmarks and giving a Secure Score with prioritized recommendations — while **CWPP** protects running workloads with threat detection for servers, containers, databases, storage, etc. Together they cover prevent + detect across the cloud."
- **Secure Score**: "A quantified measure of your security posture (0–100%) based on how many recommendations you've remediated, weighted by impact. I use it to prioritize and track remediation over time, assign recommendation owners with due dates, and report posture to leadership — it makes security measurable."
- **AKS/container plans**: "**Defender for Containers** provides image/registry vulnerability scanning, Kubernetes posture (misconfig) checks, runtime threat detection (suspicious process/exec), and admission control insights. Combined with Defender for Servers on nodes, it secures the whole container supply chain and runtime."
- **Attack path analysis**: "In the Defender CSPM tier, the **cloud security graph** models resources + relationships to surface **attack paths** — chains of misconfigurations an attacker could exploit (e.g., internet-exposed VM → excessive permissions → sensitive data). It prioritizes the fixes that break real attack chains, not just isolated findings."
- **Sentinel/multi-cloud**: "Alerts and recommendations flow to **Sentinel** for correlation, hunting, and SOAR automation. Defender onboards **AWS/GCP** via connectors and on-prem via **Azure Arc**, giving one posture + protection view across clouds."

## 7. Common Mistakes
- Leaving only free CSPM on (no CWPP threat detection) for prod.
- Ignoring Secure Score / no remediation ownership.
- Not onboarding multi-cloud/hybrid → blind spots.
- No integration with Sentinel/SOC (alerts unactioned).
- Skipping DevOps/IaC scanning (shift-left gap).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Enable all Defender plans | full protection | per-resource cost |
| Agentless scanning | easy, broad | less depth than agent |
| Strict compliance standards | audit-ready | more findings to manage |

## 9. Production Best Practices
- Enable relevant **Defender plans** on prod (Servers/Containers/SQL/Storage/KeyVault/DevOps).
- Drive **Secure Score** with owners + due dates + automation.
- Onboard multi-cloud + Arc; enable Defender CSPM (attack paths).
- Integrate alerts with **Sentinel** + SOAR playbooks.
- Continuous export; compliance dashboard for audits; shift-left IaC/secret scanning.

## 10. Security Considerations
- Runtime threat detection + vulnerability scanning across workloads.
- Attack path analysis to prioritize exploitable risks.
- Least privilege on Defender/security roles; protect the security data.
- Container image + registry + admission scanning for AKS supply chain.

## 11. Cost Optimization
- Enable Defender plans selectively per resource sensitivity/environment.
- Agentless scanning reduces agent overhead; scope non-prod lighter.
- Remediation reduces incident cost; right-size log ingestion to Sentinel.

## 12. Troubleshooting Scenarios
- **Missing threat alerts** → Defender plan not enabled for that resource type.
- **Low Secure Score** → unremediated high-impact recommendations; assign owners.
- **AKS image risks unseen** → Defender for Containers/registry scan not enabled.
- **Multi-cloud blind spots** → AWS/GCP connector not onboarded.
- **Alert fatigue** → tune/suppress + correlate in Sentinel.

## 13. Hands-on Example
```bash
az security pricing create -n VirtualMachines --tier Standard       # Defender for Servers
az security pricing create -n Containers --tier Standard            # Defender for Containers
az security pricing create -n KeyVaults --tier Standard
```

## 14. Terraform Example
```hcl
resource "azurerm_security_center_subscription_pricing" "containers" {
  tier = "Standard" resource_type = "Containers"     # enable CWPP for AKS/containers
}
resource "azurerm_security_center_subscription_pricing" "servers" {
  tier = "Standard" resource_type = "VirtualMachines"
}
```

## 15. Azure Example
```bash
# Stream Defender alerts to Sentinel via continuous export / data connector
az security automation create -g rg -n export-to-sentinel \
  --scopes $SUB_ID --sources '[{"eventSource":"Alerts"}]' --actions @loganalytics.json
```

## 16. FastAPI / Python Example
```python
# Pull Defender for Cloud security alerts/recommendations into an internal dashboard
from azure.mgmt.security import SecurityCenter
from azure.identity import DefaultAzureCredential

def open_alerts(sub_id: str):
    client = SecurityCenter(DefaultAzureCredential(), sub_id)   # Managed Identity
    return [a.alert_display_name for a in client.alerts.list()
            if a.status == "Active"]
```

## 17. AKS Example
**Defender for Containers** scans ACR images for vulnerabilities, checks Kubernetes posture (privileged pods, exposed dashboards), and detects runtime threats (crypto-mining, reverse shells) in AKS. Findings appear as recommendations (Secure Score) and alerts (to Sentinel); admission control + image gating enforce shift-left before deploy.

## 18. How to Remember
**"CNAPP = CSPM (Secure Score + recommendations + attack paths) + CWPP (runtime threat detection per resource). Multi-cloud + DevOps; alerts → Sentinel."**

## 19. Real-World Analogy
A building's combined safety inspector + security guard service: the inspector continuously checks for hazards and rates your building (Secure Score + recommendations, mapping how a burglar could chain unlocked doors = attack paths), while guards watch for break-ins in real time across all your buildings, even ones in other cities (multi-cloud). Incidents get reported to the central command center (Sentinel).

## 20. One-Page Cheat Sheet
- **What**: **CNAPP** = **CSPM** (posture) + **CWPP** (workload protection) for cloud + hybrid + multi-cloud.
- **CSPM**: Secure Score, recommendations, compliance (CIS/PCI/ISO), **attack path analysis** (security graph), agentless scan.
- **CWPP**: threat detection for Servers (MDE), **Containers/AKS**, SQL/Cosmos, Storage (malware), Key Vault, APIs, **DevOps** (IaC/secret scan).
- **Multi-cloud**: AWS/GCP connectors + on-prem via **Arc**.
- **Integrate**: alerts → **Sentinel** (SIEM/XDR) + SOAR; assign remediation owners/due dates.
- **Tiers**: free foundational CSPM vs paid **Defender plans** per resource.
