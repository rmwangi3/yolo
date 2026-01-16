#!/bin/bash

# YOLO E-commerce - Deployment Testing Script
# This script tests the Ansible deployment of the YOLO e-commerce application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Test functions
test_vagrant_running() {
    print_test "Vagrant VM is running"
    if vagrant status | grep -q "running"; then
        print_success "Vagrant VM is running"
        return 0
    else
        print_fail "Vagrant VM is not running"
        return 1
    fi
}

test_ansible_files() {
    print_test "Ansible files exist"
    local files=("playbook.yml" "ansible.cfg" "inventory" "vars/main.yml")
    local all_exist=true
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file exists"
        else
            print_fail "$file not found"
            all_exist=false
        fi
    done
    
    [ "$all_exist" = true ]
}

test_roles_exist() {
    print_test "Ansible roles exist"
    local roles=("docker" "clone_repo" "mongodb" "backend" "client")
    local all_exist=true
    
    for role in "${roles[@]}"; do
        if [ -d "roles/$role/tasks" ] && [ -f "roles/$role/tasks/main.yml" ]; then
            print_success "Role '$role' exists"
        else
            print_fail "Role '$role' not found or incomplete"
            all_exist=false
        fi
    done
    
    [ "$all_exist" = true ]
}

test_docker_installed() {
    print_test "Docker is installed in VM"
    if vagrant ssh -c "docker --version" &>/dev/null; then
        local version=$(vagrant ssh -c "docker --version" 2>/dev/null)
        print_success "Docker is installed: $version"
        return 0
    else
        print_fail "Docker is not installed"
        return 1
    fi
}

test_containers_running() {
    print_test "Docker containers are running"
    local containers=("yolo-mongo" "yolo-backend" "yolo-client")
    local all_running=true
    
    for container in "${containers[@]}"; do
        if vagrant ssh -c "docker ps --format '{{.Names}}'" 2>/dev/null | grep -q "$container"; then
            print_success "Container '$container' is running"
        else
            print_fail "Container '$container' is not running"
            all_running=false
        fi
    done
    
    [ "$all_running" = true ]
}

test_frontend_accessible() {
    print_test "Frontend is accessible"
    local url="http://192.168.56.10:3000"
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        print_success "Frontend is accessible at $url"
        return 0
    else
        print_fail "Frontend is not accessible at $url"
        return 1
    fi
}

test_backend_api() {
    print_test "Backend API is accessible"
    local url="http://192.168.56.10:5000/api/products"
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        print_success "Backend API is accessible at $url"
        
        # Test if API returns JSON
        if curl -s "$url" | grep -q "\["; then
            print_success "Backend API returns valid JSON"
        else
            print_fail "Backend API does not return valid JSON"
        fi
        return 0
    else
        print_fail "Backend API is not accessible at $url"
        return 1
    fi
}

test_mongodb_volume() {
    print_test "MongoDB volume exists"
    if vagrant ssh -c "docker volume ls" 2>/dev/null | grep -q "mongo-data"; then
        print_success "MongoDB volume 'mongo-data' exists"
        return 0
    else
        print_fail "MongoDB volume 'mongo-data' not found"
        return 1
    fi
}

test_docker_network() {
    print_test "Docker network exists"
    if vagrant ssh -c "docker network ls" 2>/dev/null | grep -q "yolo-network"; then
        print_success "Docker network 'yolo-network' exists"
        return 0
    else
        print_fail "Docker network 'yolo-network' not found"
        return 1
    fi
}

test_documentation() {
    print_test "Documentation files exist"
    local docs=("README.md" "explanation.md" "QUICKSTART.md" "DEPLOYMENT_SUMMARY.md")
    local all_exist=true
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            print_success "$doc exists"
        else
            print_fail "$doc not found"
            all_exist=false
        fi
    done
    
    [ "$all_exist" = true ]
}

test_application_directory() {
    print_test "Application directory exists in VM"
    if vagrant ssh -c "[ -d /opt/yolo ]" 2>/dev/null; then
        print_success "Application directory '/opt/yolo' exists"
        return 0
    else
        print_fail "Application directory '/opt/yolo' not found"
        return 1
    fi
}

# Main test execution
main() {
    print_header "YOLO E-commerce - Deployment Tests"
    
    print_info "Starting deployment verification tests..."
    echo ""
    
    # File structure tests
    print_header "File Structure Tests"
    test_ansible_files
    test_roles_exist
    test_documentation
    
    # VM tests
    print_header "Virtual Machine Tests"
    test_vagrant_running
    
    # Docker tests
    print_header "Docker Tests"
    test_docker_installed
    test_docker_network
    test_mongodb_volume
    
    # Container tests
    print_header "Container Tests"
    test_containers_running
    test_application_directory
    
    # Application tests
    print_header "Application Tests"
    test_frontend_accessible
    test_backend_api
    
    # Summary
    print_header "Test Summary"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! Deployment is successful.${NC}"
        echo ""
        echo -e "${BLUE}Access your application:${NC}"
        echo -e "  Frontend: ${GREEN}http://192.168.56.10:3000${NC}"
        echo -e "  Backend:  ${GREEN}http://192.168.56.10:5000/api/products${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

# Run tests
main
