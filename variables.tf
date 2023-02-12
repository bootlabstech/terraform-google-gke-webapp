#forwarding_rule
variable "ip_protocol" {
  type        = string
  description = "The IP protocol to which this rule applies.  Possible values are TCP, UDP, ESP, AH, SCTP, and ICMP."
}
variable "load_balancing_scheme" {
  type        = string
  description = "This signifies what the GlobalForwardingRule will be used.The value of INTERNAL_SELF_MANAGED means that this will be used for Internal Global HTTP(S) LB. The value of EXTERNAL means that this will be used for External Global Load Balancing (HTTP(S) LB, External TCP/UDP LB, SSL Proxy). The value of EXTERNAL_MANAGED means that this will be used for Global external HTTP(S) load balancers.  Possible values are EXTERNAL, EXTERNAL_MANAGED, and INTERNAL_SELF_MANAGED"
}
variable "port_range" {
  type        = string
  description = "This field is used along with the target field https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule#port_range"
}
variable "ip_address" {
  type        = string
  description = "The IP address that this forwarding rule serves. When a client sends traffic to this IP address, the forwarding rule directs the traffic to the target that you specify in the forwarding rule"
}
# variable "project_id" {
#   type        = string
#   description = " The ID of the project in which the resource belongs"
# }
variable "name" {
  type        = string
  description = "Name of the resource; provided by the client when the resource is created"
}
#backend service
variable "protocol" {
  type        = string
  description = "The protocol this BackendService uses to communicate with backends.Possible values are HTTP, HTTPS, HTTP2, TCP, SSL, and GRPC"
}
variable "network" {
  type        = string
  description = "Indicates whether the backend service will be used with internal or external load balancing. Possible values are EXTERNAL, INTERNAL_SELF_MANAGED, and EXTERNAL_MANAGED"
}
variable "group" {
  type        = string
  description = "The fully-qualified URL of an Instance Group or Network Endpoint Group resource"
}
variable "health_checks" {
  type        = list(string)
  description = "The health_checks"
}

# database
variable "db_root_username" {
  type        = string
  description = "The root username for the database instance"
}

variable "network_id" {
  description = "The id of the vpc"
  type        = string
}

variable "instance_name" {
  description = "The name of the database instance"
  type        = string
}

variable "database_version" {
  description = "The MySQL, PostgreSQL or SQL Server version to use. Supported values include MYSQL_5_6, MYSQL_5_7, MYSQL_8_0, POSTGRES_9_6,POSTGRES_10, POSTGRES_11, POSTGRES_12, POSTGRES_13, SQLSERVER_2017_STANDARD, SQLSERVER_2017_ENTERPRISE, SQLSERVER_2017_EXPRESS, SQLSERVER_2017_WEB. SQLSERVER_2019_STANDARD, SQLSERVER_2019_ENTERPRISE, SQLSERVER_2019_EXPRESS, SQLSERVER_2019_WEB"
  type        = string
}

variable "region" {
  description = "The region the instance will sit in"
  type        = string
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the instance"
  type        = bool
}

variable "tier" {
  description = "The machine type to use"
  type        = string
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)"
  type        = string
}

variable "disk_size" {
  description = "The size of data disk, in GB. Size of a running instance cannot be reduced but can be increased"
  type        = string
}

variable "disk_autoresize" {
  description = "Configuration to increase storage size automatically"
  type        = bool
}

variable "backup_enabled" {
  description = "True if backup configuration is enabled"
  type        = bool
}

variable "binary_log_enabled" {
  description = "True if backup configuration is enabled"
  type        = bool
}

variable "ipv4_enabled" {
  description = "True if backup configuration is enabled"
  type        = bool
  default     = false
}

variable "backup_start_time" {
  description = "HH:MM format time indicating when backup configuration starts"
  type        = string
}

# variable "database_flags" {
#   description = "The id of the vpc"
#   type = list(object({
#     name  = string
#     value = string
#   }))
# }

# variable "insights_config" {
#   description = "The id of the vpc"
#   type = list(object({
#     query_insights_enabled  = bool
#     query_string_length     = number
#     record_application_tags = bool
#     record_client_address   = bool
#   }))
# }

# variable "maintenance_window" {
#   description = "Subblock for instances declares a one-hour maintenance window when an Instance can automatically restart to apply updates"
#   type = list(object({
#     maintenance_window_day          = number
#     maintenance_window_hour         = number
#     maintenance_window_update_track = string
#   }))
# }

variable "shared_vpc_project_id" {
  description = "Shared VPC project"
  type        = string
}

variable "project_id" {
  description = "The project where the database lives"
  type        = string
}

variable "private_ip_address_name" {
  description = "The name of the static private ip for the database"
  type        = string
}

# variable "reserved_peering_ranges" {
#   description = "List of peering ranges"
#   type        = list(string)
# }

variable "encryption_key_name" {
  type        = string
  description = "the Customer Managed Encryption Key used to encrypt the boot disk attached to each node in the node pool"
  default     = ""
}




//required variables
# variable "rediscache_details" {
#   description = "The rediscache details"
#   type        = list(any)
# }

# variable "project_id" {
#   description = "The ID of the project in which the resource belongs. If it is not provided, the provider project is used"
#   type        = string
# }
variable "authorized_network" {
  description = "The full name of the Google Compute Engine network to which the instance is connected. If left unspecified, the default network will be used."
  type        = string
}

//optional variables

# variable "region" {
#   description = "The name of the Redis region of the instance."
#   type        = string
#   default     = "asia-south1"
# }

variable "redis_configs" {
  description = "Redis configuration parameters, according to http://redis.io/topics/config. Please check Memorystore documentation for the list of supported parameters"
  type        = map(string)
  default     = {}
}

variable "redis_version" {
  description = "The version of Redis software. If not provided, latest supported version will be used. Please check the API documentation linked at the top for the latest valid values."
  type        = string
  default     = "REDIS_6_X"
}

variable "redis_tier" {
  description = "The service tier of the instance. Must be one of these values:Basic or Standard_ha"
  type        = string
  default     = "STANDARD_HA"
}

variable "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance. If set to true AUTH is enabled on the instance."
  type        = bool
  default     = false
}

variable "transit_encryption_mode" {
  description = "The TLS mode of the Redis instance"
  type        = string
  default     = "SERVER_AUTHENTICATION"
}
variable "connect_mode" {
  description = "The connect mode of the Redis instance"
  type        = string
  default     = "PRIVATE_SERVICE_ACCESS"
}

variable "name_reserved_ip_range" {
  type        = string
  description = "For PRIVATE_SERVICE_ACCESS mode value must be the name of an allocated address range associated with the private service access connection,"
}

variable "host_project_id" {
  type        = string
  description = "The project id of the host project"
}

variable "memory_size_gb" {
  type        = number
  description = "The project id of the host project"
}
variable "redis_name" {
  type        = string
  description = "The project id of the host project"
}

# GKE
// required variables
variable "gke_name" {
  type        = string
  description = "this name will be used as prefix for all the resources in the module"
}

variable "location" {
  type        = string
  description = <<-EOT
  {
   "type": "api",
   "purpose": "autocomplete",
   "data":"api/gcp/locations",
   "description": "regions used for deployment"
}
EOT
}

variable "gke_network" {
  type        = string
  description = "this is the vpc for the cluster"
}

variable "subnet" {
  type        = string
  description = "this is the subnet for the cluster"
}

variable "default_node_pool_min_count" {
  type        = number
  description = "this is the min count in the default node pool"
}

variable "default_node_pool_max_count" {
  type        = number
  description = "this is the max count in the default node pool"
}

variable "machine_type" {
  type        = string
  description = <<-EOT
  {
   "type": "json",
   "purpose": "autocomplete",
   "data": [
    "f2-micro",
    "e3-micro",
    "e2-small",
    "g1-small",
    "e2-medium",
    "t2d-standard-1"
   ],
   "description": "regions used for deployment"
}
EOT
}

variable "image_type" {
  type        = string
  default     = "cos_containerd"
  description = "the default image type used by NAP once a new node pool is being created"
}

# variable "project_id" {
#   type        = string
#   description = <<-EOT
#   {
#    "type": "api",
#    "purpose": "autocomplete",
#    "data": "http://localhost:8000/api/v1/organizations/mpaasworkspacetest/projects",
#    "description": ""
#   }
# EOT
# }

variable "preemptible" {
  type        = bool
  description = "if set to true, the secondary node pool will be preemptible nodes"
}

variable "boot_disk_kms_key" {
  type        = string
  description = "the Customer Managed Encryption Key used to encrypt the boot disk attached to each node in the node pool"
  default     = ""
}

// optional variables
variable "service_account_id" {
  type        = string
  description = "the id is used as a postfix in service account created for the kubernetes engine"
  default     = "gke-sa"
}

variable "cluster_postfix" {
  type        = string
  description = "this will be used as the postfix for the cluster name, along with var.name"
  default     = "gke-k8s"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "the master network ip range"
  default     = "172.16.0.32/28"
}

variable "enable_private_cluster" {
  type        = bool
  description = "if enabled cluster becomes a private cluster"
  default     = true
}

variable "enable_private_googleapis_route" {
  type        = bool
  description = "enable route for private google service"
  default     = false
}

variable "create_private_dns_zone" {
  type        = bool
  description = "enable dns for private google service"
  default     = false
}

variable "enable_private_googleapis_firewall" {
  type        = bool
  description = "enable firewall for private google service"
  default     = false
}

variable "enable_cloud_nat" {
  type        = bool
  description = "if enabled cloud nat will be created for private clusters"
  default     = false
}

variable "is_shared_vpc" {
  type        = bool
  description = "if the vpc and subnet is from a shared vpc"
  default     = false
}

# variable "host_project_id" {
#   type        = string
#   description = "the host project id, needed only if is_shared_vpc is set to true"
#   default     = ""
# }

variable "services_secondary_range_name" {
  type        = string
  description = "the secondary range name of the subnet to be used for services, this is needed if is_shared_vpc is enabled"
  
}

variable "cluster_secondary_range_name" {
  type        = string
  description = "the secondary range name of the subnet to be used for pods, this is needed if is_shared_vpc is enabled"
}

variable "subnet_region" {
  type        = string
  description = <<-EOT
  {
   "type": "api",
   "purpose": "autocomplete",
   "data":"api/gcp/regions",
   "description": "regions used for deployment"
}
EOT
  default     = ""
}

variable "enable_shielded_nodes" {
  type        = bool
  default     = true
  description = "Enable Shielded Nodes features on all nodes in this cluster"
}

variable "workload_identity" {
  type        = bool
  default     = true
  description = "to enable workload identity metadata"
}

variable "enable_intranode_visibility" {
  type        = bool
  default     = true
  description = "to enable intra node visibility for the cluster"
}

variable "remove_default_node_pool" {
  type        = bool
  default     = true
  description = " If true, deletes the default node pool upon cluster creation. If you're using google_container_node_pool resources with no default node pool, this should be set to true, alongside setting initial_node_count to at least 1"
}

variable "oauth_scopes" {
  type        = list(string)
  description = "oauth scopes for gke cluster"
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

# variable "enable_binary_authorization" {
#   type        = bool
#   default     = true
#   description = "to enable binary authorization"
# }

variable "node_locations" {
  type        = list(string)
  description = "The list of zones in which the cluster's nodes are located. Nodes must be in the region of their regional cluster or in the same region as their cluster's zone for zonal clusters. If this is specified for a zonal cluster, omit the cluster's zone."
  default     = []
}

variable "containerAdminMembers" {
  type        = list(string)
  description = "The list of members who will have container admin role."
  default     = []
}

variable "cluster_default_max_pods_per_node" {
  type        = number
  description = "The default maximum number of pods per node in this cluster. See the official documentation for more information"
  default     = 64
}

variable "primary_node_pool_max_pods_per_node" {
  type        = number
  description = "The maximum number of pods per primary node in this node pool"
  default     = 64
}


variable "enable_release_channel" {
  type        = bool
  description = "Configuration options for the Release channel feature, which provide more control over automatic upgrades of your GKE clusters"
  default     = true
}

variable "release_channel" {
  type        = string
  description = "The selected release channel"
}


# variable "secondary_node_pool_max_pods_per_node" {
#   type        = number
#   description = "The maximum number of pods per secondary node in this node pool"
#   default     = 64
# }
# variable "secondary_node_pool_min_count" {
#   type        = number
#   description = "this is the min count in the secondary node pool"
# }

# variable "secondary_node_pool_max_count" {
#   type        = number
#   description = "this is the min count in the secondary node pool"
# }
# variable "enable_private_endpoint" {
#   type        = bool
#   description = "Configuration options for the Release channel feature, which provide more control over automatic upgrades of your GKE clusters"
#   default     = false
# }
