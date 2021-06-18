# This sets up a load balancer on the services network for the
# sole purpose of allowing us to deploy Healthwatch on that network.

resource "nsxt_lb_pool" "healthwatch-web" {
  description              = "The Server Pool of Healthwatch HTTP traffic handling VMs"
  display_name             = "${var.environment_name}-healthwatch-web-pool"
  algorithm                = "ROUND_ROBIN"
  tcp_multiplexing_enabled = false

  snat_translation {
    type = "SNAT_AUTO_MAP"
  }

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_pool" "healthwatch-https" {
  description              = "The Server Pool of Healthwatch HTTPS traffic handling VMs"
  display_name             = "${var.environment_name}-healthwatch-https-pool"
  algorithm                = "ROUND_ROBIN"
  tcp_multiplexing_enabled = false

  snat_translation {
    type = "SNAT_AUTO_MAP"
  }

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_fast_tcp_application_profile" "healthwatch_lb_tcp_application_profile" {
  display_name  = "${var.environment_name}-healthwatch-lb-tcp-application-profile"
  close_timeout = "8"
  idle_timeout  = "1800"

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_tcp_virtual_server" "lb_healthwatch_web_virtual_server" {
  description            = "The Virtual Server for Healthwatch HTTP traffic"
  display_name           = "${var.environment_name}-healthwatch-web-vs"
  application_profile_id = nsxt_lb_fast_tcp_application_profile.healthwatch_lb_tcp_application_profile.id
  ip_address             = var.nsxt_lb_healthwatch_virtual_server_ip_address
  ports                  = ["80"]
  pool_id                = nsxt_lb_pool.healthwatch-web.id

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_tcp_virtual_server" "lb_healthwatch_https_virtual_server" {
  description            = "The Virtual Server for Healthwatch HTTPS traffic"
  display_name           = "${var.environment_name}-healthwatch-https-vs"
  application_profile_id = nsxt_lb_fast_tcp_application_profile.healthwatch_lb_tcp_application_profile.id
  ip_address             = var.nsxt_lb_healthwatch_virtual_server_ip_address
  ports                  = ["443"]
  pool_id                = nsxt_lb_pool.healthwatch-https.id

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_service" "healthwatch_lb" {
  description  = "The Load Balancer for handling Healthwatch traffic."
  display_name = "${var.environment_name}-healthwatch-lb"

  enabled           = true
  logical_router_id = nsxt_logical_tier1_router.t1_services.id
  size              = "SMALL"
  virtual_server_ids = [
    nsxt_lb_tcp_virtual_server.lb_healthwatch_web_virtual_server.id,
    nsxt_lb_tcp_virtual_server.lb_healthwatch_https_virtual_server.id
  ]

  depends_on = [
    nsxt_logical_router_link_port_on_tier1.t1_infrastructure_to_t0,
    nsxt_logical_router_link_port_on_tier1.t1_services_to_t0,
  ]

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

variable "nsxt_lb_healthwatch_virtual_server_ip_address" {
  description = "The ip address on which the Virtual Server listens for Healthwatch (Grafana dashboard) traffic, should be in the same subnet as the external IP pool, but not in the range of available IP addresses, e.g. `10.195.74.20`"
  type        = string
}

locals {
  healthwatch_config = {
    lb_pool_web = nsxt_lb_pool.healthwatch-web.display_name
    lb_pool_https = nsxt_lb_pool.healthwatch-https.display_name
  }
}

output "healthwatch_config" {
  value = local.healthwatch_config
}

