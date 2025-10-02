#!/bin/bash
set -e

# Color definitions for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}  RKE2 Cluster Setup Tool        ${NC}"
echo -e "${BLUE}=================================${NC}"

# Define paths and configurations
BASE_DIR="$(pwd)"
ANSIBLE_DIR="${BASE_DIR}/../ansible-playbooks"
SSH_KEY_PATH="${BASE_DIR}/../ssh-key/rke2-common.pem"
SSH_CONFIG_PATH="${HOME}/.ssh/config"

# Define cluster information (hardcoded)
JUMP_HOST_IP="63.177.5.34"
MASTER_PRIVATE_IP="10.0.1.10"
WORKER_IPS=("10.0.0.10")
GPU_IPS=("10.0.0.41")
CLUSTER_NAME="rke2-cluster"

# 1. Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check if SSH key exists
if [ ! -f "${SSH_KEY_PATH}" ]; then
  echo -e "${RED}SSH key not found at ${SSH_KEY_PATH}${NC}"
  echo -e "${RED}Please ensure your SSH key is in the correct location${NC}"
  exit 1
fi

# Ensure SSH key has correct permissions
chmod 600 "${SSH_KEY_PATH}"
echo -e "${GREEN}SSH key permissions set to 600${NC}"

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
  echo -e "${RED}Ansible is not installed. Please install Ansible first.${NC}"
  exit 1
fi

echo -e "${GREEN}All prerequisites are met!${NC}"

# 2. Display infrastructure information
echo -e "\n${GREEN}Infrastructure information:${NC}"
echo -e "  Jump Host IP: ${JUMP_HOST_IP}"
echo -e "  Master Private IP: ${MASTER_PRIVATE_IP}"
echo -e "  Worker IPs: ${WORKER_IPS[*]}"
echo -e "  GPU Node IPs: ${GPU_IPS[*]}" # Display GPU nodes
echo -e "  Cluster Name: ${CLUSTER_NAME}"

# 3. Set up SSH jump configuration
echo -e "\n${YELLOW}Setting up SSH jump configuration...${NC}"

# Create SSH config directory if it doesn't exist
mkdir -p "${HOME}/.ssh"

# Back up existing SSH config if it exists
if [ -f "${SSH_CONFIG_PATH}" ]; then
  cp "${SSH_CONFIG_PATH}" "${SSH_CONFIG_PATH}.bak.$(date +%s)"
  echo -e "${YELLOW}Backed up existing SSH config to ${SSH_CONFIG_PATH}.bak.$(date +%s)${NC}"
fi

# Create new SSH config
cat > "${SSH_CONFIG_PATH}" << EOF
# Jump host configuration - directly accessible
Host jumphost
  HostName ${JUMP_HOST_IP}
  User rocky
  IdentityFile ${SSH_KEY_PATH}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# Master node configuration - accessed via jump host
Host master
  HostName ${MASTER_PRIVATE_IP}
  User ubuntu
  IdentityFile ${SSH_KEY_PATH}
  ProxyJump jumphost
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# Generic pattern for any internal IPs in the cluster subnet
Host 10.0.*.*
  ProxyJump jumphost
  User ubuntu
  IdentityFile ${SSH_KEY_PATH}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

chmod 600 "${SSH_CONFIG_PATH}"
echo -e "${GREEN}SSH config created at ${SSH_CONFIG_PATH}${NC}"

# 4. Test SSH connectivity to jump host
echo -e "\n${YELLOW}Testing SSH connectivity to jump host...${NC}"
ssh -o ConnectTimeout=5 jumphost "echo 'SSH to jump host successful!'" || {
  echo -e "${RED}Failed to connect to jump host. Check your SSH configuration and make sure:${NC}"
  echo -e "${RED}1. The SSH key at ${SSH_KEY_PATH} exists and has correct permissions${NC}"
  echo -e "${RED}2. The jump host at ${JUMP_HOST_IP} is reachable${NC}"
  echo -e "${RED}3. The user 'ubuntu' can SSH into the jump host${NC}"
  exit 1
}

# 8. Set up Ansible inventory and configuration
echo -e "\n${YELLOW}Setting up Ansible inventory and configuration...${NC}"

# Create Ansible inventory directory
mkdir -p "${ANSIBLE_DIR}/inventory/group_vars"

# Create static inventory file
cat > "${ANSIBLE_DIR}/inventory/inventory.ini" << EOF
# RKE2 Cluster Inventory

[servers]
server1 ansible_host=${MASTER_PRIVATE_IP}

[agents]
EOF

# Add worker nodes to inventory
WORKER_COUNT=1
for IP in "${WORKER_IPS[@]}"; do
  echo "worker${WORKER_COUNT} ansible_host=${IP}" >> "${ANSIBLE_DIR}/inventory/inventory.ini"
  WORKER_COUNT=$((WORKER_COUNT+1))
done

# Add GPU nodes to both agents and gpu_agents groups
if [ ${#GPU_IPS[@]} -gt 0 ]; then
  # Add GPU nodes to agents group first
  GPU_COUNT=1
  for IP in "${GPU_IPS[@]}"; do
    echo "gpu${GPU_COUNT} ansible_host=${IP}" >> "${ANSIBLE_DIR}/inventory/inventory.ini"
    GPU_COUNT=$((GPU_COUNT+1))
  done
  
  # Then create the separate gpu_agents group
  echo -e "\n[gpu_agents]" >> "${ANSIBLE_DIR}/inventory/inventory.ini"
  GPU_COUNT=1
  for IP in "${GPU_IPS[@]}"; do
    echo "gpu${GPU_COUNT}" >> "${ANSIBLE_DIR}/inventory/inventory.ini"
    GPU_COUNT=$((GPU_COUNT+1))
  done
fi

# Add inventory structure
cat >> "${ANSIBLE_DIR}/inventory/inventory.ini" << EOF

[rke2:children]
servers
agents
gpu_agents

[rke2:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=${SSH_KEY_PATH}
ansible_ssh_common_args='-F ${SSH_CONFIG_PATH}'
EOF

echo -e "${GREEN}Static inventory created at ${ANSIBLE_DIR}/inventory/inventory.ini${NC}"

# Create group_vars with the required variables
cat > "${ANSIBLE_DIR}/inventory/group_vars/all.yml" << EOF
---
os: "linux"
arch: "amd64"

ansible_become: true
ansible_become_method: sudo

# Cluster information
cluster_name: "${CLUSTER_NAME}"
EOF

# Create GPU node specific variables
cat > "${ANSIBLE_DIR}/inventory/group_vars/gpu_agents.yml" << EOF
---
# GPU node specific configuration
gpu_enabled: true
container_runtime: "containerd"
EOF

echo -e "${GREEN}Group variables created at ${ANSIBLE_DIR}/inventory/group_vars/all.yml${NC}"
echo -e "${GREEN}GPU node variables created at ${ANSIBLE_DIR}/inventory/group_vars/gpu_agents.yml${NC}"

# Update ansible.cfg to use static inventory
cat > "${ANSIBLE_DIR}/ansible.cfg" << EOF
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
ssh_args = -F ${SSH_CONFIG_PATH} -o ControlMaster=auto -o ControlPersist=30m
EOF

echo -e "${GREEN}Ansible configuration created at ${ANSIBLE_DIR}/ansible.cfg${NC}"

# 9. Install required Ansible collections
echo -e "\n${YELLOW}Installing required Ansible collections...${NC}"
cd "${ANSIBLE_DIR}"
ansible-galaxy collection install kubernetes.core community.general || {
  echo -e "${RED}Failed to install Ansible collections.${NC}"
  exit 1
}

# 10. Test Ansible connectivity
echo -e "\n${YELLOW}Testing Ansible inventory...${NC}"
ansible-inventory --graph

echo -e "${YELLOW}Testing Ansible connectivity to master...${NC}"
ansible server1 -m ping || {
  echo -e "${RED}Failed to ping master node with Ansible. Check your SSH configuration.${NC}"
  exit 1
}

echo -e "${YELLOW}Testing Ansible connectivity to workers...${NC}"
ansible agents -m ping && \
  echo -e "${GREEN}Successfully pinged worker nodes with Ansible!${NC}" || \
  echo -e "${RED}Warning: Failed to ping some worker nodes with Ansible.${NC}"

# Test Ansible connectivity to GPU nodes
if [ ${#GPU_IPS[@]} -gt 0 ]; then
  echo -e "${YELLOW}Testing Ansible connectivity to GPU nodes...${NC}"
  ansible gpu_agents -m ping && \
    echo -e "${GREEN}Successfully pinged GPU nodes with Ansible!${NC}" || \
    echo -e "${RED}Warning: Failed to ping some GPU nodes with Ansible.${NC}"
fi

# 11. Final instructions
echo -e "\n${BLUE}=================================${NC}"
echo -e "${BLUE}  Setup Complete!                ${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "\n${GREEN}Your RKE2 cluster environment with GPU nodes is now set up!${NC}"
echo -e "\n${YELLOW}To deploy your RKE2 cluster, run:${NC}"
echo -e "${GREEN}cd ${ANSIBLE_DIR} && ansible-playbook rke2_configure.yaml${NC}"
echo -e "\n${YELLOW}For SSH access to the nodes:${NC}"
echo -e "${GREEN}  Jump host: ssh jumphost${NC}"
echo -e "${GREEN}  Master node: ssh master${NC}"
echo -e "${GREEN}  Worker nodes: ssh WORKER_IP (e.g., ssh 10.0.0.10)${NC}"
echo -e "${GREEN}  GPU nodes: ssh GPU_IP (e.g., ssh 10.0.0.41)${NC}"
echo -e "\n${YELLOW}Remember to use the private IP (${MASTER_PRIVATE_IP}) for internal cluster communication${NC}"