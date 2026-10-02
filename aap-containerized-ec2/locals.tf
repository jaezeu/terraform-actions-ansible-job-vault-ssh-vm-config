locals {
  tags = merge(
    {
      Project   = "ansible-automation-platform"
      ManagedBy = "terraform"
    },
    var.tags,
  )

  azs            = slice(data.aws_availability_zones.available.names, 0, 1)
  public_subnets = [cidrsubnet(var.vpc_cidr, 8, 0)]

  create_key_pair      = var.ssh_public_key == ""
  ec2_ssh_key_filename = "${path.module}/ssh-key/${var.name}-ec2.pem"

  aap_admin_password        = var.aap_admin_password != "" ? var.aap_admin_password : random_password.aap_admin.result
  postgresql_admin_password = var.postgresql_admin_password != "" ? var.postgresql_admin_password : random_password.postgresql_admin.result

  # The containerized installer uses the inventory hostname as the TLS SAN and
  # the public URL of every component, so it must be the externally reachable name.
  aap_hostname = aws_eip.this.public_dns
  aap_url      = "https://${local.aap_hostname}"
}
