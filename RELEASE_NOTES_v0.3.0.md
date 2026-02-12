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

### AWS provider version constraint

- **Supported versions**: `>= 5.0` (reverted from temporarily pinned `~> 5.0`).
- AWS provider 6.x introduces deprecation warnings but is now supported for customers comfortable with those warnings.

## New features

### Multi-OS distribution support

New `ec2_os_distro` variable supports multiple Linux distributions.

- `ubuntu` (default) - Ubuntu 22.04 LTS
- `rhel` - Red Hat Enterprise Linux 9
- `al2023` - Amazon Linux 2023
- `centos` - CentOS (requires custom AMI via `vm_image_id`)

Each OS has dedicated AMI data source filters ensuring the correct latest AMI is selected.

### Custom AMI support

Enhanced `vm_image_id` variable now includes the following.

- Validation to ensure AMI IDs start with `ami-`
- Requirement for CentOS: must provide custom AMI when `ec2_os_distro = "centos"`
- Automatic coordination with `ec2_os_distro` for proper install script behavior

### Route53 DNS integration

New native support for creating the following Route53 alias records.

- `create_route53_vault_dns_record` - Enable Route53 alias record creation.
- `route53_vault_hosted_zone_name` - Hosted zone name for the alias record.
- `route53_vault_hosted_zone_is_private` - Support for private hosted zones.

### AWS Systems Manager (SSM) Support

New `ec2_allow_ssm` variable enables SSM agent connectivity:

- Attaches `AmazonSSMManagedInstanceCore` managed policy to Vault IAM role
- Supports secure instance access without SSH

### Custom startup script template

New `custom_startup_script_template` variable allows the following.

- Use of custom install scripts located in `./templates/` directory.
- Full control over Vault installation process.
- Script must include all required template variables.

### Architecture detection

The install script now automatically detects the system architecture as one of the following.

- `linux_amd64` (x86_64)
- `linux_arm64` (aarch64)
- `linux_arm` (arm)

### Binary checksum verification

Enhanced security with GPG signature and SHA256 checksum verification is now included and performs the following functions.

- Downloads and imports the HashiCorp GPG public key
- Verifies SHA256SUMS signature file
- Validates binary checksum before installation
- Graceful handling of both `sha256sum` and `shasum` utilities

### Cross-zone load balancing

New `enable_cross_zone_load_balancing` variable for Network Load Balancer:

- Distributes traffic evenly across all registered targets in all enabled availability zones.
- Default: `false`
- Recommended for production multi-AZ deployments

```hcl
enable_cross_zone_load_balancing = true
```

### Base64-encoded secrets manager support

Enhanced TLS certificate retrieval with automatic format detection:

- **Auto-detection**: Automatically detects and decodes base64-encoded certificate secrets.
- **Validation**: Validates certificates contain valid PEM-formatted data after retrieval.
- **Error handling**: Fails gracefully with clear error messages (exit codes 5-7) if certificates are empty or invalid.
- Supports both raw PEM and base64-encoded certificate values in AWS Secrets Manager.
- Variable descriptions updated to recommend base64-encoded storage.

### Load balancer security group

New dedicated security group for the load balancer with improved access controls are included with this release.

- `net_ingress_lb_cidr_blocks` - Provided to allow the specification of CIDR blocks allowed to access Vault via the load balancer.
- `net_ingress_lb_security_group_ids` - Allows specification of  security group IDs allowed to access Vault via the load balancer.
- New output `vault_load_balancer_security_group_id` for downstream security group rules.
- Proper egress rule from load balancer to Vault instances on API port.

### Security group rule improvements

Enhanced security group rules with conditional creation and use of the `for_each` argument.

- `net_ingress_vault_security_group_ids` - Now creates rules per security group ID (using `for_each`).
- `net_ingress_ssh_security_group_ids` - Now creates rules per security group ID (using `for_each`).
- SSH and Vault API CIDR rules are only created when CIDRs are provided.
- Added self-referencing rule for Vault API port (8200) to support `auto_join`.
- Uses `var.vault_port_api` instead of hardcoded `8200`.

## Improvements

### Install script enhancements

- **Certificate handling**: New `retrieve_certs_from_awssm` function with base64 auto-detection and PEM validation.
- **Package management**: Separated Amazon Linux 2023 package handling, enabling `gnupg2-full` swap from `gnupg2-minimal`.
- **Binary deployment**: Improved permissions setting and symlink creation to `/usr/local/bin/vault`.
- **Logging**: Enhanced logging throughout the installation process.
- **Error handling**: Better error messages for unsupported architectures, failed verifications, and certificate issues (exit codes 5-7).
- **Disk preparation**: Added 20-second delay for EBS volume attachment reliability.
- **EBS detection**: Added error handling when no EBS volume is found attached.
- **CLI config**: Uses `var.vault_port_api` instead of hard-coded port in profile script.

### User data compression

- Changed from `base64encode` to `base64gzip` for user data, reducing payload size.

### Data source improvements

- Added `aws_partition` data source for proper ARN construction across partitions (commercial, GovCloud, China).
- Refactored AMI selection with conditional data sources based on `ec2_os_distro`.
- Added `aws_ami.selected` data source to query the specific AMI being used.

### Code quality

- Removed commented-out code in `locals.tf`
- Fixed errant TFE references in templates (changed to Vault)
- Standardized template directive spacing in outputs

## Bug fixes

- **Raft initialization failure**: Fixed default `vault_raft_performance_multiplier` causing Vault cluster to fail initialization
- **EBS attachment timing**: Added delay to prevent race condition when mounting EBS volumes
- **Missing EBS volume handling**: Added explicit error when expected EBS volume is not found
- **OS distro case sensitivity**: Fixed inconsistent variable casing in package installation logic

## Compliance and infrastructure

- Updated copyright headers (compliance batch update)
- Added GitHub workflow permissions for releases
- Added release task workflow
- Template sync from upstream

## Documentation

- Added troubleshooting section to main README with links to cloud-init debugging resources.
- Enhanced docs for Custom AMI deployment.
- Added DNS Route53 configuration documentation.
- Added custom startup script documentation.
- Added AL2023 gnupg2 note.

## Dependencies

| Dependency   | Version  |
|--------------|----------|
| AWS Provider |  >= 5.0  |

## Upgrade Guide

### From 0.2.0 to 0.3.0

1. **Review Raft performance multiplier**: If you had issues with cluster initialization, no changes needed - the new default fixes this. If you explicitly set this to `0`, update to a value between `1-10`.

1. **OS distribution selection**: If using the default Ubuntu AMI, no changes needed. To use a different OS, use the following.

   ```hcl
   ec2_os_distro = "rhel"  # or "al2023", "centos"

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

### Automated contributors

- hashicorp-copywrite[bot] - Compliance automation
- actions-template-sync - Template synchronization
