# Company Inc. - Cloud Architecture Design Document

**Version:** 1.0  
**Date:** March 2026  

---

## Executive Summary

This document outlines the cloud infrastructure architecture for Company Inc.'s web application deployment on **Google Cloud Platform (GCP)**. The design prioritizes scalability, security, cost-effectiveness, and operational excellence using managed Kubernetes (GKE) as the core compute platform.

---

## 1. Cloud Environment Structure

### 1.1 GCP Project Structure

| Project | Purpose | Environment |
|---------|---------|-------------|
| `company-prod` | Production workloads | Production |
| `company-staging` | Pre-production testing | Staging |
| `company-dev` | Development & experimentation | Development |

### 1.2 Justification

**Why GCP over AWS:**
- **GKE superiority**: GKE offers the most mature managed Kubernetes with Autopilot mode and superior cluster upgrades
- **Cost efficiency**: Sustained use discounts (up to 30%) and committed use discounts without upfront payment

**Why multi-project structure:**
- **Blast radius isolation**: Production issues don't affect dev/staging
- **Billing separation**: Clear cost attribution per environment
- **IAM boundaries**: Least-privilege access per environment
- **Quota management**: Independent resource quotas

---

## 2. Network Design

### 2.1 VPC Architecture

Each project has its own VPC with a single private subnet for GKE workloads:

| Project | VPC CIDR | Region |
|---------|----------|--------|
| `company-prod` | 10.0.0.0/16 | us-central1 |
| `company-staging` | 10.1.0.0/16 | us-central1 |
| `company-dev` | 10.2.0.0/16 | us-central1 |

### 2.2 Security Controls

| Layer | Control | Purpose |
|-------|---------|---------|
| **Perimeter** | Cloud Armor | DDoS protection, WAF, geo-blocking (first layer) |
| **CDN** | Cloud CDN | Caching, edge delivery (after security filtering) |
| **Ingress** | Global HTTPS Load Balancer | TLS termination, routing to Storage/GKE |
| **Network** | VPC Firewall Rules | Deny-all default, explicit allow rules |
| **Pod-level** | GKE Network Policies | Namespace isolation, egress control |

### 2.3 Network Security Rules

- **GKE nodes**: Private nodes, no public IPs
- **Egress**: Controlled via Cloud NAT with logging
- **Database**: Private connectivity only (no public endpoints)

---

## 3. Frontend Hosting (Cloud Storage)

### 3.1 Static Site Hosting

The React SPA frontend is deployed to **Cloud Storage** with static website hosting:

| Setting | Value |
|---------|-------|
| **Bucket** | `company-{env}-frontend` |
| **Main page** | `index.html` |
| **Error page** | `index.html` (SPA routing) |
| **Access** | Public via Load Balancer only |

**Benefits:**
- **Cost-effective**: No compute resources for static files
- **Scalable**: Automatic global distribution via CDN
- **Simple deployment**: Just upload built assets
- **High availability**: 99.99% SLA

### 3.2 CDN Integration

- Cloud CDN caches frontend assets at edge locations
- Cache invalidation on deployment
- Compression enabled (gzip/brotli)

---

## 4. Compute Platform (GKE)

### 4.1 Cluster Configuration

| Setting | Production | Staging/Dev |
|---------|------------|-------------|
| **Mode** | GKE Standard | GKE Autopilot |
| **Version** | Regular channel | Rapid channel |
| **Nodes** | Private | Private |
| **Control Plane** | Regional (HA) | Zonal |

### 4.2 Node Pool Strategy (Production)

```yaml
Node Pools:
  - name: system
    machineType: e2-medium
    minNodes: 2
    maxNodes: 4
    taints: [CriticalAddonsOnly]
    
  - name: application
    machineType: e2-standard-4
    minNodes: 2
    maxNodes: 20
    autoscaling: enabled
    
  - name: spot-burst
    machineType: e2-standard-4
    minNodes: 0
    maxNodes: 50
    preemptible: true
    taints: [spot=true:NoSchedule]
```

### 4.3 Scaling Policies

- **Horizontal Pod Autoscaler (HPA)**: CPU/memory-based (target: 70%)
- **Vertical Pod Autoscaler (VPA)**: Recommendation mode for right-sizing
- **Cluster Autoscaler**: Node pool scaling based on pending pods
- **Spot instances**: Burst workloads on preemptible nodes (70% cost savings)

### 4.4 Containerization Strategy (Backend)

**Image Building (GitHub Actions):**
```
Developer Push → GitHub Actions → Build & Scan → Artifact Registry → GKE
```

- Multi-stage Dockerfiles for minimal images
- Distroless base images for security
- Vulnerability scanning via Trivy/Grype
- Image signing for supply chain security

**Container Registry:**
- **Artifact Registry** in each GCP project
- Vulnerability scanning enabled
- Lifecycle policies for image cleanup

### 4.5 CI/CD Pipeline

**Frontend Pipeline:**
```
GitHub → GitHub Actions → Build React → Upload to Cloud Storage → CDN Invalidation
```

**Backend Pipeline:**
```
GitHub → GitHub Actions → Build Container → Artifact Registry → GKE (via Helm)
```

| Component | Build | Deploy |
|-----------|-------|--------|
| Frontend (React) | `npm run build` | `gsutil rsync` to Cloud Storage |
| Backend (Flask) | Docker build | Helm upgrade to GKE |

| Stage | Tool | Purpose |
|-------|------|---------|
| Source | GitHub | Version control |
| Build | GitHub Actions | Container/asset builds, testing |
| Registry | GCP Artifact Registry | Backend image storage |
| Frontend | Cloud Storage | Static asset hosting |
| Backend | GitHub Actions + Helm | Kubernetes deployment |
| Secrets | GCP Secret Manager | Credential injection via Workload Identity |

**GitHub Actions Workflow:**
- Build and push backend images on PR merge
- Build and deploy frontend assets to Cloud Storage
- Run security scans (Trivy, SAST)
- Deploy to staging automatically
- Production deployment with manual approval
- CDN cache invalidation after frontend deploy

---

## 5. Database (MongoDB)

### 5.1 Recommendation: MongoDB Atlas on GCP

**Justification:**
- **Managed service**: Zero operational overhead for database management
- **Native GCP integration**: Private Service Connect for secure connectivity
- **Multi-region**: Built-in cross-region replication
- **Compliance**: SOC2, HIPAA, GDPR certifications
- **Cost**: Pay-per-use with auto-scaling

### 5.2 Configuration

| Setting | Production | Staging | Dev |
|---------|------------|---------|-----|
| **Tier** | M30 (dedicated) | M10 (shared) | M0 (free) |
| **Replicas** | 3-node replica set | 3-node | Single |
| **Region** | us-central1 | us-central1 | us-central1 |
| **Storage** | Auto-expand | Fixed 10GB | Fixed 5GB |

### 5.3 Backup Strategy

- **Continuous backups**: Point-in-time recovery (PITR) - 7 days retention
- **Scheduled snapshots**: Daily at 02:00 UTC - 30 days retention
- **Cross-region backup**: Replicated to us-east1
- **Testing**: Monthly restore drills to staging

### 5.4 High Availability

- **Replica Set**: 3 members across availability zones
- **Automatic failover**: < 10 seconds
- **Read preference**: Secondary preferred for read scaling

### 5.5 Disaster Recovery

| Scenario | RTO | RPO | Strategy |
|----------|-----|-----|----------|
| Node failure | < 1 min | 0 | Automatic failover |
| AZ failure | < 10 sec | 0 | Replica promotion |
| Region failure | < 1 hour | < 1 hour | Cross-region restore |
| Data corruption | < 4 hours | Variable | PITR restore |

---

## 6. Security Summary

| Domain | Implementation |
|--------|----------------|
| **Identity** | Cloud IAM, Workload Identity |
| **Network** | Private GKE, VPC firewalls, Cloud Armor |
| **Data** | Encryption at rest (CMEK), TLS in transit |
| **Secrets** | GCP Secret Manager + Workload Identity |
| **Compliance** | Cloud Audit Logs, Security Command Center |
| **Containers** | Trivy scanning, image signing |

---

## 7. Cost Optimization

| Strategy | Estimated Savings |
|----------|-------------------|
| Static frontend on Cloud Storage | 80-90% vs GKE hosting |
| Sustained use discounts | 20-30% |
| Spot VMs for burst | 60-70% |
| GKE Autopilot (staging/dev) | 30-40% |
| Right-sizing via VPA | 15-25% |
| Committed use (Year 1+) | 30-50% |
