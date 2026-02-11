# Deployment Troubleshooting

## Viewing Installation Logs

During deployment, the output of the `user_data` script can be traced in:
- `/var/log/cloud-init.log` - Cloud-init execution log
- `/var/log/cloud-init-output.log` - Standard output from cloud-init
- `/var/log/vault-cloud-init.log` - Vault-specific installation log (due to `set -xeuo pipefail`)

## Common Issues

### Raft Initialization Failure

If you see `could not start clustered storage: HeartbeatTimeout is too low`, ensure `vault_raft_performance_multiplier` is set between 1-10 (default is 5).

### EBS Volume Mount Failures

The install script includes a 20-second delay for EBS attachment. If issues persist, check:
- EC2 instance has proper IAM permissions for `ec2:DescribeVolumes`
- EBS volumes are in the same availability zone as the instance

### SSM Connection Issues

If using `ec2_allow_ssm = true` and SSM is not connecting:
- Ensure the AMI has the SSM agent installed
- Verify VPC endpoints for SSM exist or NAT gateway allows outbound traffic

### Base64 Encoded Secrets Support

If you encounter `Error initializing listener of type tcp: error loading TLS cert: decoded PEM is blank`, this indicates you have provided base64 encoded TLS secrets to a release `<= 2.0`. Update to the latest version which includes automatic base64 decoding support.

## Debug Resources

- [AWS EC2 User Data Troubleshooting](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#userdata-linux)
- [Cloud-init Debugging Guide](https://cloudinit.readthedocs.io/en/latest/howto/debugging.html#cloud-init-ran-but-didn-t-do-what-it-want-it-to)
