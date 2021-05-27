locals {
  stable_config_opsmanager = {
    environment_name = var.environment_name
    
    nsxt_host     = var.nsxt_host
    nsxt_username = var.nsxt_username
    nsxt_password = var.nsxt_password

    ops_manager_ssh_public_key  = tls_private_key.ops-manager.public_key_openssh
    ops_manager_ssh_private_key = tls_private_key.ops-manager.private_key_pem
    ops_manager_public_ip       = var.ops_manager_public_ip
    ops_manager_private_ip      = nsxt_nat_rule.dnat_om.translated_network

    infrastructure_subnet_name               = nsxt_logical_switch.infrastructure_ls.display_name
    infrastructure_subnet_cidr               = "${var.subnet_prefix}.1.0/24"
    infrastructure_subnet_gateway            = "${var.subnet_prefix}.1.1"
    infrastructure_subnet_reserved_ip_ranges = "${var.subnet_prefix}.1.1-${var.subnet_prefix}.1.10"

    allow_unverified_ssl      = var.allow_unverified_ssl
    disable_ssl_verification  = !var.allow_unverified_ssl
  }
}

output "stable_config_opsmanager" {
  value     = jsonencode(local.stable_config_opsmanager)
  sensitive = true
}
