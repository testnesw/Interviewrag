# 36 · High Availability (HA)

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
High Availability means designing systems so they **keep running despite failures** — no single point of failure, automatic recovery, minimal downtime. DR is about recovering from disasters; HA is about avoiding downtime in the first place.

## 2. Architect-Level Explanation
Designing for continuous operation within (and across) regions:
- **Redundancy**: multiple instances across **Availability Zones** (in-region) and/or regions.
- **No SPOF**: redundant compute, data, network, and dependencies.
- **Health + self-healing**: health probes, load balancer removal, autoscaling, orchestration (K8s reschedules).
- **Data HA**: zone-redundant storage (ZRS), SQL zone-redundant/AlwaysOn, Cosmos multi-region.
- **SLA composition**: overall SLA is the product of dependencies — reduce/decouple critical dependencies.
- **Distinction**: HA = uptime within normal operations; DR = recovery after catastrophic loss (different targets).

## 3. Real Enterprise Use Case
A storefront runs a VMSS/AKS across 3 Availability Zones behind a zone-redundant Load Balancer/App Gateway, with zone-redundant SQL and ZRS storage, autoscaling, health probes, and PodDisruptionBudgets — achieving 99.99% with no single point of failure in-region.

## 4. Architecture Diagram (ASCII)
```
        Zone-redundant LB / App Gateway
     ┌──────────────┼──────────────┐
   AZ1            AZ2            AZ3
  app x2         app x2         app x2   (autoscale + health probes)
     └──────────────┼──────────────┘
        Zone-redundant SQL (AlwaysOn) + ZRS storage
   Self-healing: unhealthy instances removed/rescheduled
```

## 5. Interview Questions
1. HA vs DR?
2. Availability Zones vs Availability Sets?
3. How do you eliminate single points of failure?
4. How is a composite SLA calculated?
5. How do you achieve data HA?

## 6. Strong Interview Answers
- **HA vs DR**: "HA keeps the system up during normal failures (a node/zone dies) with redundancy and self-healing; DR recovers from catastrophic events (region loss) with defined RTO/RPO. Different goals, both needed."
- **Zones vs Sets**: "Availability Zones are physically separate datacenters within a region (protects against datacenter failure, 99.99% VM SLA); Availability Sets spread VMs across fault/update domains within one datacenter (protects against rack/host + planned maintenance). Zones are stronger — I default to zones."
- **No SPOF**: "Redundant instances across zones, redundant data replication, redundant network paths, and decoupling (queues) so one failure doesn't cascade. Audit every dependency for single points."
- **Composite SLA**: "Multiply dependent components' SLAs (serial dependencies lower it); parallel redundancy raises it. Fewer critical serial dependencies = higher effective SLA."
- **Data HA**: "ZRS storage, zone-redundant/AlwaysOn SQL, Cosmos multi-region — synchronous within a region for zero-RPO HA."

## 7. Common Mistakes
- Single instance / single zone.
- Availability Set when zones are available.
- Redundant app but single-instance database (hidden SPOF).
- Ignoring dependency SLAs (composite math).
- No health probes / self-healing.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Multi-zone | strong in-region HA | slight cross-zone latency/cost |
| Multi-region | survive region loss | cost, complexity, consistency |
| More redundancy | higher SLA | higher cost |

## 9. Production Best Practices
- Deploy across ≥2–3 Availability Zones.
- Zone-redundant data + load balancing.
- Autoscaling + health probes + self-healing.
- PodDisruptionBudgets (K8s); graceful shutdown.
- Decouple with queues; design for partial failure.
- Test with chaos engineering.

## 10. Security Considerations
- Redundant components share the same security posture.
- HA shouldn't weaken isolation (zone-redundant firewalls too).
- Protect against correlated failures (shared identity/secrets).

## 11. Cost Optimization
- Right-size redundancy to the SLA needed.
- Zones add minimal cost vs regions.
- Autoscale down in low demand; spot for stateless HA tiers.

## 12. Troubleshooting Scenarios
- **Downtime despite redundancy** → hidden SPOF (DB/dependency).
- **Zone outage impact** → not truly zone-redundant config.
- **Cascading failure** → missing decoupling/circuit breakers.
- **Slow failover** → health probe intervals / draining.

## 13. Hands-on Example
```bash
az vmss create -g rg-app -n app-vmss --zones 1 2 3 --instance-count 3 \
  --image Ubuntu2204 --upgrade-policy-mode Automatic
```

## 14. Terraform Example
```hcl
resource "azurerm_mssql_database" "db" {
  name        = "app-db"
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = "BC_Gen5_2"          # Business Critical
  zone_redundant = true              # zone-redundant HA
}
```

## 15. Azure Example
```bash
az storage account create -n appzrs -g rg-app -l eastus \
  --sku Standard_ZRS   # zone-redundant storage
```

## 16. FastAPI / Python Example
```python
@app.get("/health/ready")   # readiness: only 200 when deps are healthy
def ready():
    if not db_ok() or not cache_ok():
        raise HTTPException(503, "not ready")
    return {"status": "ready"}
```

## 17. AKS Example
Spread node pools across zones (`--zones 1 2 3`), set pod anti-affinity + topology spread constraints, PodDisruptionBudgets, HPA, and multiple replicas so zone/node failure never takes the service down.

## 18. How to Remember
**"No single point of failure + self-healing."** HA = stay up during failures; DR = recover from disaster.

## 19. Real-World Analogy
A hospital with backup generators, multiple ORs, and cross-trained staff: if one system or person fails, care continues without interruption — versus a rebuild plan after a fire (DR).

## 20. One-Page Cheat Sheet
- **HA vs DR**: avoid downtime (HA) vs recover from disaster (DR).
- **Redundancy**: ≥2–3 Availability Zones; zone-redundant data + LB.
- **Zones > Availability Sets** (datacenter-level vs rack-level).
- **Kill SPOFs**: redundant compute *and* data *and* dependencies.
- **Composite SLA**: serial deps multiply down; parallel redundancy raises it.
- **Self-heal**: health probes, autoscale, PDBs, decoupling; chaos-test it.
