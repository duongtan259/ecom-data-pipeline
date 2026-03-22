# ecom-data-pipeline

A portfolio-grade batch data pipeline built on **dbt + BigQuery**, orchestrated by **Cloud Workflows + Cloud Run Jobs** on GCP.

Implements a medallion architecture (Bronze → Silver → Gold → Reporting) sourced from the
[TheLook e-commerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)
BigQuery public dataset.

---

## Architecture

```
Cloud Scheduler  (daily 1 AM UTC)
       │
       ▼
Cloud Workflows  (ecom-pipeline)
       │
       ├─ bronze-layer  ──▶  Cloud Run Job  ──▶  dbt run --select bronze
       │
       ├─ silver-layer  ──▶  Cloud Run Job  ──▶  dbt run + test --select staging
       │
       ├─ gold-layer    ──▶  Cloud Run Job  ──▶  dbt run + test --select marts
       │
       └─ reporting-layer ▶  Cloud Run Job  ──▶  dbt run + test --select reporting
                                    │
                                    ▼
                              BigQuery (US)
                         bigquery-public-data.thelook_ecommerce
                                    │
                         bronze_prod  →  silver_prod  →  gold_prod  →  reporting_prod
```

### dbt models

| Layer | Dataset | Models |
|-------|---------|--------|
| Bronze | `bronze_prod` | `bronze_orders`, `bronze_users`, `bronze_order_items`, `bronze_products` |
| Silver | `silver_prod` | `stg_orders`, `stg_users`, `stg_order_items` |
| Gold | `gold_prod` | `daily_revenue`, `user_cohorts`, `product_performance`, `customer_summary` |
| Reporting | `reporting_prod` | `rpt_executive_summary`, `rpt_top_products` |

---

## GCP Resources

| Resource | Name | Purpose |
|---|---|---|
| Artifact Registry | `ecom-pipeline` | Docker image for dbt runner |
| Cloud Run Jobs | `bronze/silver/gold/reporting-layer` | Run each dbt layer |
| Cloud Workflows | `ecom-pipeline` | Orchestrate the 4-job chain |
| Cloud Scheduler | `ecom-pipeline-daily` | Trigger at 1 AM UTC |
| BigQuery datasets | `*_prod` | Production output |

---

## Quick Start

### One-time GCP setup

```bash
export GCP_PROJECT_ID=your-project-id
export GCP_REGION=us-central1

# Build and push the dbt image first
docker buildx build --platform linux/amd64 -f Dockerfile.cloudrun \
  -t ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/ecom-pipeline/dbt:latest \
  --push .

# Provision all GCP resources (Run Jobs, Workflow, Scheduler, IAM, BQ datasets)
bash gcp/setup_cloudrun.sh
```

### Trigger manually

```bash
gcloud workflows run ecom-pipeline --location=us-central1 --project=your-project-id
```

---

## Project Structure

```
ecom-data-pipeline/
├── Dockerfile.cloudrun         # Slim dbt image (Cloud Run Jobs)
├── run_dbt.sh                  # Cloud Run entrypoint
├── dbt_project.yml
├── profiles.yml                # dbt → BigQuery (dev + prod targets)
├── gcp/
│   ├── setup_cloudrun.sh       # one-time GCP provisioning script
│   └── workflow.yaml           # Cloud Workflows definition
├── models/
│   ├── sources.yml
│   ├── bronze/
│   ├── staging/
│   ├── marts/
│   └── reporting/
├── macros/
└── .github/workflows/
    ├── dbt_tests.yaml          # compile + source tests on push
    ├── dbt_docs.yaml           # docs → GitHub Pages
    └── deploy_cloudrun.yaml    # build dbt image, update Cloud Run Jobs + Workflow
```

---

## GitHub Actions CI

Repository secrets required:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | GCP project ID |
| `GCP_REGION` | Region (e.g. `us-central1`) |
| `WORKLOAD_IDENTITY_PROVIDER` | WIF provider resource name |
| `SERVICE_ACCOUNT` | CI service account email |

Workflows:
- **`dbt_tests.yaml`** — `dbt compile` + source tests on every push
- **`dbt_docs.yaml`** — generates and deploys dbt docs to GitHub Pages
- **`deploy_cloudrun.yaml`** — builds dbt image, updates Cloud Run Jobs + Workflow on every push to `main`
