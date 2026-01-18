variable "vagrant_box" {
  description = "Vagrant box to use for VM provisioning"
  type        = string
  default     = "geerlingguy/ubuntu2004"
}

variable "vm_memory" {
  description = "Memory allocation for the VM in MB"
  type        = number
  default     = 2048
}

variable "vm_cpus" {
  description = "Number of CPUs for the VM"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port for the client application"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port for the backend API"
  type        = number
  default     = 5000
}

variable "mongodb_port" {
  description = "Port for MongoDB"
  type        = number
  default     = 27017
}
