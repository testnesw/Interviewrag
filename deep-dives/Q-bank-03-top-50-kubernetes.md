# Question Bank · Top 50 Kubernetes & AKS Architect Questions

> Architect-level answers. Say them aloud.

---

## Core Concepts (1–14)

**1. What is Kubernetes?**
A container orchestrator that maintains **declared desired state** — you describe what you want (YAML), controllers continuously reconcile actual to desired (scheduling, healing, scaling). "Declare, don't do."

**2. Explain the control plane components.**
API server (front door), etcd (state store), scheduler (places pods), controller manager (reconciles), cloud-controller-manager. In AKS the control plane is Azure-managed.

**3. What is a Pod?**
Smallest deployable unit — one or more co-located containers sharing network/storage. Pods are ephemeral and disposable ("cattle not pets").

**4. Deployment vs ReplicaSet vs StatefulSet vs DaemonSet vs Job?**
Deployment = stateless rollouts (manages ReplicaSets); StatefulSet = stable identity/storage (databases); DaemonSet = one pod per node (agents); Job/CronJob = run-to-completion/scheduled. (D-S-D-J.)

**5. What is a Service and its types?**
Stable virtual IP + DNS load-balancing to pods. ClusterIP (internal), NodePort (node port), LoadBalancer (cloud LB), ExternalName. Decouples clients from ephemeral pod IPs.

**6. ClusterIP vs NodePort vs LoadBalancer vs Ingress?**
ClusterIP = internal only; NodePort = port on every node; LoadBalancer = external cloud LB (per service); Ingress = L7 routing (host/path) for many services behind one entry.

**7. What is Ingress?**
L7 HTTP(S) routing (host/path-based) via an ingress controller (NGINX/AGIC) — TLS termination, one entry point for many services.

**8. ConfigMap vs Secret?**
ConfigMap = non-sensitive config; Secret = sensitive data (base64, not encrypted by default) — use Key Vault CSI + encryption at rest for real secrets.

**9. What is a Namespace?**
Virtual cluster partition for isolation, quotas, and RBAC scoping — separate teams/environments.

**10. How does the scheduler place pods?**
Filters nodes by requests/constraints (affinity, taints/tolerations, node selectors) then scores and picks the best fit.

**11. Taints, tolerations, affinity?**
Taints repel pods from nodes; tolerations let specific pods land there; affinity/anti-affinity attract/repel pods relative to nodes/other pods (spread, co-location).

**12. Requests vs limits?**
Requests = guaranteed, used for scheduling; limits = hard cap (CPU throttled, memory OOMKilled). Set both; missing requests hurt scheduling.

**13. Liveness vs readiness vs startup probes?**
Liveness restarts hung containers; readiness gates traffic; startup protects slow-starting apps from premature liveness kills.

**14. QoS classes?**
Guaranteed (requests=limits), Burstable (requests<limits), BestEffort (none) — determines eviction priority under pressure.

---

## Scaling & Reliability (15–28)

**15. HPA vs VPA vs Cluster Autoscaler vs KEDA?**
HPA scales pods on metrics; VPA right-sizes pod resources; Cluster Autoscaler scales nodes; KEDA scales on event sources (queue depth) incl. scale-to-zero. (H-K-C.)

**16. How does HPA work?**
Watches metrics (CPU/memory/custom), compares to target, and adjusts replica count within min/max — needs metrics-server + requests set.

**17. How does Cluster Autoscaler work?**
Adds nodes when pods are unschedulable (pending), removes underutilized nodes when pods can reschedule elsewhere.

**18. How do you achieve zero-downtime deploys?**
Rolling update + readiness probes + PodDisruptionBudget + graceful shutdown (SIGTERM/preStop) + surge/unavailable settings.

**19. Rolling vs blue-green vs canary in K8s?**
Rolling = gradual replace (default); blue-green = two full envs, switch service; canary = shift small % (mesh/ingress weights) with metric gates.

**20. What is a PodDisruptionBudget?**
Guarantees a minimum number/percentage of pods stay available during voluntary disruptions (node drain, upgrades).

**21. How does K8s self-heal?**
Controllers reconcile: restart failed containers, reschedule pods off dead nodes, maintain replica counts — automatically.

**22. StatefulSet vs Deployment for databases?**
StatefulSet gives stable network identity + ordered deployment + persistent per-pod volumes — required for stateful workloads; Deployments assume interchangeable pods.

**23. Persistent volumes and storage classes?**
PV = provisioned storage; PVC = a claim/request; StorageClass = dynamic provisioning template (Azure Disk/Files). Decouples pods from storage.

**24. How do you handle node failure?**
Controller reschedules pods to healthy nodes; anti-affinity spreads replicas; multi-zone node pools survive zone loss; PDBs protect during maintenance.

**25. Multi-zone HA on AKS?**
Spread node pools across availability zones + pod anti-affinity/topology spread so replicas land in different zones.

**26. How do you upgrade AKS safely?**
Surge upgrade node pools with PDBs + drain/cordon, blue-green node pools for major changes, test in non-prod, control-plane then node pools.

**27. What causes CrashLoopBackOff and how to debug?**
App crash/misconfig/failed liveness/missing dependency. Debug: `kubectl logs` (+ `--previous`), `describe pod`, check env/config/probes/resources.

**28. What causes Pending pods?**
Insufficient resources (scale nodes), unschedulable constraints (taints/affinity), or no PV. Check `describe pod` events.

---

## Security & Networking (29–40)

**29. How do you secure an AKS cluster?**
Workload/Managed Identity, RBAC, network policies, private cluster, Azure Policy/Gatekeeper, Key Vault CSI for secrets, image scanning, non-root, read-only FS, mesh mTLS.

**30. What is Workload Identity?**
Federates a Kubernetes service account with an Entra identity via OIDC so pods get Azure tokens with **no secrets** — replaces pod-managed identity.

**31. How does pod networking work?**
Flat network — every pod has a routable IP; all pods communicate by default. Restrict with **network policies**. CNI (Azure CNI/kubenet) provides IPs.

**32. Azure CNI vs kubenet?**
Azure CNI assigns VNet IPs to pods (integrates with VNet, more IPs consumed); kubenet uses NAT (fewer IPs, extra hop). CNI for enterprise networking/private endpoints.

**33. What are network policies?**
L3/L4 allow rules controlling pod-to-pod/namespace traffic — default-deny + explicit allow for micro-segmentation (zero trust inside cluster).

**34. How do you manage secrets securely?**
Key Vault + CSI Secrets Store driver (mounts secrets, Workload Identity), enable encryption at rest for etcd, avoid plain Secrets, rotate.

**35. RBAC in Kubernetes?**
Roles/ClusterRoles + bindings grant least-privilege API access to users/service accounts; integrate with Entra for cluster auth on AKS.

**36. Private AKS cluster — why?**
API server gets a private endpoint (no public IP) — control-plane access stays within the VNet; combine with private endpoints for data services.

**37. How do you enforce policy at scale?**
Azure Policy for AKS / OPA Gatekeeper: admission-control policies (no privileged pods, required labels, allowed registries) as code.

**38. Pod security best practices?**
Non-root, read-only root FS, drop capabilities, no privileged, seccomp, resource limits, Pod Security Admission/standards.

**39. Service mesh — when and what?**
Istio/Linkerd for mTLS, traffic shaping (canary), retries, and uniform observability across many services without app changes — overhead, so use when needed.

**40. Ingress controller options on AKS?**
NGINX (popular, flexible), Application Gateway Ingress Controller (AGIC, WAF + Azure-native), or gateway API — choose by WAF/feature needs.

---

## Operations & Cost (41–50)

**41. How do you monitor AKS?**
Container Insights + Managed Prometheus/Grafana, OpenTelemetry for app traces, log analytics; alert on pod restarts, node pressure, HPA saturation, PVC usage.

**42. Golden signals for a K8s service?**
Latency, traffic, errors, saturation — per deployment; plus pod restarts, OOMKills, and resource utilization vs requests/limits.

**43. How do you optimize AKS cost?**
Right-size requests/limits, cluster autoscaler, **spot node pools** for interruptible work, bin-packing, KEDA scale-to-zero, reserved instances, remove idle namespaces.

**44. What are spot node pools?**
Deeply discounted evictable VMs for fault-tolerant/batch workloads (with tolerations); mix with on-demand for baseline.

**45. What is Helm and why use it?**
Package manager: templated, versioned, parameterized charts for repeatable releases + rollbacks across environments.

**46. Helm vs Kustomize?**
Helm = templating + packaging + releases; Kustomize = template-free overlays/patches per environment. Often combined.

**47. How do you do GitOps on AKS?**
Argo CD/Flux reconcile cluster state to a Git repo — declarative, auditable, revertible deployments; Git is the source of truth.

**48. How do you handle configuration across environments?**
Helm values / Kustomize overlays per env + ConfigMaps/Secrets (Key Vault CSI); keep config out of images.

**49. Debug a service that's slow under load.**
Check HPA scaling + node saturation, resource throttling (limits), probe flapping, downstream latency (traces), and network policy/DNS issues.

**50. Design a production AKS platform for GenAI.**
Private cluster, multi-zone node pools (+ GPU/spot pools), Azure CNI + network policies, Workload Identity, Key Vault CSI, AGIC/NGINX ingress, KEDA + HPA + cluster autoscaler, Container Insights + OTel, GitOps (Flux), Azure Policy — hosting stateless orchestrator to AOAI via private endpoints.

---

## Practice Tips
- Be ready to **draw**: pod → deployment → service → ingress, and the scaling trio (HPA/CA/KEDA).
- Tie answers to **AKS-native** features (Workload Identity, AGIC, Container Insights, spot pools).
- Always mention **requests/limits, probes, and PDBs** for reliability questions.

---

> Next: Top 50 Python.
