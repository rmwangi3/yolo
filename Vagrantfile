# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Using Jeff Geerling's Ubuntu 20.04 box
  config.vm.box = "geerlingguy/ubuntu2004"
  
  config.vm.hostname = "yolo-ansible"
  
  # Network configuration - forwarding ports for the application
  config.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"  # Client frontend
  config.vm.network "forwarded_port", guest: 5000, host: 5000, host_ip: "127.0.0.1"  # Backend API
  config.vm.network "private_network", ip: "192.168.56.10"
  
  # VM provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "yolo-ansible-vm"
    vb.memory = "2048"
    vb.cpus = 2
  end
  
  # Synced folder to share project files
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  
  # Disable default SSH key replacement for easier access
  config.ssh.insert_key = false
  
  # Provision with Ansible
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.verbose = "v"
    ansible.extra_vars = {
      ansible_python_interpreter: "/usr/bin/python3"
    }
  end
end
