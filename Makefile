.PHONY: help up provision ssh status halt destroy reload logs clean test

help:
	@echo "YOLO E-commerce - Ansible Deployment Commands"
	@echo "=============================================="
	@echo ""
	@echo "Vagrant Commands:"
	@echo "  make up          - Start and provision the VM"
	@echo "  make provision   - Re-run Ansible provisioning"
	@echo "  make ssh         - SSH into the VM"
	@echo "  make status      - Check VM status"
	@echo "  make halt        - Stop the VM"
	@echo "  make reload      - Restart the VM with provisioning"
	@echo "  make destroy     - Destroy the VM"
	@echo ""
	@echo "Ansible Commands:"
	@echo "  make playbook    - Run the playbook manually"
	@echo "  make ping        - Test Ansible connectivity"
	@echo "  make docker-only - Deploy only Docker"
	@echo "  make backend-only - Deploy only backend"
	@echo "  make client-only - Deploy only client"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make logs        - View container logs"
	@echo "  make test        - Test the application"
	@echo "  make clean       - Clean up logs and temp files"
	@echo "  make ps          - Show running containers"
	@echo ""

# Vagrant Commands
up:
	vagrant up

provision:
	vagrant provision

ssh:
	vagrant ssh

status:
	vagrant status

halt:
	vagrant halt

destroy:
	vagrant destroy -f

reload:
	vagrant reload --provision

# Ansible Commands
playbook:
	ansible-playbook -i inventory playbook.yml

ping:
	ansible all -m ping -i inventory

docker-only:
	ansible-playbook -i inventory playbook.yml --tags docker

backend-only:
	ansible-playbook -i inventory playbook.yml --tags backend

client-only:
	ansible-playbook -i inventory playbook.yml --tags client

containers-only:
	ansible-playbook -i inventory playbook.yml --tags containers

test-only:
	ansible-playbook -i inventory playbook.yml --tags test

# Utility Commands
logs:
	@echo "=== Backend Logs ==="
	@vagrant ssh -c "docker logs yolo-backend --tail 50"
	@echo ""
	@echo "=== Client Logs ==="
	@vagrant ssh -c "docker logs yolo-client --tail 50"
	@echo ""
	@echo "=== MongoDB Logs ==="
	@vagrant ssh -c "docker logs yolo-mongo --tail 50"

ps:
	@echo "Running Containers:"
	@vagrant ssh -c "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

test:
	@echo "Testing Backend API..."
	@curl -s http://192.168.56.10:5000/api/products | head -20
	@echo ""
	@echo "Testing Frontend..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" http://192.168.56.10:3000

clean:
	rm -f ansible.log
	rm -rf /tmp/ansible_facts

# Quick commands
start: up
stop: halt
restart: reload
remove: destroy
