output "application_url" {
  description = "URL to access the application"
  value       = "http://localhost:3000"
}

output "backend_url" {
  description = "URL to access the backend API"
  value       = "http://localhost:5000"
}

output "mongodb_connection" {
  description = "MongoDB connection string"
  value       = "mongodb://localhost:27017"
}

output "deployment_status" {
  description = "Status of the deployment"
  value       = "Terraform provisioning completed. Run 'vagrant ssh' to access the VM."
}
