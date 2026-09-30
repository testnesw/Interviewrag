# 37 · RTO / RPO

> Domain: Azure Architecture & Networking · Level: Principal/Enterprise Architect

## 1. Beginner Explanation
- **RTO (Recovery Time Objective)** = how *fast* you must be back up after a failure.
- **RPO (Recovery Point Objective)** = how much *data* you can afford to lose (measured in time).
They're the two targets that drive your backup and DR design.

## 2. Architect-Level Explanation
Quantified recovery targets set the architecture:
- **RTO** → drives compute/failover strategy (backup restore vs standby vs active-active) and automation.
- **RPO** → drives data replication frequency/mode (backup interval, async vs synchronous replication).
- **Lower RTO/RPO = higher cost/complexity** — a business trade-off per workload tier.
- Related: **MTTR** (mean time to recover), **MTBF** (mean time between failures), and **SLA** (availability commitment) — RTO/RPO are per-incident recovery targets, SLA is aggregate uptime.
- Must be **validated by drills**; theoretical targets are meaningless untested.

## 3. Real Enterprise Use Case
A bank tiers workloads: Tier 0 payments (RTO 5 min, RPO ~0 → active-active + synchronous), Tier 1 core apps (RTO 1 hr, RPO 15 min → warm standby + async), Tier 3 reporting (RTO 24 hr, RPO 24 hr → nightly backup). Architecture and cost follow the tier.

## 4. Architecture Diagram (ASCII)
```
     Failure event
        │
   ── RPO ──►│◄────── data loss window ──────
   (last good point)          │
                              │◄──── RTO ────►│ back online
                         downtime window
 Tighter RTO ⇒ standby/active-active (compute)
 Tighter RPO ⇒ frequent/synchronous replication (data)
 Cost rises sharply as both approach zero
```

## 5. Interview Questions
1. Define RTO and RPO with an example.
2. How do RTO/RPO drive architecture choices?
3. RPO vs backup frequency — the relationship?
4. RTO/RPO vs SLA vs MTTR?
5. Can RTO/RPO ever be zero?

## 6. Strong Interview Answers
- **Define**: "RTO is the maximum acceptable *downtime* — e.g., 'back within 1 hour'. RPO is the maximum acceptable *data loss* — e.g., 'lose at most 15 minutes of data'. If a failure hits at 12:00 with RPO 15 min, I must recover data to ≥11:45."
- **Drive architecture**: "RTO shapes compute recovery (backup restore for hours, warm standby for minutes, active-active for seconds). RPO shapes data replication (nightly backup for 24h RPO, async geo-replication for minutes, synchronous for near-zero). I set them per workload tier and design to the tightest that's justified."
- **RPO vs backup**: "RPO ≥ backup interval — if you back up every 6 hours, worst-case RPO is ~6 hours. To lower RPO you replicate more frequently or continuously (log shipping/synchronous)."
- **vs SLA/MTTR**: "SLA is aggregate uptime commitment (e.g., 99.99%); MTTR is average recovery time; RTO/RPO are the *targets* for a specific disaster recovery. They're related but distinct."
- **Zero?**: "Near-zero RPO needs synchronous replication (latency/distance limits) and near-zero RTO needs active-active — achievable but expensive; true absolute zero is impractical, so we get 'close enough' for the business."

## 7. Common Mistakes
- Not defining them (design without targets).
- Setting all workloads to the tightest tier (over-spend).
- Backup interval > RPO (can't meet target).
- Never validating with drills.
- Confusing RTO/RPO with SLA.

## 8. Trade-offs
| Target | Tighter means | Cost |
|--------|---------------|------|
| RTO | standby/active-active compute | ↑↑ |
| RPO | frequent/synchronous replication | ↑↑ |
| Both near-zero | active-active + sync | highest |

## 9. Production Best Practices
- Define RTO/RPO per workload with business owners.
- Tier workloads; match strategy to tier.
- Ensure backup/replication frequency ≤ RPO.
- Automate failover to meet RTO.
- Validate via regular DR drills; measure actuals vs targets.

## 10. Security Considerations
- Backups/replicas encrypted (CMK) and access-controlled.
- Immutable/soft-delete backups (ransomware protection).
- Secure failover controls (PIM/RBAC).

## 11. Cost Optimization
- Don't over-tighten: match RTO/RPO to real business impact.
- Cheaper tiers (backup/restore) for low-criticality data.
- Reserved capacity only where standby is always-on.

## 12. Troubleshooting Scenarios
- **Missed RTO** → manual/untested failover; automate + drill.
- **Missed RPO** → replication lag / infrequent backups; increase frequency/sync.
- **Cost overrun** → over-tiered workloads; re-tier by impact.
- **Backup unusable** → untested restores; test restore regularly.

## 13. Hands-on Example
```text
Workload tiering:
 Tier 0: RTO 5m / RPO 0    → active-active, synchronous
 Tier 1: RTO 1h / RPO 15m  → warm standby, async geo-replication
 Tier 3: RTO 24h/ RPO 24h  → nightly backup/restore
```

## 14. Terraform Example
```hcl
# RPO via backup frequency; retention for restore points
resource "azurerm_backup_policy_vm" "policy" {
  name                = "tier1-policy"
  resource_group_name = azurerm_resource_group.dr.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  backup { frequency = "Hourly" time = "23:00" }   # tighter RPO
  retention_daily { count = 30 }
}
```

## 15. Azure Example
```bash
# Check SQL failover-group replication (drives RPO)
az sql failover-group show -n pay-fog -g rg-db --server primary-sql \
  --query "{policy:readWriteEndpoint.failoverPolicy, grace:readWriteEndpoint.failoverWithDataLossGracePeriodMinutes}"
```

## 16. FastAPI / Python Example
```python
@app.get("/dr/status")
def dr_status():
    return {"last_backup": get_last_backup_time(),      # informs RPO
            "replication_lag_seconds": get_repl_lag(),  # actual vs RPO target
            "rpo_target_min": 15, "rto_target_min": 60}
```

## 17. AKS Example
For AKS stateful workloads, back up persistent volumes + cluster state (Velero) at a frequency ≤ RPO; multi-region GitOps + data replication meet RTO; validate by restoring into a secondary cluster during drills.

## 18. How to Remember
**"RTO = clock (time down), RPO = data (time lost)."** Tighter targets = more money; always drill.

## 19. Real-World Analogy
Saving a document: RPO is how often you hit save (how much work you'd lose if it crashes); RTO is how quickly you can reopen and resume. Autosave every second (low RPO) and instant reopen (low RTO) cost more effort/resources.

## 20. One-Page Cheat Sheet
- **RTO** = max downtime; **RPO** = max data loss (both in time).
- **RTO drives compute** (restore→standby→active-active).
- **RPO drives data replication** (backup interval→async→synchronous).
- **RPO ≥ backup frequency**; tighten by replicating more often.
- **Tier workloads**; match strategy + cost to business impact.
- **vs SLA/MTTR**: per-incident recovery targets vs aggregate uptime / avg recovery.
- **Validate with DR drills** — untested targets don't count.
