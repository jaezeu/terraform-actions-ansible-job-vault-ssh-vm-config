output "instance_id" {
  description = "ID of the AAP EC2 instance"
  value       = module.ec2.id
}

output "public_ip" {
  description = "Elastic IP of the AAP EC2 instance"
  value       = aws_eip.this.public_ip
}

output "public_dns" {
  description = "Public DNS name used as the AAP hostname in the installer inventory"
  value       = local.aap_hostname
}

output "aap_url" {
  description = "URL of the AAP platform gateway once the installer has completed"
  value       = local.aap_url
}

output "aap_admin_username" {
  description = "AAP admin username"
  value       = "admin"
}

output "aap_admin_password" {
  description = "AAP admin password"
  value       = local.aap_admin_password
  sensitive   = true
}

output "ssh_user" {
  description = "SSH user for the RHEL instance"
  value       = "ec2-user"
}

output "ssh_private_key_path" {
  description = "Path to the generated SSH private key, if one was created"
  value       = local.create_key_pair ? local.ec2_ssh_key_filename : null
}

output "ssh_command" {
  description = "SSH command to reach the instance"
  value       = "ssh -i ${local.create_key_pair ? local.ec2_ssh_key_filename : "<your-private-key>"} ec2-user@${aws_eip.this.public_ip}"
}

output "installer_inventory_path" {
  description = "Path to the rendered installer inventory"
  value       = local_sensitive_file.installer_inventory.filename
}
