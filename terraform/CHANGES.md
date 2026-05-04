# Changes

Reverse-chronological log of structural / behavioural changes. Bug fixes that
don't change behaviour aren't listed unless they shaped the design.

## 0.1.1 — Submission prep

### Removed

- **`modules/acm`** — kept until now as "not deployed in POC", but unused
  in any unit. Removed to reduce surface area. ACM / HTTPS path remains
  documented in README → TODO for whenever a real domain is delegated to
  this account.

### Changed

- Repo restructured: `terraform/` is now a subdirectory of the submission
  root (`poc-task-for-opsfleet/{terraform,architecture}/`). Internal layout
  of `terraform/` unchanged — all unit and module paths are the same.

## 0.1.0 — POC complete

### Added

- **Three-tier layout** under `non-prod/poc/us-east-1/`: `bootstrap/`, `persistent/`, `workload/`.
  Tiers separated by lifecycle, not by feature, so `terragrunt run --all destroy
  --working-dir workload` blows away the cluster without touching the cicd-role
  or state bucket.
- **`bootstrap/iam-state`** — `cicd-deployment-role` + scoped policies
  (s3-state, iam-management with `iam:PermissionsBoundary` condition,
  infra, runtime), `cicd-boundary` policy, `AWSServiceRoleForEC2Spot`.
- **`bootstrap/s3-state`** — KMS-encrypted tfstate bucket (`use_lockfile = true`,
  no DynamoDB).
- **`workload/vpc`** — wrapper over `terraform-aws-modules/vpc/aws`. Single NAT,
  EKS / Karpenter / ALB-controller subnet discovery tags.
- **`workload/eks`** — wrapper over `terraform-aws-modules/eks/aws`. EKS 1.32,
  public + private endpoint, Access Entries (cluster creator → ClusterAdmin),
  KMS envelope encryption, addons (CoreDNS, kube-proxy, VPC CNI, Pod Identity
  Agent). Bootstrap NG: 2× t4g.medium across AZs.
- **`workload/karpenter`** — wrapper over
  `terraform-aws-modules/eks/aws//modules/karpenter` (IRSA + node IAM role +
  SQS interruption queue + EventBridge) + Helm chart **vendored locally**
  at `modules/karpenter/charts/karpenter-1.2.0.tgz` + default
  `EC2NodeClass` and `NodePool` (multi-arch, spot+on-demand, c/m/r families,
  consolidate when empty/underutilized).
- **`workload/aws-lb-controller`** — IRSA via
  `terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks`
  + Helm release. Pinned to bootstrap NG, 2 replicas spread across AZs.
- **`workload/metrics-server`** — generic `helm-release` wrapper. Required for
  `kubectl top` and HPA. Pinned to bootstrap NG.
- **`workload/nginx`** — bitnami/nginx chart through `helm-release`, with HPA
  (2..10 replicas, 50% CPU target), `karpenter.sh/capacity-type=spot`
  nodeSelector, AWS LB Controller Ingress (HTTP only), `keepwarm` Deployment
  via chart's `extraDeploy` for non-zero baseline metrics.
- **`persistent/bastion`** — t4g.small in default VPC, EIP, IAM with
  `AmazonSSMManagedInstanceCore`, OpenVPN community via cloud-init.
  `create_dns_record = false` because no Route53 zone in this account.
- **`modules/helm-release`** — generic wrapper used by `metrics-server` and
  `nginx`. Configures helm provider with `aws eks get-token` exec auth.
- **Testing methodology** in README: health smoke, end-to-end ALB,
  Karpenter provisioning, HPA + Karpenter cascade.

### Changed / decided

- **Karpenter chart vendoring** instead of pulling from
  `oci://public.ecr.aws/karpenter` at every `terraform plan`. The helm
  provider v3 has a bug where the OCI auth token (TTL 12h) caches in state
  and fails with `403 expired` on subsequent applies.
- **HTTP-only Ingress** on nginx. ACM DNS-validation requires the cert's
  zone to live in this AWS account, which the POC's candidate domains did
  not (one was corp-managed, one was in a different account). Cross-account
  DNS automation is TODO.
- **Bitnami chart override**: `image.repository = bitnamilegacy/nginx` plus
  `global.security.allowInsecureImages = true`. Bitnami moved free-tier
  images in mid-2025.
- **Bootstrap node group sizing** done by manual
  `aws eks update-nodegroup-config` because
  `terraform-aws-modules/eks/aws//modules/eks-managed-node-group` ignores
  `desired_size` changes by design (lets HPA / autoscalers manage runtime
  scaling without diff).

### Known issues / TODO

See README.md → "TODO" section.
