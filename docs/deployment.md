# Deployment and operations

[← Project overview](../README.md)

## Engineering decisions

- **Explicit dependencies:** networking and IAM wait for API enablement; GKE depends on the network outputs.
- **Custom-mode networking:** only the declared subnet is created. SSH ingress is limited to IAP's forwarding range and VMs tagged `vm-server`.
- **Keyless identity:** no service account private keys are generated. The automation account receives `roles/container.viewer`; impersonation or federation trust must be configured separately.
- **Lifecycle safeguards:** GKE deletion protection defaults to enabled. APIs stay enabled after Terraform destroy to avoid disrupting other project resources.
- **Reproducibility:** the Google provider stays on the 6.12 patch line, with checksums tracked in the lock file. CI runs formatting and schema validation without cloud credentials.

## Quick start

### Prerequisites

- Terraform 1.9 or newer, below 2.0 (CI uses 1.9.8).
- Google Cloud CLI and an existing project with billing enabled and sufficient GKE quota.
- A deployment identity permitted to enable services, manage networks and GKE, create service accounts, and manage project IAM. The created viewer identity is not the deployment identity.
- For cluster access: `kubectl` and the `gke-gcloud-auth-plugin`.

Authenticate and bootstrap Service Usage if it is not already enabled:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable serviceusage.googleapis.com --project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

Prepare your local configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID and region.
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=deployment.tfplan
terraform apply deployment.tfplan
```

Review the plan before applying. Deployment creates billable cloud resources; CI never applies infrastructure.

Connect to the cluster (use the same region and project as your configuration):

```bash
gcloud container clusters get-credentials kubernetescluster \
  --region us-central1 \
  --project YOUR_PROJECT_ID
kubectl get namespaces
```

### Inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `project_id` | Required | Existing Google Cloud project |
| `region` | `us-central1` | Subnet and regional GKE location |
| `zone` | `us-central1-a` | Provider default zone; no VM created by root |
| `deletion_protection` | `true` | Prevent accidental cluster deletion |

### Outputs

| Output | Meaning |
| --- | --- |
| `cluster_names` | GKE cluster names |
| `network_name` | VPC name |
| `service_account_email` | Keyless automation identity |
| `activate_api` | Managed API names; retained for compatibility |

## Repository layout

```text
.github/workflows/terraform.yml  # Formatting and validation
main.tf                         # Provider and module composition
versions.tf                     # Terraform and provider constraints
variables.tf / outputs.tf       # Root interface
terraform.tfvars.example         # Safe starting configuration
modules/
  necessary_api/                # Project service enablement
  network/                      # VPC, subnet, IAP SSH firewall
  kubernetes/                   # Regional Autopilot clusters
  service_account/              # Automation identity and IAM grants
  virtual_machine/              # Optional standalone Ubuntu VM
```

## Operations and limitations

**State:** the default backend is local. State and saved plans can contain sensitive information and are ignored by Git. Before team use, configure a GCS backend with a separately provisioned bucket, restricted access, versioning, and an agreed recovery process. Commit the provider lock file; never commit credentials or state.

**Access:** the firewall rule alone does not grant SSH access. Optional VM users also need IAP tunnel access and OS Login permissions. Use `gcloud compute ssh vm-server --tunnel-through-iap --zone YOUR_ZONE --project YOUR_PROJECT_ID`. No application ports are opened by this module.

**Production scope:** this is a portfolio foundation, not a complete production platform. It does not configure private GKE endpoints, explicit Pod/Service secondary ranges, a custom node service account, workload deployment, Kubernetes RBAC, federation trust, budgets, or alerting. Review these with your organization's policies before deployment. Resource names are fixed, so use separate projects for isolated environments or extend naming before deploying multiple copies into one project.

**Validation:** CI checks syntax and provider schemas for the root and optional VM module. It does not prove IAM permissions, quota availability, or successful deployment. Run a real plan in your target project before applying.

### Existing deployments

Review the plan carefully when upgrading from the initial version:

- The VPC changes from automatic to custom subnet mode; review existing auto-created subnets and workloads.
- The existing firewall rule is narrowed to IAP SSH, removing direct internet access to SSH and application ports.
- The managed service account key is removed and broad admin grants are replaced with Container Viewer. Migrate consumers to keyless authentication first. Historical state backups may still contain the old private key and require controlled retention.
- GKE deletion protection is enabled; the old `kubernetes_sa_key` output is removed.
- The optional VM uses an Ubuntu image family and no longer uploads a local SSH key. If you use it independently, review image-related replacement and OS Login access before applying.

### Cleanup

First set `deletion_protection = false` in `terraform.tfvars`, then apply that change before destroying:

```bash
terraform plan -out=teardown-prep.tfplan
terraform apply teardown-prep.tfplan
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Review both plans. Project APIs intentionally remain enabled. Check for workload-created resources and storage that may require separate cleanup.

## References

- [Google provider: custom VPC networks](https://registry.terraform.io/providers/hashicorp/google/6.12.0/docs/resources/compute_network)
- [Google provider: project services](https://registry.terraform.io/providers/hashicorp/google/6.12.0/docs/resources/google_project_service)
- [Google Cloud: IAP TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding)
- [Terraform: GCS backend](https://developer.hashicorp.com/terraform/language/backend/gcs)
