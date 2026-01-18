variable "vm_name" {
  description = "Name of the Vagrant VM"
  type        = string
  default     = "yolo-ansible-vm"
}

variable "vm_memory" {
  description = "VM memory in MB"
  type        = number
  default     = 1024
}

variable "vm_cpus" {
  description = "Number of CPUs"
  type        = number
  default     = 1
}

variable "frontend_port" {
  description = "Frontend port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Backend API port"
  type        = number
  default     = 5000
}
