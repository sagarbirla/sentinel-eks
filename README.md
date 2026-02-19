# Rapyd Sentinel Infrastructure - Multi-VPC EKS Setup

## Overview

This project implements a multi-VPC Kubernetes architecture for Rapyd Sentinel, demonstrating secure cross-cluster communication, infrastructure as code best practices, and automated CI/CD deployment.

### Key Components

1. **VPC Gateway**: Hosts internet-facing proxy services
   - CIDR: 10.0.0.0/16
   - 2 Private Subnets (AZ1, AZ2)
   - 2 Public Subnets (for NAT Gateways and Load Balancers)

2. **VPC Backend**: Hosts internal processing services
   - CIDR: 10.1.0.0/16
   - 2 Private Subnets (AZ1, AZ2)
   - NAT Gateway for outbound connectivity
   - No public access

3. **VPC Peering**: Secure private communication between VPCs
   - Bidirectional routing
   - Security group controls

4. **EKS Clusters**:
   - Gateway cluster: t3.medium nodes (2-4 instances)
   - Backend cluster: t3.medium nodes (2-4 instances)

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository
- Terraform >= 1.5.0
- kubectl >= 1.27
- AWS CLI v2

## Quick Start

### 1. Fork and Clone

### 2. Configure AWS Access

Add the following secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 3. Create backend bucket

```cd bootstrap
terraform init
terraform apply -var="backend_bucket_name=<bucket-name>"

# Update backend.tf file with the bucket name
```

### 4. Deploy via GitHub Actions

```bash
# PR creation will run validation and tf plan
# PR merge will execute tf apply and kubectl apply -f kubernetes/*
git add .
git commit -m "Initial deployment"
git push origin HEAD:branchname
```

The CI/CD pipeline will:
1. Validate Terraform and k8s manifests
2. Plan infrastructure changes and comment on the PR for easy review
3. Apply Terraform (on main branch)
4. Deploy Kubernetes workloads
5. Validate gateway/backend connectivity

## Architecture Details

### Networking Configuration

#### Kubernetes NetworkPolicy

Backend cluster implements NetworkPolicy to restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-service-policy
spec:
  podSelector:
    matchLabels:
      app: backend-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/16  # Only from Gateway VPC
    ports:
    - protocol: TCP
      port: 8080
```

### Cross-Cluster Communication

The Gateway proxy forwards traffic to the Backend service:

1. **Service Discovery**: Backend service is running behind an internal NLB
2. **Network Path**: 
   - Request → ALB (public) → Gateway Proxy Pod
   - Gateway Proxy → VPC Peering → Internal NLB → Backend Service Pod
3. **Security**: 
   - Traffic flows over private IPs only
   - Security Groups enforce source/destination restrictions
   - No public exposure of backend services

#### Proxy Configuration

The NGINX proxy in the gateway cluster uses:

```nginx
upstream backend {
    server <internal-nlb-fqdn>:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

The backend service endpoint is rendered during the CI/CD pipeline

## CI/CD Pipeline

### GitHub Actions Workflow

Located in `.github/workflows/deploy.yml`:

**Stages:**

1. **Validate**
   - Terraform format check
   - Terraform validate
   - TFLint for best practices
   - Kubernetes manifest validation with yamllint and kubeconform

2. **Plan**
   - Terraform plan with detailed output
   - Plan output is commented on the PR for review

3. **Apply** (main branch only)
   - Terraform apply
   - Infrastructure provisioning

4. **Deploy**
   - Update kubeconfig for both clusters
   - Deploy backend service
   - Deploy gateway proxy
   - Dry-run validation before apply


### Least Privilege Principle

- EKS cluster roles: Minimal permissions for cluster operations
- Node roles: EC2, ECR, CloudWatch permissions only
- Service accounts: Scoped to specific AWS resources needed
- No wildcard permissions in production roles

## Design Trade-offs

### Decisions Made

1. **VPC Peering vs Transit Gateway**
   - **Chosen**: VPC Peering
   - **Rationale**: Simpler for two VPCs, lower cost, sufficient for POC
   - **Production**: Consider Transit Gateway for 3+ VPCs or hub-spoke architecture

2. **NAT Gateway Strategy**
   - **Chosen**: One NAT Gateway per VPC (single AZ)
   - **Rationale**: Cost optimization for POC
   - **Production**: NAT Gateway per AZ for high availability

3. **EKS Node Instance Type**
   - **Chosen**: t3.medium (2 vCPU, 4 GB RAM)
   - **Rationale**: Adequate for demo workloads, cost-effective
   - **Production**: Right-size based on workload (use t3.large or compute-optimized)

4. **Service Discovery**
   - **Chosen**: Hardcoded NLB FQDN for POC
   - **Rationale**: Simplicity, no DNS dependencies
   - **Production**: Use Route53 private hosted zones or service mesh

5. **Load Balancer Type**
   - **Chosen**: Load Balancer
   - **Rationale**: Simple integration with EKS
   - **Production**: Use ALB with WAF integration

Due to the challenge timeline, the following were simplified:
- Single NAT Gateway per VPC (not HA)
- Basic NGINX proxy (no advanced routing)
- Hardcoded backend endpoint (no dynamic discovery)
- Basic NetworkPolicy examples

## What's Next

### Phase 1B

1. Implement logic for terragrunt/workspace to be able to manage multiple environments
2. Separate repo for terraform modules
3. Handle the use case to delete the kubernetes objects
4. Use of OIDC for github workflows
5. Enable and version control EKS critical Add-ons like kube-proxy, CoreDNS, pod identity agent, vpc-cni etc.

### Phase 2: Production Readiness

1. **Ingress Gateway**
   - to manage the routing between services and internet

2. **Observability Stack**
   - Prometheus + Grafana
   - ELK or CloudWatch Logs Insights

3. **GitOps** (ArgoCD/Flux)
   - Declarative application deployment
   - Automated sync from Git
   - Rollback capabilities

4. **Secret Management**
   - External Secrets Operator with AWS Secrets Manager
   - Vault for dynamic secrets
   - Sealed Secrets for Git storage
