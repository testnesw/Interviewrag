# DEEP MECHANICS · Microsoft Defender for Cloud

> Level 2 — CSPM vs CWP, secure score, regulatory compliance, Defender plans,
> and recommendations.

---

## 0. The precise mental model
Defender for Cloud is Azure's **cloud security posture + workload protection** platform. Two pillars: **CSPM** (find & fix **misconfigurations/risk** → *prevent*, measured by **Secure Score**) and **CWP** (Defender plans that **detect threats** on running workloads → *respond*). It's multi-cloud (Azure/AWS/GCP) and hybrid.

---

## 1. Two pillars
- **CSPM (Cloud Security Posture Management)** — continuously assess resources against security best practices → **recommendations** + **Secure Score**. Free foundational tier + paid **Defender CSPM** (attack path analysis, agentless scanning).
- **CWP (Cloud Workload Protection)** — the **Defender plans** (per resource type) → threat detection, alerts, behavioral analytics.

## 2. Secure Score
- A **percentage** of implemented security recommendations weighted by impact → single measurable posture metric.
- Improving score = remediating recommendations (e.g., enable MFA, encrypt disks, restrict NSG, close management ports).
- Drives prioritization; track trend over time.

## 3. Recommendations & standards
- Built from the **Microsoft Cloud Security Benchmark (MCSB)** + custom.
- Each recommendation → affected resources + **remediation steps** (often "Fix" button) + severity.
- **Regulatory compliance** dashboard maps posture to standards (PCI-DSS, ISO 27001, NIST, CIS, SOC 2).

## 4. Defender plans (CWP examples)
- **Servers** (integrates MDE/EDR), **Storage** (malware scan, anomalous access), **SQL/Databases**, **Containers/AKS** (image scan + runtime threat detection), **Key Vault**, **App Service**, **APIs**, **DNS**, **Resource Manager**.
- Each emits **security alerts** with severity + investigation context.

## 5. Threat detection & response
- Alerts use behavioral analytics + threat intel + **MITRE ATT&CK** mapping.
- **Attack path analysis** (Defender CSPM) → shows exploitable chains (e.g., internet-exposed VM → identity → data).
- Integrates with **Sentinel** (SIEM) for correlation + SOAR response; **workflow automation** (Logic Apps) for auto-remediation.

## 6. Coverage
- **Multi-cloud** (AWS/GCP connectors) + hybrid (Arc-enabled servers) → single posture view.
- **Agentless** scanning (disk snapshots) + agent-based (MDE) options.

## 7. The hard follow-ups (with answers)
1. **"CSPM vs CWP?"** → CSPM = posture/misconfig prevention (**Secure Score**); CWP = Defender plans = runtime **threat detection**. (§1)
2. **"What's Secure Score?"** → weighted % of implemented recommendations → single posture metric to improve. (§2)
3. **"Prove PCI/ISO compliance?"** → **regulatory compliance** dashboard mapping. (§3)
4. **"Detect a compromised VM?"** → **Defender for Servers** (EDR/MDE) alerts. (§4)
5. **"See exploitable attack chains?"** → **attack path analysis** (Defender CSPM). (§5)
6. **"Correlate alerts org-wide / auto-respond?"** → export to **Sentinel** + workflow automation. (§5)
7. **"Multi-cloud?"** → AWS/GCP connectors + Arc for hybrid. (§6)

## 8. One-screen recall
- **CSPM** (posture, misconfig → prevent, **Secure Score**) + **CWP** (Defender plans → detect threats).
- **Secure Score** = weighted % of recommendations done → prioritize remediation.
- **Recommendations** from **MCSB**; **regulatory compliance** (PCI/ISO/NIST/CIS).
- **Defender plans**: Servers(EDR), Storage, SQL, Containers, Key Vault, App Service, APIs…
- **Detection**: MITRE ATT&CK alerts + **attack path analysis**; → **Sentinel** + auto-remediation.
- **Multi-cloud** (AWS/GCP) + hybrid (Arc); agentless + agent.

> Next: Microsoft Sentinel.
