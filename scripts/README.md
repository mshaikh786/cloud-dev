# RKE2 Cluster Setup Tool Documentation

## Overview

The RKE2 Cluster Setup Tool is a comprehensive Bash script designed to automate the preparation and configuration of a Rancher Kubernetes Engine 2 (RKE2) cluster environment on AWS EC2 instances. This tool facilitates the implementation of a production-ready Kubernetes environment with support for:

- Single master node (control plane)
- Multiple CPU-only worker nodes
- GPU-enabled worker nodes
- Jump host (bastion) configuration
- SSH connectivity testing and configuration
- Ansible inventory and configuration generation

## System Architecture

The cluster architecture implemented by this tool consists of:

| Component | Description | Example IP |
|-----------|-------------|------------|
| Jump Host | Bastion server for secure access to cluster | 50.19.181.55 (Public IP) |
| Master Node | Runs the Kubernetes control plane and etcd | 10.0.1.10 (Private IP) |
| Worker Nodes | Standard compute nodes for workloads | 10.0.0.10 (Private IP) |
| GPU Nodes | NVIDIA GPU-enabled nodes for ML/AI workloads | 10.0.0.41 (Private IP) |

## Prerequisites

Before running the tool, ensure you have:

1. **SSH Key Pair**: A valid SSH key pair located at the expected path (`../ssh-key/talha.pem`)
2. **Ansible**: Installed on the machine where you run the script
3. **AWS EC2 Instances**: Properly configured EC2 instances that are already provisioned with:
   - A jump host with public IP accessibility
   - A master node with a private IP
   - Worker nodes with private IPs
   - GPU nodes with private IPs (if applicable)

## Tool Features

### 1. Prerequisite Validation
- Checks for the existence of required SSH keys
- Verifies SSH key permissions (sets to 600)
- Confirms Ansible installation

### 2. SSH Configuration
- Creates a centralized SSH config file at `~/.ssh/config`
- Configures jump host proxy for internal node access
- Sets up direct access to all cluster nodes via the jump host

### 3. Connectivity Testing
- Tests SSH connectivity to the jump host
- Tests connectivity to master node via jump host
- Tests connectivity between master and worker nodes
- Tests connectivity to GPU nodes (when applicable)

### 4. Ansible Configuration
- Creates a comprehensive inventory structure with:
  - Server group (master node)
  - Agents group (worker nodes)
  - GPU agents group (GPU-enabled nodes)
- Sets up Ansible group variables with cluster configuration
- Creates GPU-specific configuration (driver version, container runtime)
- Configures Ansible settings for optimal SSH connectivity

### 5. Ansible Environment Setup
- Installs required Ansible collections (`kubernetes.core`, `community.general`)
- Tests inventory configuration
- Validates connectivity to all node types

## Usage Guide

### Installation and Execution

1. Place the script in your desired directory
2. Ensure the SSH key is located at `../ssh-key/talha.pem` relative to the script location
3. Make the script executable:
   ```bash
   chmod +x setup-rke2-cluster.sh
   ```
4. Execute the script:
   ```bash
   ./setup-rke2-cluster.sh
   ```

### Configuration

The tool uses hardcoded cluster information that you may need to modify before execution:

```bash
# Define cluster information (hardcoded)
JUMP_HOST_IP="50.19.181.55"
MASTER_PRIVATE_IP="10.0.1.10"
WORKER_IPS=("10.0.0.10")
GPU_IPS=("10.0.0.41")
CLUSTER_NAME="rke2-cluster"
```

Modify these values to match your AWS EC2 infrastructure configuration.

### Directory Structure

The tool expects the following directory structure:

```
.
├── setup-rke2-cluster.sh (this script)
├── ../ssh-key/
│   └── talha.pem (SSH private key)
└── ../ansible-playbooks/
    ├── inventory/ (created by the script)
    ├── rke2_configure.yaml (to be executed after setup)
    └── ansible.cfg (created by the script)
```

## Generated Files

### SSH Configuration

The script creates an SSH configuration file at `~/.ssh/config` with the following structure:

```
# Jump host configuration - directly accessible
Host jumphost
  HostName 50.19.181.55
  User ubuntu
  IdentityFile /path/to/talha.pem
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# Master node configuration - accessed via jump host
Host master
  HostName 10.0.1.10
  User ubuntu
  IdentityFile /path/to/talha.pem
  ProxyJump jumphost
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# Generic pattern for any internal IPs in the cluster subnet
Host 10.0.*.*
  ProxyJump jumphost
  User ubuntu
  IdentityFile /path/to/talha.pem
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

### Ansible Inventory

The script generates an Ansible inventory file at `../ansible-playbooks/inventory/inventory.ini`:

```ini
# RKE2 Cluster Inventory

[servers]
server1 ansible_host=10.0.1.10

[agents]
worker1 ansible_host=10.0.0.10
gpu1 ansible_host=10.0.0.41

[gpu_agents]
gpu1

[rke2:children]
servers
agents
gpu_agents

[rke2:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/path/to/talha.pem
ansible_ssh_common_args='-F /home/user/.ssh/config'
```

### Ansible Group Variables

The script creates the following group variables files:

1. `../ansible-playbooks/inventory/group_vars/all.yml`:
```yaml
---
os: "linux"
arch: "amd64"

ansible_become: true
ansible_become_method: sudo

# Cluster information
cluster_name: "rke2-cluster"
```

2. `../ansible-playbooks/inventory/group_vars/gpu_agents.yml`:
```yaml
---
# GPU node specific configuration
gpu_enabled: true
nvidia_driver_version: "535"  # Adjust version as needed
container_runtime: "containerd"
```

### Ansible Configuration

The script creates an Ansible configuration file at `../ansible-playbooks/ansible.cfg`:

```ini
[defaults]
host_key_checking = False
ansible_interpreter_python = auto
ansible_collections_path = ./rke2-ansible/collections/requirements.yaml
inventory = inventory/inventory.ini
retry_files_enabled = False
stdout_callback = yaml 
roles_path    = ./rke2-ansible/roles

[ssh_connection]
pipelining = True
ssh_args = -F /home/user/.ssh/config -o ControlMaster=auto -o ControlPersist=30m
```

## Deploying the RKE2 Cluster

After the setup tool completes successfully, deploy the RKE2 cluster by running:

```bash
cd ../ansible-playbooks && ansible-playbook rke2_configure.yaml
```

This will execute the Ansible playbook that configures and deploys RKE2 on all nodes.

## SSH Access to Cluster Nodes

After setup, you can access cluster nodes using:

- Jump host: `ssh jumphost`
- Master node: `ssh master`
- Worker nodes: `ssh 10.0.0.10` (using the actual IP)
- GPU nodes: `ssh 10.0.0.41` (using the actual IP)

## Troubleshooting

### SSH Connection Issues

If you encounter SSH connection issues:

1. Verify the SSH key permissions:
   ```bash
   chmod 600 ../ssh-key/talha.pem
   ```

2. Check that the jump host is reachable:
   ```bash
   ssh -i ../ssh-key/talha.pem ubuntu@50.19.181.55
   ```

3. Ensure security groups allow SSH traffic between nodes

### Ansible Connectivity Issues

If Ansible connectivity tests fail:

1. Verify your Ansible installation:
   ```bash
   ansible --version
   ```

2. Check network connectivity between nodes using the manual SSH commands
3. Verify IP addresses and SSH configurations in the inventory file

## Security Considerations

This tool implements several security practices:

1. SSH key-based authentication
2. Jump host for secure access to private infrastructure
3. Proper SSH key permissions (600)
4. SSH configuration backup before modification

However, be aware that for simplicity, the tool disables strict host key checking. In a production environment, consider adjusting this configuration to enhance security.

## Limitations and Known Issues

1. The script uses hardcoded values for IP addresses and cluster configuration
2. StrictHostKeyChecking is disabled, which prioritizes convenience over security
3. The script assumes all nodes use the Ubuntu operating system with the 'ubuntu' user

## Conclusion

The RKE2 Cluster Setup Tool streamlines the preparation of a production-ready Kubernetes environment using RKE2 on AWS EC2 instances. By automating SSH configuration, connectivity testing, and Ansible preparation, it significantly reduces the manual effort required to set up a cluster with GPU support.