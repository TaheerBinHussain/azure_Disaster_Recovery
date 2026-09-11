# 🚀 Azure Disaster Recovery — Week 6 Cloud Native AI

![Azure](https://img.shields.io/badge/Azure-Free_Tier-0078D4?logo=microsoftazure)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![FastAPI](https://img.shields.io/badge/API-FastAPI-009688?logo=fastapi)
![Cost](https://img.shields.io/badge/Cost-$0.00-brightgreen)

> **Week 6 of the AI Platform Engineering Bootcamp** — Production-grade deployment on Azure using **100% free-tier services**.

---

## 🏗️ Architecture

```
┌───────────────────────────────────────────────────────────┐
│                     ZERO COST STACK                       │
│                                                           │
│  GitHub Repo ──push──► GitHub Actions (FREE 2000 min/mo) │
│                              │                            │
│                    ┌─────────┴──────────┐                 │
│                    │ Build Docker Image  │                 │
│                    │ Push → ghcr.io FREE │                 │
│                    │ Terraform Apply     │                 │
│                    └─────────┬──────────┘                 │
│                              │                            │
│                              ▼                            │
│         ┌────────────────────────────────────┐            │
│         │   Azure Container Apps (FREE)      │            │
│         │   ┌──────────┐  ┌──────────┐       │            │
│         │   │  BLUE v1 │  │ GREEN v2 │       │            │
│         │   │ 90% traffic│ 10% traffic        │            │
│         │   └──────────┘  └──────────┘       │            │
│         │   Scale: 0 → 3 replicas             │            │
│         │   Self-healing (liveness probes)    │            │
│         └───────────────┬────────────────────┘            │
│                         │                                  │
│         ┌───────────────▼────────────────────┐            │
│         │  Azure Monitor + App Insights       │            │
│         │  Azure Key Vault (secrets)          │            │
│         │  FREE tiers — $0/month              │            │
│         └────────────────────────────────────┘            │
└───────────────────────────────────────────────────────────┘
```

---

## ✅ Features Demonstrated

| Feature | Implementation | Free? |
|---|---|---|
| **CI/CD Pipeline** | GitHub Actions | ✅ 2000 min/mo |
| **Container Registry** | GitHub Container Registry (ghcr.io) | ✅ Free |
| **Infrastructure as Code** | Terraform → Azure Container Apps | ✅ Free |
| **Blue/Green Deployment** | Revision-based traffic splitting | ✅ Free |
| **Canary Deployment** | Gradual 10%→100% traffic shift | ✅ Free |
| **Auto Rollback** | Health check failure → revert | ✅ Free |
| **Zero-Downtime Deploy** | Container Apps revision model | ✅ Free |
| **Auto-scaling** | Scale 0→3 replicas on HTTP load | ✅ Free |
| **Self-Healing** | Liveness + Readiness probes | ✅ Free |
| **Monitoring** | Azure Monitor + App Insights | ✅ 5 GB/mo |
| **Secrets Management** | Azure Key Vault | ✅ 10k ops/mo |
| **IAM** | Service Principal + RBAC | ✅ Free |

---

## 📁 Project Structure

```
azure_Disaster_Recovery/
├── app/
│   ├── main.py              # FastAPI application
│   └── requirements.txt     # Python dependencies
├── infra/
│   └── main.tf              # Terraform — all Azure resources
├── scripts/
│   ├── blue_green.sh        # Blue/Green deployment switcher
│   ├── canary.sh            # Canary rollout (10%→100%)
│   └── setup_secrets.sh     # One-shot GitHub Secrets setup
├── .github/
│   └── workflows/
│       └── deploy.yml       # CI/CD pipeline
├── Dockerfile               # Multi-stage, optimised image
└── README.md
```

---

## 🚀 Quick Start

### 1. Setup GitHub Secrets (one time)

```bash
chmod +x scripts/setup_secrets.sh
./scripts/setup_secrets.sh
```

### 2. Deploy Infrastructure (one time)

```bash
cd infra
terraform init
terraform apply -auto-approve
```

### 3. Trigger CI/CD

```bash
git add .
git commit -m "feat: initial deployment"
git push origin main
# GitHub Actions automatically builds, pushes, and deploys
```

### 4. Blue/Green Deployment

```bash
# Deploy green revision and promote to 100%
./scripts/blue_green.sh green latest
```

### 5. Canary Deployment

```bash
# Gradual rollout: 10% → 25% → 50% → 75% → 100%
./scripts/canary.sh v2.0.0
```

---

## 🔗 Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /` | Dashboard UI — shows deployment color, version, region |
| `GET /health` | Liveness probe — Azure restarts container if this fails |
| `GET /ready` | Readiness probe — Azure waits before routing traffic |
| `GET /info` | Full deployment metadata (JSON) |
| `GET /docs` | Swagger UI (auto-generated) |

---

## 💰 Cost Breakdown — $0.00/month

| Service | Free Allowance | Usage |
|---|---|---|
| Azure Container Apps | 180,000 vCPU-s/month | < 5% |
| GitHub Actions | 2,000 min/month | < 10% |
| GitHub Container Registry | Unlimited (public) | ✅ |
| Azure Monitor / Log Analytics | 5 GB/month logs | < 1 GB |
| Azure Application Insights | 5 GB/month | < 1 GB |
| Azure Key Vault | 10,000 ops/month | < 100 |
| **Total** | | **$0.00** |

---

## 🏷️ Week 6 Concept Mapping

| Roadmap Concept | Azure Implementation |
|---|---|
| AWS → Azure | Azure Container Apps |
| Terraform | Terraform + AzureRM provider |
| GitHub Actions | GitHub Actions (same!) |
| Secrets / IAM | Key Vault + Service Principal |
| Networking | Container Apps managed VNet |
| Autoscaling | HTTP-based scale rules (0→3) |
| Cost Optimization | Scale-to-zero, free tiers |
| Blue/Green | Revision-based traffic weights |
| Canary | Gradual revision traffic shift |
| Auto Rollback | Health check → revert script |
| Zero Downtime | Rolling revision update |
| Self-Healing | Liveness probe → auto restart |
| Disaster Recovery | Multi-revision + rollback |

---

*Built during Week 6 of the AI Platform Engineering & Autonomous Systems Bootcamp*
