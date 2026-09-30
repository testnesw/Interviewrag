# DEEP MECHANICS · Virtual Network (VNet)

> Level 2 — address space, subnets, routing (system + UDR), service vs private
> endpoints, and how traffic actually flows.

---

## 0. The precise mental model
A VNet is your **private, isolated network in Azure** — an address space you carve into **subnets**, within which resources get private IPs and communicate. Everything about Azure networking (NSGs, routing, peering, endpoints) hangs off the VNet. The core mechanics: **CIDR planning**, **routing (system routes + UDRs)**, and **how you reach PaaS services privately**.

---

## 1. Address space & subnets
- VNet has one or more **CIDR ranges** (RFC1918 private, e.g., 10.0.0.0/16). Plan **non-overlapping** ranges (overlap breaks peering/VPN).
- **Subnets** partition the space (10.0.1.0/24). Azure reserves **5 IPs per subnet** (first 4 + last).
- Some services need **dedicated/delegated subnets** (Firewall, Bastion, App Gateway, VNet integration).

## 2. Default connectivity & system routes
- Resources in the same VNet can talk **by default** (across subnets) — subnets are not isolation boundaries by themselves; you add **NSGs** to restrict.
- **System routes** (invisible default route table): local VNet, internet, peered VNets. Azure handles basic routing automatically.

## 3. User-Defined Routes (UDRs)
Override system routes to control the **next hop**:
- Force egress through a **firewall/NVA** (0.0.0.0/0 → firewall IP).
- Route between spokes via hub.
- **Route priority**: UDR > BGP > system route (most specific prefix wins; UDR overrides system).

## 4. Reaching PaaS: Service Endpoints vs Private Endpoints
- **Service Endpoint** — extends VNet identity to a PaaS service over the Azure backbone; the service still has a **public IP** but restricts access to your subnet. Free, simpler, but not a private IP.
- **Private Endpoint** — gives the PaaS service a **private IP in your subnet** (via Private Link) → traffic never touches public internet, works across peering/on-prem. Preferred for security. (See Private Endpoint deep dive.)

## 5. Connectivity options
- **VNet peering** — connect VNets (non-transitive).
- **VPN Gateway** — encrypted tunnel over internet to on-prem.
- **ExpressRoute** — private dedicated on-prem link.
- **VNet integration** — App Service/Functions outbound into a VNet.

## 6. Security layers
NSGs (subnet/NIC stateful rules), Azure Firewall (central), ASGs (group NICs by role), Private Endpoints, DDoS protection. Defense-in-depth.

## 7. The hard follow-ups (with answers)
1. **"Can subnets talk by default?"** → yes, within a VNet; add NSGs to restrict. (§2)
2. **"Force all outbound through a firewall?"** → UDR 0.0.0.0/0 → firewall private IP on the subnet. (§3)
3. **"Service endpoint vs private endpoint?"** → subnet-restricted public IP (backbone) vs **private IP in your subnet** (no public exposure). (§4)
4. **"Why plan non-overlapping CIDRs?"** → overlap breaks peering/VPN routing. (§1)
5. **"How many usable IPs in a /24 subnet?"** → 256 − 5 reserved = 251. (§1)

## 8. One-screen recall
- VNet = **private isolated network**; CIDR space → **subnets** (Azure reserves **5 IPs**/subnet); plan **non-overlapping**.
- Intra-VNet traffic flows **by default**; restrict with **NSGs**. **System routes** handle local/internet/peered.
- **UDRs** override next-hop (force firewall 0.0.0.0/0→FW IP); priority **UDR > BGP > system**.
- PaaS access: **Service Endpoint** (subnet-restricted public IP) vs **Private Endpoint** (private IP, no public path — preferred).
- Connect via **peering / VPN / ExpressRoute / VNet integration**.
- Security: NSG + Firewall + ASG + Private Endpoint + DDoS.

> Next: NSG.
