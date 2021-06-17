resource "nsxt_lb_http_monitor" "healthwatch-web" {
  description           = "The Active Health Monitor (healthcheck) for Healthwatch HTTP traffic."
  display_name          = "${var.environment_name}-healthwatch-web-monitor"
  monitor_port          = 8080
  request_method        = "GET"
  request_url           = "/health"
  request_version       = "HTTP_VERSION_1_1"
  response_status_codes = [200]

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_http_monitor" "healthwatch-https" {
  description           = "The Active Health Monitor (healthcheck) for Healthwatch HTTPS traffic."
  display_name          = "${var.environment_name}-healthwatch-https-monitor"
  monitor_port          = 8080
  request_method        = "GET"
  request_url           = "/health"
  request_version       = "HTTP_VERSION_1_1"
  response_status_codes = [200]

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_lb_pool" "healthwatch-web" {
  description              = "The Server Pool of Healthwatch HTTP traffic handling VMs"
  display_name             = "${var.environment_name}-healthwatch-web-pool"
  algorithm                = "ROUND_ROBIN"
  tcp_multiplexing_enabled = false
  active_monitor_id        = nsxt_lb_http_monitor.healthwatch-web.id

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
  active_monitor_id        = nsxt_lb_http_monitor.healthwatch-https.id

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
  logical_router_id = nsxt_logical_tier1_router.t1_deployment.id
  size              = "SMALL"
  virtual_server_ids = [
    nsxt_lb_tcp_virtual_server.lb_healthwatch_web_virtual_server.id,
    nsxt_lb_tcp_virtual_server.lb_healthwatch_https_virtual_server.id
  ]

  depends_on = [
    nsxt_logical_router_link_port_on_tier1.t1_infrastructure_to_t0,
    nsxt_logical_router_link_port_on_tier1.t1_deployment_to_t0,
  ]

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}
