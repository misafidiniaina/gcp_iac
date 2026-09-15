# Terraform Beginner's Guide

This guide explains this repository from the ground up. It assumes that you are new to Terraform and gives you a safe path from an empty Google Cloud project to a planned infrastructure deployment.

## 1. What this project does

Terraform is an Infrastructure as Code tool. Instead of creating cloud resources manually in the Google Cloud Console, you describe the desired infrastructure in `.tf` files. Terraform then compares that description with the real project and proposes the changes required to make them match.

This repository creates a small, production-oriented Google Cloud foundation:

- a custom VPC network, subnet, firewall rule and Cloud NAT;
- one regional GKE Autopilot cluster with private nodes;
- dedicated Google service accounts for the cluster and operators;
- a Docker Artifact Registry repository with immutable image tags;
- monitoring for repeated container restarts;
- a project-scoped billing budget with email notifications;
- optional keyless identities for Kubernetes workloads;
- a protected Google Cloud Storage bucket for Terraform state.

The infrastructure layer does **not** deploy an application, database, domain, ingress controller or application secrets. Those belong in an application delivery project or in Kubernetes manifests managed separately.

## 2. The basic Terraform vocabulary

| Term     | Meaning in this project                                                                         |
| -------- | ----------------------------------------------------------------------------------------------- |
| Provider | The plugin Terraform uses to talk to Google Cloud. It is declared in `versions.tf`.             |
| Resource | One cloud object managed by Terraform, such as a VPC, bucket or GKE cluster.                    |
| Module   | A reusable folder containing related Terraform resources.                                       |
| Variable | An input value, such as the project ID or region.                                               |
| Output   | A value Terraform prints after a plan or apply, such as the cluster name.                       |
| State    | Terraform's record of the resources it manages. This project stores it in a private GCS bucket. |
| Plan     | A preview of the changes Terraform would make.                                                  |
| Apply    | The command that performs the approved changes.                                                 |
| Backend  | The place where Terraform state is stored and locked. This project uses the GCS backend.        |

The normal workflow is:

```text
write configuration -> terraform plan -> review -> terraform apply -> verify
```

`plan` does not change Google Cloud. `apply` does.

## 3. Repository map

### Root configuration

- `main.tf` composes the modules and defines the dependency order.
- `variables.tf` defines configurable inputs and validates their format.
- `outputs.tf` exposes useful values after deployment.
- `versions.tf` pins Terraform and the Google provider versions and enables the GCS backend.
- `terraform.tfvars.example` is a template for your environment values.
- `backend.hcl.example` is a template for the remote state bucket and prefix.
- `.terraform.lock.hcl` records the exact provider checksums selected by Terraform. Keep it committed.

### Modules

| Folder                      | Responsibility                                                                            |
| --------------------------- | ----------------------------------------------------------------------------------------- |
| `modules/necessary_api`     | Enables Google Cloud APIs required by the other modules.                                  |
| `modules/network`           | Creates the VPC, subnet, Pod and Service ranges, firewall rule, router and NAT.           |
| `modules/service_account`   | Creates service accounts and attaches project IAM roles.                                  |
| `modules/kubernetes`        | Creates the regional private GKE Autopilot cluster.                                       |
| `modules/artifact_registry` | Creates the regional Docker repository and grants nodes read access.                      |
| `modules/operations`        | Creates restart monitoring and billing budget notifications.                              |
| `modules/workload_identity` | Connects one Kubernetes service account to one Google service account without a key file. |
| `modules/virtual_machine`   | Optional standalone VM module; it is not called by the root configuration.                |

### Bootstrap configuration

The `bootstrap/` folder is intentionally separate. It creates the GCS bucket that will hold Terraform state. The bucket must exist before the root configuration can use it as a backend.

### Tests and CI

- `tests/production.tftest.hcl` checks important root and module safeguards using a mocked provider.
- `bootstrap/tests/state.tftest.hcl` checks that state storage is private, versioned and protected.
- `.github/workflows/terraform.yml` runs formatting, validation and tests on pushes and pull requests.

Tests do not create real Google Cloud resources and do not replace a live deployment verification.

## 4. Prerequisites

Install or make available:

- Terraform `>= 1.9.0, < 2.0.0`;
- the Google Cloud CLI (`gcloud`);
- `kubectl`;
- `gke-gcloud-auth-plugin` for GKE authentication;
- an existing Google Cloud project with billing enabled;
- an operator identity allowed to enable APIs, manage IAM, networking, GKE, Artifact Registry, Monitoring and billing budgets.

Authenticate locally:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable serviceusage.googleapis.com storage.googleapis.com --project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with an existing project ID. Terraform uses Application Default Credentials when it talks to Google Cloud.

## 5. First deployment: create remote state

Terraform state is important because it maps configuration to real resources. This project protects that state with bucket versioning, public access prevention, soft deletion and `prevent_destroy`.

The bootstrap state is initially local. That is acceptable for this one-time step, but the root infrastructure must use the remote bucket.

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
```

Edit `bootstrap/terraform.tfvars`:

```hcl
project_id    = "YOUR_PROJECT_ID"
bucket_name   = "YOUR_GLOBALLY_UNIQUE_BUCKET_NAME"
region        = "us-central1"
state_members = ["user:your-email@example.com"]
```

The bucket name is globally unique. `state_members` must contain explicit users, groups or service accounts. Never use `allUsers` or `allAuthenticatedUsers`.

Create the bucket:

```bash
terraform -chdir=bootstrap init
terraform -chdir=bootstrap fmt
terraform -chdir=bootstrap validate
terraform -chdir=bootstrap plan -out=bootstrap.tfplan
terraform -chdir=bootstrap apply bootstrap.tfplan
```

Review the plan before applying it. Keep the bucket alive for as long as the root state is needed.

## 6. Configure the root infrastructure

Create the two local configuration files:

```bash
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
```

Set the state bucket and a unique prefix in `backend.hcl`:

```hcl
bucket = "YOUR_GLOBALLY_UNIQUE_BUCKET_NAME"
prefix = "production/infrastructure"
```

The prefix is a folder-like namespace inside the bucket. Use a different prefix for every environment. Never use the root prefix for the bootstrap state.

Then edit `terraform.tfvars`:

```hcl
project_id          = "YOUR_PROJECT_ID"
region              = "us-central1"
zone                = "us-central1-a"
deletion_protection = true

billing_account = "012345-ABCDEF-012345"
monthly_budget  = 100
budget_currency = "USD"
alert_email     = "operations@example.com"

cluster_operator_members = ["user:your-email@example.com"]
```

Important inputs:

- `project_id` is the Google Cloud project where resources are created.
- `region` is where the regional GKE cluster and registry are created.
- `billing_account` must be a real billing account ID with access to manage budgets.
- `monthly_budget` creates notifications; it is **not** a spending limit.
- `alert_email` receives restart and budget notifications.
- `cluster_operator_members` controls who can discover and connect to the cluster. Kubernetes permissions are granted separately with RBAC.
- `deletion_protection = true` prevents accidental GKE deletion or replacement.

Initialize the root configuration with the remote backend:

```bash
terraform init -backend-config=backend.hcl
```

Terraform may ask whether it should migrate existing state. Read that prompt carefully. For an existing deployment, back up the current state and use `-migrate-state`; do not point an empty remote state at resources that are already managed elsewhere.

## 7. Inspect, test and deploy

Run the local checks before creating anything:

```bash
terraform fmt -check -recursive
terraform validate
terraform test
```

Create a saved plan:

```bash
terraform plan -out=deployment.tfplan
```

The plan should be treated like a change request. Check the project, region, IAM roles, network ranges, cluster settings, budget and any planned replacements. Apply only after reviewing it:

```bash
terraform apply deployment.tfplan
```

Terraform prints outputs such as the cluster name, network name, Artifact Registry URL and service account emails. To print them again later:

```bash
terraform output
```

After applying, confirm that no unexpected changes remain:

```bash
terraform plan
```

An empty plan means the deployed infrastructure matches the configuration at that moment.

## 8. Connect to the cluster

The nodes and IP control-plane endpoint are private. Authorized operators connect through GKE's IAM-authenticated DNS endpoint:

```bash
gcloud container clusters get-credentials kubernetescluster \
  --dns-endpoint \
  --region us-central1 \
  --project YOUR_PROJECT_ID
kubectl get namespaces
```

Being able to discover the cluster does not automatically grant administrator access inside every Kubernetes namespace. A Kubernetes administrator must create the appropriate `Role` and `RoleBinding` objects. Avoid routine `cluster-admin` access.

## 9. Workload identity in plain language

Applications sometimes need to read a bucket, publish messages or call another Google Cloud service. Do not put a Google service-account key JSON file in an image, repository or Terraform variable.

Instead, define an identity:

```hcl
workload_identities = {
  orders = {
    account_id                 = "orders-app"
    namespace                  = "orders"
    kubernetes_service_account = "api"
  }
}
```

The module creates the exact trust relationship for the `orders/api` Kubernetes service account. Your Kubernetes manifest must then:

1. create the `orders` namespace;
2. create the `api` Kubernetes service account;
3. annotate it with `iam.gke.io/gcp-service-account`;
4. use `serviceAccountName: api` in the Pod;
5. grant the Google service account only the resource-level roles the application needs.

The module creates the identity binding, but it intentionally does not grant application data permissions. That least-privilege decision belongs to the application owner.

## 10. Safety rules and costs

- State can contain sensitive values. Restrict bucket access and keep separate prefixes for environments.
- Terraform plans can replace resources. Treat replacement of a live GKE cluster as a possible outage.
- Disable `deletion_protection` only when intentionally preparing a cluster teardown, then apply that change before destroying.
- The Artifact Registry repository and state bucket have deletion protection. A normal `terraform destroy` will not remove them.
- Budget alerts are delayed notifications, not hard spending caps.
- GKE, Cloud NAT, Artifact Registry, storage, logs and monitoring can all generate charges.
- Review Pod resource requests, replica counts, image retention and log volume before production traffic.

## 11. Useful commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Check configuration without contacting a live backend
terraform init -backend=false
terraform validate

# See which resources Terraform manages
terraform state list

# Show one output value
terraform output cluster_names

# Inspect a saved plan in human-readable form
terraform show deployment.tfplan
```

Do not edit files inside `.terraform/`; Terraform creates that directory locally. Do not edit `.terraform.lock.hcl` by hand unless you understand provider lock-file management.

## 12. Where to continue

- Read [deployment.md](deployment.md) for the complete deployment and migration procedure.
- Read [production.md](production.md) for infrastructure acceptance, application readiness and incident checks.
- Read the module `variables.tf` and `outputs.tf` files when you need the exact contract of a module.
- Start with a non-production Google Cloud project and a dedicated state prefix before managing a live environment.
