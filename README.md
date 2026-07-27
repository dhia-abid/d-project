# Docker Learning Lab - Simple Containerized Web App

A beginner-friendly DevOps learning project that demonstrates the complete deployment pipeline from browser to Docker container.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Explanation](#architecture-explanation)
3. [Installation Guide](#installation-guide)
4. [Running the Application](#running-the-application)
5. [Networking Explanation](#networking-explanation)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Manual Learning Section](#manual-learning-section)
8. [Explain Every Decision](#explain-every-decision)
9. [Commands Reference](#commands-reference)
10. [Security Configuration](#security-configuration)

---

## Project Overview

### What This Application Does

This is a simple web application with two buttons that trigger CSS animations:

- **Button 1**: Triggers a spin and scale animation
- **Button 2**: Triggers a bounce and color change animation

The application itself is intentionally simple because the **purpose is learning**, not complexity. This project serves as a hands-on laboratory for understanding:

- Docker containers and images
- Docker Compose orchestration
- Reverse proxy configuration with Nginx
- Linux networking fundamentals
- DNS and local domain resolution
- Firewall configuration with firewalld
- SSH security basics

### Why This Architecture Was Chosen

This architecture represents a **production-like deployment pattern** while remaining simple enough for beginners:

1. **Separation of concerns**: The web server (Nginx) is separate from the application (Flask)
2. **Security**: The application is not directly exposed to the internet
3. **Scalability**: This pattern can scale to multiple application containers
4. **Real-world relevance**: This is how modern web applications are actually deployed

---

## Architecture Explanation

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Browser                             │
│                  (Chrome, Firefox, etc.)                    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ HTTP Request
                               │ http://myapp.local or http://localhost
                               ↓
┌─────────────────────────────────────────────────────────────┐
│                  Fedora VM Firewall                          │
│                   (firewalld)                                │
│                    Port 80 Open                              │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────┐
│              Nginx Container (Reverse Proxy)                 │
│                   Port 80 (Exposed)                          │
│                   nginx.conf                                 │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ Proxy Pass to app:5000
                               ↓
┌─────────────────────────────────────────────────────────────┐
│              Docker Network (app_network)                    │
│                   Bridge Network                             │
│                   Internal DNS Resolution                     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────┐
│              Flask Application Container                     │
│                   Port 5000 (Internal)                      │
│                   Gunicorn WSGI Server                       │
│                   Python Flask App                           │
└─────────────────────────────────────────────────────────────┘
```

### Component Explanations

#### 1. User Browser
- **What**: The web browser on your computer or inside the VM
- **Role**: Initiates HTTP requests to view the web application
- **Access methods**:
  - `http://localhost` - Resolves to 127.0.0.1 (your own machine)
  - `http://myapp.local` - Local domain name (requires /etc/hosts configuration)
  - `http://<VM-IP>` - Direct IP access to the Fedora VM

#### 2. Fedora VM Firewall (firewalld)
- **What**: Fedora's default firewall management system
- **Role**: Controls which network traffic is allowed into the VM
- **Configuration**: Port 80 must be open for HTTP traffic
- **Why needed**: Security - only allow necessary traffic

#### 3. Nginx Container (Reverse Proxy)
- **What**: A lightweight, high-performance web server and reverse proxy
- **Role**: 
  - Receives incoming HTTP requests on port 80
  - Forwards requests to the Flask application
  - Handles SSL/TLS termination (not implemented in this basic version)
  - Provides load balancing capabilities (for future scaling)
- **Why use Nginx instead of exposing Flask directly**:
  - **Security**: Flask is not designed to handle direct internet exposure
  - **Performance**: Nginx is faster at serving static files and handling connections
  - **Flexibility**: Easy to add SSL, caching, and other features
  - **Standard practice**: This is how production applications are deployed

#### 4. Docker Network (app_network)
- **What**: A virtual network created by Docker Compose
- **Type**: Bridge network (isolated network for containers)
- **Role**: Enables communication between containers
- **DNS**: Docker provides internal DNS so containers can reach each other by name
- **Why needed**: Containers need to communicate without exposing ports to the host

#### 5. Flask Application Container
- **What**: Container running the Python Flask web application
- **Server**: Gunicorn (production WSGI server, not Flask's built-in dev server)
- **Port**: Listens on port 5000 internally (not exposed to host)
- **Role**: Handles application logic and serves the web page
- **Why not exposed directly**: Security best practice - always use a reverse proxy

---

## Installation Guide

### Prerequisites

- Fedora Linux VM running in VirtualBox
- LXQt desktop environment (or any desktop environment)
- User account with sudo privileges
- Internet connection

### Step 1: Update System

```bash
sudo dnf update -y
```

**Explanation**:
- `sudo`: Run with superuser (administrator) privileges
- `dnf`: Fedora's package manager (Dandified YUM)
- `update`: Update all installed packages to latest versions
- `-y`: Automatically answer "yes" to all prompts

**Why**: Ensures your system has the latest security patches and bug fixes.

### Step 2: Install Docker

```bash
sudo dnf install -y docker
```

**Explanation**:
- `install`: Install new packages
- `docker`: The Docker containerization platform

**Why**: Docker is required to run containers.

### Step 3: Enable and Start Docker Service

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

**Explanation**:
- `systemctl`: System service manager
- `enable`: Enable service to start automatically on boot
- `start`: Start the service immediately

**Why**: Docker runs as a background service (daemon) and needs to be running.

### Step 4: Add User to Docker Group

```bash
sudo usermod -aG docker $USER
```

**Explanation**:
- `usermod`: Modify user account
- `-aG docker`: Append user to docker group
- `$USER`: Your current username

**Why**: Allows you to run Docker commands without sudo. **Important**: You must log out and log back in for this to take effect.

### Step 5: Verify Docker Installation

```bash
docker --version
docker run hello-world
```

**Explanation**:
- `--version`: Show Docker version
- `run hello-world`: Run a test container to verify Docker works

**Expected output**: "Hello from Docker!" message indicating successful installation.

### Step 6: Install Docker Compose

```bash
sudo dnf install -y docker-compose
```

**Explanation**: Docker Compose is a separate tool for managing multi-container applications.

**Why**: Our project uses Docker Compose to orchestrate the app and nginx containers.

### Step 7: Clone or Copy Project Files

If you have this project in a git repository:

```bash
git clone <repository-url>
cd <project-directory>
```

Otherwise, copy the project folder to your Fedora VM.

### Step 8: Configure Local DNS (Optional but Recommended)

Edit `/etc/hosts` to add local domain resolution:

```bash
sudo nano /etc/hosts
```

Add this line at the end:

```
127.0.0.1    myapp.local
```

**Explanation**:
- `/etc/hosts`: Local DNS configuration file
- `127.0.0.1`: Localhost IP address
- `myapp.local`: Your custom domain name

**Why**: Allows you to access the app at `http://myapp.local` instead of `http://localhost`

**Save and exit**: Press `Ctrl+X`, then `Y`, then `Enter`

### Step 9: Configure Firewall

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Explanation**:
- `firewall-cmd`: Firewall management command
- `--permanent`: Make rule persistent across reboots
- `--add-service=http`: Allow HTTP traffic (port 80)
- `--reload`: Apply the changes

**Why**: The firewall blocks incoming traffic by default. We need to allow HTTP.

### Step 10: Verify Firewall Configuration

```bash
sudo firewall-cmd --list-all
```

**Expected output**: Should show `http` under `services`.

---

## Running the Application

### Step 1: Navigate to Project Directory

```bash
cd /path/to/project
```

### Step 2: Build Docker Images

```bash
docker compose build
```

**Explanation**:
- `compose`: Use Docker Compose
- `build`: Build images based on Dockerfile

**What happens**:
1. Docker reads `docker-compose.yml`
2. For the `app` service, it reads the `Dockerfile`
3. Downloads base Python image (if not already cached)
4. Installs dependencies from `requirements.txt`
5. Copies application code
6. Creates a Docker image

**Why**: Images must be built before containers can run.

### Step 3: Start Containers

```bash
docker compose up
```

**Explanation**:
- `up`: Create and start containers

**What happens**:
1. Docker Compose reads `docker-compose.yml`
2. Creates a network named `app_network`
3. Builds the app image (if not already built)
4. Creates and starts the `app` container
5. Pulls the nginx image (if not already cached)
6. Creates and starts the `nginx` container
7. Maps port 80 on host to port 80 in nginx container

**Expected output**: Logs from both containers showing they started successfully.

### Step 4: Run in Detached Mode (Optional)

To run containers in the background:

```bash
docker compose up -d
```

**Explanation**:
- `-d`: Detached mode (run in background)

**Why**: Frees up your terminal for other commands.

### Step 5: Check Running Containers

```bash
docker ps
```

**Explanation**:
- `ps`: List running containers

**Expected output**: Should show two containers: `flask_app` and `nginx_proxy`.

**Columns explained**:
- `CONTAINER ID`: Unique identifier
- `IMAGE`: Image used to create container
- `COMMAND`: Command running in container
- `CREATED`: When container was created
- `STATUS`: Current status (should be "Up X minutes")
- `PORTS`: Port mappings (should show `0.0.0.0:80->80/tcp`)
- `NAMES`: Container names

### Step 6: View Container Logs

```bash
docker logs flask_app
docker logs nginx_proxy
```

**Explanation**:
- `logs`: Show container output
- `flask_app` / `nginx_proxy`: Container names

**Why**: Debugging - see what's happening inside containers.

**Follow logs in real-time**:

```bash
docker logs -f flask_app
```

**Explanation**: `-f` flag follows log output (like `tail -f`).

### Step 7: Access the Application

Open your browser and navigate to:

- `http://localhost`
- `http://myapp.local` (if you configured /etc/hosts)
- `http://127.0.0.1`

**Expected result**: A page with two buttons and a colored box. Click buttons to see animations.

### Step 8: Stop Containers

```bash
docker compose down
```

**Explanation**:
- `down`: Stop and remove containers and networks

**What happens**:
1. Stops both containers
2. Removes containers
3. Removes the network
4. Keeps images (for faster rebuilds)

### Step 9: Stop and Remove Everything (Including Images)

```bash
docker compose down --rmi all
```

**Explanation**:
- `--rmi all`: Also remove images

**Why**: Clean slate - rebuild everything from scratch.

---

## Networking Explanation

### IP Addresses

An IP address is a numerical label assigned to each device on a computer network.

**Key concepts**:

- **IPv4**: Most common format (e.g., `192.168.1.1`, `127.0.0.1`)
- **IPv6**: Newer format (e.g., `::1`, `2001:db8::1`)
- **Private IPs**: Used internally (e.g., `192.168.x.x`, `10.x.x.x`)
- **Public IPs**: Used on the internet

**In this project**:
- `127.0.0.1`: Localhost (your own machine)
- `172.x.x.x`: Docker bridge network (internal container communication)
- VM IP: Your Fedora VM's IP on the VirtualBox network

### Ports

A port is a communication endpoint. Think of IP as the building address and port as the apartment number.

**Key concepts**:
- **Port numbers**: 0-65535
- **Well-known ports**: 0-1023 (require root/admin)
- **Registered ports**: 1024-49151
- **Dynamic ports**: 49152-65535

**In this project**:
- **Port 80**: HTTP (standard web traffic)
- **Port 5000**: Flask application (internal, not exposed)
- **Port mapping**: `80:80` maps host port 80 to container port 80

**Why port mapping**: Containers are isolated. Port mapping allows external access.

### TCP Basics

TCP (Transmission Control Protocol) is a reliable, connection-oriented protocol.

**Key concepts**:
- **Three-way handshake**: SYN, SYN-ACK, ACK (establishes connection)
- **Reliable delivery**: Guarantees data arrives in order
- **Flow control**: Manages data transmission rate

**In this project**: HTTP runs over TCP. Your browser establishes a TCP connection to Nginx.

### DNS Basics

DNS (Domain Name System) translates domain names to IP addresses.

**Key concepts**:
- **DNS hierarchy**: Root → TLD → Domain → Subdomain
- **DNS servers**: Servers that store DNS records
- **Resolution process**: Browser → OS → DNS server → IP address

**In this project**:
- **Public DNS**: Not needed for local development
- **/etc/hosts**: Local DNS override (bypasses public DNS)
- **Local domain**: `myapp.local` resolves to `127.0.0.1`

**DNS resolution order**:
1. Check `/etc/hosts`
2. Check local cache
3. Query DNS servers

### Localhost

**Localhost** refers to your own computer.

**Key concepts**:
- **localhost**: Domain name that resolves to `127.0.0.1`
- **127.0.0.1**: Loopback IP address (always points to your own machine)
- **::1**: IPv6 loopback address

**Why use localhost**: Testing without network dependency.

### Docker Networking

Docker provides several network drivers:

**Bridge (default)**:
- Isolated network for containers
- Containers can communicate by name
- Port mapping for external access

**Host**:
- Container uses host's network stack
- No isolation
- Performance benefit

**Overlay**:
- Multi-host networking
- For swarm/clusters

**None**:
- No network access
- For highly secure containers

**In this project**:
- **Network name**: `app_network`
- **Driver**: bridge
- **Internal DNS**: Docker provides DNS so `nginx` can reach `app` by name

**Container communication**:
- Nginx config: `proxy_pass http://app:5000`
- Docker DNS resolves `app` to container's internal IP
- No need to know actual IP addresses

---

## Troubleshooting Guide

### Problem: Website Does Not Open

**Possible causes and solutions**:

#### 1. Containers Not Running

**Check**:
```bash
docker ps
```

**If no containers listed**:
```bash
docker compose up
```

**Explanation**: Containers must be running to serve the application.

#### 2. Wrong Port

**Check**:
```bash
docker ps
```

**Look at PORTS column**: Should show `0.0.0.0:80->80/tcp`

**If not**:
- Check `docker-compose.yml` port mapping
- Ensure no other service is using port 80

**Check what's using port 80**:
```bash
sudo ss -tulpn | grep :80
```

**Explanation**: Port conflicts prevent Nginx from starting.

#### 3. Firewall Blocking

**Check**:
```bash
sudo firewall-cmd --list-all
```

**Look for `http` under services**.

**If not listed**:
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Explanation**: Firewall blocks traffic by default.

#### 4. Nginx Configuration Error

**Check logs**:
```bash
docker logs nginx_proxy
```

**Common errors**:
- Syntax error in `nginx.conf`
- Upstream server not reachable
- Permission issues

**Test nginx config**:
```bash
docker exec nginx_proxy nginx -t
```

**Explanation**: Nginx won't start if config is invalid.

#### 5. Application Container Error

**Check logs**:
```bash
docker logs flask_app
```

**Common errors**:
- Python syntax error
- Missing dependencies
- Port already in use

**Explanation**: If app container fails, Nginx can't proxy to it.

#### 6. DNS/Hosts Issue

**If using myapp.local**:
```bash
cat /etc/hosts
```

**Should contain**:
```
127.0.0.1    myapp.local
```

**If not**: Add the line as shown in Installation Guide.

**Test DNS resolution**:
```bash
ping myapp.local
```

**Should ping 127.0.0.1**.

**Alternative**: Use `http://localhost` or `http://127.0.0.1`.

### Problem: Container Keeps Restarting

**Check**:
```bash
docker ps -a
```

**Look at STATUS**: Should show "Restarting" if container is crashing.

**Check logs**:
```bash
docker logs flask_app
```

**Common causes**:
- Application crash
- Missing dependencies
- Configuration error

**Solution**: Fix the error in code or config, then rebuild:
```bash
docker compose down
docker compose build
docker compose up
```

### Problem: Changes Not Reflecting

**If you modified code but don't see changes**:

**Rebuild image**:
```bash
docker compose down
docker compose build
docker compose up
```

**Explanation**: Docker images are immutable. Changes require rebuilding.

**For nginx.conf changes**:
- If using volume mount (as in this project): Changes apply automatically on restart
- Restart nginx:
```bash
docker compose restart nginx
```

### Problem: Permission Denied

**If you get "permission denied" errors**:

**Add user to docker group** (if not done):
```bash
sudo usermod -aG docker $USER
```

**Log out and log back in**.

**Or use sudo**:
```bash
sudo docker compose up
```

**Explanation**: Docker requires group membership for socket access.

### Problem: Cannot Access from Another Machine

**If you want to access from host machine**:

**Find VM IP**:
```bash
ip addr show
```

**Look for IP under your network interface** (e.g., `eth0`, `enp0s3`).

**From host browser**: `http://<VM-IP>`

**If still not accessible**:
- Check VirtualBox network settings (should be Bridged or Host-only)
- Check firewall on Fedora VM
- Check firewall on host machine

---

## Manual Learning Section

If you wanted to rebuild this project manually without AI, these are the concepts you need to learn.

### Linux Topics

#### Filesystem
- **Directory structure**: Understanding `/home`, `/etc`, `/var`, etc.
- **Absolute vs relative paths**: `/home/user/file` vs `./file`
- **File permissions**: `rwx` permissions, `chmod`, `chown`
- **Hidden files**: Files starting with `.` (like `.env`)

**Commands to learn**:
- `ls`: List files
- `cd`: Change directory
- `pwd`: Print working directory
- `mkdir`: Create directory
- `rm`: Remove files/directories
- `cp`: Copy files
- `mv`: Move/rename files

#### Permissions
- **User/Group/Others**: Permission categories
- **Read/Write/Execute**: Permission types
- **Numeric notation**: `755`, `644`, etc.
- **sudo**: Running commands as superuser

**Commands to learn**:
- `chmod`: Change permissions
- `chown`: Change owner
- `sudo`: Execute as superuser
- `su`: Switch user

#### Processes
- **Process ID (PID)**: Unique identifier for running processes
- **Parent/child processes**: Process hierarchy
- **Signals**: Communication between processes (SIGTERM, SIGKILL)
- **Daemons**: Background processes

**Commands to learn**:
- `ps`: List processes
- `top`: Monitor processes
- `kill`: Send signals to processes
- `pkill`: Kill processes by name
- `pgrep`: Find process IDs

#### Services
- **Systemd**: Linux service manager
- **Units**: Services, sockets, timers, etc.
- **Enabling/disabling**: Auto-start configuration
- **Status checking**: Verify service health

**Commands to learn**:
- `systemctl start`: Start service
- `systemctl stop`: Stop service
- `systemctl restart`: Restart service
- `systemctl enable`: Enable auto-start
- `systemctl status`: Check status
- `journalctl`: View logs

#### SSH
- **SSH protocol**: Secure remote login
- **SSH keys**: Public/private key authentication
- **SSH config**: Client configuration
- **SSH daemon**: Server configuration

**Commands to learn**:
- `ssh`: Connect to remote server
- `ssh-keygen`: Generate SSH keys
- `ssh-copy-id`: Copy public key to server
- `scp`: Secure copy over SSH

### Networking Topics

#### IP Addresses
- **IPv4 vs IPv6**: Address formats
- **Private vs Public**: Address ranges
- **Subnetting**: Network segmentation
- **CIDR notation**: `192.168.1.0/24`

**Commands to learn**:
- `ip`: Show/configure IP addresses
- `ifconfig`: Legacy IP command (deprecated)
- `ping`: Test connectivity
- `traceroute`: Trace packet path

#### Ports
- **Port numbers**: Service identification
- **Well-known ports**: Standard services
- **Port binding**: Associating with IP
- **Port forwarding**: Routing traffic

**Commands to learn**:
- `ss`: Socket statistics (modern)
- `netstat`: Network statistics (legacy)
- `lsof`: List open files (including ports)
- `nmap`: Network scanning

#### DNS
- **Domain hierarchy**: Root → TLD → Domain
- **DNS records**: A, AAAA, CNAME, MX, etc.
- **DNS resolution**: Query process
- **Local DNS**: `/etc/hosts`, local cache

**Commands to learn**:
- `nslookup`: DNS lookup
- `dig`: DNS lookup (more detailed)
- `host`: Simple DNS lookup
- `/etc/hosts`: Local DNS file

#### NAT (Network Address Translation)
- **Purpose**: IP address conservation
- **Types**: Static, dynamic, PAT
- **Port forwarding**: NAT variant
- **Docker NAT**: Container networking

**Concepts to learn**:
- How VirtualBox networking works
- Bridge vs NAT networking
- Port forwarding in VirtualBox

#### Firewall
- **Purpose**: Network security
- **Rules**: Allow/deny logic
- **Zones**: Firewalld concept
- **Services vs Ports**: Abstraction levels

**Commands to learn**:
- `firewall-cmd`: Firewalld management
- `iptables`: Low-level firewall rules
- `ufw`: Ubuntu firewall (simpler)

### Docker Topics

#### Images
- **What**: Read-only templates for containers
- **Layers**: Union filesystem
- **Dockerfile**: Image definition
- **Registry**: Image storage (Docker Hub)

**Commands to learn**:
- `docker build`: Build image
- `docker pull`: Download image
- `docker push`: Upload image
- `docker images`: List images
- `docker rmi`: Remove image

#### Containers
- **What**: Running instances of images
- **Lifecycle**: Create, start, stop, remove
- **Isolation**: Process, network, filesystem
- **Resources**: CPU, memory limits

**Commands to learn**:
- `docker run`: Create and start container
- `docker start`: Start stopped container
- `docker stop`: Stop running container
- `docker restart`: Restart container
- `docker rm`: Remove container
- `docker ps`: List containers

#### Volumes
- **What**: Persistent data storage
- **Types**: Named, bind mount, tmpfs
- **Lifecycle**: Independent of containers
- **Backup**: Volume management

**Commands to learn**:
- `docker volume create`: Create volume
- `docker volume ls`: List volumes
- `docker volume rm`: Remove volume
- `docker volume inspect`: Inspect volume

#### Networks
- **What**: Container communication
- **Drivers**: Bridge, host, overlay, none
- **DNS**: Internal name resolution
- **Isolation**: Network segmentation

**Commands to learn**:
- `docker network create`: Create network
- `docker network ls`: List networks
- `docker network inspect`: Inspect network
- `docker network connect`: Connect container
- `docker network disconnect`: Disconnect container

#### Compose
- **What**: Multi-container orchestration
- **YAML**: Configuration format
- **Services**: Container definitions
- **Dependencies**: Startup order

**Commands to learn**:
- `docker compose up`: Start services
- `docker compose down`: Stop services
- `docker compose build`: Build images
- `docker compose ps`: List containers
- `docker compose logs`: View logs

### Web Topics

#### HTTP
- **Protocol**: Hypertext Transfer Protocol
- **Methods**: GET, POST, PUT, DELETE
- **Status codes**: 200, 404, 500, etc.
- **Headers**: Metadata in requests/responses

**Tools to learn**:
- `curl`: Command-line HTTP client
- `wget`: Download files
- Browser DevTools: Inspect HTTP traffic

#### Reverse Proxy
- **What**: Server that forwards requests
- **Benefits**: Security, performance, flexibility
- **Load balancing**: Distributing traffic
- **SSL termination**: Handling HTTPS

**Concepts to learn**:
- Forward proxy vs reverse proxy
- Proxy headers (X-Forwarded-For)
- Upstream servers
- Health checks

#### Nginx
- **What**: Web server and reverse proxy
- **Configuration**: Directive-based
- **Events/HTTP/Server blocks**: Hierarchy
- **Upstreams**: Backend definitions

**Directives to learn**:
- `listen`: Port configuration
- `server_name`: Domain matching
- `location`: URL path matching
- `proxy_pass`: Forwarding requests
- `proxy_set_header`: Header manipulation

---

## Explain Every Decision

### Why Nginx Instead of Exposing Flask Directly?

**Decision**: Use Nginx as a reverse proxy instead of exposing Flask directly to the internet.

**Reasons**:

1. **Security**: Flask's built-in server is not designed for production. It's single-threaded and not hardened against attacks. Nginx is battle-tested and secure.

2. **Performance**: Nginx can handle thousands of concurrent connections efficiently. Flask would struggle under load.

3. **Features**: Nginx provides:
   - SSL/TLS termination (HTTPS)
   - Static file serving (faster than Flask)
   - Load balancing (for multiple app instances)
   - Caching
   - Rate limiting
   - Request buffering

4. **Separation of concerns**: Web server (Nginx) handles HTTP, application server (Flask) handles business logic.

5. **Industry standard**: This is how production applications are deployed. Learning this pattern prepares you for real-world scenarios.

**Alternative considered**: Expose Flask directly on port 80.

**Why rejected**: Less secure, less performant, not professional practice.

### Why Docker Compose?

**Decision**: Use Docker Compose instead of running containers manually with `docker run`.

**Reasons**:

1. **Simplicity**: One command (`docker compose up`) vs multiple complex `docker run` commands.

2. **Configuration as code**: `docker-compose.yml` documents the entire setup in one file.

3. **Networking**: Compose automatically creates and manages networks.

4. **Dependencies**: Compose handles startup order (nginx waits for app).

5. **Reproducibility**: Anyone can run the same setup with the same file.

6. **Development workflow**: Easy to start/stop entire stack.

**Alternative considered**: Use individual `docker run` commands.

**Why rejected**: More error-prone, harder to document, not reproducible.

### Why a Local DNS Entry?

**Decision**: Configure `myapp.local` in `/etc/hosts` instead of just using `localhost`.

**Reasons**:

1. **Learning**: Teaches how DNS and `/etc/hosts` work.

2. **Realism**: Simulates a real domain name without buying one.

3. **Flexibility**: Easy to change domain by editing one file.

4. **Testing**: Tests reverse proxy's domain handling.

5. **Best practice**: Production apps use domain names, not IPs.

**Alternative considered**: Only use `localhost`.

**Why rejected**: Misses learning opportunity, less realistic.

### Why Port 80?

**Decision**: Use port 80 for HTTP instead of a non-standard port like 8080.

**Reasons**:

1. **Standard**: Port 80 is the standard HTTP port.

2. **Simplicity**: No need to specify port in URL (`http://myapp.local` vs `http://myapp.local:8080`).

3. **Firewall**: HTTP is a pre-defined service in firewalld.

4. **Realism**: Production apps use standard ports.

5. **Learning**: Teaches about well-known ports.

**Alternative considered**: Use port 8080.

**Why rejected**: Non-standard, requires port in URL, less realistic.

### Why This Folder Structure?

**Decision**: Organize project with separate `app/` and `nginx/` directories.

**Reasons**:

1. **Separation of concerns**: Application code separate from infrastructure config.

2. **Clarity**: Easy to find what you need.

3. **Scalability**: Easy to add more services (e.g., database in `db/`).

4. **Professional**: Follows industry best practices.

5. **Docker context**: `app/` contains only what the app container needs.

**Structure explained**:
```
project/
├── app/              # Application code
│   ├── app.py        # Flask application
│   ├── requirements.txt  # Python dependencies
│   ├── templates/    # HTML templates
│   └── static/       # CSS, JS, images
├── nginx/            # Nginx configuration
│   └── nginx.conf    # Nginx config file
├── Dockerfile        # App container build instructions
├── docker-compose.yml # Multi-container orchestration
├── .env.example      # Environment variables template
└── README.md         # Documentation
```

**Alternative considered**: Put everything in root directory.

**Why rejected**: Messy, hard to maintain, not professional.

### Why Gunicorn Instead of Flask's Built-in Server?

**Decision**: Use Gunicorn as the WSGI server instead of `flask run`.

**Reasons**:

1. **Production-ready**: Gunicorn is designed for production. Flask's server is for development only.

2. **Performance**: Gunicorn can handle multiple concurrent requests with worker processes.

3. **Stability**: Gunicorn is more stable under load.

4. **Process management**: Gunicorn manages worker processes, auto-restarts crashed workers.

5. **Standard practice**: This is how Python web apps are deployed in production.

**Alternative considered**: Use Flask's built-in server with `flask run`.

**Why rejected**: Not production-ready, single-threaded, not secure.

### Why Python 3.11 Slim Image?

**Decision**: Use `python:3.11-slim` as the base image.

**Reasons**:

1. **Small size**: "Slim" variant is much smaller than full image (~100MB vs ~900MB).

2. **Security**: Fewer packages = smaller attack surface.

3. **Sufficient**: Contains everything needed to run Python apps.

4. **Modern**: Python 3.11 is recent and performant.

**Alternative considered**: Use `python:3.11` (full image).

**Why rejected**: Unnecessary bloat, larger download, more security updates needed.

### Why Alpine Linux for Nginx?

**Decision**: Use `nginx:alpine` image.

**Reasons**:

1. **Tiny size**: Alpine Linux is extremely small (~5MB base).

2. **Security**: Minimal packages = small attack surface.

3. **Performance**: Lightweight and fast.

4. **Sufficient**: Contains everything needed to run Nginx.

**Alternative considered**: Use `nginx:latest` (Debian-based).

**Why rejected**: Larger size (~140MB vs ~40MB), more unnecessary packages.

### Why Bridge Network?

**Decision**: Use Docker's bridge network driver.

**Reasons**:

1. **Isolation**: Containers are isolated from host network.

2. **Communication**: Containers can communicate with each other.

3. **DNS**: Docker provides internal DNS for service discovery.

4. **Default**: Bridge is the default and most common network type.

5. **Sufficient**: Port mapping allows external access when needed.

**Alternative considered**: Use host network.

**Why rejected**: No isolation, security risk, port conflicts, not professional.

### Why Restart Policy "unless-stopped"?

**Decision**: Set `restart: unless-stopped` in docker-compose.yml.

**Reasons**:

1. **Resilience**: Containers restart automatically if they crash.

2. **Convenience**: Don't have to manually restart after crashes.

3. **Production-like**: Production containers should auto-restart.

4. **Control**: "unless-stopped" allows manual stops without auto-restart.

**Alternative considered**: Use `restart: always`.

**Why rejected**: Would restart even when we manually stop it (annoying during development).

**Alternative considered**: No restart policy.

**Why rejected**: Containers stay stopped after crashes (bad for reliability).

---

## Commands Reference

### Docker Commands

#### `docker ps`
**Purpose**: List running containers.

**Example output**:
```
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                NAMES
abc123def456  nginx:alpine   "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   0.0.0.0:80->80/tcp   nginx_proxy
```

**Common flags**:
- `-a`: Show all containers (including stopped)
- `-q`: Only show container IDs

#### `docker images`
**Purpose**: List Docker images.

**Example output**:
```
REPOSITORY   TAG          IMAGE ID       CREATED        SIZE
nginx        alpine       abc123def456   2 days ago     40MB
<none>       <none>       def456ghi789   5 minutes ago   150MB
```

#### `docker compose up`
**Purpose**: Create and start containers.

**Flags**:
- `-d`: Detached mode (background)
- `--build`: Rebuild images before starting
- `--force-recreate`: Recreate containers even if no change

#### `docker compose down`
**Purpose**: Stop and remove containers and networks.

**Flags**:
- `--volumes`: Also remove volumes
- `--rmi all`: Also remove images
- `--remove-orphans`: Remove containers for services not in compose file

#### `docker logs`
**Purpose**: Show container logs.

**Flags**:
- `-f`: Follow log output (real-time)
- `--tail N`: Show last N lines
- `--since TIME`: Show logs since time
- `--until TIME`: Show logs until time

**Examples**:
```bash
docker logs flask_app
docker logs -f nginx_proxy
docker logs --tail 50 flask_app
```

#### `docker exec`
**Purpose**: Execute command in running container.

**Examples**:
```bash
docker exec -it flask_app bash
docker exec nginx_proxy nginx -t
```

**Flags**:
- `-it`: Interactive mode with TTY
- `-u USER`: Run as specific user

#### `docker build`
**Purpose**: Build Docker image from Dockerfile.

**Examples**:
```bash
docker build -t myapp:latest .
docker build -f Dockerfile.prod -t myapp:prod .
```

**Flags**:
- `-t NAME`: Tag the image
- `-f FILE`: Use specific Dockerfile
- `--no-cache`: Don't use cache

#### `docker run`
**Purpose**: Run a container from an image.

**Examples**:
```bash
docker run -d -p 80:80 nginx:alpine
docker run -it ubuntu bash
```

**Flags**:
- `-d`: Detached mode
- `-p PORT:PORT`: Port mapping
- `-v HOST:CONTAINER`: Volume mount
- `-e KEY=VALUE`: Environment variable
- `--name NAME`: Container name
- `--network NET`: Connect to network

### Linux Commands

#### `systemctl`
**Purpose**: Control systemd services.

**Examples**:
```bash
sudo systemctl start docker
sudo systemctl stop docker
sudo systemctl restart docker
sudo systemctl enable docker
sudo systemctl disable docker
sudo systemctl status docker
```

**Subcommands**:
- `start`: Start service
- `stop`: Stop service
- `restart`: Restart service
- `enable`: Enable auto-start on boot
- `disable`: Disable auto-start
- `status`: Show service status
- `is-active`: Check if active

#### `journalctl`
**Purpose**: View systemd logs.

**Examples**:
```bash
sudo journalctl -u docker
sudo journalctl -u docker -f
sudo journalctl --since today
```

**Flags**:
- `-u UNIT`: Show logs for specific unit
- `-f`: Follow logs (real-time)
- `--since TIME`: Show logs since time
- `--until TIME`: Show logs until time
- `-n LINES`: Show last N lines

#### `ss`
**Purpose**: Socket statistics (modern replacement for netstat).

**Examples**:
```bash
ss -tulpn
ss -tulpn | grep :80
ss -s
```

**Flags**:
- `-t`: TCP sockets
- `-u`: UDP sockets
- `-l`: Listening sockets
- `-p`: Show process
- `-n`: Numeric (don't resolve names)
- `-s`: Summary statistics

#### `firewall-cmd`
**Purpose**: Manage firewalld firewall.

**Examples**:
```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --add-service=http
sudo firewall-cmd --add-port=8080/tcp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Subcommands**:
- `--list-all`: Show all settings
- `--add-service=SVC`: Allow service temporarily
- `--add-port=PORT/PROTO`: Allow port temporarily
- `--permanent`: Make changes permanent
- `--reload`: Apply changes

#### `ip`
**Purpose**: Show/configure network interfaces (modern replacement for ifconfig).

**Examples**:
```bash
ip addr show
ip addr show eth0
ip route show
```

**Subcommands**:
- `addr`: Address configuration
- `route`: Routing table
- `link`: Network interfaces

#### Other Useful Linux Commands

**File operations**:
```bash
ls -la              # List files with details
cd /path/to/dir     # Change directory
pwd                 # Print working directory
mkdir dirname       # Create directory
rm filename          # Remove file
rm -r dirname       # Remove directory
cp src dest         # Copy file
mv src dest         # Move/rename file
cat filename        # Show file contents
less filename       # View file (scrollable)
tail -f filename    # Follow file (real-time)
```

**Permissions**:
```bash
chmod 755 file      # Set permissions
chown user:group file  # Change owner
sudo                # Run as superuser
su - user           # Switch user
```

**Process management**:
```bash
ps aux              # List processes
top                 # Monitor processes
kill PID            # Send signal to process
pkill name          # Kill process by name
```

**System information**:
```bash
uname -a            # System information
df -h               # Disk usage
free -h             # Memory usage
uptime              # System uptime
```

---

## Security Configuration

### SSH Configuration

SSH (Secure Shell) is used for secure remote access to your Fedora VM.

#### SSH Key Authentication

SSH keys are more secure than password authentication.

**Generate SSH key pair**:
```bash
ssh-keygen -t ed25519 -a 100
```

**Explanation**:
- `-t ed25519`: Use Ed25519 algorithm (modern, secure)
- `-a 100`: 100 key derivation rounds (harder to brute-force)

**Files created**:
- `~/.ssh/id_ed25519`: Private key (KEEP SECRET)
- `~/.ssh/id_ed25519.pub`: Public key (can be shared)

**Copy public key to server**:
```bash
ssh-copy-id user@hostname
```

**Or manually**:
```bash
cat ~/.ssh/id_ed25519.pub | ssh user@hostname "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### Disable Password Authentication

For better security, disable password authentication and require SSH keys.

**Edit SSH config**:
```bash
sudo nano /etc/ssh/sshd_config
```

**Change these lines**:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

**Restart SSH**:
```bash
sudo systemctl restart sshd
```

**Explanation**: Now only users with SSH keys can log in.

#### SSH Hardening Best Practices

1. **Use SSH keys**: More secure than passwords
2. **Disable root login**: Prevent direct root access
3. **Change default port**: Security through obscurity (limited benefit)
4. **Use fail2ban**: Block brute-force attempts
5. **Keep updated**: Security patches

**Disable root login**:
```
PermitRootLogin no
```

### Firewall Configuration

Firewalld is Fedora's default firewall management system.

#### Basic Concepts

- **Zones**: Pre-defined rule sets (public, home, work, etc.)
- **Services**: Named groups of ports (http, https, ssh)
- **Ports**: Individual port/protocol combinations
- **Permanent vs runtime**: Permanent rules survive reboots

#### Common Commands

**Check current zone**:
```bash
sudo firewall-cmd --get-default-zone
```

**List all settings**:
```bash
sudo firewall-cmd --list-all
```

**Allow service temporarily**:
```bash
sudo firewall-cmd --add-service=http
```

**Allow service permanently**:
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Allow port temporarily**:
```bash
sudo firewall-cmd --add-port=8080/tcp
```

**Allow port permanently**:
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

#### Firewall Best Practices

1. **Default deny**: Only allow necessary traffic
2. **Use services**: Prefer services over raw ports (more maintainable)
3. **Zone appropriately**: Use correct zone for your network
4. **Test changes**: Verify after making changes
5. **Document rules**: Know why each rule exists

**For this project**:
- Allow HTTP (port 80) for web access
- Allow SSH (port 22) for remote access
- Block everything else

---

## Project Folder Structure

```
project/
├── app/                          # Application directory
│   ├── app.py                    # Flask application main file
│   ├── requirements.txt          # Python dependencies
│   ├── templates/                # HTML templates
│   │   └── index.html            # Main page template
│   └── static/                   # Static files (CSS, JS, images)
│       ├── style.css             # Stylesheet
│       └── script.js             # JavaScript
├── nginx/                        # Nginx configuration
│   └── nginx.conf                # Nginx reverse proxy config
├── Dockerfile                    # Build instructions for app container
├── docker-compose.yml            # Multi-container orchestration
├── .env.example                  # Environment variables template
└── README.md                     # This file
```

### File Explanations

#### `app/app.py`
- **Purpose**: Main Flask application
- **Content**: Route handlers and application logic
- **Why**: Single file for simplicity in this learning project

#### `app/requirements.txt`
- **Purpose**: Python dependencies
- **Content**: List of packages with versions
- **Why**: Reproducible builds, exact versions

#### `app/templates/index.html`
- **Purpose**: HTML template for the web page
- **Content**: HTML structure with Jinja2 templating
- **Why**: Separation of presentation from logic

#### `app/static/style.css`
- **Purpose**: CSS styles for the web page
- **Content**: Styling rules and animations
- **Why**: Separation of concerns, easier maintenance

#### `app/static/script.js`
- **Purpose**: JavaScript for interactivity
- **Content**: Animation trigger logic
- **Why**: Client-side interactivity without server round-trips

#### `nginx/nginx.conf`
- **Purpose**: Nginx reverse proxy configuration
- **Content**: Upstream definition and proxy rules
- **Why**: Centralized web server configuration

#### `Dockerfile`
- **Purpose**: Build instructions for app container
- **Content**: Base image, dependencies, code copy, startup command
- **Why**: Reproducible container builds

#### `docker-compose.yml`
- **Purpose**: Multi-container orchestration
- **Content**: Service definitions, networks, volumes
- **Why**: One-command startup of entire stack

#### `.env.example`
- **Purpose**: Template for environment variables
- **Content**: Example configuration values
- **Why**: Documentation and security (don't commit actual .env)

#### `README.md`
- **Purpose**: Project documentation
- **Content**: Setup instructions, explanations, troubleshooting
- **Why**: Essential for learning and reproducibility

---

## Conclusion

This project provides a complete, production-like deployment environment for learning Docker, Linux, and networking fundamentals. By building and running this application, you've gained hands-on experience with:

- **Docker**: Images, containers, networks, compose
- **Linux**: Services, firewall, permissions, processes
- **Networking**: IP addresses, ports, DNS, reverse proxy
- **Web**: HTTP, Nginx, Flask
- **Security**: SSH keys, firewall rules

### Next Steps for Learning

1. **Modify the application**: Add a third button or new animation
2. **Add a database**: Include PostgreSQL or MySQL
3. **Add HTTPS**: Configure SSL/TLS with Let's Encrypt
4. **Add monitoring**: Include Prometheus and Grafana
5. **Deploy to cloud**: Try deploying to a VPS (DigitalOcean, Linode)

### Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Fedora Documentation](https://docs.fedoraproject.org/)
- [Linux Journey](https://linuxjourney.com/) - Interactive Linux tutorial

---

**Happy learning!**
