<<<<<<< HEAD
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
=======
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
>>>>>>> master
  type        = number
  default     = 3000
}

variable "backend_port" {
<<<<<<< HEAD
  description = "Port for the backend API"
  type        = number
  default     = 5000
}

variable "mongodb_port" {
  description = "Port for MongoDB"
  type        = number
  default     = 27017
}
=======
  description = "Backend API port"
  type        = number
  default     = 5000
}
>>>>>>> master
