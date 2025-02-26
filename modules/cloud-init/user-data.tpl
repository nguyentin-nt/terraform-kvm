#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
users:
  - name: root
    ssh_authorized_keys:
      - ${file("~/.ssh/id_rsa.pub")}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: false
      addresses:
        - ${ipaddress}/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

runcmd:
  - echo 'GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0"' >> /etc/default/grub
  - echo 'GRUB_TERMINAL=serial' >> /etc/default/grub
  - echo 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"' >> /etc/default/grub
  - grub2-mkconfig -o /boot/grub2/grub.cfg
  - systemctl enable serial-getty@ttyS0.service
  - systemctl start serial-getty@ttyS0.service
