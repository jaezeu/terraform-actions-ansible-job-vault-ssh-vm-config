module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.name}-sg"
  description = "Security group for the Ansible Automation Platform host"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = concat(
    [
      for cidr in var.allowed_cidrs : {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        description = "AAP gateway HTTPS from ${cidr}"
        cidr_blocks = cidr
      }
    ],
    [
      for cidr in var.ssh_allowed_cidrs : {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "SSH from ${cidr}"
        cidr_blocks = cidr
      }
    ],
  )

  # The installer pulls images from registry.redhat.io and packages from RHUI.
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
