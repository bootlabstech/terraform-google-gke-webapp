# Creating Load Balancer
resource "google_compute_backend_service" "backend_service" {
  project               = var.project_id
  name                  = "${var.name}-backend-service"
  protocol              = var.protocol
  health_checks         = var.health_checks
  load_balancing_scheme = var.load_balancing_scheme
  backend {
    group = var.group
  }
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  project               = var.project_id
  name                  = "${var.name}-forwarding-rule"
  target                = google_compute_target_http_proxy.target-proxy.id
  ip_protocol           = var.ip_protocol
  load_balancing_scheme = var.load_balancing_scheme
  port_range            = var.port_range
  ip_address            = var.ip_address
  network               = var.network
  depends_on = [
    google_compute_target_http_proxy.target-proxy
  ]
}

resource "google_compute_target_http_proxy" "target-proxy" {
  project = var.project_id
  name    = "${var.name}-target-proxy"
  url_map = google_compute_url_map.url_map.id
  depends_on = [
    google_compute_url_map.url_map
  ]
}

resource "google_compute_url_map" "url_map" {
  project         = var.project_id
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.backend_service.id
  depends_on = [
    google_compute_backend_service.backend_service
  ]
}

# Creating SQL Database

resource "random_string" "sql_server_suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "random_password" "sql_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  number           = true
  override_special = "-_!#^~%@"
}

resource "google_sql_user" "users" {
  name     = var.db_root_username
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  password = random_password.sql_password.result
}

# resource "google_compute_global_address" "private_ip_address" {

#   name          = var.private_ip_address_name
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   project       = var.shared_vpc_project
#   prefix_length = 16
#   network       = var.network_id
# }

# resource "google_compute_address" "private_ip_address" {
#   count = "${var.create_peering_range && var.subnetwork_id != "" ? 1 : 0}"
#   name          = var.private_ip_address_name
#   prefix_length = 16
#   project       = var.shared_vpc_project_id
#   subnetwork    = var.subnetwork_id
#   address_type  = "INTERNAL"
#   purpose       = "VPC_PEERING"
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   count = "${var.create_peering_range ? 1 : 0}"
#   network                 = var.network_id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_address.private_ip_address.name]
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = var.network_id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = var.reserved_peering_ranges
# }

resource "google_sql_database_instance" "instance" {
  #ts:skip=AC_GCP_0003 DB SSL needs application level changes
  provider            = google-beta
  name                = "${var.instance_name}-${random_string.sql_server_suffix.id}"
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.deletion_protection
  root_password       = random_password.sql_password.result
  encryption_key_name = var.encryption_key_name == "" ? null : var.encryption_key_name

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    backup_configuration {
      enabled            = var.backup_enabled
      start_time         = var.backup_start_time
      binary_log_enabled = var.binary_log_enabled
    }

    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = var.network_id
    }

    # dynamic "database_flags" {
    #   for_each = var.database_flags
    #   content {
    #     name  = database_flags.value.name
    #     value = database_flags.value.value
    #   }
    # }

    # dynamic "insights_config" {
    #   for_each = var.insights_config
    #   content {
    #     query_insights_enabled  = insights_config.value.query_insights_enabled
    #     query_string_length     = insights_config.value.query_string_length
    #     record_application_tags = insights_config.value.record_application_tags
    #     record_client_address   = insights_config.value.record_client_address
    #   }
    # }

    # dynamic "maintenance_window" {
    #   for_each = var.maintenance_window
    #   content {
    #     day          = maintenance_window.value.maintenance_window_day
    #     hour         = maintenance_window.value.maintenance_window_hour
    #     update_track = maintenance_window.value.maintenance_window_update_track
    #   }
    # }
  }

  depends_on = [
    #google_service_networking_connection.private_vpc_connection,
    google_project_service_identity.sa , google_compute_global_forwarding_rule
  ]

}

//Create this in the first run, allow google_sql_database_instance to fail. 
//Then add iam binding for this SA in keyring rerun this module again.
resource "google_project_service_identity" "sa" {
  provider = google-beta

  project = var.project_id
  service = "sqladmin.googleapis.com"
}

# Creating redis cache
data "google_compute_network" "redis-network" {
  name    = var.name_reserved_ip_range
  project = var.host_project_id
}
resource "google_project_service" "redisapi" {
  project = var.project_id
  service = "redis.googleapis.com"
}
resource "google_redis_instance" "gcp_redis" {
  depends_on              = [google_project_service.redisapi]  
  name                    = var.redis_name
  memory_size_gb          = var.memory_size_gb 
  authorized_network      = var.authorized_network
  redis_configs           = var.redis_configs
  redis_version           = var.redis_version
  tier                    = var.redis_tier
  region                  = var.region
  project                 = var.project_id
  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.transit_encryption_mode
  connect_mode            = var.connect_mode
  reserved_ip_range       = data.google_compute_network.redis-network.id

}

# creating GKE

resource "google_service_account" "default" {
  account_id   = "${var.name}-sa"
  display_name = "${var.name}-sa"
  project      = var.project_id
}

resource "google_container_cluster" "primary" {
  project                     = var.project_id
  name                        = "${var.name}-${var.cluster_postfix}"
  location                    = var.location
  node_locations              = length(var.node_locations) != 0 ? var.node_locations : null
  networking_mode             = "VPC_NATIVE"
  network                     = var.network
  subnetwork                  = var.subnet
  enable_shielded_nodes       = var.enable_shielded_nodes
  enable_intranode_visibility = var.enable_intranode_visibility
  #enable_binary_authorization = var.enable_binary_authorization

  ip_allocation_policy {
    cluster_ipv4_cidr_block       = var.is_shared_vpc ? null : "/14"
    services_ipv4_cidr_block      = var.is_shared_vpc ? null : "/16"
    cluster_secondary_range_name  = var.is_shared_vpc ? var.cluster_secondary_range_name : null
    services_secondary_range_name = var.is_shared_vpc ? var.services_secondary_range_name : null
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool  = var.remove_default_node_pool
  initial_node_count        = 1
  default_max_pods_per_node = var.cluster_default_max_pods_per_node

  dynamic "release_channel" {
    for_each = var.enable_release_channel ? [1] : []
    content {
      channel = var.release_channel
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = var.enable_private_cluster == true ? [1] : []
    content {
    }
  }

  dynamic "workload_identity_config" {
    for_each = var.workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_cluster
    enable_private_endpoint = var.enable_private_cluster
    master_ipv4_cidr_block  = var.enable_private_cluster ? var.master_ipv4_cidr_block : null

    master_global_access_config {
      enabled = true
    }
  }

  //this is needed even if we are deleting defaul node pool at once
  //because if we are enabling shielded nodes we have to enable secure boot also, without which default node pool 
  //won't be created
  node_config {
    service_account = google_service_account.default.email
    machine_type    = var.machine_type
    image_type      = var.image_type
    //not advisable to use preemptible nodes for default node pool
    # preemptible       = var.preemptible
    # dynamic "taint" {
    #   for_each = var.preemptible ? [
    #     {
    #       key    = "cloud.google.com/gke-preemptible"
    #       value  = "true"
    #       effect = "NO_SCHEDULE"
    #     }
    #   ] : []
    #   content {
    #     key    = taint.value.key
    #     value  = taint.value.value
    #     effect = taint.value.effect
    #   }
    # }
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes = tolist(var.oauth_scopes)
    dynamic "workload_metadata_config" {
      for_each = var.workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }
    dynamic "shielded_instance_config" {
      for_each = var.enable_shielded_nodes ? [1] : []
      content {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to node_config, because it usually always changes after
      # resource is created
      node_config,
    ]
  }

  depends_on = [
    google_project_iam_member.project,
    google_compute_subnetwork_iam_member.cloudservices,
    google_compute_subnetwork_iam_member.container_engine_robot,
  ]
}

resource "google_container_node_pool" "primary_node_pool" {
  provider           = google-beta
  project            = var.project_id
  name               = "${var.name}-primary-node-pool"
  location           = var.location
  cluster            = google_container_cluster.primary.name
  initial_node_count = 1
  max_pods_per_node  = var.primary_node_pool_max_pods_per_node

  autoscaling {
    min_node_count = var.default_node_pool_min_count
    max_node_count = var.default_node_pool_max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    service_account   = google_service_account.default.email
    machine_type      = var.machine_type
    image_type        = var.image_type
    boot_disk_kms_key = var.boot_disk_kms_key

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes = tolist(var.oauth_scopes)
    dynamic "workload_metadata_config" {
      for_each = var.workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to node_config, because it usually always changes after
      # resource is created
      node_config,
    ]
  }

  depends_on = [
    google_project_iam_member.project,
    google_compute_subnetwork_iam_member.cloudservices,
    google_compute_subnetwork_iam_member.container_engine_robot,
  ]
}

# resource "google_container_node_pool" "secondary_node_pool" {
#   provider           = google-beta
#   project            = var.project_id
#   name               = "${var.name}-secondary-node-pool"
#   location           = var.location
#   cluster            = google_container_cluster.primary.name
#   initial_node_count = 1
#   max_pods_per_node  = var.secondary_node_pool_max_pods_per_node

#   autoscaling {
#     min_node_count = var.secondary_node_pool_min_count
#     max_node_count = var.secondary_node_pool_max_count
#   }

#   management {
#     auto_repair  = true
#     auto_upgrade = true
#   }

#   node_config {
#     service_account   = google_service_account.default.email
#     preemptible       = var.preemptible
#     machine_type      = var.machine_type
#     image_type        = var.image_type
#     boot_disk_kms_key = var.boot_disk_kms_key == "" ? null : var.boot_disk_kms_key

#     dynamic "taint" {
#       for_each = var.preemptible ? [
#         {
#           key    = "cloud.google.com/gke-preemptible"
#           value  = "true"
#           effect = "NO_SCHEDULE"
#         }
#       ] : []

#       content {
#         key    = taint.value.key
#         value  = taint.value.value
#         effect = taint.value.effect
#       }
#     }

#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     oauth_scopes = tolist(var.oauth_scopes)
#     dynamic "workload_metadata_config" {
#       for_each = var.workload_identity ? [1] : []
#       content {
#         mode = "GKE_METADATA"
#       }
#     }
#     shielded_instance_config {
#       enable_secure_boot          = true
#       enable_integrity_monitoring = true
#     }
#   }

#   lifecycle {
#     ignore_changes = [
#       # Ignore changes to node_config, because it usually always changes after
#       # resource is created
#       node_config,
#     ]
#   }

#   depends_on = [
#     google_project_iam_member.project,
#     google_compute_subnetwork_iam_member.cloudservices,
#     google_compute_subnetwork_iam_member.container_engine_robot,
#   ]
# }

//Enable a route to default internet gateway
//Enable this if private google access is being used, check compatibility with automatically created dns zone in host project
//Don't use this if cloud NAT is enabled
resource "google_compute_route" "route" {
  count            = var.enable_private_cluster && var.enable_private_googleapis_route ? 1 : 0
  name             = "private-googleapis-route"
  project          = var.host_project_id
  dest_range       = "199.36.153.8/30"
  network          = var.network
  next_hop_gateway = "default-internet-gateway"
  priority         = 0
}

//Allow health check probes to reach cluster(cluster creation fails at health check without this)
//Don't use this if cloud NAT is enabled
resource "google_compute_firewall" "health-ingress-firewall" {
  count         = var.enable_private_cluster && var.enable_private_googleapis_firewall ? 1 : 0
  name          = "health-check-ingress"
  network       = var.network
  project       = var.host_project_id
  direction     = "INGRESS"
  priority      = 0
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
  }
}

//Allow cluster to reach health check probes(not verified if we really need this)
//Don't use this if cloud NAT is enabled
resource "google_compute_firewall" "health-egress-firewall" {
  count              = var.enable_private_cluster && var.enable_private_googleapis_firewall ? 1 : 0
  name               = "health-check-egress"
  network            = var.network
  project            = var.host_project_id
  direction          = "EGRESS"
  priority           = 0
  destination_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
  }
}

//Allow cluster to reach private.googleapis.com(alternative restricted.googleapis.com can also be used)
//Don't use this if cloud NAT is enabled
resource "google_compute_firewall" "googleapis-egress-firewall" {
  count              = var.enable_private_cluster && var.enable_private_googleapis_firewall ? 1 : 0
  name               = "googleapis-egress"
  network            = var.network
  project            = var.host_project_id
  direction          = "EGRESS"
  priority           = 0
  destination_ranges = ["199.36.153.8/30"]

  allow {
    protocol = "tcp"
  }
}

//Create an external NAT IP
//Don't use this if private google access is being used
resource "google_compute_address" "nat" {
  count   = var.enable_private_cluster && var.enable_cloud_nat ? 1 : 0
  name    = format("%s-nat-ip", var.name)
  project = var.host_project_id
  region  = var.subnet_region
}

//Create a cloud router for use by the Cloud NAT
//Don't use this if private google access is being used
resource "google_compute_router" "router" {
  count   = var.enable_private_cluster && var.enable_cloud_nat ? 1 : 0
  name    = format("%s-cloud-router", var.name)
  project = var.host_project_id
  network = var.network
  region  = var.subnet_region

  bgp {
    asn = 64514
  }
}

//Create a NAT router so the nodes can reach DockerHub, etc
//Don't use this if private google access is being used
resource "google_compute_router_nat" "nat" {
  count   = var.enable_private_cluster && var.enable_cloud_nat ? 1 : 0
  name    = format("%s-cloud-nat", var.name)
  project = var.host_project_id
  router  = google_compute_router.router[0].name
  region  = google_compute_router.router[0].region

  nat_ip_allocate_option = "MANUAL_ONLY"

  nat_ips = [google_compute_address.nat[0].self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = var.subnet
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      var.cluster_secondary_range_name,
      var.services_secondary_range_name,
    ]
  }
}

module "gcr-dns" {
  count                              = var.enable_private_cluster && var.create_private_dns_zone ? 1 : 0
  source                             = "bootlabstech/dns-managed-zone/google"
  version                            = "1.0.10"
  name                               = "gcr-io"
  dns_name                           = "gcr.io."
  is_private                         = true
  force_destroy                      = true
  description                        = "private zone for GCR.io"
  project                            = var.project_id
  private_visibility_config_networks = [var.network]
  records = [
    {
      name    = "*.gcr.io."
      type    = "CNAME"
      ttl     = "300"
      rrdatas = ["gcr.io."]
    },
    {
      name = "gcr.io."
      type = "A"
      ttl  = "300"
      rrdatas = [
        "199.36.153.10",
        "199.36.153.11",
        "199.36.153.8",
        "199.36.153.9"
      ]
    }
  ]
}

module "googleapis-dns" {
  count                              = var.enable_private_cluster && var.enable_private_googleapis_route && var.create_private_dns_zone ? 1 : 0
  source                             = "bootlabstech/dns-managed-zone/google"
  version                            = "1.0.10"
  name                               = "googleapis-com"
  dns_name                           = "googleapis.com."
  is_private                         = true
  force_destroy                      = true
  description                        = "private zone for googleapis.com"
  project                            = var.project_id
  private_visibility_config_networks = [var.network]
  records = [
    {
      name    = "*.googleapis.com."
      type    = "CNAME"
      ttl     = "300"
      rrdatas = ["private.googleapis.com."]
    },
    {
      name = "private.googleapis.com."
      type = "A"
      ttl  = "300"
      rrdatas = [
        "199.36.153.10",
        "199.36.153.11",
        "199.36.153.8",
        "199.36.153.9"
      ]
    }
  ]
}

# iam for gke
locals {
  if_create = var.is_shared_vpc ? 1 : 0
}

data "google_project" "host_project" {
  count      = local.if_create
  project_id = var.host_project_id
}

data "google_project" "service_project" {
  count      = local.if_create
  project_id = var.project_id
}

// project level access
// https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc
resource "google_project_iam_member" "project" {
  count   = local.if_create
  project = data.google_project.host_project[0].project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${data.google_project.service_project[0].number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "securityadmin" {
  count   = local.if_create
  project = data.google_project.host_project[0].project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:service-${data.google_project.service_project[0].number}@container-engine-robot.iam.gserviceaccount.com"
}

// network access
// https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc
resource "google_compute_subnetwork_iam_member" "cloudservices" {
  count      = local.if_create
  project    = data.google_project.host_project[0].project_id
  subnetwork = var.subnet
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.service_project[0].number}@cloudservices.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "container_engine_robot" {
  count      = local.if_create
  project    = data.google_project.host_project[0].project_id
  subnetwork = var.subnet
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.service_project[0].number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "containerAdmin" {
  count   = length(var.containerAdminMembers) != 0 ? 1 : 0
  project = data.google_project.service_project[0].project_id
  role    = "roles/container.admin"

  members = var.containerAdminMembers
}

# //Docker pull from cluster
# resource "google_storage_bucket_iam_member" "member" {
#   bucket = "asia.artifacts.${var.project_id}.appspot.com"
#   role   = "roles/storage.objectViewer"
#   member = "serviceAccount:${google_service_account.default.email}"
#   depends_on = [
#     google_service_account.default
#   ]
# }
