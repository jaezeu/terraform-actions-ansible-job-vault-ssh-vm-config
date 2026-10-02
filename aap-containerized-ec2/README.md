# Ansible Automation Platform containerized install on a single RHEL EC2 instance

Terraform provisions a RHEL 9 EC2 host sized for the AAP containerized growth topology, renders the installer inventory, and a helper script runs the Red Hat containerized installer on the host. The result is a working platform gateway, automation controller, automation hub, and Event-Driven Ansible on one instance.

This folder is self-contained and can be moved into its own repository.

## What gets created

| Component | Source |
|-----------|--------|
| VPC with one public subnet, internet gateway, route table | [terraform-aws-modules/vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) |
| Security group allowing 443 and 22 from your CIDRs | [terraform-aws-modules/security-group](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws) |
| EC2 key pair, generated locally if you do not supply one | [terraform-aws-modules/key-pair](https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws) |
| RHEL 9 EC2 instance with encrypted gp3 root volume, IMDSv2, SSM instance profile | [terraform-aws-modules/ec2-instance](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws) |
| Elastic IP so the AAP hostname survives reboots | `aws_eip` |
| Installer inventory with generated passwords | `local_sensitive_file` in `generated/` |

The installer itself is not run by Terraform. The setup bundle must be downloaded from the Red Hat Customer Portal with your own subscription, so it is handled by `scripts/install-aap.sh` after the apply.

## Prerequisites

- Terraform 1.10 or later and AWS credentials with permission to create VPC, EC2, and IAM resources.
- A Red Hat account with an AAP subscription. A free 60-day trial is sufficient.
- The AAP containerized setup bundle for your version, downloaded from the [Red Hat Customer Portal](https://access.redhat.com/downloads/content/480). Pick the file named `ansible-automation-platform-containerized-setup-bundle-<version>-x86_64.tar.gz`.
- A [registry.redhat.io service account](https://access.redhat.com/terms-based-registry/) for pulling container images.
- `ssh`, `scp`, and `bash` on your workstation.

## Deploy

Step 1: Copy the example variables and fill in your values.

```bash
cp terraform.tfvars.example terraform.tfvars
```

Set `allowed_cidrs` and `ssh_allowed_cidrs` to your own public IP. Set `registry_username` and `registry_password` to your registry service account.

Step 2: Apply.

```bash
terraform init
terraform apply
```

The apply writes the SSH private key to `ssh-key/` and the installer inventory to `generated/inventory`. Both are gitignored.

Step 3: Run the installer, passing the path to the downloaded bundle.

```bash
chmod +x scripts/*.sh
./scripts/install-aap.sh ~/Downloads/ansible-automation-platform-containerized-setup-bundle-2.5-15-x86_64.tar.gz
```

The script waits for cloud-init to finish, copies the bundle and inventory to the host, and runs the installer playbook. Expect 20 to 40 minutes.

Step 4: Log in and attach a subscription.

```bash
terraform output aap_url
terraform output -raw aap_admin_password
```

Open the URL, accept the self-signed certificate, and log in as `admin`. On first login the platform gateway asks for a subscription. Use your Red Hat account credentials or upload a manifest.

## Using this with the Terraform Actions demo

The parent repository's step 05 playbook and step 06 Terraform both expect an existing controller. Point them at this instance:

```bash
export CONTROLLER_HOST="$(terraform output -raw aap_url)"
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD="$(terraform output -raw aap_admin_password)"
```

For step 06 set `aap_host`, `aap_username`, and `aap_password` in its `terraform.tfvars` to the same values. The certificate is self-signed, so keep `controller_validate_certs: false` in the playbooks.

## Variables

| Name | Default | Description |
|------|---------|-------------|
| `region` | `us-east-1` | AWS region |
| `name` | `aap` | Resource name prefix |
| `vpc_cidr` | `10.10.0.0/16` | VPC CIDR |
| `allowed_cidrs` | `["0.0.0.0/0"]` | CIDRs allowed to reach 443 |
| `ssh_allowed_cidrs` | `["0.0.0.0/0"]` | CIDRs allowed to reach 22. Empty list disables SSH ingress |
| `instance_type` | `m6i.xlarge` | 4 vCPU and 16 GiB is the documented minimum |
| `root_volume_size` | `120` | Root volume in GiB, minimum 60 |
| `rhel_ami_name_filter` | `RHEL-9.6*_HVM-*-x86_64-*-Hourly2-GP3` | Red Hat published AMI filter |
| `ssh_public_key` | `""` | Supply to use your own key instead of a generated one |
| `registry_username` | required | registry.redhat.io username |
| `registry_password` | required | registry.redhat.io password |
| `aap_admin_password` | `""` | Generated when empty |
| `postgresql_admin_password` | `""` | Generated when empty |
| `install_automation_hub` | `true` | Include automation hub |
| `install_eda` | `true` | Include Event-Driven Ansible |
| `tags` | `{}` | Extra tags |

## Operations

Re-run the installer after changing the inventory:

```bash
terraform apply
./scripts/install-aap.sh <bundle>
```

Remove AAP from the host but keep the instance:

```bash
./scripts/uninstall-aap.sh
```

SSH without opening port 22, using SSM Session Manager:

```bash
aws ssm start-session --target "$(terraform output -raw instance_id)"
```

## Cleanup

```bash
terraform destroy
```

This removes the instance, Elastic IP, security group, VPC, key pair, and IAM role. Delete `ssh-key/` and `generated/` locally if you no longer need them.

## Security notes

- The default CIDRs are open to the internet for convenience. Narrow them before applying.
- Passwords live in Terraform state and in `generated/inventory`. Use a remote backend with encryption and never commit either file.
- The installer issues a self-signed certificate for the Elastic IP's public DNS name. For a stable, trusted endpoint, point a DNS record at the Elastic IP and pass your own certificates through the installer inventory variables.
- The RHEL hourly AMI includes the OS subscription through Red Hat Update Infrastructure. AAP itself still needs a subscription attached in the UI after install.
