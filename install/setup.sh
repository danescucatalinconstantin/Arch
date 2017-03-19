#!/bin/bash

installDir=/archInstall
. $installDir/readProps.sh

partition_drive() {
    local dev="$1"; shift

    # Must be refactor for real masine
#    parted -s "$dev" \
#        mklabel msdos \
#        mkpart primary ext4 1 100M \
#        mkpart primary ext4 100M 7G \
#        mkpart primary linux-swap 7G 8G \
#        mkpart primary ext4 8G 100% \
#        set 1 boot on

    parted -s "$dev" \
        mklabel msdos \
        mkpart primary ext4 1M 512M \
        mkpart primary linux-swap 512M 1.5G \
        mkpart primary ext4 1.5G 100% \
        set 1 boot on
}


format_filesystems() {
    local dev="$1"; shift

#    mkfs.ext4 "$dev"1
#    mkfs.ext4 "$dev"2
#    mkswap "$dev"3
#    mkfs.ext4 "$dev"4
#    swapon "$dev"3

    mkfs.ext4 "$dev"1
    mkswap "$dev"2
    swapon "$dev"2
    mkfs.ext4 "$dev"3
}


mount_filesystems() {
    local dev="$1"; shift

#    mount "$dev"2 /mnt
#    mkdir /mnt/boot
#    mount "$dev"1 /mnt/boot
#    mkdir /mnt/home
#    mount "$dev"4 /mnt/home

    mount "$dev"3 /mnt
    mkdir /mnt/boot
    mount "$dev"1 /mnt/boot
}

update_packs() {
    yes | pacman -Syu
    yes | pacman -Scc
}

choose_mirror() {
    yes | pacman -S reflector
    reflector --verbose --country '$COUNTRY' -l 5 --sort rate --save /etc/pacman.d/mirrorlist
}


install_base() {
    printf '\n\ny\n' | pacstrap -i /mnt base base-devel
}

set_fstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
}

unmount_filesystems() {
    umount -R /mnt
}






echo '-------------Setup---------------'

echo 'Creating partitions'
partition_drive "$DRIVE"

echo 'Formatting filesystems'
format_filesystems "$DRIVE"

echo 'Mounting filesystems'
mount_filesystems "$DRIVE"

echo 'Update packs'
update_packs

echo 'Choose closest mirror list'
choose_mirror

echo 'Installing base system'
install_base

echo 'Setting fstab'
set_fstab

echo 'Chrooting into installed system to continue setup...'
cp -R $installDir /mnt$installDir
arch-chroot /mnt /bin/bash $installDir/config-root.sh

echo 'Unmounting filesystems'
unmount_filesystems
echo 'Done! Reboot system.'
reboot



