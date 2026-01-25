# Image Scanning Policy for 5G Telco Cloud

## Policy Statement
All container images deployed to the 5G telco cloud must be scanned for vulnerabilities and meet the following criteria:

### Severity Thresholds
- **CRITICAL vulnerabilities**: ZERO allowed in production
- **HIGH vulnerabilities**: Maximum 5 allowed (with remediation plan required)
- **MEDIUM vulnerabilities**: Maximum 20 allowed
- **LOW vulnerabilities**: Acceptable (document only)

### Scanning Requirements
1. All images must be scanned with Trivy or equivalent CVE scanner
2. Scans must be performed:
   - Before image is pushed to container registry
   - Weekly for all images in production use
   - When new CVEs are published affecting used packages

### Compliance Requirements
- **GDPR**: Images handling personal data must have zero CRITICAL vulnerabilities
- **PCI-DSS**: Images handling payment data must have zero CRITICAL and zero HIGH vulnerabilities
- **SOC2**: All scans must be logged with results retained for 1 year

### Exemption Process
If a vulnerability cannot be remediated immediately:
1. Create security exception ticket with justification
2. Implement compensating controls (network policies, WAF rules, etc.)
3. Get approval from security team
4. Document in security register
5. Schedule remediation within 30 days for CRITICAL, 90 days for HIGH

### Implementation in CI/CD
```
build image -> scan with Trivy -> check policy -> push to registry -> deploy
|
FAIL if policy violated
### Monitoring
- Weekly vulnerability reports sent to security team
- Automated alerts for newly discovered CVEs in running images
- Monthly security review of all exceptions

## Examples of Acceptable Images
- `nginx:1.24-alpine` - Latest stable, regularly updated
- `alpine:3.18` - Minimal attack surface
- Images from official repos with recent update dates

## Examples of Unacceptable Images
- `nginx:1.14` - EOL version with known CVEs
- Images with CRITICAL vulnerabilities
- Images from unknown/untrusted sources
- Images with outdated base OS (e.g., ubuntu:16.04)