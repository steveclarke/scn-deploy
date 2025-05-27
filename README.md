# Saltbox Church Network Docker Stack

## Table of Contents

- [Saltbox Church Network Docker Stack](#saltbox-church-network-docker-stack)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [The Docker Host Server](#the-docker-host-server)
  - [Authenticate the GitHub Container Registry](#authenticate-the-github-container-registry)
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
