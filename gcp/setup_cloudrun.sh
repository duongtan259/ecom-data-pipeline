#!/usr/bin/env bash
# One-time setup: provisions all GCP resources for the ecom Cloud Run pipeline.
# Run once from your local machine with owner/editor permissions.
#
#   export GCP_PROJECT_ID=data-491008
#   bash gcp/setup_cloudrun.sh

set -euo pipefail

PROJECT="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
REGION="${GCP_REGION:-us-central1}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/ecom-pipeline/dbt:latest"

RUNNER_SA="ecom-runner@${PROJECT}.iam.gserviceaccount.com"
WORKFLOW_SA="ecom-workflow@${PROJECT}.iam.gserviceaccount.com"
SCHEDULER_SA="ecom-scheduler@${PROJECT}.iam.gserviceaccount.com"

echo "=== Enabling APIs ==="
gcloud services enable \
  run.googleapis.com \
  workflows.googleapis.com \
  cloudscheduler.googleapis.com \
  artifactregistry.googleapis.com \
  --project="$PROJECT"

echo "=== Artifact Registry ==="
gcloud artifacts repositories create ecom-pipeline \
  --repository-format=docker \
  --location="$REGION" \
  --project="$PROJECT" 2>/dev/null || echo "  repo already exists"

echo "=== Service accounts ==="
for name in ecom-runner ecom-workflow ecom-scheduler; do
  gcloud iam service-accounts create "$name" \
    --project="$PROJECT" \
    --display-name="$name" 2>/dev/null || echo "  $name already exists"
done

echo "=== IAM bindings ==="
# dbt runner: BigQuery access
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${RUNNER_SA}" \
  --role="roles/bigquery.dataEditor" --condition=None
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${RUNNER_SA}" \
  --role="roles/bigquery.jobUser" --condition=None

# Workflow SA: run Cloud Run Jobs and read executions
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${WORKFLOW_SA}" \
  --role="roles/run.developer" --condition=None
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${WORKFLOW_SA}" \
  --role="roles/run.viewer" --condition=None

# Scheduler SA: trigger Workflows
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SCHEDULER_SA}" \
  --role="roles/workflows.invoker" --condition=None

# CI/CD SA (from OIDC): update jobs + workflows
CI_SA="${CI_SA:-}"
if [[ -n "$CI_SA" ]]; then
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${CI_SA}" \
    --role="roles/run.developer" --condition=None
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${CI_SA}" \
    --role="roles/workflows.editor" --condition=None
fi

echo "=== BigQuery prod datasets ==="
for ds in bronze_prod silver_prod gold_prod reporting_prod; do
  bq mk --dataset --location=US "${PROJECT}:${ds}" 2>/dev/null || echo "  $ds already exists"
done

echo "=== Cloud Run Jobs ==="
for layer in bronze silver gold reporting; do
  if gcloud run jobs describe "${layer}-layer" --region="$REGION" --project="$PROJECT" &>/dev/null; then
    gcloud run jobs update "${layer}-layer" \
      --image="$IMAGE" \
      --region="$REGION" \
      --project="$PROJECT"
  else
    gcloud run jobs create "${layer}-layer" \
      --image="$IMAGE" \
      --region="$REGION" \
      --service-account="$RUNNER_SA" \
      --set-env-vars="LAYER=${layer},GCP_PROJECT_ID=${PROJECT},DBT_TARGET=prod" \
      --max-retries=1 \
      --task-timeout=30m \
      --project="$PROJECT"
  fi
done

echo "=== Cloud Workflow ==="
gcloud workflows deploy ecom-pipeline \
  --location="$REGION" \
  --service-account="$WORKFLOW_SA" \
  --source="$(dirname "$0")/workflow.yaml" \
  --project="$PROJECT"

echo "=== Cloud Scheduler ==="
WORKFLOW_URI="https://workflowexecutions.googleapis.com/v1/projects/${PROJECT}/locations/${REGION}/workflows/ecom-pipeline/executions"
if gcloud scheduler jobs describe ecom-pipeline-daily --location="$REGION" --project="$PROJECT" &>/dev/null; then
  gcloud scheduler jobs update http ecom-pipeline-daily \
    --location="$REGION" \
    --schedule="0 1 * * *" \
    --project="$PROJECT"
else
  gcloud scheduler jobs create http ecom-pipeline-daily \
    --location="$REGION" \
    --schedule="0 1 * * *" \
    --time-zone="UTC" \
    --uri="$WORKFLOW_URI" \
    --message-body="{}" \
    --oauth-service-account-email="$SCHEDULER_SA" \
    --project="$PROJECT"
fi

echo ""
echo "=== Done! ==="
echo "Trigger manually:"
echo "  gcloud workflows run ecom-pipeline --location=$REGION --project=$PROJECT"
