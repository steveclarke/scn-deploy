terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create SSH key resource
resource "digitalocean_ssh_key" "deploy" {
  name       = "scn-deploy-key"
  public_key = file(var.ssh_public_key_path)
}

# Create the droplet
resource "digitalocean_droplet" "scn_docker_host" {
  name     = var.droplet_name
  region   = var.region
  size     = var.droplet_size
  image    = var.droplet_image
  
  ssh_keys = [digitalocean_ssh_key.deploy.fingerprint]
  
  tags = ["scn", "docker", "production"]
  
  # Enable backups if specified
  backups = var.enable_backups
  
  # Enable monitoring
  monitoring = true
  
  # Enable IPv6
  ipv6 = true
  
  # User data script to set up the server
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    deploy_user_public_key = file(var.ssh_public_key_path)
  })
}

# Create a firewall
resource "digitalocean_firewall" "scn_firewall" {
  name = "scn-docker-firewall"
  
  droplet_ids = [digitalocean_droplet.scn_docker_host.id]
  
  # Allow SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_allowed_ips
  }
  
  # Allow HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # Allow HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Create a project (optional)
resource "digitalocean_project" "scn_project" {
  name        = "Saltbox Church Network"
  description = "Docker host for SCN application stack"
  purpose     = "Web Application"
  environment = var.environment
  
  resources = [digitalocean_droplet.scn_docker_host.urn]
} 
