# Personal Data Pipeline

A portfolio-grade data pipeline built with **Apache Airflow + dbt + BigQuery**, containerised with **Docker Compose**.

Mirrors a production medallion architecture (Bronze → Silver → Gold → Reporting) using the
[TheLook e-commerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)
BigQuery public dataset as the data source.

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │         Docker Compose (local)              │
                    │                                             │
                    │   ┌──────────┐    ┌──────────────────────┐  │
                    │   │ Postgres │    │      Airflow          │  │
                    │   │(metadata)│    │  webserver+scheduler  │  │
                    │   └──────────┘    └──────────────────────┘  │
                    └─────────────────────────────────────────────┘
                                          │ triggers dbt
                                          ▼
                    ┌─────────────────────────────────────────────┐
                    │              BigQuery (GCP)                  │
                    │                                             │
                    │  bigquery-public-data.thelook_ecommerce     │
                    │           │                                 │
                    │           ▼                                 │
                    │  bronze_dev   (raw data)                    │
                    │           │                                 │
                    │           ▼                                 │
                    │  silver_dev   (cleaned + typed)             │
                    │           │                                 │
                    │           ▼                                 │
                    │  gold_dev     (business aggregates)         │
                    │           │                                 │
                    │           ▼                                 │
                    │  reporting_dev (dashboard-ready)            │
                    └─────────────────────────────────────────────┘
```

### DAG chain (runs daily at 1 AM UTC)

```
bronze_layer_dag  →  silver_layer_dag  →  gold_layer_dag  →  reporting_layer_dag
```

### dbt models

| Layer | Dataset | Models |
|-------|---------|--------|
| Bronze | `bronze_dev` | `bronze_orders`, `bronze_users`, `bronze_order_items`, `bronze_products` |
| Silver | `silver_dev` | `stg_orders`, `stg_users`, `stg_order_items` |
| Gold | `gold_dev` | `daily_revenue`, `user_cohorts`, `product_performance`, `customer_summary` |
| Reporting | `reporting_dev` | `rpt_executive_summary`, `rpt_top_products` |

---

## Prerequisites

- Docker Desktop
- A personal GCP project with BigQuery API enabled
- A GCP service account JSON key with **BigQuery Data Editor** + **BigQuery Job User** roles

---

## Quick Start

### 1. Clone and configure

```bash
git clone <your-repo-url> personal-data-pipeline
cd personal-data-pipeline

cp .env.example .env
# Edit .env — fill in GCP_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS
```

### 2. Create BigQuery datasets

In your GCP project, create these datasets (region: US):

```
bronze_dev
silver_dev
gold_dev
reporting_dev
```

Or run via `bq`:

```bash
for ds in bronze_dev silver_dev gold_dev reporting_dev; do
  bq mk --dataset --location=US $GCP_PROJECT_ID.$ds
done
```

### 3. Start the stack

```bash
# First run — initialise the Airflow DB and create admin user
docker compose up airflow-init

# Start everything
docker compose up -d

# Check all containers are healthy
docker compose ps
```

### 4. Open Airflow

Go to [http://localhost:8080](http://localhost:8080) — login: `admin` / `admin`

Enable and trigger **`bronze_layer_dag`** manually to kick off the full pipeline.

### 5. Tear down

```bash
docker compose down          # stops containers, keeps volumes
docker compose down -v       # stops containers AND deletes Postgres volume
```

---

## Project Structure

```
personal-data-pipeline/
├── docker-compose.yml          # Airflow stack (LocalExecutor)
├── Dockerfile                  # Airflow image + dbt-bigquery
├── requirements.txt
├── .env.example
├── dbt_project.yml
├── profiles.yml                # dbt → BigQuery connection
├── dags/
│   ├── bronze_layer_dag.py
│   ├── silver_layer_dag.py
│   ├── gold_layer_dag.py
│   └── reporting_layer_dag.py
├── models/
│   ├── sources.yml
│   ├── bronze/
│   ├── staging/
│   ├── marts/
│   └── reporting/
├── macros/
│   ├── generate_schema_name.sql
│   ├── generate_surrogate_key.sql
│   ├── parse_datetime.sql
│   └── unique_combination_of_columns.sql
└── .github/workflows/
    └── dbt_tests.yaml
```

---

## Development

### Run dbt locally (outside Docker)

```bash
pip install dbt-bigquery==1.7.4
export GCP_PROJECT_ID=your-project-id
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

dbt run --select bronze
dbt run --select staging
dbt run --select marts
dbt run --select reporting

dbt test
dbt docs generate && dbt docs serve
```

### Run dbt inside the running container

```bash
docker compose exec airflow-scheduler bash
cd /opt/airflow/dbt
dbt run --select bronze
```

---

## GitHub Actions CI

Set these repository secrets:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `WORKLOAD_IDENTITY_PROVIDER` | GCP Workload Identity Provider resource name |
| `SERVICE_ACCOUNT` | Service account email |

The `dbt_tests.yaml` workflow runs `dbt compile` + source tests on every push to `main`/`dev`.
