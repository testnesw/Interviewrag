# 43 · Services

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A Service gives a stable network address to a group of Pods. Since Pods come and go (with changing IPs), the Service provides one consistent name/IP and load-balances traffic across the healthy Pods behind it.

## 2. Architect-Level Explanation
A stable networking abstraction over ephemeral Pods:
- **Selector → Endpoints**: matches Pods by label; kube-proxy programs routing (iptables/IPVS/eBPF).
- **Types**: **ClusterIP** (internal virtual IP, default), **NodePort** (port on every node), **LoadBalancer** (cloud LB, external), **ExternalName** (DNS CNAME).
- **Discovery**: internal DNS (`svc.namespace.svc.cluster.local`).
- **Headless** (`clusterIP: None`): direct Pod DNS for stateful/discovery.
- **EndpointSlices**: scalable endpoint tracking; only **ready** Pods (readiness probe) receive traffic.

## 3. Real Enterprise Use Case
A microservices platform: internal services use ClusterIP + DNS for east-west traffic; the public API uses a LoadBalancer (Azure Standard LB) or, more commonly, an Ingress; a StatefulSet database uses a headless Service for stable per-Pod addressing.

## 4. Architecture Diagram (ASCII)
```
   DNS: api.app.svc.cluster.local → ClusterIP 10.1.2.3
                     │ (kube-proxy: iptables/IPVS)
        ┌────────────┼────────────┐
      Pod(api)     Pod(api)     Pod(api)   ← only READY pods (endpoints)
   Types: ClusterIP (internal) | NodePort | LoadBalancer (external)
```

## 5. Interview Questions
1. Why do we need Services?
2. Explain the Service types.
3. How does a Service find its Pods?
4. ClusterIP vs LoadBalancer vs Ingress?
5. What is a headless Service?

## 6. Strong Interview Answers
- **Why**: "Pods are ephemeral with changing IPs; a Service gives a stable virtual IP/DNS name and load-balances across healthy Pods, decoupling clients from Pod churn."
- **Types**: "ClusterIP for internal-only (default); NodePort exposes a port on each node; LoadBalancer provisions a cloud LB for external access; ExternalName maps to an external DNS name."
- **Selector**: "The Service's label selector builds an EndpointSlice of matching, ready Pods; kube-proxy routes the virtual IP to those endpoints. Failing readiness removes a Pod from rotation."
- **ClusterIP vs LB vs Ingress**: "ClusterIP = internal; LoadBalancer = one external L4 IP per service (can get expensive); Ingress = one entry point doing L7 host/path routing to many services (preferred for HTTP)."
- **Headless**: "`clusterIP: None` returns individual Pod IPs via DNS instead of a virtual IP — used by StatefulSets and clients that need direct Pod addressing."

## 7. Common Mistakes
- A LoadBalancer per service (cost) instead of Ingress.
- Selector not matching Pod labels → no endpoints.
- No readiness probe → traffic to unready pods.
- Relying on NodePort for production external access.
- Forgetting namespace in cross-namespace DNS.

## 8. Trade-offs
| Type | Pro | Con |
|------|-----|-----|
| ClusterIP | simple internal | not external |
| NodePort | external w/o LB | node ports, not scalable |
| LoadBalancer | real external IP | one LB/IP per svc, cost |
| Ingress | L7, one entry, many svcs | needs controller |

## 9. Production Best Practices
- ClusterIP + Ingress for HTTP; LoadBalancer sparingly.
- Readiness probes to control endpoints.
- Use DNS names, not IPs; namespace-qualified.
- Headless for stateful discovery.
- Network policies to restrict service access.

## 10. Security Considerations
- Network policies (default deny) for east-west.
- Internal LB annotation for private exposure.
- mTLS via service mesh for sensitive traffic.
- Limit externally exposed services.

## 11. Cost Optimization
- Consolidate external exposure behind one Ingress/LB.
- Internal services stay ClusterIP (free).
- Avoid per-service cloud LBs.

## 12. Troubleshooting Scenarios
- **No endpoints** → selector/label mismatch (`kubectl get endpoints`).
- **Connection refused** → readiness failing / wrong targetPort.
- **External IP pending** → cloud LB provisioning / quota.
- **DNS fails** → CoreDNS / wrong FQDN / namespace.

## 13. Hands-on Example
```bash
kubectl expose deployment api --port=80 --target-port=8000  # ClusterIP
kubectl get endpoints api        # verify Pods behind service
kubectl get svc
```

## 14. Terraform Example
```hcl
resource "kubernetes_service" "api" {
  metadata { name = "api" namespace = "app" }
  spec {
    selector = { app = "api" }
    port { port = 80 target_port = 8000 }
    type = "ClusterIP"
  }
}
```

## 15. Azure Example
```yaml
# Internal Azure Load Balancer service on AKS
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec: { type: LoadBalancer }
```

## 16. FastAPI / Python Example
```python
import httpx
# Service-to-service call via stable DNS name (not Pod IP)
@app.get("/aggregate")
async def aggregate():
    async with httpx.AsyncClient() as c:
        r = await c.get("http://orders.app.svc.cluster.local/orders")
    return r.json()
```

## 17. AKS Example
`type: LoadBalancer` provisions an Azure Standard LB with a public (or internal) IP; for HTTP, prefer an Ingress controller (NGINX/AGIC) so many services share one entry point and get L7 features.

## 18. How to Remember
**"Stable front door for changing Pods."** ClusterIP (internal), LoadBalancer (external L4), Ingress (external L7) — readiness decides who's behind it.

## 19. Real-World Analogy
A customer-service hotline number (stable) that routes your call to any available agent (Pod). Agents change shifts constantly, but you always dial the same number.

## 20. One-Page Cheat Sheet
- **What**: stable IP/DNS + load balancing over ephemeral Pods.
- **Types**: ClusterIP (internal), NodePort, LoadBalancer (external L4), ExternalName.
- **Selector → EndpointSlice** of *ready* Pods (readiness matters).
- **HTTP external**: prefer Ingress (L7, one entry) over many LoadBalancers.
- **Headless** (`clusterIP: None`): direct Pod DNS for stateful.
- **Debug**: `kubectl get endpoints` for selector issues.
