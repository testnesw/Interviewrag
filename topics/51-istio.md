# 51 · Istio

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
Istio is the **most popular service mesh**. It manages secure, reliable, observable communication between microservices using Envoy proxies — adding mTLS, traffic routing, and telemetry without changing app code.

## 2. Architect-Level Explanation
An Envoy-based mesh with a consolidated control plane:
- **Control plane**: **istiod** (config, service discovery, certificate authority for mTLS).
- **Data plane**: Envoy sidecars (or **ambient mode**: ztunnel for L4 + waypoint proxies for L7).
- **Core CRDs**: **VirtualService** (routing rules), **DestinationRule** (subsets, load-balancing, circuit breaking), **Gateway** (ingress/egress), **PeerAuthentication** (mTLS mode), **AuthorizationPolicy** (access control).
- **Capabilities**: traffic shifting (canary/blue-green), fault injection, retries/timeouts, mTLS, RBAC, rich telemetry.
- On AKS: **managed Istio add-on** (supported, upgrades handled).

## 3. Real Enterprise Use Case
An enterprise uses the AKS managed Istio add-on: strict mTLS across all namespaces, canary deploys via VirtualService weight shifting, AuthorizationPolicies enforcing which services may call which, fault injection in staging for resilience testing, and traces to App Insights.

## 4. Architecture Diagram (ASCII)
```
        istiod (config + CA for mTLS)
             │ pushes config/certs
   Gateway ─► VirtualService (routing) ─► DestinationRule (subsets/CB)
             │
   Service A [Envoy] ◄──mTLS (PeerAuthentication)──► [Envoy] Service B
             │ AuthorizationPolicy (who can call whom)
        Telemetry ─► metrics/traces
   Ambient mode: ztunnel (L4) + waypoint (L7), no sidecars
```

## 5. Interview Questions
1. What are istiod and Envoy?
2. VirtualService vs DestinationRule vs Gateway?
3. How do you do canary with Istio?
4. How do PeerAuthentication and AuthorizationPolicy work?
5. Sidecar vs ambient mode?

## 6. Strong Interview Answers
- **istiod/Envoy**: "istiod is the control plane — it configures proxies, does discovery, and acts as the CA for mTLS. Envoy is the data-plane proxy (sidecar or ambient) that actually handles traffic."
- **CRDs**: "VirtualService defines routing (host/path/weight, retries, fault injection); DestinationRule defines subsets, load-balancing, and circuit breaking for a destination; Gateway manages ingress/egress at the mesh edge. You typically pair a VirtualService with a DestinationRule."
- **Canary**: "Define subsets (v1/v2) in a DestinationRule, then a VirtualService with weighted routing (95/5) and gradually shift — safe, code-free canary."
- **Auth**: "PeerAuthentication sets mTLS mode (strict/permissive) for workload-to-workload encryption; AuthorizationPolicy enforces which identities can access which services (zero-trust RBAC)."
- **Sidecar vs ambient**: "Sidecars are per-Pod Envoys (isolation, overhead); ambient splits into a per-node ztunnel (L4/mTLS) and optional waypoint proxies (L7), reducing resource cost — good for large clusters."

## 7. Common Mistakes
- VirtualService without matching DestinationRule subsets.
- Jumping to strict mTLS and breaking traffic (migrate via permissive).
- Ignoring sidecar overhead at scale.
- Self-managing Istio when the AKS add-on suffices.
- Over-broad AuthorizationPolicies.

## 8. Trade-offs
| Aspect | Istio | Lighter (Linkerd) |
|--------|-------|-------------------|
| Features | very rich | simpler, fast |
| Complexity | high | low |
| Ambient/eBPF | yes | different model |

## 9. Production Best Practices
- Use the AKS managed add-on (upgrades handled).
- Migrate mTLS permissive → strict.
- Pair VirtualService + DestinationRule for routing/CB.
- Least-privilege AuthorizationPolicies.
- Consider ambient mode for overhead; integrate telemetry.

## 10. Security Considerations
- Strict mTLS + workload identity.
- AuthorizationPolicy default-deny, allow explicitly.
- Secure istiod; automatic cert rotation.
- Egress control via Gateway.

## 11. Cost Optimization
- Ambient mode to cut sidecar CPU/memory.
- Right-size Envoy resources.
- Mesh only namespaces that need it.

## 12. Troubleshooting Scenarios
- **503/no route** → VirtualService/DestinationRule subset mismatch (`istioctl analyze`).
- **mTLS breakage** → PeerAuthentication mode mismatch.
- **Access denied** → AuthorizationPolicy too restrictive.
- **Config not applied** → istiod health / proxy sync (`istioctl proxy-status`).

## 13. Hands-on Example
```bash
istioctl analyze -n app          # validate mesh config
istioctl proxy-status            # proxy sync state
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  # ...
  service_mesh_profile {
    mode      = "Istio"
    revisions = ["asm-1-22"]
  }
}
```

## 15. Azure Example
```bash
az aks mesh enable -g rg-aks -n prod-aks
az aks mesh get-revisions -l eastus       # supported Istio revisions
```

## 16. FastAPI / Python Example
```python
# App unchanged; Istio injects mTLS + routing. Expose metrics for mesh dashboards.
from prometheus_client import Counter
requests_total = Counter("app_requests_total", "requests")
@app.middleware("http")
async def count(req, call_next):
    requests_total.inc()
    return await call_next(req)
```

## 17. AKS Example (mTLS + canary)
```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: { name: default, namespace: app }
spec: { mtls: { mode: STRICT } }
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata: { name: api, namespace: app }
spec:
  host: api
  subsets:
    - { name: v1, labels: { version: v1 } }
    - { name: v2, labels: { version: v2 } }
```

## 18. How to Remember
**"istiod configures Envoys; CRDs shape traffic + security."** VirtualService = routing, DestinationRule = subsets/CB, PeerAuth = mTLS, AuthzPolicy = access.

## 19. Real-World Analogy
An air-traffic control system (istiod) directing every plane (Envoy) — deciding routes (VirtualService), which runways/aircraft types (DestinationRule subsets), verifying identity (mTLS), and clearing who may land where (AuthorizationPolicy).

## 20. One-Page Cheat Sheet
- **What**: Envoy-based service mesh; control plane = istiod (config + mTLS CA).
- **CRDs**: VirtualService (routing), DestinationRule (subsets/CB), Gateway (edge), PeerAuthentication (mTLS), AuthorizationPolicy (access).
- **Canary**: subsets + weighted VirtualService.
- **Security**: strict mTLS + default-deny AuthorizationPolicy.
- **Modes**: sidecar vs ambient (ztunnel + waypoint) for lower overhead.
- **AKS**: managed Istio add-on; debug with `istioctl analyze`/`proxy-status`.
