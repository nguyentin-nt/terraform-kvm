terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}
variable "vm_list" {
  description = "Danh sách VM từ CSV"
  type        = map(any)
}

# Cloud-init để gán IP, hostname từ CSV
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.vm_list

  name      = "cloudinit-${each.value.vm_name}.iso"
  pool      = "default"
  user_data = data.template_file.user_data[each.key].rendered
}

data "template_file" "user_data" {
  for_each = var.vm_list

  template = file("${path.module}/user-data.tpl")
  vars = {
    hostname  = each.value.hostname
    ipaddress = each.value.ip_address
  }
}

output "cloudinit_disk" {
  value = { for k, v in libvirt_cloudinit_disk.commoninit : k => v.id }
}
