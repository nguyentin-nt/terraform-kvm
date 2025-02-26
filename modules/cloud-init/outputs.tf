output "cloudinit_ids" {
  value = { for vm, disk in libvirt_cloudinit_disk.commoninit : vm => disk.id }
}

