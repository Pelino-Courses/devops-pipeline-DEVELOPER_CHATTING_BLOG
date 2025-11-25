# Deployment Guide

## Prerequisites

### Required Tools
- Azure CLI (v2.50+)
- Terraform CLI (v1.5+)
- Ansible (v2.14+)
- Docker & Docker Compose
- Git
- Node.js 18+

### Required Accounts
- GitHub account
- Azure subscription
- Terraform Cloud account

## Initial Setup

### 1. Azure Configuration

```bash
# Login to Azure
az login

# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Note the output - you'll need:
# - appId (CLIENT_ID)
# - password (CLIENT_SECRET)
# - tenant (TENANT_ID)
```

### 2. Terraform Cloud Setup

1. Create account at https://app.terraform.io
2. Create organization
3. Create workspace named `devops-pipeline-infrastructure`
4. Configure variables:
   - `ARM_CLIENT_ID` (Azure service principal appId)
   - `ARM_CLIENT_SECRET` (sensitive)
   - `ARM_TENANT_ID`
   - `ARM_SUBSCRIPTION_ID`
   - `ssh_public_key` (your SSH public key)

### 3. GitHub Secrets Configuration

Navigate to Settings → Secrets and Variables → Actions, add:

#### Azure Credentials
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`

#### Terraform
- `TF_API_TOKEN` (from Terraform Cloud)

#### Azure Container Registry
- `ACR_NAME`
- `ACR_LOGIN_SERVER`
- `ACR_USERNAME` (service principal appId)
- `ACR_PASSWORD` (service principal password)

#### VM Access
- `SSH_PRIVATE_KEY` (private SSH key matching public key in Terraform)
- `VM_PUBLIC_IP` (will be set after first deployment)

#### Database
- `DB_USER` (for MongoDB - optional)
- `DB_PASSWORD`
- `DB_NAME`

## Deployment Steps

### Step 1: Infrastructure Provisioning

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (if running locally)
terraform init

# Review plan
terraform plan

# Apply infrastructure
terraform apply
```

**Note**: Infrastructure pipeline runs automatically on push to `main` branch.

### Step 2: Update VM_PUBLIC_IP Secret

After Terraform completes:
1. Get VM public IP from Terraform output
2. Update `VM_PUBLIC_IP` secret in GitHub

### Step 3: Application Deployment

Deployment happens automatically when you push to `main`:

```bash
git checkout main
git merge develop
git push origin main
```

The CD pipeline will:
1. Build Docker images
2. Push to ACR
3. Run Ansible to configure VM
4. Deploy application containers

### Step 4: Verify Deployment

```bash
# Check application
curl http://YOUR_VM_IP

# Check backend health
curl http://YOUR_VM_IP:5000/health

# SSH into VM to check containers
ssh azureuser@YOUR_VM_IP
docker ps
docker-compose logs
```

## Manual Deployment (if needed)

### Run Ansible Manually

```bash
cd ansible

# Install required collections
ansible-galaxy collection install azure.azcollection
ansible-galaxy collection install community.docker

# Create inventory file
cat > inventory/hosts << EOF
[app_servers]
azure-vm ansible_host=YOUR_VM_IP ansible_user=azureuser
EOF

# Run playbook
ansible-playbook playbooks/setup-server.yml -i inventory/hosts
```

## Troubleshooting

### Terraform Issues

**Provider authentication failed**
```bash
# Verify Azure credentials
az account show
az account list

# Re-authenticate
az login
```

**State lock errors**
- Wait for current operation to complete
- Force unlock if necessary (use with caution):
  ```bash
  terraform force-unlock LOCK_ID
  ```

### Ansible Issues

**SSH connection failed**
```bash
# Test SSH connection
ssh -i ~/.ssh/your_key azureuser@YOUR_VM_IP

# Fix permissions
chmod 600 ~/.ssh/your_key
```

**ACR login failed**
```bash
# Verify ACR credentials
az acr login --name YOUR_ACR_NAME

# Check service principal permissions
az role assignment list --assignee YOUR_APP_ID
```

### Application Issues

**Containers not starting**
```bash
# SSH into VM
ssh azureuser@YOUR_VM_IP

# Check logs
cd /opt/devops-app
docker-compose logs

# Restart containers
docker-compose down
docker-compose up -d
```

**Cannot pull images from ACR**
```bash
# Login to ACR on VM
az acr login --name YOUR_ACR_NAME

# Or use docker login
docker login YOUR_ACR_NAME.azurecr.io
```

## Rolling Back

### Rollback Application

```bash
# SSH into VM
ssh azureuser@YOUR_VM_IP

# Navigate to app directory
cd /opt/devops-app

# Pull specific version
export IMAGE_TAG=previous-version
docker-compose pull
docker-compose up -d
```

### Rollback Infrastructure

```bash
cd terraform

# Revert to previous state
terraform plan -out=rollback.tfplan
terraform apply rollback.tfplan
```

## Maintenance

### Update Dependencies

```bash
# Backend
cd backend
npm update
npm audit fix

# Frontend  
cd frontend
npm update
npm audit fix
```

### Rotate Secrets

1. Generate new credentials in Azure
2. Update GitHub Secrets
3. Update Terraform Cloud variables
4. Re-run deployment pipeline

### Monitor Resources

```bash
# Check Azure resources
az resource list --resource-group devopspipeline-dev-rg

# Check costs
az consumption usage list
```

## Emergency Procedures

### Complete System Down

1. Check Azure portal for resource status
2. Review GitHub Actions for failed pipelines
3. SSH into VM and check logs
4. If necessary, destroy and recreate:
   ```bash
   terraform destroy
   terraform apply
   ```

### Security Incident

1. Rotate all secrets immediately
2. Check security scanning results
3. Review access logs
4. Update firewall rules if needed
