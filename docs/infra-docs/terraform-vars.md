Terraform variables and onboarding

Required (typical) example:

```bash
export PROJECT_ID=deployment-494918
cd terraform
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state" -backend-config="prefix=deploy"
terraform plan \
  -var="gcp_project_id=${PROJECT_ID}" \
  -var="environment=staging" \
  -var="machine_type=e2-micro" \
  -var="mongodb_machine_type=e2-micro" \
  -var="use_zonal_mig=true" \
  -out=plan.tfplan

# apply once you reviewed the plan:
terraform apply "plan.tfplan"
```

Important variables (root `terraform/variables.tf`):

- `gcp_project_id` (string) — GCP project id. No default for production.
- `gcp_region` (string) — default `us-central1`.
- `gcp_zone` (string) — default `us-central1-a` (used when `use_zonal_mig=true`).
- `environment` (string) — `staging` or `prod`. Default: `staging`.
- `machine_type` (string) — VM type for app instances. Default: `e2-micro`.
- `mongodb_machine_type` (string) — VM type for MongoDB. Default: `e2-micro`.
- `use_zonal_mig` (bool) — `true` for simple zonal MIG (staging); `false` for regional MIG (prod HA).

Module-level important inputs (modules/compute):
- `service_name` — `frontend` or `backend`.
- `container_image` — artifact registry image path.
- `container_port` — container port (3000 frontend, 9001 backend).
- `min_replicas` / `max_replicas` — autoscaling bounds (staging uses small values by default).

Notes:
- Keep `use_zonal_mig=true` for cheap staging (single-zone). Switch to `false` for HA prod after reviewing update policies.
- Terraform backend requires a GCS bucket named `${PROJECT_ID}-terraform-state` — create it with:

```bash
gsutil mb gs://${PROJECT_ID}-terraform-state
```
