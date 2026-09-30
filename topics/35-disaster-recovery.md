# 35 · Disaster Recovery (DR)

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
Disaster Recovery is your **plan to recover after a major failure** (region outage, data loss). It's about getting systems and data back within acceptable time and data-loss limits.

## 2. Architect-Level Explanation
Recovery strategy driven by **RTO** (time to recover) and **RPO** (acceptable data loss):
- **Strategies (increasing cost/complexity)**: Backup & restore → Pilot light → Warm standby → **Active-active (multi-region)**.
- **Data replication**: geo-redundant storage (GRS/RA-GRS), SQL geo-replication / failover groups, Cosmos multi-region writes.
- **Compute**: redeploy via IaC, pre-provisioned standby, or always-on multi-region.
- **Traffic failover**: Front Door / Traffic Manager health-based routing.
- **Tooling**: Azure Site Recovery (VM replication/failover), region pairs (sequential updates, paired failover).
- **DR is validated by drills**, not assumed.

## 3. Real Enterprise Use Case
A payments platform runs active-passive across East US (primary) and West US (secondary): SQL failover group (async), RA-GRS storage, IaC-deployed standby, Front Door health-probe failover. Quarterly DR drills validate RTO < 30 min, RPO < 5 min.

## 4. Architecture Diagram (ASCII)
```
        Front Door (health-based failover)
          │ primary                 │ secondary
   [ Region A (East US) ]     [ Region B (West US) ]
     App + SQL primary  ──replication──► SQL secondary (async)
     RA-GRS storage ─────geo-replicate──► read replica
   Failover: promote secondary + reroute traffic
   RTO/RPO targets validated via DR drills
```

## 5. Interview Questions
1. RTO vs RPO — and how do they drive DR design?
2. Compare backup/restore, pilot light, warm standby, active-active.
3. How do you replicate data across regions?
4. What are region pairs?
5. How do you test DR?

## 6. Strong Interview Answers
- **RTO/RPO**: "RTO is max acceptable downtime; RPO is max acceptable data loss. Tight RTO/RPO push toward warm standby/active-active (costly); loose targets allow backup/restore. I set them per workload with the business."
- **Strategies**: "Backup/restore (cheapest, hours RTO); pilot light (core running, scale on failover); warm standby (scaled-down live copy, faster); active-active (both serve traffic, near-zero RTO, highest cost). Choose by RTO/RPO + budget."
- **Replication**: "RA-GRS for storage, SQL auto-failover groups (async geo-replication), Cosmos multi-region writes. Async means some RPO; synchronous limits distance/latency."
- **Region pairs**: "Microsoft-paired regions get sequential platform updates and prioritized recovery; I place primary/secondary in a pair for data residency + coordinated recovery."
- **Testing**: "Scheduled DR drills (planned + unplanned failover), validate RTO/RPO, runbooks, and data integrity — DR that isn't tested doesn't work."

## 7. Common Mistakes
- No defined RTO/RPO (design in a vacuum).
- Never testing failover.
- Replicating data but not config/secrets/DNS.
- Assuming backups = DR.
- Both regions dependent on a single shared component.

## 8. Trade-offs
| Strategy | RTO/RPO | Cost |
|----------|---------|------|
| Backup/restore | hours | low |
| Pilot light | ~1 hr | low-med |
| Warm standby | minutes | med-high |
| Active-active | near zero | high |

## 9. Production Best Practices
- Define RTO/RPO per workload with business.
- IaC for repeatable region rebuild.
- Automate failover + DNS/traffic reroute.
- Replicate data + config + secrets.
- Regular, documented DR drills; runbooks.

## 10. Security Considerations
- Secondary region same security posture (identity, encryption, network).
- Protect replicated data (CMK, private endpoints).
- Access to failover controls (PIM, RBAC).

## 11. Cost Optimization
- Match strategy to actual RTO/RPO (don't over-provision).
- Pilot light / warm standby vs always-on active-active.
- Reserved capacity for standby where predictable.

## 12. Troubleshooting Scenarios
- **Failover slow/failed** → untested runbook, missing dependency in secondary.
- **Data loss > RPO** → replication lag / async gap.
- **Traffic not rerouting** → Front Door/TM health probe/config.
- **Secondary can't start** → missing config/secrets/IaC drift.

## 13. Hands-on Example
```bash
# SQL auto-failover group across regions
az sql failover-group create -n pay-fog -g rg-db --server primary-sql \
  --partner-server secondary-sql --failover-policy Automatic \
  --grace-period 1
```

## 14. Terraform Example
```hcl
resource "azurerm_mssql_failover_group" "fog" {
  name      = "pay-fog"
  server_id = azurerm_mssql_server.primary.id
  partner_server { id = azurerm_mssql_server.secondary.id }
  read_write_endpoint_failover_policy {
    mode = "Automatic" grace_minutes = 60
  }
}
```

## 15. Azure Example
```bash
# Azure Site Recovery: replicate VMs to secondary region
az backup vault create -n dr-vault -g rg-dr -l westus
# configure ASR replication + recovery plan for orchestrated failover
```

## 16. FastAPI / Python Example
```python
# App uses the failover-group listener (auto-redirects to active primary)
DB_HOST = "pay-fog.database.windows.net"   # follows failover automatically
@app.get("/health/db")
def db_health():
    return {"connected": try_connect(DB_HOST)}
```

## 17. AKS Example
Run AKS in two regions (active-passive or active-active); GitOps deploys identical clusters; data via SQL failover group/Cosmos multi-region; Front Door fails traffic over on regional health-probe failure.

## 18. How to Remember
**"RTO = time, RPO = data."** Pick a strategy (backup → pilot → warm → active-active) to hit them, and drill it.

## 19. Real-World Analogy
A business continuity plan for a factory fire: how fast you reopen (RTO) and how much in-progress work you lose (RPO) — from rebuilding from records (backup) to running a fully-staffed backup factory (active-active). And you run fire drills.

## 20. One-Page Cheat Sheet
- **RTO** = downtime tolerance; **RPO** = data-loss tolerance.
- **Strategies**: backup/restore → pilot light → warm standby → active-active (cost ↑, RTO/RPO ↓).
- **Data**: RA-GRS, SQL failover groups, Cosmos multi-region.
- **Traffic**: Front Door / Traffic Manager health-based failover.
- **Region pairs** for coordinated recovery + data residency.
- **Test with DR drills** — replicate data + config + secrets, not just data.
