# Terraform Configuration for SCN Docker Host

This Terraform configuration automates the deployment of a Digital Ocean droplet
for the Saltbox Church Network Docker stack.

## Features

- **Automated Server Setup**: Uses cloud-init to automatically configure Ubuntu 22.04 with:
  - Docker and Docker Compose installation
  - `deploy` user creation with sudo privileges
  - UFW firewall configuration (ports 22, 80, 443)
  - SSH key generation for GitHub repository access
  - Directory structure setup

- **Security**: 
  - Digital Ocean firewall rules
  - SSH key-based authentication only
  - Optional IP whitelisting for SSH access

- **Infrastructure**:
  - Configurable droplet size and region
  - Automated backups
  - Monitoring enabled
  - IPv6 support

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads) installed (version 1.0+)
2. A [Digital Ocean account](https://www.digitalocean.com/)
3. A [Digital Ocean API token](https://cloud.digitalocean.com/account/api/tokens)
4. An SSH key pair on your local machine

## Usage

1. **Copy and configure the variables file**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your Digital Ocean API token and other settings.

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the deployment plan**:
   ```bash
   terraform plan
   ```

4. **Deploy the infrastructure**:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted to confirm.

5. **After deployment**, Terraform will output:
   - The server's IP address
   - SSH connection command
   - Next steps for completing the setup

## Post-Deployment Steps

1. **SSH into the server**:
   ```bash
   ssh deploy@<server-ip>
   ```

2. **Add the deploy key to GitHub**:
   ```bash
   cat /home/deploy/.ssh/id_ed25519.pub
   ```
   Add this key as a deploy key in your GitHub repository settings.

3. **Clone the repository**:
   ```bash
   cd /home/deploy/docker
   git clone git@github.com:steveclarke/scn-deploy.git scn
   ```

4. **Set up GitHub Container Registry authentication**:
   ```bash
   export CR_PAT=YOUR_TOKEN
   echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
   ```

5. **Configure environment files** and start the stack as described in the main README.

## Managing the Infrastructure

- **View current state**:
  ```bash
  terraform show
  ```

- **Destroy the infrastructure** (warning: this will delete the droplet):
  ```bash
  terraform destroy
  ```

- **Update infrastructure** (after changing configuration):
  ```bash
  terraform apply
  ```

## Configuration Options

See `variables.tf` for all available configuration options. Key options include:

- `droplet_size`: Server size (default: s-2vcpu-4gb)
- `region`: Digital Ocean region (default: nyc3)
- `enable_backups`: Enable automated backups (default: true)
- `ssh_allowed_ips`: IP addresses allowed to SSH (default: all)

## Security Recommendations

For production deployments:

1. Restrict SSH access to specific IP addresses in `terraform.tfvars`
2. Use a strong API token and keep it secure
3. Regularly update the server and Docker images
4. Enable and configure Digital Ocean monitoring alerts
5. Consider using Digital Ocean Spaces for backup storage

## Troubleshooting

- **SSH connection refused**: Wait a few minutes after deployment for cloud-init to complete
- **Permission denied**: Ensure you're using the `deploy` user, not `root`
- **Docker commands fail**: Log out and back in to pick up the docker group membership 
