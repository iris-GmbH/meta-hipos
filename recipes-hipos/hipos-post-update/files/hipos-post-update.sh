#!/bin/sh
#
# Copyright (C) 2026 iris-GmbH infrared & intelligent sensors
#

set -eu

TAG=$0

log() {
	echo "$TAG $1"
}

get_firmware_bootpath() {
	ROOTDEV=$(lsblk -sno PATH,TYPE "$(findmnt -n -o SOURCE /)" | awk '$2 == "disk" { print $1; exit }')
	if grep -q 'firmwareslot=b' /proc/cmdline; then
		CUR_FITIMAGE_DEV=${ROOTDEV}p3
		ALT_FITIMAGE_DEV=${ROOTDEV}p2
		CUR_FW_SUFFIX="b"
		ALT_FW_SUFFIX="a"
	else
		CUR_FITIMAGE_DEV=${ROOTDEV}p2
		ALT_FITIMAGE_DEV=${ROOTDEV}p3
		CUR_FW_SUFFIX="a"
		ALT_FW_SUFFIX="b"
	fi
}

is_alt_fw_update_required() {
	# Alternative firmware needs an update if roothash differs
	if ! cmp -s /mnt/keystore/verity/rootfs_a.hashdevice /mnt/keystore/verity/rootfs_b.hashdevice
	then
		return 0
	fi
	return 1
}

do_alt_fw_update() {
	# do fitimage first, then userdata, then rootfs, and the keystore artifacts last

	# mirror fitimage to alt partition
	mkdir -p /tmp/cur_boot /tmp/alt_boot
	mount "${CUR_FITIMAGE_DEV}" /tmp/cur_boot
	mount "${ALT_FITIMAGE_DEV}" /tmp/alt_boot
	cp -a "/tmp/cur_boot/fitImage.signed" "/tmp/alt_boot/fitImage.signed"
	umount /tmp/cur_boot /tmp/alt_boot
	rm -r /tmp/cur_boot /tmp/alt_boot

	_LVM_ROOTFS="/dev/mapper/hydralvm-rootfs_"
	_LVM_USERDATA="/dev/mapper/hydralvm-rootfs_"

	alt_rootfs="${_LVM_ROOTFS}${ALT_FW_SUFFIX}"
	alt_userdata="${_LVM_USERDATA}${ALT_FW_SUFFIX}"

	# create new / empty ext4 on userdata volume
	label_decrypt_userdata="tmp_decrypt_userdata_${ALT_FW_SUFFIX}"
	dmsetup -v create "$label_decrypt_userdata" --table \
		"0 $(blockdev --getsz $alt_userdata) crypt capi:tk(cbc(aes))-eboiv :64:logon:dmcrypt: 0 $alt_userdata 0 1 sector_size:4096"

	mkfs.ext4 -qF "/dev/mapper/${label_decrypt_userdata}" ; sync

	sleep 1 # workaround for removing without busy errors
	dmsetup remove "${label_decrypt_userdata}"

	# resize alt_rootfs and mirror cur_rootfs to alt_rootfs
	rootfs_bytes=$(lvs --noheadings --units b --nosuffix -o lv_size "hydralvm/rootfs_${CUR_FW_SUFFIX}" | xargs)
	lvresize --autobackup n --force --yes --quiet -L "$rootfs_bytes"B "$alt_rootfs" 2> /dev/null

	label_decrypt_rootfs="tmp_decrypt_rootfs_${ALT_FW_SUFFIX}"
	dmsetup -v create "$label_decrypt_rootfs" --table \
		"0 $(blockdev --getsz $alt_rootfs) crypt capi:tk(cbc(aes))-eboiv :64:logon:dmcrypt: 0 $alt_rootfs 0 1 sector_size:4096"

	dd if="/dev/mapper/decrypted-hydralvm-rootfs_${CUR_FW_SUFFIX}" of="/dev/mapper/${label_decrypt_rootfs}"
	sync

	sleep 1
	dmsetup remove "${label_decrypt_rootfs}"

	# mirror keystore artifacts
	mount -o remount,rw /mnt/keystore
	cp -a "/mnt/keystore/verity/rootfs_${CUR_FW_SUFFIX}.roothash" "/mnt/keystore/verity/rootfs_${ALT_FW_SUFFIX}.roothash"
	cp -a "/mnt/keystore/verity/rootfs_${CUR_FW_SUFFIX}.roothash.signature" "/mnt/keystore/verity/rootfs_${ALT_FW_SUFFIX}.roothash.signature"
	cp -a "/mnt/keystore/verity/rootfs_${CUR_FW_SUFFIX}.hashdevice" "/mnt/keystore/verity/rootfs_${ALT_FW_SUFFIX}.hashdevice"
	mount -o remount,ro /mnt/keystore
}

reset_uboot_envs() {
	TMP_ENV_FILE="/tmp/reset_update_envs"

	# Always set firmware to the current one (translate to firmware=0/1)
	case "${CUR_FIRMWARE_SUFFIX}" in
		"b") firmware=1 ;;
		*) firmware=0 ;;
	esac
	printf "bootcount=0\nupgrade_available=0\nustate=0\nfirmware=%s\n" "$firmware" > "$TMP_ENV_FILE"

	# Use a temp file to write u-boot-env's in one go
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
}

is_migrating_legacy_device() {
	# Check if a non-deploy device is missing _b volumes
	if ! grep -Eq "(empty|snakeoil)" /sys/firmware/devicetree/base/chosen/iris,hab-srk
	then
		return 1
	fi

	if lvs hydralvm/rootfs_b > /dev/null && lvs hydralvm/userdata_b > /dev/null
	then
		return 1
	fi

	return 0
}

finalize_migration() {
	# if p2 exists and is behind p4, delete p2
	start_p2=$(lsblk -dnro START "${ROOTDEV}p2")
	start_p4=$(lsblk -dnro START "${ROOTDEV}p4")
	if [ -b "${ROOTDEV}p2" ] && [ "$start_p4" -lt "$start_p2" ]
	then
    	parted -s "$ROOTDEV" rm "${ROOTDEV}p2"
    	partprobe "$ROOTDEV"
	fi

	# if p2 does not exist, create it at new location
	if [ ! -b "${ROOTDEV}p2" ]
	then
	    end_p1=$(parted -sm "$ROOTDEV" unit MiB print | grep -E "^1:" | cut -d: -f3 | grep -o "[0-9]*")
		start_p3=$(parted -sm "$ROOTDEV" unit MiB print | grep -E "^3:" | cut -d: -f2 | grep -o "[0-9]*")
		parted -s "$ROOTDEV" unit MiB mkpart primary ext4 "$end_p1" "$start_p3"
		partprobe "$ROOTDEV"
	fi

	# if p2 exists and is at expected location, reformat it
	start_p2=$(lsblk -dnro START "${ROOTDEV}p2")
	if [ -b "${ROOTDEV}p2" ] && [ "$start_p2" -eq "286720" ]
	then
		mkfs.ext4 "${ROOTDEV}p2"
	fi

	# p2 is left empty - file sync happens afterwards

	# Let LVM write some data to volatile storage
	export LVM_SYSTEM_DIR=/run/lvm

	# extend p4 + LVM (safe to run without checks)
	parted -s "$ROOTDEV" resizepart 4 100%
    partprobe "$ROOTDEV"
    pvresize "${ROOTDEV}p4"

	# get size of existing rootfs
	rootfs_bytes=$(lvs --noheadings --units b --nosuffix -o lv_size hydralvm/rootfs_a | xargs)

	lvs hydralvm/rootfs_b > /dev/null || lvcreate -y -n "rootfs_b" -L "${rootfs_bytes}B" "hydralvm"
	lvs hydralvm/userdata_b > /dev/null || lvcreate -y -n "userdata_b" -L 256MB "hydralvm"
	vgmknodes

	# LVM is ready - data sync happens afterwards
	# both volumes exist with no file system on it
}

get_firmware_bootpath # set device variables

keyctl link @us @s

# Migrate legacy devices if needed, can be removed in future versions
if is_migrating_legacy_device
then
	finalize_migration
fi

LOCK_FILE="/tmp/hipos-post-update.lock"
touch "$LOCK_FILE"

# read env
PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
if [ "$PENDING_UPDATE" = "1" ]
then
	reset_uboot_envs
fi

if is_alt_fw_update_required
then
	do_alt_fw_update
fi
