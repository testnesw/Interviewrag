# 44 · Ingress

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
Ingress is a **single entry point for HTTP/HTTPS traffic** into your cluster. Instead of exposing every service with its own load balancer, one Ingress routes requests by hostname and URL path to the right service — and handles TLS.

## 2. Architect-Level Explanation
An L7 routing API implemented by an **Ingress Controller**:
- **Ingress resource**: rules (host + path → service:port) + TLS config; it's just config.
- **Ingress Controller**: the actual proxy (NGINX, AGIC, Istio, Traefik) that watches Ingress resources and programs routing.
- **Features**: TLS termination, host/path routing, rewrites, rate limiting, auth (varies by controller).
- **Evolution**: the **Gateway API** is the newer, more expressive successor (role-oriented, richer routing).
- One external LB fronts the controller; many services share it.

## 3. Real Enterprise Use Case
A SaaS runs NGINX Ingress: `app.contoso.com/api`→api-svc, `/`→frontend-svc, `admin.contoso.com`→admin-svc. TLS certs from cert-manager/Key Vault, rate limiting and WAF (or AGIC+App Gateway WAF), one public IP for dozens of services.

## 4. Architecture Diagram (ASCII)
```
 Client ─HTTPS─► [ External LB ] ─► Ingress Controller (NGINX/AGIC)
                                      │ reads Ingress rules
        host app.contoso.com:
          /api  ─► api-svc   ─► Pods
          /     ─► web-svc   ─► Pods
        host admin.contoso.com ─► admin-svc ─► Pods
   TLS terminated at controller ; one entry point, many services
```

## 5. Interview Questions
1. Ingress vs LoadBalancer Service?
2. Ingress resource vs Ingress Controller?
3. How does TLS work with Ingress?
4. Common controllers and how to choose?
5. What is the Gateway API?

## 6. Strong Interview Answers
- **Ingress vs LB**: "A LoadBalancer Service gives one external L4 IP per service — costly and no L7 features. Ingress provides one entry point with L7 host/path routing and TLS for many services behind a single LB."
- **Resource vs controller**: "The Ingress resource is just declarative routing rules; nothing happens without an Ingress Controller (NGINX/AGIC/Istio) actually running as the proxy that implements them."
- **TLS**: "TLS is terminated at the controller using certificates from a Secret (often managed by cert-manager or Key Vault). You can re-encrypt to backends if needed."
- **Choosing**: "NGINX for flexibility/community; **AGIC** to leverage Azure Application Gateway + WAF; Istio/Gateway for mesh-integrated routing. Pick by WAF needs, Azure integration, and features."
- **Gateway API**: "The successor to Ingress — more expressive, role-oriented (GatewayClass/Gateway/HTTPRoute), better for advanced routing and multi-team ownership. I'd adopt it for new platforms."

## 7. Common Mistakes
- Deploying Ingress resources without a controller.
- One LoadBalancer per service instead of Ingress.
- Missing/mismatched TLS Secret.
- Path/pathType confusion (Prefix vs Exact).
- No WAF on internet-facing ingress.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Ingress | L7, one entry, TLS, cost-efficient | needs controller, L7 only |
| LoadBalancer/svc | simple L4 external | per-service IP, cost |
| Gateway API | expressive, role-based | newer, migration effort |

## 9. Production Best Practices
- One controller (HA, autoscaled) + one external LB.
- Automated TLS (cert-manager/Key Vault) + rotation.
- WAF (AGIC+App Gateway or NGINX+ModSecurity).
- Rate limiting + sensible timeouts.
- Consider Gateway API for new clusters.

## 10. Security Considerations
- TLS everywhere; strong ciphers, HSTS.
- WAF for internet-facing ingress.
- Restrict controller RBAC; network policies.
- Auth at edge (OAuth2 proxy) where needed.

## 11. Cost Optimization
- One LB/entry point for many services (vs many LBs).
- Autoscale the controller to demand.
- Cache/CDN static via Front Door in front.

## 12. Troubleshooting Scenarios
- **404/502** → wrong service/port, backend unhealthy, path rules.
- **TLS errors** → Secret missing/mismatched host, cert chain.
- **No routing** → controller not installed / ingressClass mismatch.
- **Wrong path match** → pathType Prefix vs Exact.

## 13. Hands-on Example
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress --create-namespace
kubectl get ingress
```

## 14. Terraform Example
```hcl
resource "kubernetes_ingress_v1" "app" {
  metadata { name = "app-ingress" namespace = "app"
    annotations = { "kubernetes.io/ingress.class" = "nginx" } }
  spec {
    tls { hosts = ["app.contoso.com"] secret_name = "app-tls" }
    rule { host = "app.contoso.com"
      http { path { path = "/api" path_type = "Prefix"
        backend { service { name = "api" port { number = 80 } } } } }
    }
  }
}
```

## 15. Azure Example
```bash
# Enable AGIC add-on (App Gateway Ingress Controller) on AKS
az aks enable-addons -g rg-aks -n prod-aks -a ingress-appgw \
  --appgw-id <app-gateway-id>
```

## 16. FastAPI / Python Example
```python
# Service targeted by Ingress path /api → this app
@app.get("/api/health")
def health(): return {"status": "ok"}
```

## 17. AKS Example (Ingress manifest)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: app
  annotations: { kubernetes.io/ingress.class: azure/application-gateway }
spec:
  tls: [{ hosts: [app.contoso.com], secretName: app-tls }]
  rules:
    - host: app.contoso.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend: { service: { name: api, port: { number: 80 } } }
```

## 18. How to Remember
**"One smart HTTP door for many rooms."** Ingress = rules; Controller = the proxy that enforces them; one LB, many services.

## 19. Real-World Analogy
A building's front desk that reads each visitor's destination (host/path) and directs them to the right office (service), checks their secure badge (TLS), and screens threats (WAF) — instead of every office having its own street entrance.

## 20. One-Page Cheat Sheet
- **What**: L7 HTTP(S) entry point routing host/path → services, with TLS.
- **Two parts**: Ingress resource (rules) + Ingress Controller (proxy — required).
- **vs LoadBalancer svc**: one entry for many services + L7 features vs one IP each.
- **Controllers**: NGINX, AGIC (App Gateway+WAF), Istio/Gateway API.
- **Secure**: TLS (cert-manager/Key Vault) + WAF + rate limiting.
- **Future**: Gateway API supersedes Ingress.
