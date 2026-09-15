# Production verification

[← Project overview](../README.md) · [Deployment guide](deployment.md)

This configuration targets a small, single-region service. CI validates schemas and uses mocked providers to test safeguards. It cannot establish Google Cloud permissions, quota, network reachability, alert delivery, application availability, or recovery time. Record the results below in your release process after deploying.

## Infrastructure acceptance

1. Review an authenticated Terraform plan for replacements, IAM grants, budget scope and expected resources. After applying, run another plan and investigate unexpected changes.
2. Check GKE nodes have no public IPs, the public control-plane IP endpoint is disabled, and an authorized operator can connect through `--dns-endpoint`. Confirm a user without the required permissions is denied.
3. Pull a uniquely tagged image from the managed registry using a test workload. Check internet dependencies through NAT, including DNS and external API calls.
4. Confirm the root and bootstrap use different remote state prefixes. Confirm another operator can access state and unauthorized identities cannot. Check object versions and test the documented recovery procedure on a disposable state copy.
5. Verify the operations email channel. Generate repeated container restarts in a test namespace, confirm the alert arrives, and resolve it. Confirm the project and recipient on the billing budget; use the billing console to verify notification configuration.
6. Review logs/metrics in Cloud Monitoring. Check billing after representative traffic, including NAT, telemetry and storage. Budget alerts do not stop workloads.

## Application acceptance

The infrastructure does not define your application, domain, database or data retention requirements. Keep the following configuration in the application delivery repository:

- **Availability:** at least two replicas for services needing continuity, readiness/liveness/startup probes, a disruption budget, and topology spread across zones. Test a rolling update and rollback under load; choose requests/limits and autoscaling maxima from measurements.
- **Access:** namespace-specific Roles/RoleBindings for operators; use `kubectl auth can-i` with those identities to verify permitted actions and denied access to other namespaces. Avoid routine cluster-admin. For Google Groups RBAC, validate group membership and propagation.
- **Network policy:** default-deny ingress/egress in application namespaces, then explicitly permit DNS, required dependencies and ingress-controller traffic. Include access needed by Workload Identity; test before moving traffic. GKE's network-policy support does not create these application policies for you.
- **Secrets:** use the dedicated workload identity and resource-specific IAM grants. Never place credentials in images, manifests or Terraform variables. Test that each workload can access its own resources and cannot read another workload's data.
- **Release:** publish immutable tags/digests, retain rollback images, scan application images, configure HTTPS with your domain, and test certificate renewal. Set uptime, error-rate and latency alerts against the actual endpoint and define who responds.
- **Recovery:** define acceptable data loss and restoration time. For stateful services, configure database/PV backups and retention, restore into an isolated environment, and measure recovery. Terraform state backups do not back up application data.

A regional cluster handles some zonal failures; this architecture does not provide regional disaster recovery. If regional outages exceed your service's tolerance, add an independently tested second-region recovery design.

## Incident procedures

**Restart alert:** inspect Pod events and previous logs (`kubectl describe pod` and `kubectl logs --previous`), compare the most recent rollout, check resource exhaustion/dependency failures, then roll back a faulty release. Confirm the alert clears.

**Budget alert:** inspect the project's cost breakdown and recent changes. Check replica growth, NAT egress, telemetry volume, and image retention. Adjust workloads deliberately; do not automatically shut down production based on an alert.

**State recovery:** stop Terraform writers, preserve current state, identify the correct bucket object version, and restore it under operator review. Run a refreshed plan to reconcile actual cloud resources. Never restore an old state version and immediately apply it blindly, or force-unlock while another writer is active.

**Cluster recovery:** recreate infrastructure from reviewed code in an isolated target, deploy the last known good application, restore its data, verify health/access, then switch traffic. Record the elapsed time and update the recovery procedure.
