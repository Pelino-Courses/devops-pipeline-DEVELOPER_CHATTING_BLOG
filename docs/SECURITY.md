# Security Documentation

## Security Overview

This project implements comprehensive security practices across all layers of the application and infrastructure lifecycle.

## Security Principles

1. **Defense in Depth**: Multiple layers of security controls
2. **Least Privilege**: Minimal necessary permissions
3. **Secrets Management**: No hardcoded credentials
4. **Automated Scanning**: Continuous security validation
5. **Zero Trust**: Verify everything, trust nothing

## Network Security

### Firewall Configuration

**Network Security Group Rules**:
- **Port 22** (SSH): Management access only
- **Port 80** (HTTP): Frontend application
- **Port 443** (HTTPS): Secure frontend application
- **Port 5000**: Backend API
- **All other ports**: Blocked

### UFW (Uncomplicated Firewall)
```bash
# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allowed services
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 5000/tcp  # Backend API
```

### Fail2ban Configuration
- **Ban Time**: 3600 seconds (1 hour)
- **Find Time**: 600 seconds (10 minutes)
- **Max Retry**: 5 attempts
- **Services Protected**: SSH

## Application Security

### Authentication & Authorization

**JWT (JSON Web Tokens)**:
- Secure token-based authentication
- Configurable expiration
- Refresh token support

**Password Security**:
- Bcrypt hashing (cost factor: 10)
- Minimum password requirements
- No password storage in plain text

### API Security

- **CORS**: Configured for specific origins
- **Rate Limiting**: Prevents abuse
- **Input Validation**: All user inputs sanitized
- **SQL Injection Prevention**: Parameterized queries (MongoDB)
- **XSS Protection**: Content Security Policy headers

### Secrets Management

**Never Commit**:
- Passwords
- API keys
- Private keys
- Environment variables with sensitive data

**GitHub Secrets** (encrypted):
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `SSH_PRIVATE_KEY`
- `ACR_PASSWORD`
- `DB_PASSWORD`
- `TF_API_TOKEN`

**Access Control**:
- Secrets only accessible during workflow runs
- Masked in logs
- Restricted by repository permissions

## Infrastructure Security

### Azure Resources

**Service Principal**:
- Minimal permissions (Contributor on Resource Group only)
- Regularly rotated credentials
- No excessive privileges

**SSH Access**:
- Key-based authentication only
- No password authentication
- Key rotation policy

**Virtual Machine**:
- Latest Ubuntu LTS with security updates
- Unattended security updates enabled
- Minimal installed packages

### Terraform Security

**State Management**:
- Encrypted at rest in Terraform Cloud
- TLS encryption in transit
- Access controlled by Terraform Cloud RBAC

**Infrastructure Scanning**:
- **tfsec**: Terraform security scanner
- **Checkov**: Policy-as-code scanner
- Runs on every PR and push

## Container Security

### Image Security

**Base Images**:
- Official images from Docker Hub
- Minimal images (Alpine where possible)
- Regular updates

**Image Scanning**:
- Trivy scanner in CI/CD
- Scans for OS and library vulnerabilities
- Blocks deployment on CRITICAL/HIGH findings

**Best Practices**:
- No secrets in images
- Non-root user when possible
- Multi-stage builds to minimize size
- Layer caching security

### Container Registry

**Azure Container Registry**:
- Private registry
- Role-based access control
- Service principal authentication
- Geo-replication for availability

## CI/CD Security

### Automated Security Scanning

#### Dependency Scanning
```yaml
- Name: npm audit
- Frequency: Every PR, push, weekly
- Action: Alert on moderate+ vulnerabilities
- Tools: npm audit
```

#### Static Application Security Testing (SAST)
```yaml
- Name: CodeQL Analysis
- Frequency: Every PR, push
- Languages: JavaScript
- Action: Create security alerts
```

#### Container Scanning
```yaml
- Name: Trivy Scanner
- Frequency: Every image build
- Severity: CRITICAL, HIGH
- Action: Fail on vulnerable images
```

#### Infrastructure Scanning
```yaml
- Name: tfsec, Checkov
- Frequency: Every Terraform change
- Action: Fail on high-risk issues
```

#### Secret Scanning
```yaml
- Name: TruffleHog
- Frequency: Every commit
- Action: Alert on exposed secrets
```

#### Dynamic Application Security Testing (DAST)
```yaml
- Name: OWASP ZAP
- Frequency: Weekly, on-demand
- Type: Baseline scan
- Action: Generate security report
```

### Branch Protection

**Main Branch**:
- Require pull request reviews (1+)
- Require status checks to pass
- No force pushes
- No deletions
- CODEOWNERS enforcement

## Monitoring & Incident Response

### Security Monitoring

- **GitHub Security Alerts**: Dependency vulnerabilities
- **CodeQL Alerts**: Code security issues
- **Failed Login Attempts**: Fail2ban logs
- **Firewall Logs**: Blocked connection attempts

### Incident Response Plan

1. **Detection**: Automated alerts, manual discovery
2. **Analysis**: Assess scope and impact
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Post-incident review

### Security Incident Procedures

**If secret is compromised**:
1. Immediately rotate the secret
2. Update GitHub Secrets
3. Update Terraform Cloud variables
4. Re-deploy affected services
5. Review access logs
6. Document incident

**If vulnerability is found**:
1. Assess severity and exploitability
2. Apply patch if available
3. Implement workaround if no patch
4. Test fix in non-production
5. Deploy to production
6. Verify fix effectiveness

## Compliance & Best Practices

### Security Standards

- **OWASP Top 10**: Addressed in application design
- **CIS Benchmarks**: Ubuntu hardening applied
- **Azure Security Baseline**: Infrastructure configuration

### Security Checklist

- [x] Secrets stored securely (GitHub Secrets)
- [x] Network properly segmented (NSG, firewall)
- [x] Authentication implemented (JWT)
- [x] Authorization enforced (API routes)
- [x] Encrypted connections (HTTPS)
- [x] Regular security updates (unattended-upgrades)
- [x] Security scanning automated (CI/CD)
- [x] Logging and monitoring enabled
- [x] Incident response plan documented
- [x] Regular backups configured

## Security Updates

### Automated Updates

**Ubuntu**:
```bash
# Unattended upgrades configured
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

**Docker Images**:
- Weekly automated builds
- Dependency updates via Dependabot
- Security patch testing in CI

### Manual Update Process

1. Review security advisories
2. Test updates in development
3. Deploy to production
4. Verify functionality
5. Monitor for issues

## Vulnerability Disclosure

If you discover a security vulnerability:

1. **Do not** open a public issue
2. Email: [security contact - add your email]
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and work with you to resolve the issue.

## Security Training

Team members should be familiar with:
- Secure coding practices
- Common vulnerabilities (OWASP Top 10)
- Secret management
- Incident response procedures
- Security scanning tools

## Regular Security Reviews

**Weekly**:
- Review security scan results
- Check dependency updates
- Monitor failed login attempts

**Monthly**:
- Review access controls
- Audit user permissions
- Check security configurations

**Quarterly**:
- Penetration testing
- Security training updates
- Incident response drill
- Security policy review

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Azure Security Documentation](https://docs.microsoft.com/en-us/azure/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
