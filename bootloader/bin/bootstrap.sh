#!/bin/busybox sh
# SH1MSTEAM Silent Bootloader
# Automatically boots /dev/sda4

# Disable all output
set +x

move_mounts() {
  local base_mounts="/sys /proc /dev"
  local newroot_mnt="$1"
  for mnt in $base_mounts; do
    mkdir -p "$newroot_mnt$mnt"
    mount -n -o move "$mnt" "$newroot_mnt$mnt"
  done
}

exec_init() {
  exec /sbin/init < "$TTY1" >> "$TTY1" 2>&1
}

boot_target() {
  local target="$1"
  mkdir /newroot
  
  if [ -x "$(command -v cryptsetup)" ] && cryptsetup luksDump "$target" >/dev/null 2>&1; then
    cryptsetup open $target rootfs
    mount /dev/mapper/rootfs /newroot
  else
    mount $target /newroot
  fi

  if [ -f "/bin/frecon-lite" ]; then 
    rm -f /dev/console
    touch /dev/console
    mount -o bind "$TTY1" /dev/console
  fi
  
  move_mounts /newroot
  mkdir -p /newroot/bootloader
  pivot_root /newroot /newroot/bootloader
  exec_init
}

main() {
  # Direct silent boot, no menus
  boot_target "/dev/sda4"
}

# Execute main
main "$@"
