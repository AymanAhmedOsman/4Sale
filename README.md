# DevOps 3‑Tier Application (Tasks) — EKS + Helm + Terraform + GitHub Actions

This repo contains a complete, working reference implementation to satisfy your task requirements:

- **Application**: Simple 3‑tier app (Frontend via NGINX, Backend via FastAPI, Postgres DB).
- **Local Dev**: `docker compose` for fast local testing.
- **Kubernetes**: First‑class Helm chart with HPA, NetworkPolicies, PSA (restricted) and RBAC.
- **Infrastructure (AWS)**: Terraform to provision VPC + EKS (+ core add‑ons). Dev & Prod via workspaces/vars.
- **Stress test**: Locust script with env‑configurable load profile.
- **CI/CD**: GitHub Actions for Infra and App pipelines, with DevSecOps features (Trivy scans, Cosign signing, tfsec, OIDC to AWS, RBAC‑scoped deploy).
- **Security**: WAF/DDoS options, KMS‑backed encryption, secret management options documented below.
- **Monitoring**: kube‑prometheus‑stack, Loki (optional), Postgres dashboard, alert rules, and basic OpenTelemetry + Jaeger.

> You can deploy to AWS EKS or run locally on Minikube/K3d/MicroK8s (trade‑offs noted at the end).

---

## 1) Quickstart (Local)

```bash
# 1) Build & run locally
docker compose up --build -d

# 2) Try the API
curl -X POST http://localhost:8000/addTask -H "Content-Type: application/json" -d '{"title":"demo","description":"hello"}'
curl http://localhost:8000/listTasks
# Delete by id
curl -X DELETE http://localhost:8000/deleteTask/1
```

Frontend is served on **http://localhost:8080** (simple HTML test page calling the backend).

---

## 2) Kubernetes Deploy (Helm)

```bash
# Create namespaces with restricted PSA labels
kubectl create ns app || true
kubectl label ns app pod-security.kubernetes.io/enforce=restricted --overwrite=true
kubectl label ns app pod-security.kubernetes.io/warn=restricted --overwrite=true
kubectl label ns app pod-security.kubernetes.io/audit=restricted --overwrite=true

kubectl create ns data || true
kubectl label ns data pod-security.kubernetes.io/enforce=restricted --overwrite=true
kubectl label ns data pod-security.kubernetes.io/warn=restricted --overwrite=true
kubectl label ns data pod-security.kubernetes.io/audit=restricted --overwrite=true

# Install Postgres (in data ns) via dependent Bitnami chart
helm dependency update ./app-helm
# Adjust values under helm/tasks-app/values.yaml as needed
helm upgrade --install tasks ./app-helm -n app -f ./app-helm/values.yaml

```

### HPA
Configured for the backend (FastAPI) to scale on CPU (target 70%) and QPS via custom metrics (optional). Adjust under `app-helm/templates/back-hpa.yaml` and values.

### NetworkPolicies
- Only pods in `app` namespace with label `app=backend` can reach Postgres service in `data` namespace.
- Deny all egress by default except required DNS and Postgres.

### PSA (Pod Security Admission)
- Namespaces are labeled to **enforce restricted** profile.
- Pods run as non‑root with read‑only FS where possible. See `securityContext` in charts.

---

## 3) Terraform (AWS)

Structure under `infra/terraform`. Two environments (dev/prod) using workspaces or per‑env tfvars:
```bash
cd infra/terraform
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars


terraform plan -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

Creates:
- VPC, public/private subnets, NAT, IGW
- EKS cluster and node group
- Core add‑ons: VPC CNI, CoreDNS, kube-proxy (managed), optional: AWS Load Balancer Controller, EBS CSI
- Outputs kubeconfig for `kubectl` / `helm`

> Requires AWS account & permissions (recommended: GitHub OIDC with fine‑grained IAM).

---

## 4) Stress Testing (Locust)

```bash
# CLI envs
$env:TARGET_HOST=<"DNS-Loadbalancer">
$env:FRONTEND_PATH="/" 
$env:BACKEND_PATH="/api/listTasks" 
$env:WAIT_TIME_MIN="1"  
$env:WAIT_TIME_MAX="2" 

locust -f testscript.py --headless -u 200 -r 20 -t 10m  


```

Only GETs (one for “frontend”, one for “backend”).
Good for smoke/latency and read-heavy scenarios or separating FE vs API paths.
---

## 5) CI/CD (GitHub Actions)

- **.github/workflows/app.yml**: Build & push backend and frontend images to GHCR; scan with **Trivy**; **Cosign** sign; deploy via Helm to EKS (RBAC‑scoped ServiceAccount).
- **.github/workflows/infra.yml**: `terraform fmt/validate/plan/apply`, drift detection, `tfsec` security scan; OIDC to AWS.

Secrets/variables to add in GitHub:
- `AWS_ACCOUNT_ID`, `AWS_REGION`, `EKS_CLUSTER_NAME`
- `AWS_ROLE_TO_ASSUME` (for OIDC)
- `COSIGN_PRIVATE_KEY` (or use keyless with Fulcio)
- Optional: `SNYK_TOKEN` / `GRYPE_DB` / `TRIVY_DB_REPOSITORY`

---

## 6) Security (How Enforced & Tests)

- **Access control**: Kubernetes **RBAC** manifests (`helm/tasks-app/templates/rbac.yaml`), GitHub OIDC role with least privileges for CI, per‑ns restrictions.
- **Encryption**: 
  - **At rest**: EBS volumes and RDS/EBS CSI with **KMS CMK**; secrets via **SOPS** or **Sealed Secrets** (examples included). 
  - **In transit**: TLS on Ingress; mTLS (optional) via service mesh (Istio/Linkerd) or OPA policies.
- **Secrets**: Examples using **Kubernetes Secrets (encrypted by KMS on EKS)** and **SOPS** template. CI avoids plaintext secrets; pull via OIDC and parameter store if preferred.
- **RBAC**: ServiceAccount‑scoped Helm deployer; read‑only permissions for CD; resource‑scoped Roles not cluster‑wide.
- **Validation**: 
  - `kubectl auth can-i ...` checks in CI
  - `conftest` (OPA) policies for **psp/psa**, runAsNonRoot, readOnlyRootFS
  - `tfsec` for IaC, Trivy for images
  - `kube-bench` / `kube-hunter` optional

---

## 7) Monitoring & Alerts

### Stack
- **kube-prometheus-stack** (Prometheus, Alertmanager, Grafana, kube-state-metrics, node-exporter)
- Optional: **Loki + Promtail** for logs
- **Postgres mixin** dashboard (Grafana): importable dashboard ID `9628` (or use provided json under `monitoring/grafana-dashboards/postgres.json`)
- **Alerts** under `monitoring/prometheus-rules.yaml`:
  - High CPU (>80% for 5m)
  - Pod crash loops
  - Postgres down



### Alert Delivery
- Configure Alertmanager receivers (email/webhook) under `monitoring/alertmanager-values.yaml`.

---

## Trade‑offs for Local Clusters

- **No LoadBalancer** (use NodePort or Ingress via `ingress-nginx` + hostPorts). 
- **Storage**: use **local-path-provisioner** or Minikube hostpath. 
- **Cloud‑integrations** (ALB, WAF, KMS) are mocked/disabled locally. Keep AWS files intact for evaluation.

---

## Tool Choices (Short Justification)

- **FastAPI**: lightweight, async, easy OpenAPI, great perf.
- **Postgres**: reliable relational DB and Helm chart support.
- **Helm**: templating, repeatable deploys, values per env.
- **Terraform**: standard for AWS infra; tfsec supports IaC scanning.
- **Trivy**: fast, free image + IaC scanning; **Cosign** for image signing and provenance.
- **kube‑prometheus‑stack**: de‑facto standard stack with Grafana.
- **Locust**: Pythonic load tests with clear user behavior models.
- **NetworkPolicy**: Calico/Cilium compatible; restrict DB access by ns/label.
- **PSA**: enforced via ns labels + Pod securityContext (non‑root, no privilege).

---




