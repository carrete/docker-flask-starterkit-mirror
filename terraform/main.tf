# -*- coding: utf-8; mode: terraform -*-

module "starterkit-mirror" {
  source  = "carrete/starterkit-mirror/aws"
  version = "~> 0"

  postgres_username = "${var.postgres_username}"
  postgres_password = "${var.postgres_password}"
  postgres_tcp_port = "${var.postgres_tcp_port}"

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
