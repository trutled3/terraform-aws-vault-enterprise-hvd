# Release Notes - v0.3.0

## Overview

This release includes significant improvements to multi-OS support, enhanced binary verification, AWS SSM integration, Route53 DNS support, cross-zone load balancing, improved security group management, base64-encoded secrets support, and several bug fixes for Vault deployment on AWS EC2.

## Breaking changes

### Raft performance multiplier default changed

- **Previous default**: `0` (use Vault default)
- **New default**: `5` (explicit Vault default value)
- **Reason**: The previous default of `0` prevented Vault from initializing with the error: `could not start clustered storage: HeartbeatTimeout is too low`
- **Migration**: If you were relying on the default, no action needed. If you explicitly set `vault_raft_performance_multiplier = 0`, update to a value between `1` and `10`.
- **Related issue**: <https://github.com/hashicorp/vault/pull/30511>

### AWS Provider Version Constraint

- **Supported versions**: `>= 5.0` (reverted from temporarily pinned `~> 5.0`)
- AWS Provider 6.x introduces deprecation warnings but is now supported for customers comfortable with those warnings

## New Features

### Multi-OS Distribution Support

New `ec2_os_distro` variable supports multiple Linux distributions:

- `ubuntu` (default) - Ubuntu 22.04 LTS
- `rhel` - Red Hat Enterprise Linux 9
- `al2023` - Amazon Linux 2023
- `centos` - CentOS (requires custom AMI via `vm_image_id`)

Each OS has dedicated AMI data source filters ensuring the correct latest AMI is selected.

### Custom AMI Support

Enhanced `vm_image_id` variable now includes:

- Validation to ensure AMI IDs start with `ami-`
- Requirement for CentOS: must provide custom AMI when `ec2_os_distro = "centos"`
- Automatic coordination with `ec2_os_distro` for proper install script behavior

### Route53 DNS Integration

New native support for creating Route53 alias records:

- `create_route53_vault_dns_record` - Enable Route53 alias record creation
- `route53_vault_hosted_zone_name` - Hosted zone name for the alias record
- `route53_vault_hosted_zone_is_private` - Support for private hosted zones

### AWS Systems Manager (SSM) Support

New `ec2_allow_ssm` variable enables SSM agent connectivity:

- Attaches `AmazonSSMManagedInstanceCore` managed policy to Vault IAM role
- Supports secure instance access without SSH

### Custom Startup Script Template

New `custom_startup_script_template` variable allows:

- Use of custom install scripts located in `./templates/` directory
- Full control over Vault installation process
- Script must include all required template variables

### Architecture Detection

Install script now automatically detects system architecture:

- `linux_amd64` (x86_64)
- `linux_arm64` (aarch64)
- `linux_arm` (arm)

### Binary Checksum Verification

Enhanced security with GPG signature and SHA256 checksum verification:

- Downloads and imports HashiCorp GPG public key
- Verifies SHA256SUMS signature file
- Validates binary checksum before installation
- Graceful handling of both `sha256sum` and `shasum` utilities

### Cross-Zone Load Balancing

New `enable_cross_zone_load_balancing` variable for Network Load Balancer:

- Distributes traffic evenly across all registered targets in all enabled Availability Zones
- Default: `false`
- Recommended for production multi-AZ deployments

```hcl
enable_cross_zone_load_balancing = true
```

### Base64-Encoded Secrets Manager Support

Enhanced TLS certificate retrieval with automatic format detection:

- **Auto-detection**: Automatically detects and decodes base64-encoded certificate secrets
- **Validation**: Validates certificates contain valid PEM-formatted data after retrieval
- **Error handling**: Fails gracefully with clear error messages (exit codes 5-7) if certificates are empty or invalid
- Supports both raw PEM and base64-encoded certificate values in Secrets Manager
- Variable descriptions updated to recommend base64-encoded storage

### Load Balancer Security Group

New dedicated security group for the load balancer with improved access controls:

- `net_ingress_lb_cidr_blocks` - CIDR blocks allowed to access Vault via LB
- `net_ingress_lb_security_group_ids` - Security group IDs allowed to access Vault via LB
- New output `vault_load_balancer_security_group_id` for downstream security group rules
- Proper egress rule from LB to Vault instances on API port

### Security Group Rule Improvements

Enhanced security group rules with conditional creation and `for_each`:

- `net_ingress_vault_security_group_ids` - Now creates rules per security group ID (using `for_each`)
- `net_ingress_ssh_security_group_ids` - Now creates rules per security group ID (using `for_each`)
- SSH and Vault API CIDR rules only created when CIDRs are provided
- Added self-referencing rule for Vault API port (8200) to support `auto_join`
- Uses `var.vault_port_api` instead of hardcoded `8200`

## Improvements

### Install Script Enhancements

- **Certificate handling**: New `retrieve_certs_from_awssm` function with base64 auto-detection and PEM validation
- **Package management**: Separated Amazon Linux 2023 package handling, enabling `gnupg2-full` swap from `gnupg2-minimal`
- **Binary deployment**: Improved permissions setting and symlink creation to `/usr/local/bin/vault`
- **Logging**: Enhanced logging throughout the installation process
- **Error handling**: Better error messages for unsupported architectures, failed verifications, and certificate issues (exit codes 5-7)
- **Disk preparation**: Added 20-second delay for EBS volume attachment reliability
- **EBS detection**: Added error handling when no EBS volume is found attached
- **CLI config**: Uses `var.vault_port_api` instead of hardcoded port in profile script

### User Data Compression

- Changed from `base64encode` to `base64gzip` for user data, reducing payload size

### Data Source Improvements

- Added `aws_partition` data source for proper ARN construction across partitions (commercial, GovCloud, China)
- Refactored AMI selection with conditional data sources based on `ec2_os_distro`
- Added `aws_ami.selected` data source to query the specific AMI being used

### Code Quality

- Removed commented-out code in `locals.tf`
- Fixed errant TFE references in templates (changed to Vault)
- Standardized template directive spacing in outputs

## Bug Fixes

- **Raft initialization failure**: Fixed default `vault_raft_performance_multiplier` causing Vault cluster to fail initialization
- **EBS attachment timing**: Added delay to prevent race condition when mounting EBS volumes
- **Missing EBS volume handling**: Added explicit error when expected EBS volume is not found
- **OS distro case sensitivity**: Fixed inconsistent variable casing in package installation logic

## Compliance & Infrastructure

- Updated copyright headers (compliance batch update)
- Added GitHub workflow permissions for releases
- Added release task workflow
- Template sync from upstream

## Documentation

- Added troubleshooting section to main README with links to cloud-init debugging resources
- Enhanced docs for Custom AMI deployment
- Added DNS Route53 configuration documentation
- Added custom startup script documentation
- Added AL2023 gnupg2 note

## Dependencies

| Dependency   | Version  |
|--------------|----------|
| AWS Provider |  >= 5.0  |

## Upgrade Guide

### From 0.2.0 to 0.3.0

1. **Review Raft Performance Multiplier**: If you had issues with cluster initialization, no changes needed - the new default fixes this. If you explicitly set this to `0`, update to a value between `1-10`.

2. **OS Distribution Selection**: If using the default Ubuntu AMI, no changes needed. To use a different OS:

   ```hcl
   ec2_os_distro = "rhel"  # or "al2023", "centos"
   ```

3. **Custom AMI Users**: If using `vm_image_id`, ensure `ec2_os_distro` matches your AMI's OS:

   ```hcl
   vm_image_id   = "ami-0123456789abcdef0"
   ec2_os_distro = "rhel"
   ```

4. **Route53 DNS (Optional)**: To enable Route53 alias records:

   ```hcl
   create_route53_vault_dns_record      = true
   route53_vault_hosted_zone_name       = "example.com"
   route53_vault_hosted_zone_is_private = false
   ```

5. **SSM Access (Optional)**: To enable AWS Systems Manager:

   ```hcl
   ec2_allow_ssm = true
   ```

6. **Cross-Zone Load Balancing (Optional)**: For multi-AZ deployments:

   ```hcl
   enable_cross_zone_load_balancing = true
   ```

7. **Load Balancer Security Group**: If you need to add custom ingress rules to the LB:

   ```hcl
   net_ingress_lb_cidr_blocks         = ["10.0.0.0/8"]
   net_ingress_lb_security_group_ids  = ["sg-0123456789abcdef0"]
   ```

   The new output `vault_load_balancer_security_group_id` can be used to create additional downstream rules.

8. **TLS Certificates in Secrets Manager**: Certificates are now recommended to be stored as base64-encoded strings. Both raw PEM and base64-encoded formats are supported (auto-detected).

## Contributors

Thanks to all contributors to this release!

- **Adam Buxton** ([@abuxton](https://github.com/abuxton))
- **Dan Brown** ([@danbr-ibm](https://github.com/danbr-ibm))
- **Jeff McCollum** ([@jeffmccollum](https://github.com/jeffmccollum))
- **Johnny Carlin** ([@thejohnny](https://github.com/thejohnny))
- **Mark Lewis** ([@lewis4](https://github.com/lewis4))
- **nhsy-hcp** ([@nhsy-hcp](https://github.com/nhsy-hcp))
- **Nick Philbrook** ([@nphilbrook](https://github.com/nphilbrook))
- **pjohnson24** ([@pjohnson24](https://github.com/pjohnson24))

### Automated Contributors

- hashicorp-copywrite[bot] - Compliance automation
- actions-template-sync - Template synchronization
