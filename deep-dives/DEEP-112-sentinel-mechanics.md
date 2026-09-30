# DEEP MECHANICS · Microsoft Sentinel

> Level 2 — cloud-native SIEM+SOAR, data connectors, analytics rules, incidents,
> UEBA, and hunting.

---

## 0. The precise mental model
Sentinel is a **cloud-native SIEM + SOAR** built on **Log Analytics**: it **ingests security logs** from everywhere, **detects** threats via **analytics rules (KQL)**, groups alerts into **incidents**, and **automates response** with **playbooks (Logic Apps)**. SIEM = collect + correlate + detect; SOAR = orchestrate + automate response.

---

## 1. Architecture
- Backed by a **Log Analytics workspace** (KQL query engine, scalable storage).
- **Data connectors** ingest from Azure, M365, Entra, firewalls, AWS/GCP, on-prem (syslog/CEF), threat intel — normalized (many via **ASIM**).
- Pay for **ingestion + retention**.

## 2. Detection — analytics rules
- **Scheduled rules** (KQL) run periodically → generate **alerts** when patterns match.
- **Microsoft/near-real-time/anomaly** rule templates.
- **UEBA** (User and Entity Behavior Analytics) → baseline normal, flag anomalies (impossible travel, unusual access).
- **Fusion** → ML correlation of low-fidelity signals into high-fidelity **multi-stage attack** incidents.

## 3. Incidents & investigation
- Alerts grouped into **incidents** (case with entities, severity, status, owner).
- **Investigation graph** → visualize entities + relationships + timeline.
- Mapped to **MITRE ATT&CK** tactics/techniques.

## 4. SOAR — automation
- **Playbooks** = **Logic Apps** triggered by alerts/incidents → automate response (disable user, isolate host, block IP, notify, enrich).
- **Automation rules** → orchestrate playbooks, assign, suppress noise, set severity.

## 5. Proactive hunting
- **Hunting queries** (KQL) + **notebooks** (Jupyter) to proactively search for threats before alerts fire.
- **Bookmarks** to save findings; **livestream** for active hunts.
- **Threat intelligence** feeds (IOCs) enrich detection.

## 6. Sentinel vs Defender for Cloud
- **Defender for Cloud** = posture + workload protection (generates alerts for Azure resources).
- **Sentinel** = **SIEM/SOAR** — aggregates alerts from Defender + everything else, correlates org-wide, automates response. They're complementary (Defender feeds Sentinel).

## 7. The hard follow-ups (with answers)
1. **"SIEM vs SOAR?"** → SIEM = collect/correlate/detect; SOAR = orchestrate/automate response; Sentinel does both. (§0)
2. **"What's it built on?"** → **Log Analytics** + **KQL**. (§1)
3. **"How are threats detected?"** → **analytics rules (KQL)** + UEBA + **Fusion** ML correlation → alerts → incidents. (§2/§3)
4. **"Auto-respond to an alert?"** → **playbooks (Logic Apps)** + automation rules. (§4)
5. **"Find threats before alerts?"** → **hunting** queries + notebooks. (§5)
6. **"Sentinel vs Defender for Cloud?"** → Defender = posture/workload alerts; Sentinel = SIEM correlating all sources + SOAR. (§6)
7. **"Cost driver?"** → **data ingestion + retention**. (§1)

## 8. One-screen recall
- **Cloud-native SIEM + SOAR** on **Log Analytics** (KQL).
- **Connectors** ingest everywhere (Azure/M365/AWS/on-prem/CEF), normalized via ASIM.
- **Detect**: analytics rules (KQL) + **UEBA** + **Fusion** → alerts → **incidents** (MITRE, investigation graph).
- **Respond**: **playbooks (Logic Apps)** + automation rules.
- **Hunt**: KQL hunting + notebooks + threat intel.
- **vs Defender for Cloud**: Defender = posture/workload; Sentinel = correlate-all + automate.

> Next: Azure Monitoring.
