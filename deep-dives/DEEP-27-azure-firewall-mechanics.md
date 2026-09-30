# DEEP MECHANICS · Azure Firewall

> Level 2 — rule types & processing order, SNAT, FQDN filtering, DNAT, threat
> intel, and where it sits in hub-spoke.

---

## 0. The precise mental model
Azure Firewall = a **managed, stateful, highly-available L3–L7 network firewall** that sits in the **hub** as the **central inspection/egress point**. Unlike NSGs (5-tuple micro-seg), it does **FQDN filtering, application rules, DNAT, threat intelligence, and IDPS** (Premium). Traffic is forced to it via **UDRs**. It's the enterprise's controlled door to the internet and between spokes.

---

## 1. Rule types & processing order (important)
Processed in this order:
```
1. DNAT rules      → inbound translation (public → private), e.g., publish a service
2. Network rules   → L3/L4 allow/deny by IP/port/protocol/Service Tag
3. Application rules→ L7 by FQDN/URL/FQDN tags (e.g., allow *.microsoft.com:443)
```
If a network rule matches, application rules aren't evaluated for that flow. **Rule Collection Groups → Collections → Rules**, ordered by priority (Firewall Policy).

## 2. FQDN / application filtering (the differentiator)
Application rules filter **outbound HTTP/S by domain name** (allow `*.github.com`, deny others) — impossible with NSGs. **FQDN tags** bundle well-known services (WindowsUpdate, etc.). This controls exactly which external sites workloads can reach → data-exfiltration control + compliance.

## 3. SNAT & DNAT
- **SNAT** — outbound traffic is source-NAT'd to the firewall's **public IP** → all egress appears from one/few IPs (whitelist-friendly, central logging). SNAT port exhaustion at huge scale → add public IPs / NAT Gateway.
- **DNAT** — inbound: translate firewall public IP:port → internal private IP:port to **publish** a service securely.

## 4. Placement in hub-spoke
Firewall lives in the **hub** (dedicated `AzureFirewallSubnet`). **UDRs** on spoke subnets force `0.0.0.0/0` → firewall private IP so **all internet-bound and cross-spoke traffic is inspected/logged** centrally.

## 5. Threat intelligence & Premium
- **Threat-intel-based filtering** — alert/deny traffic to/from known-malicious IPs/domains (Microsoft feed).
- **Premium**: **TLS inspection** (decrypt/inspect HTTPS), **IDPS** (intrusion detection/prevention signatures), URL filtering, web categories.

## 6. Firewall vs NSG vs WAF
- **NSG** — L3/L4 micro-segmentation (free, distributed).
- **Azure Firewall** — central L3–L7 egress/inspection, FQDN, threat intel.
- **WAF (App Gateway/Front Door)** — L7 **inbound** protection of web apps (OWASP, SQLi/XSS).
Different jobs; often all three.

## 7. The hard follow-ups (with answers)
1. **"Rule processing order?"** → DNAT → Network → Application. (§1)
2. **"Filter outbound by domain?"** → application rules (FQDN) — NSGs can't do this. (§2)
3. **"Why does all egress appear from one IP?"** → SNAT to the firewall public IP → whitelistable, logged. (§3)
4. **"Publish an internal service?"** → DNAT rule (public IP:port → private IP:port). (§3)
5. **"How is traffic forced to the firewall?"** → UDR 0.0.0.0/0 → firewall private IP on spokes. (§4)
6. **"Firewall vs WAF?"** → central L3–L7 egress/inspection vs inbound web-app L7 (OWASP) protection. (§6)

## 8. One-screen recall
- Azure Firewall = **managed stateful L3–L7** central firewall in the **hub**; UDR forces traffic to it.
- **Rule order**: **DNAT → Network → Application**; Firewall Policy (collection groups→collections→rules by priority).
- **Application rules = FQDN/URL filtering** (egress control) — NSGs can't.
- **SNAT** (egress → firewall public IP, whitelist/log; watch port exhaustion) + **DNAT** (publish inbound).
- **Threat intel** filtering; **Premium** = TLS inspection + IDPS + URL/web categories.
- vs **NSG** (L3/4 micro-seg) vs **WAF** (inbound web L7/OWASP).

> Next: Private Endpoint.
