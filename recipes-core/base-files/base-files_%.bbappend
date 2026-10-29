# Create mount directories for LVM and device mapper volumes
dirs755:append:hipos-cyber-security = " /mnt/hydra /mnt/keystore /mnt/datastore /mnt/provisioning"

# Create empty directories for key material bind mounts
dirs755:append:hipos-cyber-security = " \
    /etc/iris/identity \
"
