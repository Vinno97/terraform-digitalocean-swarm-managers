output "ipv4_addresses" {
  value       = ["${vultr_instance.manager.*.ipv4_address}"]
  description = "The manager nodes public ipv4 adresses"
}

output "manager_token" {
  value       = "${lookup(data.external.swarm_tokens.result, "manager", "")}"
  description = "The Docker Swarm manager join token"
  sensitive   = true
}

output "worker_token" {
  value       = "${lookup(data.external.swarm_tokens.result, "worker", "")}"
  description = "The Docker Swarm worker join token"
  sensitive   = true
}
