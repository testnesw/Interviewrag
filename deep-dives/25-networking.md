# Deep Dive · Azure Networking (VNet · NSG · UDR · Firewall · Private Link)

> Phase 3 (Azure foundation) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Azure networking is the **software-defined network** underpinning every workload: **VNets** are your private address space (subnets isolate tiers); **NSGs** are stateful L3/L4 firewalls on subnets/NICs; **UDRs (route tables)** override default routing to force traffic through appliances; **Azure Firewall** provides centralized L3–L7 egress/inspection; and **Private Link/Private Endpoints** bring PaaS services (Azure OpenAI, Storage, SQL) onto your private VNet with **no public exposure**. Together they deliver **zero-trust, private-by-default** connectivity — essential for enterprise/GenAI and regulated workloads.

---

## 2. Architect-Level Explanation
The building blocks and how they compose:
- **VNet + subnets**: private RFC1918 space; subnets segment tiers (web/app/data) and host **service delegation**.
- **NSG**: stateful allow/deny rules (priority-ordered) by IP/port/tag; applied to subnet and/or NIC; **Service Tags** (e.g., `AzureOpenAI`, `Storage`) and **ASGs** simplify rules.
- **UDR/Route Tables**: override system routes; force **0.0.0.0/0 → Azure Firewall** (forced tunneling) for egress inspection.
- **Azure Firewall**: managed, HA, L3–L7 with **FQDN filtering, threat intel, DNAT**; central egress in the hub.
- **Private Endpoint / Private Link**: a **private IP in your subnet** mapping to a PaaS resource; traffic never traverses the internet; paired with **Private DNS zones** for name resolution.
- **Peering / Virtual WAN / ExpressRoute / VPN**: connect VNets, regions, and on-prem.
- **Load balancing** (separate deep-dives): LB (L4), App Gateway (L7+WAF), Front Door (global).

Architecture goal: **private-by-default, segmented, centrally-inspected** traffic (zero trust).

---

## 3. Why It Exists
- **Problem**: cloud PaaS defaults to public endpoints; flat/unsegmented networks are breach-prone; egress is uncontrolled.
- **Breakthrough**: software-defined networking lets you build **private, segmented, policy-controlled** networks in minutes, and pull PaaS onto them via Private Link.
- **Why enterprises adopt it**: zero-trust segmentation, data exfiltration control (firewall egress), compliance (no public exposure), and hybrid connectivity to on-prem.
- **GenAI/regulated angle**: Azure OpenAI + Search + Storage via **Private Endpoints** = no data over the public internet — a common hard requirement.

---

## 4. Internal Working
**Packet path (spoke workload → Azure OpenAI, privately):**
1. Pod/VM in a **spoke subnet** resolves `myaoai.openai.azure.com` → **Private DNS zone** returns the **private endpoint IP**.
2. **NSG** on the subnet/NIC evaluates rules (priority order) → allow.
3. **UDR** may route egress `0.0.0.0/0 → Azure Firewall` in the hub (via peering) for inspection/logging.
4. Traffic to the **Private Endpoint** stays on the Microsoft backbone — **never public**.
5. Return traffic is allowed automatically (**NSGs are stateful**).

Key mechanics:
- **NSG evaluation**: lowest-priority-number rule that matches wins; default rules allow VNet-internal + deny inbound internet.
- **System routes** exist by default; **UDRs override** them (longest-prefix/UDR precedence).
- **Private DNS** is essential — without correct zones, private endpoints resolve to public IPs and break.

---

## 5. Enterprise Use Case
A regulated GenAI platform: **hub VNet** hosts Azure Firewall + DNS; **spoke VNets** host AKS and data. **Private Endpoints** expose Azure OpenAI, AI Search, Storage, and Key Vault privately; **Private DNS zones** resolve them. **NSGs** enforce least-privilege between tiers; **UDRs** force all egress through the firewall (FQDN allow-list, threat intel, full logging). No workload has a public IP; on-prem connects via **ExpressRoute**. Result: zero-trust, exfiltration-controlled, audit-ready.

---

## 6. Real Production Architecture
```
 On-prem ──ExpressRoute──► Hub VNet
                            ├─ Azure Firewall (egress, FQDN filter, logs)
                            ├─ VPN/ER Gateway
                            └─ Private DNS zones
                     peering │ (routes via UDR 0.0.0.0/0 → Firewall)
        ┌───────────── Spoke: GenAI ─────────────┐
        │ AKS subnet (NSG)  ── Private Endpoints ─┼─► Azure OpenAI
        │ Data subnet (NSG) ── Private Endpoints ─┼─► Storage · SQL · Key Vault
        │ No public IPs · ASGs group workloads    │
        └──────────────────────────────────────────┘
```

---

## 7. Security Best Practices
- **Private-by-default**: Private Endpoints for all PaaS; **disable public network access** on AOAI/Storage/etc.
- **Segment** with subnets + **NSGs** (least privilege); use **ASGs + Service Tags** for maintainable rules.
- **Force egress through Azure Firewall** (UDR) with **FQDN allow-lists + threat intel**; deny by default.
- **No public IPs** on workloads; access via bastion/private paths.
- **DDoS Protection** on critical VNets; **WAF** (App Gateway/Front Door) for inbound web.
- **Correct Private DNS** so private endpoints resolve privately (prevents accidental public egress).
- **Flow logs + NSG/Firewall logs** to Log Analytics for audit/detection.

---

## 8. Scaling Strategy
- **Plan address space** generously (Azure CNI pods consume IPs); avoid overlaps for future peering.
- **Hub-spoke** scales via peering; **Virtual WAN** for many regions/branches.
- **Azure Firewall Premium** scales throughput; **Firewall Policy** centrally manages rules at scale.
- **Service Tags** keep NSG rules scalable (no manual IP lists).
- **Multiple private endpoints** per service/region as needed.

---

## 9. High Availability Strategy
- **Zone-redundant** Azure Firewall, gateways, and load balancers.
- **Redundant hybrid links** (dual ExpressRoute / ER + VPN failover).
- **Multi-region** hubs (paired) with global routing (Front Door/Virtual WAN).
- Private endpoints per region for regional resilience.

---

## 10. Disaster Recovery Strategy
- **Network as IaC** → redeploy VNets/NSGs/UDRs/firewall policy in secondary region.
- **Paired-region hub** + private endpoints for replicated services.
- **DNS failover** (Front Door/Traffic Manager) to reroute.
- Document RTO/RPO; test regional failover including DNS + firewall rules.

---

## 11. Cost Optimization Strategy
- **Azure Firewall is costly** — consolidate egress in the hub (shared), consider **Firewall Basic** for small envs, or NVA alternatives where justified.
- **Minimize cross-region/zone data transfer** (egress charges); keep chatty services co-located.
- **Right-size gateways**; **Private Endpoints have per-hour + processing cost** — provision what's needed.
- **Reserved capacity** for ExpressRoute; consolidate low-traffic spokes.

---

## 12. Common Production Challenges
- **Private DNS misconfig** → endpoints resolve to public IPs; connectivity breaks silently.
- **IP exhaustion** (Azure CNI) → plan subnets/overlays early.
- **NSG/UDR conflicts** → asymmetric routing, blackholes; document + test.
- **Firewall as bottleneck/SPOF** → zone-redundant + right SKU.
- **Overlapping address spaces** block peering → govern IP allocation centrally.
- **Forgotten public access** on PaaS → enforce via policy (deny public).
- **Asymmetric routing** with forced tunneling → verify return paths.

---

## 13. Monitoring and Observability
- **NSG flow logs + Traffic Analytics**; **Azure Firewall logs** (allowed/denied, FQDN) → Log Analytics.
- **Connection Monitor / Network Watcher** for reachability, latency, next-hop diagnostics.
- **Private endpoint / DNS resolution** checks.
- **Alerts**: firewall denies spikes, DDoS events, gateway health, throughput saturation.

---

## 14. Troubleshooting Scenarios
- **Can't reach AOAI privately** → check Private DNS zone/link, NSG rules, firewall FQDN allow; use `nslookup` (should return private IP).
- **Intermittent drops** → asymmetric routing from UDR/forced tunneling; verify effective routes (Network Watcher).
- **Blocked outbound** → firewall deny; check firewall logs + FQDN/network rules.
- **Peering traffic fails** → overlapping/missing routes or `allowForwardedTraffic`; check peering + UDR.
- **NSG blocking** → use **NSG diagnostics / effective security rules** to find the deny.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| Azure Firewall (central egress) | control, logging | cost, potential bottleneck |
| Private Endpoints everywhere | no public exposure | DNS complexity, per-endpoint cost |
| Hub-spoke | central control | hub dependency |
| NSG-only vs Firewall | cheaper | no L7/FQDN/threat-intel |

---

## 16. When NOT to use (each)
- **Azure Firewall** for a tiny single-workload env → NSGs + service endpoints may suffice.
- **Private Endpoints** when a service isn't sensitive and public+firewall is acceptable → weigh DNS overhead.
- **Hub-spoke** for one small app → a single VNet is simpler.
- **ExpressRoute** for low-bandwidth/temporary needs → VPN is cheaper.

---

## 17. Comparison with Alternatives
| Control | Layer | Use for | Not for |
|---------|-------|---------|---------|
| **NSG** | L3/L4 stateful | subnet/NIC segmentation | L7/FQDN filtering |
| **Azure Firewall** | L3–L7 | central egress, FQDN, threat intel | cheap tiny envs |
| **Service Endpoint** | PaaS via public IP (VNet-restricted) | simpler PaaS access | true private IP |
| **Private Endpoint** | private IP for PaaS | zero public exposure | DNS-free simplicity |
| **App Gateway/Front Door** | L7 ingress + WAF | inbound web | egress control |

---

## 18. Interview Questions
1. VNet, subnet, NSG, UDR — define and relate them.
2. NSG vs Azure Firewall — when each?
3. Service Endpoint vs Private Endpoint?
4. How does forced tunneling (UDR → Firewall) work?
5. Why is Private DNS critical for Private Endpoints?
6. How do you design zero-trust/private networking for GenAI?
7. Hub-spoke vs Virtual WAN?
8. How do you control data exfiltration?
9. Common private-connectivity failure modes?
10. How do you make the network HA/DR-ready?

---

## 19. Strong Interview Answers
- **Core four**: "VNet is the private address space; subnets segment tiers; NSGs are stateful L3/L4 firewalls on subnets/NICs; UDRs override default routing to force traffic through appliances like Azure Firewall. Together they segment and control flow."
- **NSG vs Firewall**: "NSGs do L3/L4 allow/deny per subnet/NIC — cheap segmentation. Azure Firewall is a managed L3–L7 appliance for central egress with FQDN filtering, threat intel, and DNAT. I use NSGs everywhere for micro-segmentation and route egress through the Firewall for inspection and exfiltration control."
- **Service vs Private Endpoint**: "Service Endpoints keep the PaaS public IP but restrict access to your VNet; Private Endpoints give the service a private IP in your subnet — no public exposure at all. For regulated GenAI I use Private Endpoints and disable public access."
- **Private DNS**: "A Private Endpoint only helps if DNS resolves the service name to its private IP. I link Private DNS zones to the VNets; misconfigured DNS silently resolves to the public IP and breaks the private path."
- **Exfiltration control**: "Force all egress through Azure Firewall with FQDN allow-lists and threat intel, deny by default, private endpoints for PaaS, no public IPs, and full flow/firewall logging — so data can't leave to unapproved destinations."

---

## 20. Architecture Diagrams
**Private path + forced tunneling:**
```
Workload ─► [Private DNS → private IP] ─► Private Endpoint ─► PaaS (backbone)
   │ egress 0.0.0.0/0 (UDR)
   └────────────► Azure Firewall (hub) ─► allowed FQDNs only ─► Internet
NSGs gate each subnet/NIC (stateful)
```

---

## 21. Real Project Example
**Zero-trust GenAI network.** Hub with zone-redundant Azure Firewall + Private DNS; GenAI spoke with AKS. AOAI, AI Search, Storage, Key Vault all via Private Endpoints, public access disabled by policy. UDRs force egress through the firewall (FQDN allow-list to only required Microsoft endpoints + package mirrors). NSGs + ASGs segment AKS/data tiers. NSG flow logs + firewall logs to Log Analytics. On-prem via ExpressRoute. A pen-test confirmed no public data path — satisfying the compliance requirement.

---

## 22. Whiteboard Design Question
> *"Design a private, zero-trust network for a regulated GenAI platform with on-prem connectivity."*

Cover: hub-spoke (or vWAN) → zone-redundant Azure Firewall (central egress, FQDN, threat intel) → spokes for GenAI/data → Private Endpoints for AOAI/Search/Storage/KV with Private DNS → NSGs+ASGs micro-segmentation → UDR forced tunneling → ExpressRoute + VPN failover → no public IPs → policy to deny public PaaS → flow/firewall logging → HA (zonal) + DR (paired region, IaC). Emphasize DNS correctness and exfiltration control.

---

## 23. Design Review Questions
- Is **public network access disabled** on all sensitive PaaS (Private Endpoints)?
- Are **Private DNS zones** linked correctly (resolve to private IPs)?
- Is **egress forced through the Firewall** with default-deny + FQDN allow-list?
- **NSG/ASG** segmentation least-privilege; any 0.0.0.0/0 allows?
- **Address space** planned (no overlaps; IP capacity for CNI)?
- **Zone-redundant** firewall/gateways; **hybrid link** redundancy?
- **Flow + firewall logs** to Log Analytics for audit?

---

## 24. Hands-on Example
```bash
# Create a private endpoint for Azure OpenAI + wire Private DNS (no public access)
az network private-endpoint create -g rg -n aoai-pe --vnet-name spoke --subnet data \
  --private-connection-resource-id $(az cognitiveservices account show -n my-aoai -g rg --query id -o tsv) \
  --group-id account --connection-name aoai-conn
az network private-dns zone create -g rg -n privatelink.openai.azure.com
az network private-dns link vnet create -g rg -n link --zone-name privatelink.openai.azure.com \
  --virtual-network spoke --registration-enabled false
# Disable public access on the account (private only)
az cognitiveservices account update -n my-aoai -g rg --custom-domain my-aoai \
  --api-properties publicNetworkAccess=Disabled
```

---

## 25. Terraform Example
```hcl
resource "azurerm_subnet" "data" {
  name = "data" resource_group_name = var.rg
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes = ["10.20.1.0/24"]
}

resource "azurerm_network_security_group" "data_nsg" {
  name = "data-nsg" location = var.location resource_group_name = var.rg
  security_rule {                             # allow only app tier to reach data
    name = "allow-app" priority = 100 direction = "Inbound" access = "Allow"
    protocol = "Tcp" source_port_range = "*" destination_port_range = "443"
    source_application_security_group_ids = [azurerm_application_security_group.app.id]
    destination_address_prefix = "*"
  }
}

resource "azurerm_route_table" "spoke_rt" {    # force egress through firewall
  name = "spoke-rt" location = var.location resource_group_name = var.rg
  route { name = "to-fw" address_prefix = "0.0.0.0/0"
          next_hop_type = "VirtualAppliance" next_hop_in_ip_address = var.firewall_private_ip }
}

resource "azurerm_private_endpoint" "aoai" {
  name = "aoai-pe" location = var.location resource_group_name = var.rg
  subnet_id = azurerm_subnet.data.id
  private_service_connection {
    name = "aoai" is_manual_connection = false
    private_connection_resource_id = var.aoai_id  subresource_names = ["account"]
  }
  private_dns_zone_group { name = "dns" private_dns_zone_ids = [var.aoai_dns_zone_id] }
}
```

---

## 26. Azure Example
```bash
# Verify the private path: name must resolve to a private IP, and effective routes via firewall
nslookup my-aoai.openai.azure.com            # expect 10.x.x.x (private)
az network watcher show-next-hop -g rg --vm aks-node \
  --source-ip 10.20.1.10 --dest-ip 20.1.2.3  # expect next hop = VirtualAppliance (firewall)
```

---

## 27. Code Example
```json
// NSG rule using Service Tag to allow only Azure OpenAI egress (no manual IPs)
{
  "name": "allow-aoai",
  "properties": {
    "priority": 200, "direction": "Outbound", "access": "Allow", "protocol": "Tcp",
    "sourceAddressPrefix": "VirtualNetwork",
    "destinationAddressPrefix": "CognitiveServicesManagement",  // Service Tag
    "destinationPortRange": "443"
  }
}
```

---

## 28. Things Architects Must Remember
- **Private-by-default**: Private Endpoints + disable public access on sensitive PaaS.
- **Private DNS correctness is make-or-break** — wrong zone = silent public egress.
- **NSGs are stateful L3/L4**; **Azure Firewall is L3–L7** central egress — use both.
- **UDR forced tunneling** routes egress through the firewall for inspection/exfiltration control.
- **Plan address space** (CNI IPs, no overlaps) before you build.
- **Service Tags + ASGs** keep rules maintainable at scale.
- **Zone-redundant** firewall/gateways + **redundant hybrid links** for HA.
- **Log flows + firewall** to Log Analytics for audit and detection.

---

## 29. Mnemonics and Memory Tricks
- **"V-N-U-F-P"** stack: **V**Net, **N**SG, **U**DR, **F**irewall, **P**rivate Endpoint.
- **"NSG = who can talk; UDR = where traffic goes; Firewall = deep inspection."**
- **"Private Endpoint needs Private DNS or it lies"** — resolve to private IP.
- **Exfil control "F-D-N"**: **F**orce egress, **D**eny by default, **N**o public IPs.
- **"Stateful NSG"** — allow inbound, return is automatic.

---

## 30. One-Page Interview Revision Sheet
- **VNet/subnet**: private address space + tier segmentation (plan IPs; CNI hungry).
- **NSG**: stateful L3/L4 allow/deny (priority order); Service Tags + ASGs for scale.
- **UDR**: override routes; force `0.0.0.0/0 → Azure Firewall` (forced tunneling).
- **Azure Firewall**: managed L3–L7 central egress; FQDN filter, threat intel, DNAT; zone-redundant.
- **Private Link/Endpoint**: private IP for PaaS; **disable public access**; needs **Private DNS**.
- **Connectivity**: peering / Virtual WAN / ExpressRoute / VPN (redundant for HA).
- **Security**: private-by-default, segment, default-deny egress, no public IPs, DDoS/WAF, flow logs.
- **HA/DR**: zonal firewall/gateways, paired-region hub, IaC redeploy, DNS failover.
- **Cost**: consolidate firewall egress, minimize cross-region transfer, right-size gateways/endpoints.
- **Remember**: **V-N-U-F-P**; *NSG=who, UDR=where, Firewall=inspect*; *Private Endpoint needs Private DNS*; **F-D-N** exfil control.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Define VNet, subnet, NSG, and UDR and how a packet uses all four.
2. NSG vs Azure Firewall — give a scenario needing each, and one needing both.
3. Service Endpoint vs Private Endpoint — which for regulated GenAI data and why?
4. Your Private Endpoint "works" but the app hits the public IP. Diagnose it.
5. Design forced tunneling and explain the asymmetric-routing risk.
6. How do you stop data exfiltration from a GenAI workload at the network layer?
7. You're out of pod IPs mid-project. Root cause and prevention.
8. Make the hub network HA across zones and DR across regions — specifics.
9. Hub-spoke vs Virtual WAN for a 20-region enterprise — decide and defend.
10. Write the NSG/firewall posture that allows AKS to reach only AOAI, ACR, and package mirrors.

---

> Next Phase 3 topic: **API Management (APIM)**.
