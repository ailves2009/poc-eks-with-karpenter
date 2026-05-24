# Innovate Inc. — Platform POC

Cloud platform proposal and proof-of-concept for a Python/Flask + React + PostgreSQL SaaS that needs to scale from a few hundred users to millions.

## Layout

- [`architecture/`](architecture/) — **Architecture proposal**: AWS multi-account design, EKS + Karpenter compute, RDS → Aurora migration path, security/compliance posture, observability, cost optimization, and a 6-phase roadmap. Read this first.
- [`terraform/`](terraform/) — **POC implementation**: automated AWS EKS setup with Karpenter (multi-arch, Graviton + Spot), Pod Identity for VPC CNI, IRSA for in-cluster controllers. See [terraform/README.md](terraform/README.md) for the deploy walkthrough, testing methodology, and end-user examples for running workloads on x86 / arm64.

Both directories are independently navigable from this root via the README inside each. License: MIT (see [LICENSE](LICENSE)).
