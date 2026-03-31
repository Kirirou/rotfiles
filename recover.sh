#!/usr/bin/env bash

set -e

echo "Current latest remote commit:"
git ls-remote -h https://github.com/Kirirou/rotfiles master
echo ""

# Check for fzf
if ! [ -x "$(command -v fzf)" ]; then
    echo "fzf: command not found."
    echo "Installing fzf"
    nix-env -iA nixos.fzf
fi

function yesno() {
    local prompt="$1"

    while true; do
        read -rp "$prompt [y/n] " yn
        case $yn in
            [Yy]* ) echo "y"; return;;
            [Nn]* ) echo "n"; return;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

BOOTDISK=$(readlink -f /dev/disk/by-label/NIXBOOT)
SWAPDISK=$(readlink -f /dev/disk/by-label/SWAP)

# RUN CHECKS

echo "Checking mountpoint ''/mnt/boot':"
# Check boot partition
sudo mkdir -p /mnt/boot
if mountpoint -q /mnt/boot; then
    echo "Unmounting /mnt/boot"
    sudo umount -f /mnt/boot || true
fi

echo "Checking swap status for: $SWAPDISK"
# Check swap partition
if [ -b "$SWAPDISK" ]; then
swap_device=$(readlink -f "$SWAPDISK")
    echo "Swap device: $swap_device"

    # Check if the swap is currently on
    if swapon --show | grep -q "$swap_device"; then
        echo "Swap '$swap_device' is currently on."
        echo "Turning off SWAP device: $SWAPDISK"
        sudo swapoff "$SWAPDISK"
    else
        echo "Swap is already off. Continuing..."
    fi
fi

reformat_boot=$(yesno "Reformat boot?")
if [[ $reformat_boot == "y" ]]; then
    if [ -e "$BOOTDISK" ]; then
        sudo mkfs.fat -F 32 "$BOOTDISK" -n NIXBOOT
    else
        echo "Error: Boot disk does not exist /dev/disk/by-label/NIXBOOT: ${BOOTDISK}"
        echo "Is Boot partition/disk labeled 'NIXBOOT' ???"
        exit
    fi
fi

# Check if zroot pool exists to umount&export
echo "Checking zpool 'zroot' if imported"
if sudo zpool list zroot &> /dev/null; then
    echo "Zpool 'zroot' already imported. Exporting..."
    sudo zpool export zroot
fi

# -l prompts for passphrase if needed
echo "Importing zpool 'zroot'"
sudo zpool import -f -l zroot

reformat_nix=$(yesno "Reformat nix?")
if [[ $reformat_nix == "y" ]]; then
    for i in {5..0}; do
        message="Destroying 'zroot/nix' in $i seconds... <Ctrl + C> to EXIT NOW!\r"
        echo -e "\x1b[30;47m $message \x1b[0m"
        sleep 1
    done
    echo ""
    if mountpoint /mnt; then
        sudo umount -R -f /mnt/nix
    fi
    sudo zfs destroy -r zroot/nix

    sudo zfs create -o mountpoint=legacy zroot/nix
    sudo mkdir -p /mnt/nix
    sudo mount -t zfs zroot/nix /mnt/nix
fi

if mountpoint -q /mnt; then
    echo "Already mounted '/mnt' !"
    exit
else
    echo "Mounting Disks"

    echo "Mounting 'zroot/root' -> /mnt"
    sudo mount --mkdir -t zfs zroot/root /mnt
    echo "Mounting '${BOOTDISK}' -> /mnt/boot"
    sudo mount --mkdir "$BOOTDISK" /mnt/boot
    echo "Mounting 'zroot/nix' -> /mnt/nix"
    sudo mount --mkdir -t zfs zroot/nix /mnt/nix
    echo "Mounting 'zroot/tmp' -> /mnt/tmp"
    sudo mount --mkdir -t zfs zroot/tmp /mnt/tmp
    echo "Mounting 'zroot/cache' -> /mnt/cache"
    sudo mount --mkdir -t zfs zroot/cache /mnt/cache
fi

# handle persist, possibly from snapshot
restore_snapshot=$(yesno "Do you want to restore from a persist snapshot?")
if [[ "$restore_snapshot" == "y" ]]; then
snapshot_type=$(yesno "Is snapshot a file?")
    if [[ "$snapshot_type" == "y" ]]; then
        echo "Tip: use 'zfs send zroot/persist@snapshotname > /path/to/snapshotfile ' to create snapshot file."
        echo "Enter full path to snapshot: "
        read -r snapshot_file_path
        echo ""

        echo "Receiving 'zroot/persist' from snapshot '${snapshot_file_path}'"
        # shellcheck disable=SC2024 (sudo doesn't affect redirects)
        sudo zfs receive -o mountpoint=legacy zroot/persist < "$snapshot_file_path"
    else
snapshot_name=$(zfs list -H -t snapshot -r | fzf --prompt="Select snapshot to restore from: " | awk '{print $1}')
        echo "Selected snapshot: $snapshot_name"
        if zfs list "zroot/persist" &> /dev/null; then
            for i in {5..0}; do
                echo -e "Destroying 'zroot/persist' in $i seconds... <Ctrl + C> to EXIT NOW!\r"
                sleep 1
            done
            echo ""
            zfs destroy -r zroot/persist
            echo "'zroot/persist' destroyed!"
        fi
        echo ""
        echo "Receiving 'zroot/persist' from snapshot '${snapshot_name}'"
        sudo zfs send -v $snapshot_name | sudo zfs receive -v -F -o mountpoint=legacy zroot/persist
        echo "Completed persist snapshot send: "
        zfs list -o 'name,refer' -t snapshot zroot/persist
        zfs list -o 'name,used' zroot/persist
    fi
fi

echo "Mounting 'zroot/persist' -> /mnt/persist"
sudo mount --mkdir -t zfs zroot/persist /mnt/persist

echo "ZFS mounts:"
mount | grep zfs

echo "Listing of block devices: "
lsblk -o NAME,SIZE,TYPE,LABEL,ID-LINK

echo "ZFS pools:"
zpool list
echo "ZFS filesystems: "
zfs list -t filesystem

echo ""
# use fzf to select host
host=$(echo -e "desktop\nomen" | fzf --prompt="Select a host to install: ")

echo "Current Directory: $(pwd)"
flake_path=$(yesno "Use current pwd as flake path?")
if [[ $flake_path == "y" ]]; then
    echo "Recovering NixOS"
    sudo nixos-install --no-root-password --flake .#$host
else
    read -rp "Enter git rev for flake (default: master): " git_rev
    echo "Recovering NixOS..."
    sudo nixos-install --no-root-password --flake "github:Kirirou/rotfiles/${git_rev:-master}#$host"
fi
