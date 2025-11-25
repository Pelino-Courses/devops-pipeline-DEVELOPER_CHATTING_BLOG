# Architecture Documentation

## System Overview

The Developer Chatting Blog is a cloud-native application deployed on Microsoft Azure, utilizing Infrastructure as Code, automated CI/CD pipelines, and configuration management.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Source     │  │   CI/CD      │  │   Security   │      │
│  │   Control    │  │   Pipelines  │  │   Scanning   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   Terraform Cloud                            │
│              (Infrastructure State Management)               │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Microsoft Azure                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Azure Container Registry                   │ │
│  │          (Docker Images: frontend, backend)            │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Azure Virtual Network                      │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │         Azure Virtual Machine (Ubuntu)            │ │ │
│  │  │  ┌────────────────────────────────────────────┐  │ │ │
│  │  │  │         Docker Compose                      │  │ │ │
│  │  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐   │  │ │ │
│  │  │  │  │ Frontend │ │ Backend  │ │ MongoDB  │   │  │ │ │
│  │  │  │  │Container │ │Container │ │Container │   │  │ │ │
│  │  │  │  └──────────┘ └──────────┘ └──────────┘   │  │ │ │
│  │  │  └────────────────────────────────────────────┘  │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │  │              Network Security Group                │ │
│  │  │       (Firewall Rules: 22, 80, 443, 5000)         │ │
│  └──┴──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Frontend Layer
- **Technology**: HTML, CSS, JavaScript
- **Real-time**: Socket.IO client
- **Containerization**: Nginx serving static files
- **Port**: 80

### Backend Layer
- **Technology**: Node.js, Express.js
- **API**: RESTful API + Socket.IO server
- **Authentication**: JWT-based
- **API Documentation**: Swagger/OpenAPI
- **Port**: 5000

### Data Layer
- **Database**: MongoDB 7
- **Persistence**: Docker volume for data
- **Port**: 27017 (internal only)

## Infrastructure Components

### Azure Resources

#### Resource Group
- **Name**: `devopspipeline-dev-rg`
- **Location**: West Europe
- **Purpose**: Container for all deployment resources

#### Virtual Network
- **Address Space**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24
- **Purpose**: Network isolation and security

#### Network Security Group
- **Inbound Rules**:
  - SSH (22) - For management
  - HTTP (80) - Frontend access
  - HTTPS (443) - Secure frontend access
  - Backend (5000) - API access
- **Outbound Rules**: Unrestricted

#### Virtual Machine
- **Size**: Standard_B2s
- **OS**: Ubuntu 22.04 LTS
- **Disk**: 30GB Premium SSD
- **SSH**: Key-based authentication only

#### Container Registry
- **SKU**: Basic
- **Purpose**: Store Docker images
- **Access**: Service Principal authentication

## CI/CD Pipeline Architecture

### Continuous Integration (CI)

```
┌──────────────┐
│ Pull Request │
│   or Push    │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  Lint Backend    │
│  Lint Frontend   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Test Backend    │
│  Test Frontend   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Security Scan    │
│  - npm audit     │
│  - Trivy         │
│  - CodeQL        │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Build Docker    │
│    Images        │
└──────────────────┘
```

### Continuous Deployment (CD)

```
┌──────────────┐
│ Merge to Main│
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  Build & Push    │
│  Docker Images   │
│     to ACR       │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│    Terraform     │
│ Infrastructure   │
│   Provision      │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│     Ansible      │
│  Configuration   │
│   & Deployment   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Post-Deploy     │
│  Verification    │
└──────────────────┘
```

## Security Architecture

### Network Security
- Network Security Groups (NSGs) for traffic filtering
- Minimal port exposure
- SSH key-based authentication only
- Private container network

### Application Security
- JWT authentication for API
- Password hashing with bcrypt
- Input validation
- CORS configuration
- Rate limiting

### Infrastructure Security
- Service Principal with minimal permissions
- Secrets stored in GitHub Secrets
- Terraform state encrypted in Terraform Cloud
- Regular security scans

### DevSecOps
- Dependency vulnerability scanning
- Static code analysis (CodeQL)
- Container scanning (Trivy)
- Infrastructure scanning (tfsec)
- Secret scanning (TruffleHog)
- DAST with OWASP ZAP

## Data Flow

### User Request Flow

```
User Browser
     │
     ▼
   Nginx (Frontend Container)
     │
     ▼
  Express.js (Backend Container)
     │
     ▼
  MongoDB (Database Container)
```

### Real-time Communication Flow

```
User Browser (Socket.IO Client)
     │
     │ WebSocket
     ▼
Backend (Socket.IO Server)
     │
     │ Broadcast
     ▼
Other Connected Clients
```

## Deployment Flow

```
Developer
     │
     ▼
Git Push to Feature Branch
     │
     ▼
Pull Request Created
     │
     ▼
CI Pipeline Runs
     │
     ▼
Code Review & Approval
     │
     ▼
Merge to Main
     │
     ▼
CD Pipeline Triggers
     │
     ├──▶ Build Docker Images
     │
     ├──▶ Push to ACR
     │
     ├──▶ Terraform Apply
     │
     ├──▶ Ansible Deploy
     │
     └──▶ Health Checks
```

## Monitoring & Observability

### Application Monitoring
- Health check endpoints
- Application logs via Docker
- Real-time status dashboard

### Infrastructure Monitoring
- Prometheus node exporter
- System resource monitoring
- Docker container monitoring

### Logging
- Centralized Docker logs
- Application-level logging
- System logs

## Scalability Considerations

### Current Architecture
- Single VM deployment
- Suitable for development/testing
- Vertical scaling possible

### Future Enhancements
- Azure Kubernetes Service (AKS)
- Load balancer for horizontal scaling
- Azure Database for MongoDB (managed)
- Azure Cache for Redis
- CDN for static assets

## Disaster Recovery

### Backup Strategy
- MongoDB data volume backups
- Infrastructure as Code (recreatable)
- Docker images stored in ACR
- Source code in GitHub

### Recovery Procedures
1. Restore Terraform state from Terraform Cloud
2. Run `terraform apply` to recreate infrastructure
3. Run Ansible playbook to reconfigure
4. Restore MongoDB data from backup

## Performance Optimization

- Docker layer caching in CI/CD
- Nginx gzip compression
- MongoDB indexing
- Connection pooling
- Static asset caching
