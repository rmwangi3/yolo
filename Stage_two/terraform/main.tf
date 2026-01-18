terraform {
  required_version = ">= 1.0"
<<<<<<< HEAD
  
=======
>>>>>>> master
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

<<<<<<< HEAD
# Null resource to trigger Vagrant provisioning
resource "null_resource" "vagrant_provision" {
  triggers = {
    always_run = timestamp()
  }

  # Ensure Vagrant VM is up
  provisioner "local-exec" {
    command = "cd ${path.module}/.. && vagrant up"
  }

  # Wait for SSH to be available
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# Null resource to run Ansible playbook
resource "null_resource" "ansible_provision" {
  depends_on = [null_resource.vagrant_provision]

  triggers = {
    playbook_hash = filemd5("${path.module}/../playbook.yml")
  }

  # Run Ansible playbook against the Vagrant VM
  provisioner "local-exec" {
    command = "cd ${path.module}/.. && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory playbook.yml"
  }
}

# Output to verify deployment
resource "null_resource" "verify_deployment" {
  depends_on = [null_resource.ansible_provision]

  provisioner "local-exec" {
    command = "echo 'Terraform provisioning complete. Application should be accessible at http://localhost:3000'"
=======
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
    status = "Vagrant VM provisioned"
    ip     = "192.168.56.10"
    ports = {
      frontend = 3000
      backend  = 5000
    }
>>>>>>> master
  }
}
