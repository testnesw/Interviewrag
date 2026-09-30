# 29 · Private Link

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Azure Private Link is the **technology that connects your VNet privately to a service** over the Microsoft backbone. Private Endpoints are how you consume it; Private Link Service is how you publish your own service privately.

## 2. Architect-Level Explanation
Two sides of the same platform:
- **Private Endpoint (consumer side)**: private IP in your VNet to a PaaS/partner service.
- **Private Link Service (provider side)**: expose *your* service (behind a **Standard Load Balancer**) so consumers connect via their own Private Endpoints — even cross-tenant, without VNet peering.
- Traffic stays on the Microsoft backbone (no public internet); protects against data exfiltration.
- **Connection approval** workflow (auto/manual) between provider and consumer.
- Enables SaaS/multi-tenant private connectivity and secure PaaS access.

## 3. Real Enterprise Use Case
A SaaS vendor exposes its multi-tenant API via a Private Link Service behind a Standard LB. Enterprise customers create Private Endpoints in their own VNets to consume it privately — no peering, no public exposure, per-customer approval and isolation.

## 4. Architecture Diagram (ASCII)
```
 CONSUMER VNet                          PROVIDER VNet
 [Private Endpoint] ──Private Link──► [Private Link Service]
    private IP           (backbone)         │
                                      [Standard Load Balancer]
                                             │
                                        provider app
   Connection approval (auto/manual), cross-tenant OK, no peering
```

## 5. Interview Questions
1. Private Link vs Private Endpoint — the relationship?
2. What is a Private Link Service and when do you use it?
3. How is Private Link different from VNet peering?
4. How does cross-tenant private connectivity work?
5. How does Private Link prevent data exfiltration?

## 6. Strong Interview Answers
- **Relationship**: "Private Link is the umbrella technology; Private Endpoint is the consumer-side resource (private IP), and Private Link Service is the provider-side publisher behind a Standard LB. PE consumes, PLS provides."
- **PLS use**: "When *I* host a service others must reach privately (SaaS, shared platform), I front it with a Standard LB and publish a Private Link Service; consumers connect with their own Private Endpoints — no peering or public exposure."
- **vs peering**: "Peering connects entire VNets (bidirectional, address-space aware, non-transitive). Private Link exposes a *single service* with a one-way, approval-based connection — finer-grained, works cross-tenant, no IP overlap concerns."
- **Cross-tenant**: "The consumer references the provider's alias/resource; the provider approves the connection. No shared network, just a private service link."
- **Exfiltration**: "Because the endpoint maps to one specific resource, a compromised host can't use it to reach arbitrary services — plus you disable public access."

## 7. Common Mistakes
- Confusing PLS (provider) with PE (consumer).
- Publishing without a Standard LB (required).
- Forgetting connection approval workflow.
- DNS not configured on consumer side.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Private Link Service | granular, cross-tenant, no peering | LB requirement, setup |
| VNet peering | full network access | broad, same-tenant, IP planning |
| Public API + auth | simple | exposed surface |

## 9. Production Best Practices
- Standard LB in front of PLS; health probes.
- Manual approval for external/cross-tenant consumers.
- Private DNS on consumer side.
- Limit exposed service; monitor connections.
- IaC for both provider and consumer sides.

## 10. Security Considerations
- Backbone-only traffic; disable public access.
- Approval workflow gates who can connect.
- NAT/visibility controls (restrict source subnets).
- Audit connection requests + data flows.

## 11. Cost Optimization
- PLS + PE + LB hours + data processing — factor in.
- Consolidate services behind fewer PLS where feasible.

## 12. Troubleshooting Scenarios
- **Consumer can't connect** → approval pending/denied.
- **Resolves public** → consumer-side private DNS missing.
- **PLS creation fails** → not behind Standard LB / wrong SKU.
- **Intermittent** → LB health probe failing.

## 13. Hands-on Example
```bash
az network private-link-service create -g rg-prov -n my-pls \
  --vnet-name prov-vnet --subnet pls-subnet \
  --lb-name prov-lb --lb-frontend-ip-configs frontend
```

## 14. Terraform Example
```hcl
resource "azurerm_private_link_service" "pls" {
  name                = "my-pls"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.prov.name
  nat_ip_configuration {
    name = "primary" subnet_id = azurerm_subnet.pls.id primary = true
  }
  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.prov.frontend_ip_configuration[0].id ]
}
```

## 15. Azure Example
Consumers create a Private Endpoint targeting the provider's Private Link Service alias; the provider approves via `az network private-endpoint-connection approve`.

## 16. FastAPI / Python Example
```python
# Provider API served privately behind the Standard LB / PLS
from fastapi import FastAPI
app = FastAPI()
@app.get("/health")            # LB health probe target
def health(): return {"status": "ok"}
```

## 17. AKS Example
Expose an internal AKS service via an internal Standard LB, then a Private Link Service so other teams'/customers' VNets consume it privately through their Private Endpoints.

## 18. How to Remember
**"Private Link = the road; Private Endpoint = your driveway; Private Link Service = the other side's gate."** Consumer uses PE, provider publishes PLS.

## 19. Real-World Analogy
A private members-only tunnel between two buildings: the host installs a controlled gate (PLS), and each guest builds their own approved private entrance (PE) — no shared lobby (no peering), and outsiders can't wander in.

## 20. One-Page Cheat Sheet
- **Private Link**: backbone-only private connectivity technology.
- **Private Endpoint** = consumer side (private IP to one resource).
- **Private Link Service** = provider side (publish your service behind Standard LB).
- **Benefits**: cross-tenant, no peering, granular, anti-exfiltration.
- **Approval workflow** gates connections (auto/manual).
- **DNS** required on consumer side; **Standard LB** required for PLS.
