# Question Bank · Top 50 Azure Architecture Questions

> Architect-level answers spanning networking, security, governance, reliability, cost. Say them aloud.

---

## Governance & Foundation (1–12)

**1. What is the Cloud Adoption Framework (CAF)?**
Microsoft's guidance for cloud adoption across Strategy, Plan, Ready, Adopt, Govern, Manage — with **Azure Landing Zones** as the ready-state, IaC-deployed foundation for governance at scale.

**2. What is a Landing Zone?**
A pre-provisioned, governed environment (identity, networking, security, management-group hierarchy, policy) that new workloads land into — consistent, compliant, scalable. (I-N-S-G-M.)

**3. What is the Well-Architected Framework (WAF)?**
Five pillars: **Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency** — a lens to review and trade off architecture decisions.

**4. Management groups vs subscriptions vs resource groups?**
Management groups = hierarchy for policy/RBAC across many subscriptions; subscription = billing + scale/isolation boundary; resource group = lifecycle grouping of resources.

**5. What is Azure Policy?**
Policy-as-code enforcing rules at scale (audit/deny/deployIfNotExists/modify) — e.g., deny public IPs, require tags, enforce encryption. Applied via management groups. (D-A-D effects.)

**6. How do you enforce governance across many subscriptions?**
Management-group hierarchy + Azure Policy (initiatives) + RBAC + Landing Zones (IaC) + tagging standards — centralized, consistent guardrails.

**7. What is a subscription vaulting/hub topology in ALZ?**
Platform subscriptions (identity, management, connectivity/hub) separated from landing-zone (workload) subscriptions — separation of concerns and blast-radius control.

**8. Tagging strategy — why?**
Cost allocation, ownership, environment, and automation. Enforce via policy; foundational for FinOps and governance.

**9. How do you structure resource organization for an enterprise?**
MG hierarchy (root → platform/landing zones) → subscriptions per env/business unit → resource groups per workload lifecycle, with consistent naming + tags.

**10. What is Microsoft Entra ID?**
Azure's cloud identity provider (authn/authz) — users, groups, service principals, managed identities, Conditional Access, MFA. The control plane for identity.

**11. What is Conditional Access?**
Policy engine granting/blocking access based on signals (user, device, location, risk) — enforces MFA, compliant device, etc. Core to Zero Trust.

**12. RBAC vs Azure Policy?**
RBAC controls **who can do what** (permissions on resources); Policy controls **what configurations are allowed** (compliance). Complementary.

---

## Networking (13–26)

**13. Explain hub-and-spoke topology.**
Central hub VNet hosts shared services (firewall, gateways, DNS); spoke VNets host workloads, peered to the hub. Centralizes security/connectivity, isolates workloads. (V-N-U-F-P.)

**14. VNet peering vs VPN gateway?**
Peering = private, low-latency connection between VNets (same/cross-region); VPN gateway = encrypted tunnel to on-prem/other networks over internet.

**15. NSG vs Azure Firewall vs WAF?**
NSG = stateful L3/L4 subnet/NIC rules; Azure Firewall = managed L3–L7 with FQDN filtering + threat intel (central egress); WAF = L7 protection against web attacks (on App Gateway/Front Door).

**16. Private Endpoint vs Service Endpoint?**
Private Endpoint = private IP for a PaaS service inside your VNet (traffic fully private, cross-region/on-prem capable); Service Endpoint = optimized route over backbone but resource keeps a public IP. Prefer private endpoints.

**17. What is Private Link?**
The technology behind private endpoints — exposes a service via a private IP in your VNet, keeping traffic off the public internet.

**18. How do you prevent data exfiltration in Azure?**
Azure Firewall FQDN filtering + forced tunneling, private endpoints (no public data plane), NSGs, DNS control, and deny public network access on PaaS. (F-D-N.)

**19. ExpressRoute vs VPN?**
ExpressRoute = private, dedicated, high-bandwidth, SLA-backed on-prem link (no internet); VPN = encrypted over internet, cheaper, lower SLA. ExpressRoute for enterprise hybrid.

**20. Load Balancer vs Application Gateway vs Front Door?**
LB = regional L4; App Gateway = regional L7 (WAF, path routing); Front Door = global L7 (CDN, WAF, anycast, multi-region failover). Layer them.

**21. How does Azure DNS / Private DNS zones work with private endpoints?**
Private DNS zones resolve the PaaS FQDN to the private endpoint IP inside the VNet — essential so clients hit the private IP, not the public one.

**22. How do you design network for a private GenAI workload?**
Hub-spoke + Azure Firewall (egress control), private endpoints on AOAI/AI Search/Storage/Key Vault, Private DNS, NSGs, no public data plane, Managed Identity.

**23. What is a NAT Gateway?**
Provides scalable, predictable **outbound** connectivity (SNAT) for a subnet — avoids SNAT port exhaustion; explicit egress IP.

**24. Forced tunneling?**
Routes all outbound traffic through the firewall/on-prem for inspection (UDRs), preventing direct internet egress — key for exfiltration control.

**25. How do you connect multiple regions privately?**
Global VNet peering or hub-to-hub connectivity (+ ExpressRoute/VPN), with Front Door for global L7 routing/failover.

**26. What are User-Defined Routes (UDRs)?**
Custom routes overriding default routing — e.g., force traffic through Azure Firewall (next hop), enabling inspection and egress control.

---

## Reliability & DR (27–38)

**27. Availability Zones vs Availability Sets vs Regions?**
Zones = physically separate datacenters within a region (zone-redundant HA); Sets = fault/update domains within a datacenter; Regions = geographic separation (DR).

**28. How do you design for high availability?**
Zone-redundant/multi-instance deployment, load balancing, health probes, stateless services, replicated data, and resilience patterns — remove single points of failure.

**29. RTO vs RPO?**
RTO = max acceptable downtime (recovery time); RPO = max acceptable data loss (recovery point). They drive the DR pattern and replication strategy.

**30. DR patterns (active-active / active-passive / backup-restore)?**
Active-active = both regions serve (near-zero RTO/RPO, costly); active-passive = standby fails over (minutes); backup-restore = rebuild from backups (hours). Match to RTO/RPO.

**31. How does Azure Front Door provide multi-region DR?**
Global anycast + health probes route to nearest healthy region; priority routing gives active-passive/active-active failover automatically.

**32. Storage redundancy options (LRS/ZRS/GRS/GZRS)?**
LRS (one datacenter), ZRS (across zones), GRS (geo-replicated to secondary region), GZRS (zonal + geo). Pick by durability/DR needs and cost.

**33. How do you replicate databases for DR?**
Azure SQL geo-replication/failover groups, Cosmos DB multi-region writes, and geo-redundant backups — drives RPO; automate failover.

**34. How do you test DR?**
Regular failover drills (game days), validate RTO/RPO, runbooks, and Front Door/Traffic Manager failover tests — untested DR is not DR.

**35. What is graceful degradation?**
Serve reduced functionality (cached/partial results) when a dependency fails rather than a full outage — improves resilience/UX.

**36. How do you prevent cascading failures?**
Timeouts + retries (idempotent) + circuit breakers + bulkheads + backpressure (queues) between components.

**37. What SLA can you achieve and how?**
Composite SLA depends on dependencies in series (multiply) vs redundancy (parallel). Higher SLA needs zone/region redundancy and removing SPOFs; quantify per tier.

**38. Backup strategy for Azure workloads?**
Azure Backup/geo-redundant backups, defined retention, immutability/soft-delete against ransomware, and tested restores.

---

## Security, Cost & Design (39–50)

**39. What is Zero Trust in Azure?**
Verify explicitly, least privilege, assume breach: Entra + MFA/Conditional Access, RBAC least privilege, micro-segmentation (NSG/network policy), private endpoints, mTLS, continuous monitoring. (V-L-A.)

**40. Managed Identity vs Service Principal?**
Managed Identity = Azure-managed, no credentials to handle (system/user-assigned) — preferred. Service Principal = app identity you manage (secret/cert or OIDC). Prefer Managed Identity/OIDC.

**41. Key Vault best practices?**
Secrets/keys/certs, access via Managed Identity + RBAC, soft-delete + purge protection, rotation, private endpoint, and audit logging. (R-S-P-P.)

**42. What is PIM?**
Privileged Identity Management: just-in-time, time-bound, approval-based elevation for privileged roles — eliminates standing admin access.

**43. Defender for Cloud vs Sentinel?**
Defender for Cloud = CSPM + workload protection (posture, recommendations, threat detection, secure score); Sentinel = cloud SIEM/SOAR (correlation, hunting, automated response).

**44. How do you secure secrets across the platform?**
Key Vault + Managed Identity everywhere (no secrets in code/config), OIDC for CI/CD, rotation, private endpoints — plus secret scanning in pipelines.

**45. Azure cost optimization levers (FinOps)?**
Right-size, autoscale, reserved instances/savings plans, spot VMs, storage tiering, delete idle, tagging + budgets + Cost Management, and architecture choices (serverless, cache). Inform→optimize→operate.

**46. Reserved Instances vs Savings Plans vs Spot?**
RIs = commit to specific resource for discount; Savings Plans = commit to hourly spend (flexible); Spot = deep discount on evictable capacity for interruptible work.

**47. How do you monitor an Azure platform?**
Azure Monitor (metrics/logs), Log Analytics (KQL), Application Insights (APM/OTel), alerts + dashboards, and Defender/Sentinel for security — unified observability.

**48. What is Azure Monitor / Log Analytics / App Insights relationship?**
Azure Monitor is the umbrella; Log Analytics is the log store/query engine (KQL); Application Insights is app-level APM feeding into it. OpenTelemetry standardizes ingestion.

**49. How do you design a well-architected Azure GenAI platform?**
ALZ foundation (MG/policy/identity) → hub-spoke + firewall + private endpoints → AKS/Container Apps orchestrator → AOAI + AI Search (PE, Managed Identity) → APIM AI gateway → Key Vault/PIM → multi-zone HA + multi-region DR (Front Door) → Azure Monitor/OTel → FinOps (tags/budgets/model routing). Apply all five WAF pillars.

**50. Walk through the five WAF pillars for a GenAI system.**
Reliability (multi-zone/region, resilience patterns), Security (Zero Trust, private endpoints, Managed Identity, guardrails), Cost (caching, model routing, autoscale, budgets), Operational Excellence (IaC, CI/CD, OTel, runbooks), Performance (async, caching, right model/tier, PTUs).

---

## Practice Tips
- Anchor every design answer in the **WAF five pillars** and **Zero Trust**.
- Know the **networking decision tree**: NSG vs Firewall vs WAF; Private Endpoint vs Service Endpoint; LB vs App Gateway vs Front Door.
- Always map to **Managed Identity + private endpoints + Key Vault + Azure Policy** for security/governance.

---

> All question banks complete. Final step: update DAILY-COMMAND.md checklist.
