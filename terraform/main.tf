# -*- coding: utf-8; mode: terraform -*-

module "starterkit-mirror" {
  source  = "carrete/starterkit-mirror/aws"
  version = "~> 0"

  starterkit_database_username = "${var.starterkit_database_username}"
  starterkit_database_password = "${var.starterkit_database_password}"
  starterkit_database_tcp_port = "${var.starterkit_database_tcp_port}"

  starterkit_domain = "${var.starterkit_domain}"
  starterkit_region = "${var.starterkit_region}"

  starterkit_instance_ami = {
    "${var.starterkit_region}" = "${var.starterkit_instance_ami_id}"
  }
}

terraform {
  backend "s3" {
    key = "production/terraform.tfstate"
  }
}
