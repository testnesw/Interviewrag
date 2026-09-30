# 95 · Azure SQL Database

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Azure SQL Database is a **fully managed relational database** (based on SQL Server) in the cloud. Microsoft handles patching, backups, and high availability, so you focus on your data and queries instead of running database servers.

## 2. Architect-Level Explanation
Managed PaaS relational database (SQL Server engine):
- **Deployment models**: **Single Database**, **Elastic Pool** (share resources across DBs), **Managed Instance** (near-100% SQL Server compat, VNet-native, for lift-and-shift).
- **Purchasing models**: **DTU** (bundled) vs **vCore** (independent compute/storage, Reserved/Hyperscale) — vCore preferred.
- **Service tiers (vCore)**: **General Purpose** (balanced), **Business Critical** (low latency, local SSD, built-in replicas + readable secondary), **Hyperscale** (up to 100TB, fast scale, snapshot backups, multiple read replicas).
- **Serverless**: auto-scale compute + auto-pause (pay per second) for intermittent workloads.
- **HA/DR**: built-in HA (99.99%+), **zone redundancy**, **active geo-replication** / **auto-failover groups** for cross-region DR, automated backups + **PITR** (point-in-time restore), LTR (long-term retention).
- **Security**: Entra ID auth + **Managed Identity**, **private endpoints**, firewall, **TDE** (encryption at rest, CMK), **Always Encrypted**, dynamic data masking, row-level security, **Microsoft Defender for SQL**, auditing.
- **Scale**: read scale-out (readable secondaries), Hyperscale replicas; connection pooling.
- **Intelligent**: automatic tuning, query performance insight.

## 3. Real Enterprise Use Case
An OLTP application runs on Business Critical (zone-redundant, readable secondary for reporting), with **auto-failover groups** to a paired region for DR, **PITR + LTR** backups for compliance, **Entra ID + Managed Identity** auth (no passwords), **private endpoints**, TDE with CMK, and **Defender for SQL** threat detection — 99.99% SLA, automated ops.

## 4. Architecture Diagram (ASCII)
```
   App (Managed Identity) ─► private endpoint ─► Azure SQL (Primary)
                                     │ built-in HA + zone redundancy
                                     ├─► readable secondary (read scale-out)
                                     └─► auto-failover group ─► Secondary region (DR)
   Backups: automated + PITR (35d) + LTR | TDE (CMK) | Defender for SQL
   Models: Single | Elastic Pool | Managed Instance ; Tiers: GP/BC/Hyperscale
```

## 5. Interview Questions
1. Single DB vs Elastic Pool vs Managed Instance?
2. DTU vs vCore; General Purpose vs Business Critical vs Hyperscale?
3. How do you achieve HA and DR?
4. How do you secure Azure SQL?
5. When use serverless / Hyperscale?

## 6. Strong Interview Answers
- **Models**: "Single Database for one isolated DB; Elastic Pool to share compute across many DBs with variable load (cost-efficient for SaaS multi-tenant); Managed Instance for near-full SQL Server compatibility and VNet-native lift-and-shift (SQL Agent, cross-DB queries, CLR)."
- **Tiers**: "vCore over DTU for flexibility and Reserved pricing. General Purpose is balanced (remote storage); Business Critical uses local SSD + an Always On replica for low latency and a readable secondary; Hyperscale scales storage to 100TB with fast backups/restores and multiple read replicas."
- **HA/DR**: "Built-in HA gives 99.99%; zone redundancy survives a zone failure. For DR I use **active geo-replication** or **auto-failover groups** to a paired region (single connection string that follows failover), plus automated backups with **PITR** and LTR for compliance."
- **Secure**: "Entra ID auth + Managed Identity (no passwords), private endpoints + firewall, TDE (CMK) at rest, Always Encrypted for sensitive columns, dynamic data masking, row-level security, auditing, and Defender for SQL for threat detection."
- **Serverless/Hyperscale**: "Serverless auto-scales and auto-pauses — great for dev/test or intermittent apps (pay per second). Hyperscale for very large DBs needing rapid scale, fast restores, and multiple read replicas."

## 7. Common Mistakes
- SQL auth passwords instead of Entra ID/Managed Identity.
- Public access / no private endpoint.
- No geo-replication/failover group for DR.
- Under-sizing (DTU/vCore) → throttling; or over-provisioning cost.
- Not using connection pooling → connection exhaustion.

## 8. Trade-offs
| Tier | Pro | Con |
|------|-----|-----|
| General Purpose | cost-balanced | higher latency (remote storage) |
| Business Critical | low latency + replica | pricier |
| Hyperscale | huge + fast scale | some feature limits |

## 9. Production Best Practices
- vCore + right tier; zone redundancy; failover groups for DR.
- Entra ID + Managed Identity; private endpoints; TDE (CMK).
- PITR + LTR; test restores; automatic tuning.
- Connection pooling + retry (transient faults); read scale-out for reporting.
- Defender for SQL + auditing; IaC.

## 10. Security Considerations
- Entra-only auth + Managed Identity; disable SQL logins where possible.
- Private endpoints + firewall; TDE with CMK; Always Encrypted.
- Row-level security + dynamic data masking; auditing + Defender.
- Least-privilege DB roles; rotate any secrets in Key Vault.

## 11. Cost Optimization
- Elastic Pools for many variable DBs; serverless auto-pause for intermittent.
- Reserved capacity / Azure Hybrid Benefit; right-size tier.
- Scale down non-prod; monitor with Query Performance Insight.

## 12. Troubleshooting Scenarios
- **Throttling / DTU% 100** → under-sized; scale up or tune queries.
- **Transient connection errors** → add retry logic (expected in PaaS).
- **Login failed** → Entra RBAC/firewall/private endpoint.
- **Slow queries** → missing indexes; use automatic tuning / QPI.
- **Failover confusion** → use failover-group listener endpoint.

## 13. Hands-on Example
```bash
az sql db create -g rg -s sqlsrv-prod -n ordersdb \
  --edition BusinessCritical --compute-model Provisioned \
  --family Gen5 --capacity 4 --zone-redundant true --backup-storage-redundancy Zone
```

## 14. Terraform Example
```hcl
resource "azurerm_mssql_database" "orders" {
  name = "ordersdb" server_id = azurerm_mssql_server.srv.id
  sku_name = "BC_Gen5_4" zone_redundant = true
  short_term_retention_policy { retention_days = 35 }     # PITR
}
resource "azurerm_mssql_failover_group" "fog" {
  name = "orders-fog" server_id = azurerm_mssql_server.srv.id
  partner_server { id = azurerm_mssql_server.srv_dr.id }
  databases = [azurerm_mssql_database.orders.id]
  read_write_endpoint_failover_policy { mode = "Automatic" grace_minutes = 60 }
}
```

## 15. Azure Example
```bash
# Entra ID admin + Managed Identity access (no passwords)
az sql server ad-admin create -g rg -s sqlsrv-prod \
  --display-name "sql-admins" --object-id $GROUP_OBJECT_ID
```

## 16. FastAPI / Python Example
```python
# Passwordless connection using Managed Identity token
import struct, pyodbc
from azure.identity import DefaultAzureCredential

def connect():
    token = DefaultAzureCredential().get_token("https://database.windows.net/.default")
    tok = token.token.encode("utf-16-le")
    conn = pyodbc.connect(
        "Driver={ODBC Driver 18 for SQL Server};Server=sqlsrv-prod.database.windows.net;Database=ordersdb;",
        attrs_before={1256: struct.pack(f"<I{len(tok)}s", len(tok), tok)})  # SQL_COPT_SS_ACCESS_TOKEN
    return conn
```

## 17. AKS Example
AKS apps connect to Azure SQL via **private endpoint** using **Workload Identity** (passwordless Entra tokens). Connection pooling + retry handle transient faults; read replicas serve reporting queries; no credentials live in the cluster.

## 18. How to Remember
**"Managed SQL: Single/Pool/MI; vCore GP/BC/Hyperscale; HA built-in + failover groups for DR; PITR+LTR; Entra ID + private endpoint + TDE."**

## 19. Real-World Analogy
Renting a fully serviced apartment vs owning a house: the landlord (Azure) handles maintenance, security, backups, and insurance (HA/DR), and can instantly give you a bigger unit (scale) or a second apartment in another city (geo-replication) if yours floods — you just live there and use the space (your data).

## 20. One-Page Cheat Sheet
- **What**: managed PaaS relational DB (SQL Server engine); 99.99%+ SLA.
- **Models**: Single / Elastic Pool / Managed Instance. **Purchasing**: vCore (preferred) / DTU.
- **Tiers**: General Purpose, Business Critical (low latency + replica), Hyperscale (100TB); Serverless (auto-pause).
- **HA/DR**: built-in HA + zone redundancy; active geo-replication / auto-failover groups; PITR + LTR.
- **Secure**: Entra ID + Managed Identity, private endpoints, TDE (CMK), Always Encrypted, RLS, masking, Defender.
- **App**: connection pooling + retry (transient faults); read scale-out.
