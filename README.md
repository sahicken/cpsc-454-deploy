# Deployment Repository — Frontend & Backend to GCP Compute Engine

This repository deploys the frontend (Next.js) and backend (FastAPI + MongoDB) to Google Cloud Platform using Terraform and Cloud Build.

## Architecture

- **Frontend**: Next.js app running on port 3000 (via Managed Instance Group + LB)
- **Backend**: FastAPI app running on port 9001 (via Managed Instance Group + LB)
- **Database**: MongoDB on separate Compute Engine VM
- **CI/CD**: Cloud Build (automatic on git push to `main`)
- **IaC**: Terraform with GCS remote state

## Directory Structure

```
├── frontend/                 # Git submodule: cpsc454_frontend
├── backend/                  # Git submodule: cpsc454backend
├── terraform/
│   ├── main.tf              # Root config (modules + resources)
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── modules/
│       ├── compute/         # Instance template, MIG, LB
│       ├── network/         # VPC, subnet
│       ├── artifacts/       # Artifact Registry
│       └── mongodb/         # MongoDB VM
├── docker/
│   ├── frontend/Dockerfile  # Next.js build + serve
│   └── backend/Dockerfile   # FastAPI with health endpoint
├── deploy/
│   ├── health_wrapper.py    # Health endpoint injector
│   ├── health-check.sh      # Health check helper
│   └── bootstrap.sh         # Initialization script
├── cloudbuild.yaml          # CI/CD pipeline
└── README.md                # This file
```

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- Terraform >= 1.0
- Git
- (Optional) GitHub CLI for setting up Cloud Build triggers

## Setup & Deployment

### 1. Clone and Initialize Submodules

```bash
git clone <this-repo>
cd cpsc-454-deploy
git submodule update --init --recursive
```

### 2. Set GCP Project Variables

Edit `terraform/variables.tf` and set your GCP project ID:

```hcl
variable "gcp_project_id" {
  default = "your-gcp-project-id"
}
```

Or set via environment:

```bash
export TF_VAR_gcp_project_id=your-gcp-project-id
```

### 3. Create GCS Bucket for Terraform State

```bash
export PROJECT_ID=your-gcp-project-id
gsutil mb gs://${PROJECT_ID}-terraform-state
```

### 4. Initialize Terraform

```bash
cd terraform
terraform init -backend-config=bucket=${PROJECT_ID}-terraform-state
```

### 5. Plan & Apply Terraform (Staging)

```bash
terraform plan -var gcp_project_id=$PROJECT_ID -var environment=staging
terraform apply -var gcp_project_id=$PROJECT_ID -var environment=staging
```

Terraform will output the load balancer IPs:

```
frontend_lb_ip = "x.x.x.x"
backend_lb_ip  = "y.y.y.y"
mongodb_internal_ip = "10.0.0.x"
```

### 6. Set Up Cloud Build (Optional - for CI/CD)

In the GCP Console:

1. Go to **Cloud Build** → **Triggers**
2. Connect your GitHub repository
3. Create a trigger pointing to this repo on `main` branch
4. The trigger will run `cloudbuild.yaml` on each push

Alternatively, trigger manually:

```bash
gcloud builds submit --config=cloudbuild.yaml
```

### 7. Verify Deployment

Once instances are running and healthy:

```bash
# Check frontend
curl http://frontend_lb_ip

# Check backend health
curl http://backend_lb_ip:9001/health

# Check backend API docs
curl http://backend_lb_ip:9001/docs
```

## Environment Variables & Secrets

### Backend Environment Variables

The backend container receives:

- `ENVIRONMENT`: `staging` or `prod`
- `MONGODB_HOST`: Internal IP of MongoDB VM (set by Terraform)
- `MONGODB_PORT`: `27017`
- `MONGODB_URI`: Constructed from host/port
- `JWT_SECRET`: From GCP Secret Manager (if configured)
- `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`: From Secret Manager

### Frontend Environment Variables

- `NEXT_PUBLIC_API_BASE_URL`: Backend load balancer URL (set by Terraform)
- `ENVIRONMENT`: `staging` or `prod`

### Setting Secrets

Create secrets in GCP Secret Manager:

```bash
echo -n "your-jwt-secret" | gcloud secrets create jwt-secret --data-file=-
echo -n "admin" | gcloud secrets create mongo-root-username --data-file=-
echo -n "your-password" | gcloud secrets create mongo-root-password --data-file=-
```

Grant VM service account access:

```bash
gcloud secrets add-iam-policy-binding jwt-secret \
  --member=serviceAccount:app-vm-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor
```

## Health Checks & Monitoring

The load balancers perform periodic health checks:

- **Frontend**: HTTP GET `/` on port 3000
- **Backend**: HTTP GET `/health` on port 9001

The `/health` endpoint is automatically injected into the backend via `health_wrapper.py`.

## Updating Upstream Repos

To pull latest changes from upstream:

```bash
git submodule update --remote --merge
git add frontend backend
git commit -m "Update submodules to latest"
git push origin main
```

This automatically triggers Cloud Build, which rebuilds and redeploys the images.

## Database Initialization

MongoDB runs on a separate VM with default credentials (`admin` / `changeme`). 

To create test users:

```bash
# SSH into backend VM and run:
python3 create_user.py alice alicepassword
```

Or modify `deploy/bootstrap.sh` to run `create_user.py` automatically on backend startup.

## Rollback

To rollback to a previous deployment:

```bash
git revert <commit-sha>
git push origin main
```

Cloud Build will rebuild and redeploy with the previous image tag.

Alternatively, manually revert the instance template:

```bash
terraform apply -var gcp_project_id=$PROJECT_ID -var environment=staging
```

## Production Deployment

To deploy to production:

```bash
terraform apply -var gcp_project_id=$PROJECT_ID -var environment=prod
```

(Separate environment files or workspaces recommended for prod/staging separation.)

## Troubleshooting

### Cloud Build Failures

Check logs:

```bash
gcloud builds log <build-id> --stream
```

### VMs Not Becoming Healthy

```bash
# SSH into a VM and check logs:
gcloud compute ssh <instance-name> --zone us-central1-a

# Check container status:
docker ps
docker logs <container-id>
```

### MongoDB Connection Issues

Verify MongoDB VM is running and reachable:

```bash
gcloud compute instances list --filter="name:mongodb-*"
gcloud compute ssh mongodb-staging --zone us-central1-a

# Inside MongoDB VM:
docker ps  # Verify MongoDB container is running
```

## Next Steps

- [ ] Configure custom domain with Cloud DNS
- [ ] Add HTTPS (Cloud Armor + Certificate Manager)
- [ ] Set up monitoring & alerting (Cloud Monitoring)
- [ ] Implement autoscaling based on metrics
- [ ] Add log aggregation (Cloud Logging)
- [ ] Document API endpoints and deployment runbook

## Support & Questions

See individual repos for frontend and backend documentation:

- Frontend: [cpsc454_frontend](https://github.com/khoado1/cpsc454_frontend)
- Backend: [cpsc454backend](https://github.com/khoado1/cpsc454backend)
