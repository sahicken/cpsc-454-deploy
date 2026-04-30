CI/CD for staging (Cloud Build)

Overview
- Use Cloud Build triggers on merges to `staging` to build images, push to Artifact Registry, and run Terraform to deploy staging.

High-level steps the trigger performs:
1. Build frontend and backend container images
2. Push images to Artifact Registry
3. Run `terraform plan` (store plan as artifact)
4. Optionally run `terraform apply` for automatic deploy to staging (recommended only for `staging` branch)

Permissions
- Cloud Build service account needs least-privilege roles for this pipeline:
  - `roles/artifactregistry.writer` (push images)
  - `roles/storage.admin` (terraform state GCS bucket)
  - `roles/compute.admin` (create VMs, load balancers) — consider limiting to staging project
  - `roles/iam.serviceAccountUser` (if using service accounts)
  - `roles/secretmanager.secretAccessor` (read secrets)

Trigger configuration (recommended):
- Repo: GitHub repo -> connect to Cloud Build
- Event: Push to branch `staging`
- Substitutions: set `PROJECT_ID`, `ENVIRONMENT=staging`

Local test (fast)

```bash
# build images locally and push to artifact registry
docker build -t REGION-docker.pkg.dev/${PROJECT_ID}/app-images/frontend:local .
docker push REGION-docker.pkg.dev/${PROJECT_ID}/app-images/frontend:local

# run terraform plan locally (as in terraform-vars.md)
```

Notes
- If you want PR checks before allowing apply, configure the trigger to only run `plan` on PRs and require manual approval for `apply` (or run `apply` only on merged `staging`).
- For GitHub-native workflows, you can replicate similar steps in GitHub Actions; Cloud Build integrates tightly with GCP permissions for applying terraform.
