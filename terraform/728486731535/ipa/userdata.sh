#!/bin/bash
# This script expands the disk to utilize the full EBS volume on boot.

# Wait a few seconds for the device to be fully attached.
sleep 10

# Install growpart if it's not already installed.
if ! command -v growpart &>/dev/null; then
  echo "Installing cloud-utils-growpart..."
  yum install -y cloud-utils-growpart
fi

# Define device variables.
DEVICE="/dev/nvme0n1"
PARTITION="${DEVICE}p5"
LV_PATH="/dev/mapper/rocky-root"

echo "Resizing partition $PARTITION to use the full disk..."
growpart $DEVICE 5

echo "Resizing physical volume on $PARTITION..."
pvresize $PARTITION

echo "Extending logical volume $LV_PATH to use available space..."
lvextend -l +100%FREE $LV_PATH

echo "Growing XFS filesystem on /..."
xfs_growfs /

echo "Disk resize complete."