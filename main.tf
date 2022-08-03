terraform {
  required_version = ">= 1.2.0"

  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "basename" {}
variable "ibmcloud_api_key" {}
variable "region" { default = "us-south" }
variable "kube_version" { default = "1.24.3" }
variable "worker_pool_flavor" { default = "bx2.4x16" }
variable "worker_nodes_per_zone" { default = 2 }

variable "tags" { default = ["terraform", "iksvpn"] }

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

resource "ibm_resource_group" "group" {
  name = "${var.basename}-group"
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.basename}-vpc"
  resource_group = ibm_resource_group.group.id
  tags           = var.tags
}

resource "ibm_is_subnet" "subnet_1" {
  name            = "${var.basename}-subnet-1"
  resource_group  = ibm_resource_group.group.id
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.region}-1"
  ipv4_cidr_block = "10.240.0.0/24"
  tags            = var.tags
}

resource "ibm_is_public_gateway" "zone_1" {
  name = "${var.basename}-pubgw-1"
  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-1"
}

resource "ibm_is_subnet_public_gateway_attachment" "example" {
  subnet         = ibm_is_subnet.subnet_1.id
  public_gateway = ibm_is_public_gateway.zone_1.id
}

resource "ibm_container_vpc_cluster" "cluster" {
  name              = "${var.basename}-vpc"
  vpc_id            = ibm_is_vpc.vpc.id
  flavor            = var.worker_pool_flavor
  worker_count      = "1"
  kube_version      = var.kube_version
  resource_group_id = ibm_resource_group.group.id
  zones {
    subnet_id = ibm_is_subnet.subnet_1.id
    name      = "${var.region}-1"
  }
  force_delete_storage = true
  tags                 = var.tags
}

output "resource_group_name" {
  value = ibm_resource_group.group.name
}

output "cluster_name" {
  value = ibm_container_vpc_cluster.cluster.name
}
