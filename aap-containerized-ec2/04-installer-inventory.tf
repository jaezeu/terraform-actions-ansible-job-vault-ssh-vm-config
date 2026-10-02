resource "random_password" "aap_admin" {
  length  = 24
  special = false
}

resource "random_password" "postgresql_admin" {
  length  = 24
  special = false
}

# Rendered AAP containerized installer inventory. Copied to the host by
# scripts/install-aap.sh. Treated as sensitive because it embeds passwords.
resource "local_sensitive_file" "installer_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    aap_hostname              = local.aap_hostname
    aap_admin_password        = local.aap_admin_password
    postgresql_admin_password = local.postgresql_admin_password
    registry_username         = var.registry_username
    registry_password         = var.registry_password
    install_automation_hub    = var.install_automation_hub
    install_eda               = var.install_eda
  })
  filename        = "${path.module}/generated/inventory"
  file_permission = "0600"
}
