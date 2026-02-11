# Suggested Documentation Updates

## README.md Suggestions

### 1. Add Prerequisites Section Updates

The current prerequisites don't mention Route53 if DNS integration is desired. Add:

```markdown
+ (Optional) A [Route53 Hosted Zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html) if using `create_route53_vault_dns_record`
```

### 2. Add Supported Operating Systems Section

Add after Prerequisites:

```markdown
## Supported Operating Systems

This module supports the following Linux distributions via the `ec2_os_distro` variable:

| Distribution | Value | AMI Source |
|--------------|-------|------------|
| Ubuntu 22.04 LTS | `ubuntu` (default) | Canonical |
| RHEL 9 | `rhel` | Red Hat |
| Amazon Linux 2023 | `al2023` | Amazon |
| CentOS | `centos` | Custom AMI required |

> **Note:** For CentOS deployments, you must provide a custom AMI ID via `vm_image_id`.
```

### 3. Expand Troubleshooting Section

The current troubleshooting section is minimal. Suggested expansion:

```markdown
## Troubleshooting

### Viewing Installation Logs

During deployment, the output of the `user_data` script can be traced in:
- `/var/log/cloud-init.log` - Cloud-init execution log
- `/var/log/cloud-init-output.log` - Standard output from cloud-init
- `/var/log/vault-cloud-init.log` - Vault-specific installation log (due to `set -xeuo pipefail`)

### Common Issues

#### Raft Initialization Failure
If you see `could not start clustered storage: HeartbeatTimeout is too low`, ensure `vault_raft_performance_multiplier` is set between 1-10 (default is 5).

#### EBS Volume Mount Failures
The install script includes a 20-second delay for EBS attachment. If issues persist, check:
- EC2 instance has proper IAM permissions for `ec2:DescribeVolumes`
- EBS volumes are in the same availability zone as the instance

#### SSM Connection Issues
If using `ec2_allow_ssm = true` and SSM is not connecting:
- Ensure the AMI has the SSM agent installed
- Verify VPC endpoints for SSM exist or NAT gateway allows outbound traffic

#### base64 encoded secrets support.

If you encounter ` Error initializing listener of type tcp: error loading TLS cert: decoded PEM is blank` This indicates you have provided base64 encoded TLS secrets to the release `<= 2.0.`


### Debug Resources
- [AWS EC2 User Data Troubleshooting](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#userdata-linux)
- [Cloud-init Debugging Guide](https://cloudinit.readthedocs.io/en/latest/howto/debugging.html#cloud-init-ran-but-didn-t-do-what-it-want-it-to)
```

### 4. Add ARM64 Architecture Note (if applicable)

The install script supports ARM architecture detection. If ARM instances are supported, document this:

```markdown
## Architecture Support

This module supports both x86_64 (amd64) and ARM64 (aarch64) instances. The install script automatically detects the system architecture and downloads the appropriate Vault binary.
```

---

## docs/vault-deployment-customizations.md Suggestions

### 1. Add SSM Section

```markdown
## AWS Systems Manager (SSM) Access

To enable secure instance access via AWS Systems Manager Session Manager (instead of SSH), set:

\`\`\`hcl
ec2_allow_ssm = true
\`\`\`

This attaches the `AmazonSSMManagedInstanceCore` IAM policy to the Vault instance role. The AMI must have the SSM agent installed (Amazon Linux 2023 and Ubuntu official AMIs include it by default).

> **Note:** This is an alternative to SSH access and does not require opening port 22 or managing SSH keys.
```

### 2. Expand DNS Section with Examples

The current DNS section is good but could use a complete example:

```markdown
## DNS

This module supports creating an _alias_ record in AWS Route53 for the Vault FQDN to resolve to the Vault API load balancer DNS name.

### Basic Configuration

\`\`\`hcl
create_route53_vault_dns_record      = true
route53_vault_hosted_zone_name       = "example.com"
route53_vault_hosted_zone_is_private = false
\`\`\`

### Private Hosted Zone

For VPC-internal DNS resolution:

\`\`\`hcl
create_route53_vault_dns_record      = true
route53_vault_hosted_zone_name       = "internal.example.com"
route53_vault_hosted_zone_is_private = true
\`\`\`

> **Note:** Ensure `vault_fqdn` matches the desired DNS record name (e.g., `vault.example.com`).
```

### 3. Expand Custom AMI Section

```markdown
## Custom AMI

If you have a custom AWS AMI you would like to use, you can specify it via the following module input variables:

\`\`\`hcl
vm_image_id   = "<custom-ami-id>"
ec2_os_distro = "<matching-os-distro>"
\`\`\`

### Supported OS Distributions

| `ec2_os_distro` value | Description |
|----------------------|-------------|
| `ubuntu` | Ubuntu 22.04+ compatible |
| `rhel` | RHEL 9 compatible |
| `al2023` | Amazon Linux 2023 compatible |
| `centos` | CentOS (custom AMI required) |

### Important Notes

- The `ec2_os_distro` value **must** match your custom AMI's operating system to ensure the correct package manager is used during installation.
- For CentOS, you **must** provide a custom AMI via `vm_image_id` as there is no default CentOS AMI data source.
- AMI IDs must start with `ami-`.

### Example: RHEL Custom AMI

\`\`\`hcl
vm_image_id   = "ami-0123456789abcdef0"
ec2_os_distro = "rhel"
\`\`\`
```

### 4. Add Binary Verification Section

```markdown
## Binary Verification

The install script performs GPG signature and SHA256 checksum verification on the Vault binary:

1. Downloads HashiCorp's GPG public key from `https://www.hashicorp.com/.well-known/pgp-key.txt`
2. Downloads the binary, SHA256SUMS, and signature files
3. Verifies the signature file is authentic
4. Validates the binary checksum

This ensures the Vault binary has not been tampered with during download.

> **Note:** On Amazon Linux 2023, the script automatically installs `gnupg2-full` (replacing `gnupg2-minimal`) to enable GPG verification.
```

### 5. Expand Custom Startup Script Section

```markdown
## Custom startup script

While this is not recommended, this module supports the ability to use your own custom startup script to install Vault.

### Configuration

\`\`\`hcl
custom_startup_script_template = "my-custom-install.sh.tpl"
\`\`\`

### Requirements

1. The script **must** exist in a folder named `./templates/` within your current working directory
2. The script **must** contain all template variables used by the module (see default template for reference)
3. Use at your own risk - breaking changes to template variables may occur

### Template Variables

Your custom script must handle these template variables:

| Variable | Description |
|----------|-------------|
| `${systemd_dir}` | Path to systemd unit files |
| `${vault_dir_config}` | Vault configuration directory |
| `${vault_dir_home}` | Vault home directory |
| `${vault_version}` | Vault version to install |
| `${vault_fqdn}` | Fully qualified domain name |
| ... | See `templates/install-vault.sh.tpl` for complete list |

### Debugging Custom Scripts

1. Enable the local file render in `compute.tf` (commented out) to preview rendered output
2. Check `/var/log/vault-cloud-init.log` on deployed instances

> **Note:** If using Amazon Linux 2023, your script should handle the `gnupg2-minimal` to `gnupg2-full` swap for GPG verification to work.
```

---

## Now Merged Features Needing Documentation

### Cross-Zone Load Balancing (MERGED - PR #43)

Add to docs/vault-deployment-customizations.md:

```markdown
## Cross-Zone Load Balancing

By default, each load balancer node distributes traffic only to registered targets in its Availability Zone. Cross-zone load balancing enables the load balancer to distribute traffic across all registered targets in all enabled Availability Zones.

### Configuration

\`\`\`hcl
enable_cross_zone_load_balancing = true
\`\`\`

### When to Enable

- **Multi-AZ deployments**: When Vault nodes are distributed across multiple AZs and you want even traffic distribution
- **Uneven node distribution**: When the number of Vault nodes per AZ varies
- **High availability**: Ensures traffic continues to all healthy nodes even if one AZ has fewer instances

### Considerations

- Cross-zone load balancing may incur additional data transfer charges between AZs
- For symmetric AZ deployments (equal nodes per AZ), cross-zone load balancing is optional
```

### Base64 Secrets Manager Support (MERGED - PR #42)

Add to docs/vault-deployment-customizations.md:

```markdown
## AWS Secrets Manager Certificate Formats

The module supports TLS certificates stored in AWS Secrets Manager in two formats:

### Plain PEM Format
Store the certificate content directly as a string:
\`\`\`
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAJC...
-----END CERTIFICATE-----
\`\`\`

### Base64-Encoded Format (Recommended)
Store the certificate as a base64-encoded string. The install script automatically detects and decodes base64 content:
\`\`\`
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
\`\`\`

### Validation

The install script validates certificates after retrieval:
1. Checks the file is not empty (exit code 6)
2. Verifies the content contains PEM header (`-----BEGIN `) (exit code 7)
3. Fails with clear error messages if validation fails

### Troubleshooting Certificate Issues

If deployment fails with certificate errors, check `/var/log/vault-cloud-init.log` for:
- `Secret ARN cannot be empty` (exit code 5) - Secret ARN not provided
- `Certificate file is empty or missing` (exit code 6) - Secret retrieval failed
- `does not appear to contain PEM-formatted data` (exit code 7) - Content is not valid PEM format
```

### Load Balancer Security Groups (MERGED - PR #41)

Add to docs/vault-deployment-customizations.md:

```markdown
## Load Balancer Security

The module creates a dedicated security group for the Network Load Balancer, separate from the Vault instance security group.

### Controlling LB Access

To restrict which networks/services can access Vault via the load balancer:

\`\`\`hcl
# Allow specific CIDR blocks to access Vault via LB
net_ingress_lb_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]

# Allow specific security groups to access Vault via LB
net_ingress_lb_security_group_ids = ["sg-0123456789abcdef0"]
\`\`\`

### Using the LB Security Group Output

The module outputs the load balancer security group ID for use in downstream configurations:

\`\`\`hcl
output "vault_load_balancer_security_group_id" {
  value = module.vault.vault_load_balancer_security_group_id
}
\`\`\`

This can be used to:
- Add additional ingress rules from other security groups
- Reference in application security groups that need Vault access
```

### Security Group Rule Improvements (MERGED - PR #41)

Add to docs/vault-deployment-customizations.md:

```markdown
## Security Group Configuration

### Controlling Vault Instance Access

The module supports both CIDR-based and Security Group ID-based ingress rules:

\`\`\`hcl
# CIDR-based access to Vault API
net_ingress_vault_cidr_blocks = ["10.0.0.0/8"]

# Security group-based access to Vault API
net_ingress_vault_security_group_ids = ["sg-webapp", "sg-bastion"]

# CIDR-based SSH access
net_ingress_ssh_cidr_blocks = ["10.0.0.0/8"]

# Security group-based SSH access
net_ingress_ssh_security_group_ids = ["sg-bastion"]
\`\`\`

### Notes

- CIDR rules are only created if the corresponding variable contains values
- Security group ID rules use `for_each` for proper lifecycle management
- Vault instances allow API traffic (port 8200) from each other for `auto_join` discovery
```

---

## Summary of Documentation Gaps Found

| Gap | Location | Priority |
|-----|----------|----------|
| SSM support not documented | README + docs | High |
| Multi-OS support not documented | README | High |
| Cross-zone load balancing | docs | **High (NOW MERGED)** |
| Base64 secrets support | docs | **High (NOW MERGED)** |
| LB security group docs | docs | **High (NOW MERGED)** |
| Security group improvements | docs | **High (NOW MERGED)** |
| New output `vault_load_balancer_security_group_id` | README | **High (NOW MERGED)** |
| Binary verification not documented | docs | Medium |
| Route53 private zone example missing | docs | Medium |
| CentOS custom AMI requirement not clear | docs | Medium |
| ARM64 architecture support not mentioned | README | Low |
| Expanded troubleshooting | README | Medium |
| Template variables list for custom scripts | docs | Low |

---

## Merged PRs Summary

| PR | Branch | Feature | Documentation Status |
|----|--------|---------|---------------------|
| #43 | `feat/cross-zone-load-balancing` | NLB cross-zone support | **Needs docs** |
| #42 | N/A | Base64 certificate decode | **Needs docs** |
| #41 | `nphilbrook/main` | LB security group + SG improvements | **Needs docs** |
