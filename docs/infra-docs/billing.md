Costs, shutdowns, and student-friendly guidance

Quick estimate (staging minimal configuration):
- 2 app VMs (frontend + backend) using `e2-micro`: roughly $4–8 / VM / month (on-demand, varies by region) — ~ $8–16
- 1 MongoDB VM `e2-micro`: ~ $4–8 / month
- External HTTP(S) Load Balancer: small fixed cost + per-GB egress; expect ~$5–20 / month for light traffic
- Misc (IP, persistent disks, artifact registry storage): small, $1–10

Estimated monthly total (very approximate): $20–50 for light development use.

Verify exact charges:
- Console: Billing → Reports (recommended)
- Use Billing Export to BigQuery for detailed usage

Quick shutdown options (safe -> destructive):

1) Pause resources (cheap, reversible) — scale down instance groups and stop VMs

Manual (fast):
```bash
# scale MIGs to 0 using gcloud (zonal MIG example)
gcloud compute instance-groups managed resize frontend-mig --zone=us-central1-a --size=0 --project=${PROJECT_ID}
gcloud compute instance-groups managed resize backend-mig --zone=us-central1-a --size=0 --project=${PROJECT_ID}

# stop standalone VM (mongodb)
gcloud compute instances stop mongodb-staging --zone=us-central1-a --project=${PROJECT_ID}
```

2) Destroy staging infra (safe to delete, irreversible unless you recreate):

```bash
cd terraform
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state" -backend-config="prefix=deploy"
terraform destroy -var="gcp_project_id=${PROJECT_ID}" -auto-approve
```

3) Disable billing on the GCP project (last resort) — Console → Billing → Disable billing for project.

Shutdown helper script:
- See `scripts/shutdown-staging.sh` (runs `terraform destroy`) — use only when you want to tear down everything.

Budget alerts:
- Create a budget in the Billing console and add email and Pub/Sub notification channels.

If you're low on funds, prefer option (1) to stop running VMs and keep disk state.
