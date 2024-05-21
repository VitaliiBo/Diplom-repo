variable "zone_a" {
  description = "Yandex.Cloud Zone"
  default     = "ru-central1-a"
}
variable "zone_b" {
  description = "Yandex.Cloud Zone"
  default     = "ru-central1-b"
}
variable "zone_d" {
  description = "Yandex.Cloud Zone"
  default     = "ru-central1-d"
}
variable "privat_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = "b1g6lqgummp0f6chmuj5"
  folder_id = "b1gg1md6v9gjoiu7n44k"
}


resource "yandex_vpc_network" "sys-vpc-network" {
  name = "sys-vpc-network"
}

resource "yandex_vpc_subnet" "lab-subnet-a" {
  name           = "subnet-1"
  v4_cidr_blocks = ["10.0.1.0/24"]
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.sys-vpc-network.id}"
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "lab-subnet-b" {
  name           = "subnet-2"
  v4_cidr_blocks = ["10.0.2.0/24"]
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.sys-vpc-network.id}"
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "lab-subnet-d" {
  name           = "subnet-3"
  v4_cidr_blocks = ["10.0.3.0/24"]
  zone           = "ru-central1-d"
  network_id     = "${yandex_vpc_network.sys-vpc-network.id}"
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "test-route-table"
  network_id = "${yandex_vpc_network.sys-vpc-network.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
# SECURITY GROUPS >>>>>
resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion"
  network_id = yandex_vpc_network.sys-vpc-network.id

  ingress {
    protocol       = "TCP"
    description    = "allow ssh connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "alb-group" { #SECURITY LOADBALANCER
  name        = "LoadBalancer security group"
  description = "Description for security group"
  network_id     = "${yandex_vpc_network.sys-vpc-network.id}"

  ingress {
    description = "Allow health check traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "Allow health check traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "yandex_vpc_security_group" "nginx-group" {
  name        = "My security group webservers"
  network_id  = "${yandex_vpc_network.sys-vpc-network.id}"

    ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
  ingress {
    protocol       = "TCP"
    port           = 4040
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
    ingress {
    protocol       = "TCP"
    from_port      = 10050
    to_port        = 10051
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "zabbix-group" {
  name        = "Zabbix security group"
  network_id  = "${yandex_vpc_network.sys-vpc-network.id}"
  
    ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    protocol       = "TCP"
    port           = 8443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    from_port      = 10050
    to_port        = 10051
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "kibana-group" {
  name        = "kibana security group"
  network_id  = "${yandex_vpc_network.sys-vpc-network.id}"

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
      ingress {
    protocol       = "TCP"
    from_port      = 10050
    to_port        = 10051
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "elastic-group" {
  name        = "elastic security group"
  network_id  = "${yandex_vpc_network.sys-vpc-network.id}"

    ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }
      ingress {
    protocol       = "TCP"
    from_port      = 10050
    to_port        = 10051
    v4_cidr_blocks = var.privat_subnet_cidr_blocks
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
#<<<< SECURITY GROUPS
resource "yandex_compute_instance" "vm-bastion" { #Виртуалка BASTION
  name        = "vm-bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = var.zone_d

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.lab-subnet-d.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk
    }
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    ssh-keys  = "bondarenko:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "web-server-1" { #Виртуалка 1
  name = "web-server-1"
  hostname = "web-server-1"
  platform_id = "standard-v3"
  zone = var.zone_a

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.lab-subnet-a.id
    security_group_ids = [yandex_vpc_security_group.nginx-group.id]
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk
    }
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    ssh-keys  = "bondarenko:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "web-server-2" { #Виртуалка 2
  name        = "web-server-2"
  hostname    = "web-server-2"
  platform_id = "standard-v3"
  zone        = var.zone_b
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.lab-subnet-b.id
    security_group_ids = [yandex_vpc_security_group.nginx-group.id]
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk
    }
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    ssh-keys  = "bondarenko:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "zabbix" { #Виртуалка 3
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = var.zone_d

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.lab-subnet-d.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.zabbix-group.id] 
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk
      size = 10
    }
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    ssh-keys  = "bondarenko:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "elastic" { #Виртуалка 4
  name     = "elastic"
  hostname = "elastic"
  platform_id = "standard-v3"
  zone = var.zone_d

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.lab-subnet-d.id
    security_group_ids = [yandex_vpc_security_group.elastic-group.id] 
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk
      size = 10
    }
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    ssh-keys  = "bondarenko:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "kibana" { #Виртуалка 5
  name     = "kibana"
  hostname = "kibana"
  platform_id = "standard-v3"
  zone = var.zone_d

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  network_interface {
    nat       = true
    subnet_id = yandex_vpc_subnet.lab-subnet-d.id
    security_group_ids = [yandex_vpc_security_group.kibana-group.id]
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk
      size = 10
    }
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    ssh-keys  = "bondarenko:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_alb_target_group" "vm-nginx-servers" { # Целевая группа
  name = "vm-nginx-servers"

  target {
    subnet_id  = yandex_vpc_subnet.lab-subnet-a.id
    ip_address = yandex_compute_instance.web-server-1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.lab-subnet-b.id
    ip_address = yandex_compute_instance.web-server-2.network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "backend_group" { # Группа Бэк-эндов
  name = "backend-group"

  http_backend{
    target_group_ids = ["${yandex_alb_target_group.vm-nginx-servers.id}"]

    name   = "http-backend"
    weight = 1
    port   = 80  

    healthcheck {
      timeout  = "1s"
      interval = "3s"

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "http-router" { # РОУТЕР
  name      = "my-http-router"
}

resource "yandex_alb_virtual_host" "my-virtual-host" { # Виртуальный хост 1
  name                    = "vhost-1"
  http_router_id          = yandex_alb_http_router.http-router.id
  route {
    name                  = "vroute"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.backend_group.id
        timeout           = "3s"
      }
      http_match {
        path {
          prefix = "/"
        }
      }
    }
  }
}


resource "yandex_alb_load_balancer" "web_lb" { # БАЛАНСИРОВЩИК
  name = "web-lb"
  network_id = yandex_vpc_network.sys-vpc-network.id
  security_group_ids = [yandex_vpc_security_group.alb-group.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.lab-subnet-a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.lab-subnet-b.id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}


resource "yandex_compute_snapshot_schedule" "mysnapshot" {
  name = "snapshot"

  schedule_policy {
    expression = "0 1 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
      description = "Daily snapshot"
 }

  retention_period = "168h"

  disk_ids = [
    yandex_compute_instance.vm-bastion.boot_disk.0.disk_id,
    yandex_compute_instance.web-server-1.boot_disk.0.disk_id,
    yandex_compute_instance.web-server-2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id,
    yandex_compute_instance.elastic.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id
  ]
             
}

data "template_file" "inventory" {
    template = "${file("inventory-template.ini")}"

    vars = {
        bastion = "${yandex_compute_instance.vm-bastion.network_interface.0.nat_ip_address}"
        zabbix = "${yandex_compute_instance.zabbix.network_interface.0.ip_address}"
    }
    
}

resource "null_resource" "update_inventory" {

    triggers = {
        template = "${data.template_file.inventory.rendered}"
    }

    provisioner "local-exec" {
        command = "echo '${data.template_file.inventory.rendered}' > ./../ansible/inventory.ini"
    }
}

output "external_ip_address_vm-basion" {
  value = yandex_compute_instance.vm-bastion.network_interface.0.nat_ip_address
}