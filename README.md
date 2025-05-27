# Saltbox Church Network Docker Stack

## Table of Contents

- [Saltbox Church Network Docker Stack](#saltbox-church-network-docker-stack)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [The Docker Host Server](#the-docker-host-server)
  - [Authenticate the GitHub Container Registry](#authenticate-the-github-container-registry)
  - [Initial Setup and Configuration](#initial-setup-and-configuration)
    - [1. Run the Setup Script](#1-run-the-setup-script)
    - [2. Configure Environment Variables](#2-configure-environment-variables)
      - [Main Environment Variables](#main-environment-variables)
      - [Backend Configuration (`env/backend.env`)](#backend-configuration-envbackendenv)
      - [Frontend Configuration (`env/frontend.env`)](#frontend-configuration-envfrontendenv)
      - [Database Configuration (`env/postgres.env`)](#database-configuration-envpostgresenv)
    - [3. Start Traefik (Reverse Proxy)](#3-start-traefik-reverse-proxy)
    - [4. Pull Docker Images and Start the Application](#4-pull-docker-images-and-start-the-application)
    - [5. Verify the Deployment](#5-verify-the-deployment)
    - [Available Aliases](#available-aliases)
    - [Available Scripts](#available-scripts)
  - [Maintenance Mode](#maintenance-mode)
    - [How It Works](#how-it-works)
    - [Usage](#usage)
    - [Customizing the Maintenance Page](#customizing-the-maintenance-page)

## Overview

This is the repository for managing the entire Saltbox Church Network app stack. It houses the
compose file for the stack. `Dockerfile`s are located in the individual repos.

The basic workflow is that you build the images for each service that contains a
`Dockerfile` in the respective repo, which you push to the GitHub container
registry. Then you pull the images on the docker host server and run the stack.

## The Docker Host Server

- Install Ubuntu 22.04 on a server. We're using Digital Ocean

- Enable firewall and allow ports `443`, `80`, `22`

- Create a user named `deploy` with sudo privileges:
 
  ```
  ssh root@<ip> adduser deploy
  ```

- Add deploy user to sudoers

  ```
  usermod -aG sudo deploy
  ```

- Allow `deploy` user to sudo without password by adding the following line to
`/etc/sudoers` via the `visudo` command:

 ```
deploy ALL=(ALL) NOPASSWD:ALL
 ```

- Add your ssh key to the deploy user `authorized_keys`

- Install docker using https://get.docker.com

  ```
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  ```
- Add the deploy user to the docker group

  ``` 
  sudo usermod -aG docker deploy
  ```

- Logout and log back in to pick up the new group. Test with:

  ```
  docker ps
  docker run hello-world
  ```

- Create a SSH key on the deploy server 

  ```
  ssh-keygen -t ed25519
  ```

- Grant the `~/.ssh/id_ed25519.pub`  deploy role on the *scn-deploy* GitHub repo.

  Navigate to **Repo > Settings > Deploy Keys > Add Deploy Key**
 
- Create a docker directory under `/home/deploy` and clone this repo into it

  ```
  mkdir docker
  cd docker
  git clone git@github.com:steveclarke/scn-deploy.git scn
  ```

- Authenticate the GitHub container registry on the docker host (see docs below)

- Copy and edit the `env/*.env` files as needed.

## Authenticate the GitHub Container Registry

https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

```bash
export CR_PAT=YOUR_TOKEN
```

```bash
$ echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
> Login Succeeded
```

## Initial Setup and Configuration

After cloning the repository and authenticating with the GitHub Container Registry, follow these steps to set up and start the environment:

### 1. Run the Setup Script

The setup script will create environment files from templates and configure shell aliases:

```bash
bin/setup
```

This script will:
- Copy `.env.template` to `.env` (if it doesn't exist)
- Copy all `env/*.env.template` files to `env/*.env` files
- Add SCN aliases to your `~/.bashrc` for convenient commands

### 2. Configure Environment Variables

Edit the environment files created by the setup script:

#### Main Environment Variables
Edit the main `.env` file to set:
- `BACKEND_IMAGE` - The backend Docker image (e.g., `ghcr.io/username/scn-backend:latest`)
- `FRONTEND_IMAGE` - The frontend Docker image (e.g., `ghcr.io/username/scn-frontend:latest`)
- `BACKEND_HOST_HEADER` - The domain for the API (e.g., `api.yourdomain.com`)
- `FRONTEND_HOST_HEADER` - The domain for the frontend (e.g., `yourdomain.com`)

#### Backend Configuration (`env/backend.env`)
- `RAILS_MASTER_KEY` - Rails master key for encrypted credentials
- `DATABASE_URL` - Update the password in the PostgreSQL connection string
- `CORE_APP_ENV` - Set to `production` for production deployments

#### Frontend Configuration (`env/frontend.env`)
- `NUXT_PUBLIC_CDN_URL` - CDN URL for static assets
- `NUXT_PUBLIC_SCRIPTS_GOOGLE_ANALYTICS_ID` - Google Analytics tracking ID (optional)

#### Database Configuration (`env/postgres.env`)
- `POSTGRES_PASSWORD` - Set a secure password for the PostgreSQL database

### 3. Start Traefik (Reverse Proxy)

Start the Traefik reverse proxy first, as it handles SSL certificates and routing:

```bash
bin/lift
```

Or using the full command:
```bash
docker compose -f traefik.compose.yml up -d
```

### 4. Pull Docker Images and Start the Application

Pull the latest images and start the application stack:

```bash
docker compose pull
bin/up
```

Or using the full commands:
```bash
docker compose pull
docker compose up -d
```

### 5. Verify the Deployment

Check that all services are running:

```bash
docker ps
```

You can also use the convenient alias:
```bash
dps
```

### Available Aliases

After running `bin/setup`, the following aliases will be available in new terminal sessions:
- `c` - Change to the SCN project directory
- `ff` - Clear the terminal
- `dc` - Shortcut for `docker compose`
- `dps` - Show running containers in a formatted table

### Available Scripts

The following convenience scripts are available in the `bin/` directory:
- `bin/lift` - Start Traefik reverse proxy
- `bin/up` - Start the application stack
- `bin/down` - Stop the application stack
- `bin/runner` - Run commands in the runner container (useful for Rails console, migrations, etc.)

## Maintenance Mode

The system supports a container-based maintenance mode that uses Traefik's routing capabilities to redirect all traffic to a maintenance page.

### How It Works

- A dedicated `maintenance` service is defined in `compose.yml` using nginx:alpine
- The service mounts the `maintenance` directory to serve the maintenance page
- Traefik routes with high priority (100) intercept all traffic to both the API and frontend applications
- The maintenance page at `maintenance/index.html` is shown to all users

### Usage

The `bin/maintenance` script can be used to toggle maintenance mode:

```bash
bin/maintenance on      # Enable maintenance mode
bin/maintenance off     # Disable maintenance mode
bin/maintenance status  # Check if maintenance mode is enabled
```

When maintenance mode is enabled, the script starts the maintenance container which intercepts all traffic. When disabled, the container is stopped and normal service resumes.

The `status` parameter checks the current state of maintenance mode and outputs whether it's enabled or disabled. It also returns a success exit code (0) when enabled and a failure exit code (1) when disabled, making it useful for scripting.

### Customizing the Maintenance Page

The maintenance page is located at `maintenance/index.html`. You can customize this file to match your branding and provide appropriate messaging.

The page includes:
- Responsive design with dark mode support
- Saltbox Church Network branding
- Optional JavaScript for displaying estimated completion time (commented out by default)
