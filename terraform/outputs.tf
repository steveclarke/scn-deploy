output "droplet_ip" {
  description = "The public IP address of the droplet"
  value       = digitalocean_droplet.scn_docker_host.ipv4_address
}

output "droplet_ipv6" {
  description = "The IPv6 address of the droplet"
  value       = digitalocean_droplet.scn_docker_host.ipv6_address
}

output "droplet_id" {
  description = "The ID of the droplet"
  value       = digitalocean_droplet.scn_docker_host.id
}

output "droplet_status" {
  description = "The status of the droplet"
  value       = digitalocean_droplet.scn_docker_host.status
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh deploy@${digitalocean_droplet.scn_docker_host.ipv4_address}"
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    Server deployed successfully!
    
    1. SSH into the server:
       ${self.ssh_command.value}
    
    2. Check setup notes:
       cat /home/deploy/SETUP_NOTES.txt
    
    3. Get the deploy key for GitHub:
       ssh deploy@${digitalocean_droplet.scn_docker_host.ipv4_address} 'cat /home/deploy/.ssh/id_ed25519.pub'
  EOT
} 
