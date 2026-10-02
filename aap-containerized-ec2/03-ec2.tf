module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name           = "${var.name}-ec2"
  create_private_key = local.create_key_pair
  public_key         = local.create_key_pair ? null : var.ssh_public_key
}

resource "local_sensitive_file" "private_key" {
  count = local.create_key_pair ? 1 : 0

  content         = module.key_pair.private_key_pem
  filename        = local.ec2_ssh_key_filename
  file_permission = "0400"
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = "${var.name}-ec2"

  ami                    = data.aws_ami.rhel.id
  instance_type          = var.instance_type
  key_name               = module.key_pair.key_pair_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.security_group.security_group_id]

  # Public connectivity is provided by the Elastic IP below.
  associate_public_ip_address = false

  user_data_base64            = base64encode(file("${path.module}/templates/cloud-init.yaml"))
  user_data_replace_on_change = false

  # IMDSv2 only.
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # SSM Session Manager access without opening SSH.
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for the AAP EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  enable_volume_tags = false
  root_block_device = {
    type                  = "gp3"
    size                  = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
    tags                  = { Name = "${var.name}-ec2-root" }
  }
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = { Name = "${var.name}-eip" }

  depends_on = [module.vpc]
}

resource "aws_eip_association" "this" {
  instance_id   = module.ec2.id
  allocation_id = aws_eip.this.id
}
