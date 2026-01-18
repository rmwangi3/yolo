terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "vagrant_vm" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ../.. && vagrant up"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "cd ../.. && vagrant destroy -f"
  }
}

output "vm_info" {
  value = {
    status  = "Vagrant VM provisioned"
    ip      = "192.168.56.10"
    ports   = {
      frontend = 3000
      backend  = 5000
    }
  }
}
