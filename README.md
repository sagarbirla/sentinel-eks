# Rapyd Sentinel Infrastructure - Multi-VPC EKS Setup

## Overview

This project implements a production-ready, multi-VPC Kubernetes architecture for Rapyd Sentinel, demonstrating secure cross-cluster communication, infrastructure as code best practices, and automated CI/CD deployment.

### Key Components

1. **VPC Gateway**: Hosts internet-facing proxy services
   - CIDR: 10.0.0.0/16
   - 2 Private Subnets (AZ1, AZ2)
   - 2 Public Subnets (for NAT Gateways and Load Balancers)
   - NAT Gateways for outbound connectivity

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
   - IRSA (IAM Roles for Service Accounts) enabled
   - Private endpoint access

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository
- Terraform >= 1.5.0
- kubectl >= 1.27
- AWS CLI v2

## Quick Start

### 1. Fork and Clone

### 2. Configure AWS OIDC (Recommended)

Set up GitHub OIDC provider in AWS:

```bash
# This is done once per AWS account
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

- `AWS_ACCOUNT_ID`: Your AWS account ID
- `AWS_REGION`: Target AWS region (e.g., us-east-1)

For OIDC (recommended):
- Create IAM role with trust policy for GitHub Actions

For static credentials (fallback):
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 4. Deploy via GitHub Actions

```bash
# Push to main branch to trigger deployment
git add .
git commit -m "Initial deployment"
git push origin main
```

The CI/CD pipeline will:
1. Validate Terraform configuration
2. Plan infrastructure changes
3. Apply Terraform (on main branch)
4. Deploy Kubernetes workloads
5. Validate connectivity

### 5. Manual Deployment (Development Only)

```bash
# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Configure kubectl
aws eks update-kubeconfig --name eks-gateway --region eu-west-1
aws eks update-kubeconfig --name eks-backend --region eu-west-1 --alias eks-backend

# Deploy applications
kubectl apply -f kubernetes/backend/
kubectl --context eks-backend apply -f kubernetes/backend/

kubectl apply -f kubernetes/gateway/
```

## Architecture Details

### Networking Configuration

#### VPC Gateway (10.0.0.0/16)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24
  - Host NAT Gateways and Load Balancers
  - Internet Gateway attached
  
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24
  - EKS worker nodes
  - Route to internet via NAT Gateway
  - Route to Backend VPC via peering connection

#### VPC Backend (10.1.0.0/16)
- **Private Subnets**: 10.1.10.0/24, 10.1.11.0/24
  - EKS worker nodes
  - Route to internet via NAT Gateway
  - Route to Gateway VPC via peering connection
  - No public subnets (fully private)

#### VPC Peering
- Bidirectional routing between VPCs
- Routes added to all private subnet route tables
- DNS resolution enabled across peering connection

### Security Model

#### Security Groups

1. **Gateway EKS Nodes SG**
   - Ingress: Port 80/443 from ALB
   - Egress: All traffic to Backend VPC CIDR
   - Egress: Port 443 to AWS services

2. **Backend EKS Nodes SG**
   - Ingress: Port 8080 from Gateway VPC CIDR only
   - Egress: Port 443 to AWS services
   - No direct internet access

3. **ALB Security Group**
   - Ingress: Port 80/443 from 0.0.0.0/0
   - Egress: To Gateway EKS nodes

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

**Note**: NetworkPolicy requires a CNI that supports it (AWS VPC CNI with Network Policy support or Calico). In this implementation, we rely primarily on Security Groups at the infrastructure level for simplicity.

### Cross-Cluster Communication

The Gateway proxy forwards traffic to the Backend service:

1. **Service Discovery**: Backend service DNS name is resolved within the cluster
2. **Network Path**: 
   - Request → ALB (public) → Gateway Proxy Pod
   - Gateway Proxy → VPC Peering → Backend Service Pod
3. **Security**: 
   - Traffic flows over private IPs only
   - Security Groups enforce source/destination restrictions
   - No public exposure of backend services

#### Proxy Configuration

The NGINX proxy in the gateway cluster uses:

```nginx
upstream backend {
    server backend-service.backend-vpc.internal:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

The backend service endpoint is:
- Resolved via Route53 private hosted zone (production approach)
- Or hardcoded backend service ClusterIP (POC approach)

## CI/CD Pipeline

### GitHub Actions Workflow

Located in `.github/workflows/deploy.yml`:

**Stages:**

1. **Validate**
   - Terraform format check
   - Terraform validate
   - TFLint for best practices
   - Kubernetes manifest validation with kubeval

2. **Plan**
   - Terraform plan with detailed output
   - Plan artifact saved for review

3. **Apply** (main branch only)
   - Terraform apply
   - Infrastructure provisioning

4. **Deploy**
   - Update kubeconfig for both clusters
   - Deploy backend service
   - Deploy gateway proxy
   - Dry-run validation before apply

5. **Verify**
   - Health check on backend service
   - Connectivity test from proxy to backend
   - End-to-end smoke test

### OIDC Authentication

The pipeline uses GitHub OIDC to assume an AWS IAM role without long-lived credentials:

```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GitHubActionsRole
    aws-region: ${{ secrets.AWS_REGION }}
```

## IAM Roles and Permissions

### Naming Convention

Following the required naming prefixes:

- `eks-*`: EKS cluster and node group roles
  - `eks-gateway-cluster-role`
  - `eks-gateway-node-role`
  - `eks-backend-cluster-role`
  - `eks-backend-node-role`

- `sentinel-*`: Application-specific roles
  - `sentinel-backend-service-role` (for IRSA)
  - `sentinel-gateway-proxy-role` (for IRSA)

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

4. **Network Policy Implementation**
   - **Chosen**: Security Groups as primary control
   - **Rationale**: Native AWS integration, well-understood
   - **Production**: Add Calico or AWS VPC CNI Network Policy for defense-in-depth

5. **Service Discovery**
   - **Chosen**: Hardcoded service IP for POC
   - **Rationale**: Simplicity, no DNS dependencies
   - **Production**: Use Route53 private hosted zones or service mesh

6. **Load Balancer Type**
   - **Chosen**: Classic Load Balancer (NLB fallback)
   - **Rationale**: Simple integration with EKS
   - **Production**: Use ALB with WAF integration

Due to the challenge timeline, the following were simplified:
- Single NAT Gateway per VPC (not HA)
- Basic NGINX proxy (no advanced routing)
- Hardcoded backend endpoint (no dynamic discovery)
- Limited observability (no Prometheus/Grafana)
- No TLS termination
- Basic NetworkPolicy examples

## Cost Optimization

### Current Costs (Estimated Monthly)

| Component | Quantity | Unit Cost | Total |
|-----------|----------|-----------|-------|
| NAT Gateway | 2 | ~$32 | $64 |
| NAT Gateway Data | Varies | $0.045/GB | ~$50 |
| EKS Cluster | 2 | $0.10/hr | $144 |
| EC2 t3.medium | 4-8 | $0.0416/hr | $120-240 |
| Load Balancer | 1 | $16 | $16 |
| VPC Peering | Free | - | $0 |
| **Total** | | | **~$394-514/month** |

### Optimization Strategies

1. **NAT Gateway**: Use NAT instances or single shared NAT for non-prod
2. **EKS Control Plane**: Use EKS Anywhere or k3s for dev environments
3. **Compute**: Use Spot instances for non-critical workloads (60-90% savings)
4. **Load Balancer**: Share ALB across services with path-based routing
5. **Reserved Instances**: 1-year commitment for 30-40% savings
6. **Auto-scaling**: Scale down during off-hours

## Security Considerations

### Implemented

- ✅ Private subnets for all workloads
- ✅ No public EC2 instances
- ✅ Security Groups with least privilege
- ✅ VPC Flow Logs enabled
- ✅ EKS cluster endpoint private access
- ✅ IAM roles with restricted permissions
- ✅ Secrets in AWS Secrets Manager (for production)

### Future Enhancements

- 🔲 TLS/mTLS between services
- 🔲 AWS WAF on ALB
- 🔲 GuardDuty for threat detection
- 🔲 KMS encryption for EBS volumes
- 🔲 Pod Security Standards enforcement
- 🔲 OPA for policy enforcement
- 🔲 VPN or PrivateLink for operator access

## What's Next

### Phase 2: Production Readiness

1. **Service Mesh** (Istio/Linkerd)
   - mTLS everywhere
   - Advanced traffic management
   - Observability built-in

2. **Observability Stack**
   - Prometheus + Grafana
   - ELK or CloudWatch Logs Insights
   - AWS X-Ray for distributed tracing
   - Alert manager integration

3. **GitOps** (ArgoCD/Flux)
   - Declarative application deployment
   - Automated sync from Git
   - Rollback capabilities

4. **Secret Management**
   - External Secrets Operator with AWS Secrets Manager
   - Vault for dynamic secrets
   - Sealed Secrets for Git storage

5. **Advanced Networking**
   - AWS App Mesh or Istio
   - AWS PrivateLink for AWS services
   - Transit Gateway for multi-region

6. **Disaster Recovery**
   - Multi-region setup
   - Automated backups (Velero)
   - RTO/RPO targets defined

7. **Compliance & Governance**
   - AWS Config rules
   - CloudTrail for audit
   - Compliance scanning (Prowler, ScoutSuite)
   - Cost allocation tags

## Troubleshooting

### EKS Cluster Access

```bash
# Update kubeconfig
aws eks update-kubeconfig --name eks-gateway --region us-east-1

# Verify access
kubectl get nodes
```

### Cross-VPC Connectivity Issues

```bash
# Test from Gateway pod
kubectl exec -it <gateway-pod> -- curl http://<backend-service-ip>:8080

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify peering routes
aws ec2 describe-route-tables --route-table-ids <rt-id>
```