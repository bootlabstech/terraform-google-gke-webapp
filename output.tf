output "lb_id" {
  value = google_compute_global_forwarding_rule.forwarding_rule

}

output "sql_password" {
  value     = random_password.sql_password.result
  sensitive = true
}

output "sql_name" {
  value = google_sql_database_instance.instance.name
}

output "sql_private_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}

# output "id" {
#     value = google_storage_bucket.bucket.id

# }

output "redis_id" {
    value = google_redis_instance.gcp_redis.id

}