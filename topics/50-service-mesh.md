# 50 · Service Mesh

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A service mesh adds **traffic management, security (mTLS), and observability between your microservices** — without changing app code. It uses proxies next to each service to handle service-to-service communication.

## 2. Architect-Level Explanation
A dedicated infrastructure layer for service-to-service (east-west) traffic:
- **Data plane**: sidecar proxies (Envoy) — or sidecar-less (eBPF/ambient) — intercept all service traffic.
- **Control plane**: configures proxies (Istio's istiod, Linkerd, Consul).
- **Capabilities**: mTLS (identity + encryption), traffic routing (canary/blue-green, retries, timeouts, circuit breaking), and telemetry (metrics/traces/logs) — all transparent to apps.
- **Trend**: **ambient mesh / sidecar-less** (eBPF, Cilium) to cut sidecar overhead.
- **Trade-off**: powerful but adds complexity, latency, and resource cost — adopt when scale/security justifies.

## 3. Real Enterprise Use Case
A bank with 200 microservices enforces **zero-trust mTLS** everywhere, does canary rollouts by shifting 5%→100% traffic, applies retries/circuit breakers for resilience, and gets uniform golden metrics + distributed traces — all without touching service code.

## 4. Architecture Diagram (ASCII)
```
        Control Plane (istiod) — configures proxies, issues certs
             │
   Service A                     Service B
   [app]                         [app]
   [Envoy sidecar] ◄──mTLS──►    [Envoy sidecar]
      │ retries/timeouts/CB          │
      └── telemetry ─► metrics/traces ┘
   Ambient/eBPF option: no sidecars (Cilium)
```

## 5. Interview Questions
1. What does a service mesh provide?
2. Data plane vs control plane?
3. How does mTLS work in a mesh?
4. Sidecar vs sidecar-less (ambient/eBPF)?
5. When is a mesh NOT worth it?

## 6. Strong Interview Answers
- **Provides**: "Transparent mTLS, advanced traffic management (canary, retries, timeouts, circuit breaking), and consistent observability for east-west traffic — without app code changes."
- **Planes**: "Data plane = proxies handling actual traffic; control plane = configures/secures those proxies and distributes policy and certificates."
- **mTLS**: "The control plane issues workload identities/certs; sidecars establish mutual TLS automatically, encrypting and authenticating service-to-service traffic — zero-trust by default."
- **Sidecar vs ambient**: "Sidecars are per-Pod proxies (isolation, but overhead per Pod); ambient/eBPF moves L4 into the node and L7 into shared proxies, cutting resource cost and latency. I lean toward ambient/Cilium for large clusters."
- **Not worth it**: "For a handful of services, the complexity/overhead outweighs benefits — I'd use library-level retries + Ingress + basic mTLS. Adopt a mesh at scale or for strict zero-trust/compliance."

## 7. Common Mistakes
- Adopting a mesh for a few services (over-engineering).
- Ignoring sidecar resource/latency overhead.
- mTLS misconfig breaking traffic (permissive vs strict).
- No plan for upgrades/complexity.
- Duplicating mesh features already in Ingress.

## 8. Trade-offs
| Aspect | Mesh | No mesh |
|--------|------|---------|
| Security (mTLS) | automatic | manual/library |
| Traffic control | rich | limited |
| Complexity/overhead | high | low |
| Observability | uniform | per-app |

## 9. Production Best Practices
- Adopt at scale / for zero-trust; start small (namespace).
- Strict mTLS with migration from permissive.
- Consider ambient/eBPF to reduce overhead.
- Standardize retries/timeouts/circuit breakers.
- Integrate telemetry with existing observability.

## 10. Security Considerations
- Zero-trust mTLS (strict mode) + workload identity.
- Authorization policies (who can call whom).
- Secure control plane; rotate certs automatically.
- Defense in depth with network policies.

## 11. Cost Optimization
- Sidecar overhead × many Pods adds up → ambient/eBPF.
- Right-size proxy resources.
- Only mesh namespaces that need it.

## 12. Troubleshooting Scenarios
- **503 between services** → mTLS mode mismatch / policy.
- **Latency up** → sidecar overhead; tune or go ambient.
- **Traffic not shifting** → routing/VirtualService config.
- **Cert errors** → control plane / identity issues.

## 13. Hands-on Example
```bash
istioctl install --set profile=default
kubectl label namespace app istio-injection=enabled   # auto sidecar
```

## 14. Terraform Example
```hcl
# Enable the Istio-based service mesh add-on on AKS
resource "azurerm_kubernetes_cluster" "aks" {
  # ...
  service_mesh_profile {
    mode                             = "Istio"
    internal_ingress_gateway_enabled = true
  }
}
```

## 15. Azure Example
```bash
az aks mesh enable -g rg-aks -n prod-aks   # managed Istio add-on
az aks mesh enable-ingress-gateway -g rg-aks -n prod-aks --ingress-gateway-type Internal
```

## 16. FastAPI / Python Example
```python
# App code stays clean — mesh handles mTLS/retries/telemetry transparently
@app.get("/orders")
async def orders():
    # calls to other services are auto-mTLS'd and traced by the sidecar
    return await fetch("http://inventory.app.svc.cluster.local/stock")
```

## 17. AKS Example (traffic shift / canary)
```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata: { name: api, namespace: app }
spec:
  hosts: [api]
  http:
    - route:
        - destination: { host: api, subset: v1 }
          weight: 95
        - destination: { host: api, subset: v2 }   # canary
          weight: 5
```

## 18. How to Remember
**"Proxies handle service-to-service so apps don't."** mTLS + traffic control + observability, transparently — worth it at scale.

## 19. Real-World Analogy
A team of personal translators/security escorts (sidecars) assigned to every employee: they handle secure, verified communication and log every conversation — so employees just talk normally while security and records are guaranteed.

## 20. One-Page Cheat Sheet
- **What**: infra layer for east-west traffic — mTLS, routing, observability, no app changes.
- **Planes**: data (Envoy sidecars/eBPF) + control (istiod).
- **Gives**: automatic mTLS (zero-trust), canary/retries/timeouts/circuit-breaking, uniform telemetry.
- **Trend**: ambient/sidecar-less (eBPF, Cilium) to cut overhead.
- **Adopt when**: scale or strict security/compliance — not for a few services.
- **AKS**: managed Istio add-on (`az aks mesh enable`).
