# DEEP MECHANICS · AKS Security

> Level 2 — the defense-in-depth layers: identity (Entra + Workload Identity),
> network policy, RBAC, pod security, secrets, and image/supply-chain.

---

## 0. The precise mental model
AKS security = **defense-in-depth across identity, network, workload, and supply chain**. No single control is enough; you layer: **Entra-integrated auth + RBAC** (who), **network policies + private cluster** (where traffic goes), **pod security + Workload Identity** (what pods can do), **secrets in Key Vault**, and **image scanning/admission** (what runs). Map each threat to a layer.

---

## 1. Identity & access
- **Entra ID integration** — authenticate cluster users via Entra; **Azure RBAC for Kubernetes** maps Entra identities to K8s permissions.
- **Kubernetes RBAC** — Roles/ClusterRoles + bindings for least-privilege in-cluster.
- **Workload Identity (federated)** — Pods get Entra tokens via their K8s service account → access Azure resources **keyless** (replaces pod-managed identity / stored secrets).

## 2. Network security
- **Private cluster** — API server has a private IP (no public endpoint).
- **Network Policies** (Azure/Calico/Cilium) — L3/4 Pod-to-Pod firewall (default-deny + allow specific) → micro-segmentation inside the cluster.
- **Egress control** — route through Azure Firewall (UDR) + required FQDN allow-list.
- **Authorized IP ranges** on the API server if public.

## 3. Workload/pod hardening
- **Pod Security Admission** (baseline/restricted) — block privileged/root/hostPath Pods.
- **securityContext** — runAsNonRoot, drop capabilities, read-only root FS, no privilege escalation.
- **Resource limits** (prevent noisy-neighbor/DoS).
- **Azure Policy for AKS** (Gatekeeper/OPA) — enforce org rules at admission.

## 4. Secrets
- **Secrets Store CSI Driver + Key Vault + Workload Identity** — secrets outside etcd, rotated, audited (see Secrets deep dive).
- Etcd encryption (KMS with Key Vault CMK).

## 5. Image & supply chain
- **Trusted registry (ACR)** + **image scanning** (Defender for Containers / Trivy) for CVEs.
- **Admission control** to allow only signed/scanned images.
- Minimal base images, no root, pinned digests.

## 6. Runtime & monitoring
- **Microsoft Defender for Containers** — runtime threat detection, vulnerability assessment, K8s posture.
- Audit logs → Log Analytics/Sentinel; monitor anomalous API calls.

## 7. The hard follow-ups (with answers)
1. **"How do pods access Azure resources securely?"** → **Workload Identity** (federated) → Entra token via SA, keyless. (§1)
2. **"Restrict pod-to-pod traffic?"** → Network Policies (default-deny + allow) for micro-segmentation. (§2)
3. **"Stop privileged/root containers?"** → Pod Security Admission (restricted) + securityContext + Azure Policy/OPA. (§3)
4. **"Manage secrets safely?"** → CSI Secrets Store + Key Vault + Workload Identity; etcd encryption. (§4)
5. **"Prevent vulnerable images?"** → ACR + Defender/Trivy scanning + admission control (signed/scanned only). (§5)
6. **"Hide the API server?"** → private cluster (or authorized IP ranges). (§2)

## 8. One-screen recall
- AKS security = **defense-in-depth: identity + network + workload + supply chain**.
- **Identity**: Entra integration + **Azure RBAC for K8s** + in-cluster RBAC + **Workload Identity (keyless)**.
- **Network**: **private cluster**, **Network Policies** (micro-seg), egress via **Firewall/FQDN**, authorized IPs.
- **Workload**: **Pod Security Admission (restricted)**, securityContext (nonroot/drop-caps/readonly), limits, **Azure Policy/OPA** admission.
- **Secrets**: CSI + **Key Vault** + Workload Identity; etcd encryption (CMK).
- **Supply chain**: **ACR + image scanning (Defender/Trivy)** + signed-image admission; minimal images.
- **Runtime**: **Defender for Containers** + audit logs → Sentinel.

> Next: AKS Networking.
