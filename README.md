# DevOps Pipeline - Developer Chatting Blog

Comprehensive DevOps implementation with CI/CD, Infrastructure as Code, and Configuration Management.

## Team Members

- **Romeo Pelino** - DevOps Engineer (GitHub/CI/CD Lead)
- **Additional Team Members** - Add your team members here

## Project Overview

A real-time developer chatting and blogging platform built with modern DevOps practices, featuring automated deployment pipelines, infrastructure as code, and comprehensive security scanning.

## Architecture

### Application Stack
- **Frontend**: HTML/CSS/JavaScript with Socket.IO client
- **Backend**: Node.js/Express with Socket.IO server
- **Database**: MongoDB

### Infrastructure
- **Cloud Provider**: Microsoft Azure
- **IaC Tool**: Terraform with Terraform Cloud
- **Configuration Management**: Ansible
- **Container Registry**: Azure Container Registry (ACR)
- **Compute**: Azure Virtual Machine (Ubuntu 22.04)
- **Networking**: Azure Virtual Network with NSG

### CI/CD Pipeline
- **Source Control**: GitHub
- **CI/CD Platform**: GitHub Actions
- **Containerization**: Docker
- **Orchestration**: Docker Compose

## Repository Structure

```
├── .github/
│   └── workflows/          # CI/CD pipelines
│       ├── ci-pipeline.yml       # Lint, test, build
│       ├── cd-pipeline.yml       # Deploy to Azure
│       ├── terraform.yml         # Infrastructure pipeline
│       ├── security.yml          # Security scanning
│       └── dast.yml             # OWASP ZAP scanning
├── frontend/               # Frontend application
├── backend/               # Backend API
├── terraform/             # Infrastructure as Code
├── ansible/              # Configuration management
│   ├── playbooks/        # Ansible playbooks
│   └── roles/            # Ansible roles
│       ├── docker/       # Docker installation
│       ├── security/     # Security hardening
│       ├── app-deploy/   # Application deployment
│       └── monitoring/   # System monitoring
├── security/             # Security configurations
└── docs/                 # Additional documentation
```

## Getting Started

### Prerequisites
- Git
- Docker Desktop
- Azure CLI
- Terraform CLI (v1.0+)
- Ansible (v2.9+)
- Node.js 18+

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Pelino-Courses/devops-pipeline-DEVELOPER_CHATTING_BLOG.git
   cd devops-pipeline-DEVELOPER_CHATTING_BLOG
   ```

2. **Start local environment:**
   ```bash
   docker-compose up --build
   ```

3. **Access the application:**
   - Frontend: `http://localhost`
   - Backend API: `http://localhost:5000`
   - API Documentation: `http://localhost:5000/api-docs`

## Deployment

### Infrastructure Provisioning

1. Configure Terraform Cloud workspace
2. Set required variables in Terraform Cloud
3. Push changes to `main` branch
4. Infrastructure pipeline runs automatically

### Application Deployment

1. Merge changes to `main` branch
2. CI pipeline runs tests and builds images
3. Images pushed to Azure Container Registry
4. Ansible configures and deploys to VM
5. Application accessible at production URL

## CI/CD Pipelines

### CI Pipeline
✅ Linting (ESLint)  
✅ Unit testing  
✅ Integration testing  
✅ Security scanning (Trivy, npm audit)  
✅ Docker build verification

### CD Pipeline
✅ Build and push Docker images  
✅ Infrastructure provisioning (Terraform)  
✅ Server configuration (Ansible)  
✅ Application deployment  
✅ Post-deployment verification

### Security Pipeline
✅ Dependency vulnerability scanning  
✅ Static application security testing (SAST)  
✅ Container security scanning  
✅ Infrastructure security (tfsec, Checkov)  
✅ Secret scanning (TruffleHog)  
✅ Dynamic application security testing (DAST with OWASP ZAP)

## DevOps Practices Implemented

### Version Control
- Branch protection rules
- Required pull request reviews
- Status checks before merging
- CODEOWNERS for specialized reviews

### Project Management
- GitHub Projects for task tracking
- Issue templates for consistency
- Automated project board workflows

### Security
- Automated security scanning in CI/CD
- Container vulnerability scanning
- Infrastructure security scanning
- Secret management with GitHub Secrets
- UFW firewall configuration
- Fail2ban for intrusion prevention
- Regular security updates

### Infrastructure Management
- Infrastructure as Code with Terraform
- State management with Terraform Cloud
- Automated provisioning
- Version-controlled infrastructure

### Configuration Management
- Ansible roles for modularity
- Automated server configuration
- Idempotent playbooks
- Dynamic inventory

### Monitoring
- Application health checks
- System resource monitoring
- Docker container status
- Prometheus node exporter

## Security Considerations

- ✅ All secrets stored in GitHub Secrets
- ✅ Branch protection prevents unauthorized changes
- ✅ Security scanning on every PR
- ✅ Container images scanned for vulnerabilities
- ✅ Infrastructure security validated
- ✅ Regular security updates applied automatically
- ✅ Firewall configured to allow only necessary traffic

## Troubleshooting

### Common Issues

#### Terraform Apply Fails
- Verify Azure credentials in Terraform Cloud
- Check resource name uniqueness
- Ensure subscription has sufficient quota

#### Ansible Deployment Fails
- Verify SSH key configuration
- Check VM firewall rules
- Ensure ACR credentials are correct

#### Application Not Accessible
- Verify all containers are running: `docker ps`
- Check application logs: `docker-compose logs`
- Verify firewall rules allow traffic

## Contributing

1. Create feature branch from `develop`
2. Make changes and commit
3. Push branch and create pull request
4. Ensure all CI checks pass
5. Obtain required reviews
6. Merge to `develop`

## License

MIT License

## Acknowledgments

- ALU DevOps Course
- Open source tools and communities
