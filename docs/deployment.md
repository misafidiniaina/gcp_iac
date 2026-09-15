# Deployment and operations

[← Project overview](../README.md)

## Prerequisites

- Terraform `>= 1.9, < 2.0`, Google Cloud CLI, `kubectl`, and `gke-gcloud-auth-plugin`.
- An existing billed Google Cloud project and sufficient regional quota. Use a separate project and state prefix for each environment; resource names are fixed.
- An operator with permission to enable APIs, manage networks, GKE, service accounts/IAM, Artifact Registry, Monitoring and billing budgets. Budget management also requires access to the chosen billing account. Grant these to the deployment identity; the generated viewer identity cannot deploy infrastructure.
- A monitored alert email address, billing account ID, budget amount, and currency matching that account.

Authenticate and bootstrap APIs needed before Terraform can manage infrastructure:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable serviceusage.googleapis.com storage.googleapis.com --project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

## 1. Create shared state storage

The independent [bootstrap configuration](../bootstrap/) creates a private, versioned regional bucket with seven-day soft deletion and deletion protection. Terraform's GCS backend provides state locking. State may contain sensitive information; restrict `state_members` to infrastructure operators.

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
# Edit project_id, globally unique bucket_name, region and state_members.
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -out=bootstrap.tfplan
terraform -chdir=bootstrap apply bootstrap.tfplan
```

Bootstrap initially stores its own state locally. After bucket creation, create `bootstrap/backend.tf` containing `terraform { backend "gcs" {} }`, then migrate its state into the new bucket using a separate prefix:

```bash
terraform -chdir=bootstrap init -migrate-state \
  -backend-config="bucket=YOUR_PROJECT_ID-terraform-state" \
  -backend-config="prefix=bootstrap/state"
```

Preserve a restricted backup during migration and verify the remote state before removing local copies. The bucket must outlive the root infrastructure. Never use the same prefix for bootstrap and root.

## 2. Configure and deploy the infrastructure

```bash
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
# Edit both files with your project, bucket, region, billing, budget and alert recipient.
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform test
terraform plan -out=deployment.tfplan
terraform apply deployment.tfplan
```

Review the saved plan before applying. The example budget of 100 is an example threshold, not a cost estimate. No cloud deployment was performed while preparing this configuration.

| Root input | Default / requirement |
| --- | --- |
| `project_id` | Required; existing Google Cloud project |
| `region` / `zone` | `us-central1` / `us-central1-a`; root GKE is regional |
| `billing_account` | Required billing account ID |
| `monthly_budget` | Required positive whole number |
| `budget_currency` | `USD`; must match billing account |
| `alert_email` | Required monitored inbox |
| `deletion_protection` | `true`; guards cluster deletion |
| `cluster_operator_members` | Empty; add explicit IAM users/groups/service accounts |
| `security_group` | Optional `gke-security-groups@your-domain` for Google Groups RBAC |
| `workload_identities` | Empty map; configure per-application identities as needed |

Outputs include cluster names, VPC name, viewer/node identities, managed APIs, the Docker repository URL, and workload identity emails.

## 3. Connect and assign application access

The public IP endpoint is disabled. The DNS endpoint accepts authenticated external clients, so operators do not need a VPN or bastion. This is IAM-controlled access, not a network-isolated DNS endpoint. Use the configured region:

```bash
gcloud container clusters get-credentials kubernetescluster \
  --dns-endpoint --region us-central1 --project YOUR_PROJECT_ID
```

`cluster_operator_members` receive Cluster Viewer for cluster discovery and connection. A cluster administrator must grant namespace-level Kubernetes RBAC for application operations. If using Google Groups, provision the required parent group and membership before setting `security_group`. See [production verification](production.md) for access checks.

The dedicated node identity has `roles/container.defaultNodeServiceAccount` plus reader access to the managed image repository. It has no application data permissions. Autopilot enables Workload Identity Federation for GKE. To create an application identity:

```hcl
workload_identities = {
  orders = {
    account_id                 = "orders-app"
    namespace                  = "orders"
    kubernetes_service_account = "api"
  }
}
```

Create the corresponding Kubernetes service account in your application manifests, annotate it with `iam.gke.io/gcp-service-account: orders-app@YOUR_PROJECT_ID.iam.gserviceaccount.com`, and set the Pod's `serviceAccountName: api`. Grant that Google identity only the permissions needed on specific secrets, buckets, or other resources. The module creates the exact impersonation binding; it intentionally grants no application data roles. GitHub Actions performs offline validation and needs no federation trust or deployment credentials.

## Operations

- **Networking:** node subnet `10.0.0.0/24`, Pods `10.4.0.0/14`, Services `10.8.0.0/20`. Review these against connected networks before deployment. The network module exposes these CIDRs for reuse; the root uses its defaults. NAT permits outbound internet access for the managed subnet, including its secondary ranges. It is not an outbound domain allowlist. VPC flow logs sample 10%; NAT logs errors only.
- **Upgrades:** Regular release channel; daily maintenance window 00:00–08:00 UTC (56 hours weekly). Adjust the module to your service window before deployment. Applications must tolerate node maintenance.
- **Images:** use unique immutable tags or image digests. Grant publisher access only to the release identity on this repository. No automatic image deletion policy is configured, preserving rollback images; review retention and storage costs.
- **Alerts:** more than three container restarts in a five-minute interval triggers an email. Budget thresholds cover 50%, 80%, and 100% actual spend and 100% forecast spend for this project only. Verify recipient delivery after deployment. No traffic-based uptime/latency alert is possible until an application endpoint exists.
- **Costs:** one region, no standalone VM or bastion. NAT, GKE workloads, registry/state storage, logs and metrics still cost money. Budget notifications are delayed and do not limit spending. Set application resource requests, replica limits and namespace quotas.

## Existing deployments: migration required

Back up state and review an authenticated plan before any apply. To migrate existing root local state, use `terraform init -migrate-state -backend-config=backend.hcl`; do not initialize an empty remote state and apply over existing resources.

Private nodes, the dedicated node account and explicit secondary ranges can require cluster replacement. Deletion protection will block replacement until explicitly disabled and applied. For workloads already serving users, build a new cluster in a separate project, redeploy and restore data, test it, switch traffic, then retire the old cluster. A direct replacement can cause downtime.

New required inputs are billing account, monthly budget and alert email. New resources include NAT, registry, node identity, monitoring and budget. DNS access requires `--dns-endpoint`. Existing consumers of the older viewer account remain read-only.

For upgrades from the original repository version: custom subnet mode and IAP-only SSH replaced broader network access; service account keys and admin grants were removed. Migrate old key consumers to keyless authentication and restrict historical state backups that may contain those keys.

## Cleanup

For intentional cluster teardown, set `deletion_protection = false`, then review and apply that change before planning destruction. The registry has `prevent_destroy` and the state bucket is protected independently. A full destroy will be blocked while these guards remain; decide how to preserve images and state before explicitly changing their lifecycle protections. Do not delete backups as part of routine teardown. APIs remain enabled after resource destruction; workload-created storage or load balancers may need separate cleanup.

## References

- [GKE Autopilot creation and node identity](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster)
- [GKE network isolation and DNS access](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/latest/network-isolation)
- [GCS backend, locking and versioning](https://developer.hashicorp.com/terraform/language/backend/gcs)
- [GKE Workload Identity Federation](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
