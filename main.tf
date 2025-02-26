terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Đọc dữ liệu từ CSV
data "external" "csv_reader" {
  program = ["python3", "${path.module}/read_csv.py"]
}

locals {
  vm_list = { for vm in jsondecode(data.external.csv_reader.result.vms) : vm.vm_name => vm }
}

output "vm_list" {
  value = local.vm_list
}

# Tạo volume cho từng VM từ template
resource "libvirt_volume" "vm" {
  for_each = { for vm in local.vm_list : vm.vm_name => vm }

  name           = "${each.value.vm_name}.qcow2"
  pool           = "default"
  source         = each.value.disk_source
  format         = "qcow2"
}

# Gọi module cloud-init để tạo disk cloud-init cho từng VM
module "cloud_init" {
  source  = "./modules/cloud-init"
  vm_list = local.vm_list
}

# Tạo VM từ volume đã clone từ template
resource "libvirt_domain" "vm" {
  for_each = { for vm in local.vm_list : vm.vm_name => vm }

  name   = each.value.vm_name
  memory = 2048
  vcpu   = 2
  machine = "q35"  # Sử dụng machine type q35

  cpu {
    mode = "host-passthrough"  # Sử dụng CPU của host
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "vnc"
  }

  video {
    type = "virtio"  # Sử dụng VirtIO cho video
  }

  network_interface {
    bridge = "virbr0"
  }

  disk {
    volume_id = libvirt_volume.vm[each.key].id
  }

  # Sử dụng cloud-init disk từ module
  cloudinit = module.cloud_init.cloudinit_disk[each.key]

  # Tùy chỉnh XML để gắn cloud-init disk qua SATA (hoặc VirtIO)
  xml {
    xslt = <<XSLT
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  <!-- Thay đổi bus của cloud-init disk từ ide sang sata -->
  <xsl:template match="/domain/devices/disk[@device='cdrom']/target">
    <target dev="sda" bus="sata"/>
  </xsl:template>
  <xsl:template match="/domain/devices/disk[@device='cdrom']/driver">
    <driver name="qemu" type="raw"/>
  </xsl:template>
</xsl:stylesheet>
XSLT
  }

  connection {
    type        = "ssh"
    host        = each.value.ip_address
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'VM ${each.value.vm_name} (hostname: ${each.value.hostname}) initialized with IP ${each.value.ip_address}'"
    ]
  }
}