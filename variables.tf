variable "vultr_key" {
  type        = "string"
  description = "The Vultr API Key"
}

variable "domain" {
  type        = "string"
  description = "Domain name used in hostnames, e.g example.com"
}

variable "ssh_keys" {
  type        = "list"
  description = "A list of SSH IDs that are added to manager nodes"
}

variable "provision_ssh_key" {
  default     = "~/.ssh/id_rsa"
  description = "File path to SSH private key used to access the provisioned nodes. Ensure this key is listed in the manager and work ssh keys list"
}

variable "provision_user" {
  default     = "root"
  description = "User used to log in to the droplets via ssh for issueing Docker commands"
}

variable "region" {
  description = "Datacenter region in which the cluster will be created"
  default     = "Amsterdam"
}

variable "total_instances" {
  description = "Total number of managers in cluster"
  default     = 1
}

variable "os" {
  description = "OS image used for the manager nodes"
  default     = "coreos"
}

variable "plan" {
  description = "Plan to use for manager nodes"
  default     = "1024 MB RAM,25 GB SSD"
}

variable "name" {
  description = "Prefix for name of manager nodes"
  default     = "manager"
}

variable "user_data" {
  description = "User data content for manager nodes"
  default     = ""
}

variable "docker_cmd" {
  description = "Docker command"
  default     = "sudo docker"
}

variable "tag" {
  description = "Vultr tag for the manager nodes"
  default     = "manager"
  type        = "string"
}

variable "availability" {
  description = "Availability of the node ('active'|'pause'|'drain')"
  default     = "active"
}

variable "remote_api_ca" {
  default = ""
}

variable "remote_api_key" {
  default = ""
}

variable "remote_api_certificate" {
  default = ""
}
