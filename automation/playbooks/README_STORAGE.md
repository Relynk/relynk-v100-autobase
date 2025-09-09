# PostgreSQL Cluster Storage Preparation Playbooks

This directory contains Ansible playbooks for preparing and managing storage on PostgreSQL cluster VMs.

## Overview

These playbooks automate the setup of NVMe storage devices for PostgreSQL cluster nodes, including:
- Disk partitioning
- Filesystem creation
- Mount point configuration
- Ownership and permission settings
- Persistent mounting via `/etc/fstab`

## Storage Configuration

The playbooks configure the following storage layout:

| Device    | Size  | Mount Point   | Purpose                     |
|-----------|-------|---------------|----------------------------|
| nvme0n2   | 256G  | /mnt/pgdata   | PostgreSQL data directory   |
| nvme0n3   | 64G   | /mnt/pgwal    | PostgreSQL WAL directory    |
| nvme0n4   | 32G   | /mnt/etcd     | etcd data directory         |

## Playbooks

### 1. prepare_storage.yml
Main playbook for setting up storage on PostgreSQL cluster nodes.

**Features:**
- Validates disk sizes against expected values (with 5% tolerance)
- Creates GPT partition tables
- Formats partitions with ext4 filesystem
- Sets up persistent mounts in `/etc/fstab`
- Configures proper ownership (postgres:postgres)
- Creates disk info files for documentation

**Usage:**
```bash
# Run on all postgres_cluster hosts
ansible-playbook -i ../inventory prepare_storage.yml

# Run on specific host
ansible-playbook -i ../inventory prepare_storage.yml --limit hostname

# Dry run to see what would be changed
ansible-playbook -i ../inventory prepare_storage.yml --check

# Run with verbose output
ansible-playbook -i ../inventory prepare_storage.yml -v
```

### 2. verify_storage.yml
Verification playbook to check storage configuration status.

**Features:**
- Lists all block devices
- Verifies mount points are active
- Checks ownership and permissions
- Reviews `/etc/fstab` entries
- Generates storage configuration report

**Usage:**
```bash
# Verify storage on all hosts
ansible-playbook -i ../inventory verify_storage.yml

# Verify specific host
ansible-playbook -i ../inventory verify_storage.yml --limit hostname

# Check specific aspects using tags
ansible-playbook -i ../inventory verify_storage.yml --tags mounts
ansible-playbook -i ../inventory verify_storage.yml --tags fstab
ansible-playbook -i ../inventory verify_storage.yml --tags report
```

## Prerequisites

Before running these playbooks:

1. **Inventory Configuration**: Ensure your hosts are properly defined in the inventory file under `[postgres_cluster]` group.

2. **SSH Access**: Verify SSH connectivity to target hosts:
   ```bash
   ansible -i ../inventory postgres_cluster -m ping
   ```

3. **Sudo Privileges**: The remote user must have sudo privileges.

4. **Disk Availability**: Ensure the NVMe devices are attached and visible to the OS:
   ```bash
   ansible -i ../inventory postgres_cluster -a "lsblk"
   ```

## Safety Features

The playbooks include several safety mechanisms:

- **Size Validation**: Checks disk sizes match expected values (±5% tolerance)
- **Mount Detection**: Prevents operations on already-mounted devices
- **Partition Backup**: Creates backup of existing partition tables
- **Non-destructive**: Won't overwrite existing filesystems without explicit force
- **Error Handling**: Comprehensive error messages and recovery blocks
- **Idempotency**: Safe to run multiple times

## Troubleshooting

### Common Issues

1. **Device Not Found**
   - Verify the device exists: `ls -la /dev/nvme*`
   - Check if devices have different names in your environment

2. **Size Mismatch**
   - Adjust `expected_size` in playbook vars if your disks are different
   - Increase `size_tolerance_percent` for more flexibility

3. **Permission Denied**
   - Ensure ansible user has sudo privileges
   - Check SSH key permissions

4. **Mount Failed**
   - Verify no existing mounts: `mount | grep nvme`
   - Check for filesystem errors: `fsck /dev/nvme0n2p1`

### Manual Cleanup

If you need to remove the configuration:

```bash
# Unmount filesystems
sudo umount /mnt/pgdata /mnt/pgwal /mnt/etcd

# Remove fstab entries
sudo sed -i '/\/mnt\/pgdata/d' /etc/fstab
sudo sed -i '/\/mnt\/pgwal/d' /etc/fstab
sudo sed -i '/\/mnt\/etcd/d' /etc/fstab

# Remove partitions (CAUTION: This will destroy data)
sudo wipefs -a /dev/nvme0n2
sudo wipefs -a /dev/nvme0n3
sudo wipefs -a /dev/nvme0n4
```

## Integration with PostgreSQL Deployment

After running the storage preparation playbook, you can proceed with the PostgreSQL cluster deployment:

```bash
# 1. Prepare storage
ansible-playbook -i ../inventory prepare_storage.yml

# 2. Verify storage
ansible-playbook -i ../inventory verify_storage.yml

# 3. Deploy PostgreSQL cluster
ansible-playbook -i ../inventory deploy_pgcluster.yml
```

## Customization

To customize for different environments, modify the `disk_configurations` variable in `prepare_storage.yml`:

```yaml
disk_configurations:
  - device: your_device
    expected_size: "your_size"
    mount_point: "/your/mount/point"
    filesystem: ext4  # or xfs, btrfs, etc.
    owner: postgres
    group: postgres
    description: "Your description"
```

## Tags

Available tags for selective execution:

- `packages` - Install required packages only
- `gather_info` - Collect disk information
- `user_setup` - Create postgres user/group
- `disk_setup` - Main disk configuration
- `verify` - Verification steps
- `summary` - Display summary report

Example:
```bash
ansible-playbook -i ../inventory prepare_storage.yml --tags disk_setup,verify
```

## Support

For issues or questions, check:
1. Ansible logs: Add `-vvv` for detailed output
2. System logs: `journalctl -xe`
3. Disk status: `lsblk`, `fdisk -l`, `blkid`
4. Mount status: `mount`, `findmnt`