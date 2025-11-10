# Packer template pour créer une image Proxmox avec Kubernetes/Minikube

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
  type    = string
  default = "https://your-proxmox:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "root@pam!packer"
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  default   = "your-api-token"
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "vm_id" {
  type    = number
  default = 9000
}

source "proxmox-iso" "ubuntu-k8s" {
  proxmox_url              = "${var.proxmox_api_url}"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  node                 = "${var.proxmox_node}"
  vm_id                = "${var.vm_id}"
  vm_name              = "ubuntu-k8s-template"
  template_description = "Ubuntu 22.04 with Docker, Minikube, kubectl, Helm"

  iso_file         = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true

  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "32G"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  cores   = 2
  memory  = 4096
  sockets = 1

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

  boot      = "c"
  boot_wait = "5s"

  http_directory = "http"

  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"
}

build {
  name    = "ubuntu-k8s"
  sources = ["source.proxmox-iso.ubuntu-k8s"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y cloud-init qemu-guest-agent",
    ]
  }

  provisioner "file" {
    source      = "scripts/install-kubernetes-tools.sh"
    destination = "/tmp/install-kubernetes-tools.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install-kubernetes-tools.sh",
      "sudo /tmp/install-kubernetes-tools.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo rm -rf /var/lib/cloud/instances",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo sync"
    ]
  }
}
