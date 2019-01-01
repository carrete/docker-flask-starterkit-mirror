# -*- coding: utf-8; mode: make; -*-

SHELL = bash

REGISTRY = registry.gitlab.com

# Container Linux (CoreOS) 1967.3.0 Stable Channel (HVM)
# https://coreos.com/os/docs/latest/booting-on-ec2.html
STARTERKIT_INSTANCE_AMI_ID ?= "ami-0c1cc1260c7828fcb"

.PHONY: all
all: create

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

.PHONY: pull-latest
pull-latest: is-defined-REGISTRY
	@docker pull $(REGISTRY)/tvaughan/docker-terraform:latest > /dev/null

.PHONY: %-s3-bucket
%-s3-bucket: is-defined-AWS_ACCESS_KEY_ID is-defined-AWS_SECRET_ACCESS_KEY is-defined-STARTERKIT_DOMAIN is-defined-STARTERKIT_REGION pull-latest
	@docker run --rm --name $@						\
	    -e AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"				\
	    -e AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"			\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-terraform:latest			\
	    $*-s3-bucket "$(STARTERKIT_REGION)" "$(STARTERKIT_DOMAIN)"

.PHONY: create-remote-state-bucket
create-remote-state-bucket: create-s3-bucket

.PHONY: delete-remote-state-bucket
delete-remote-state-bucket: delete-s3-bucket

.PHONY: check-environment
check-environment: is-defined-AWS_ACCESS_KEY_ID is-defined-AWS_SECRET_ACCESS_KEY is-defined-STARTERKIT_DATABASE_PASSWORD is-defined-STARTERKIT_DATABASE_TCP_PORT is-defined-STARTERKIT_DATABASE_USERNAME is-defined-STARTERKIT_DOMAIN is-defined-STARTERKIT_REGION is-defined-STARTERKIT_INSTANCE_AMI_ID

.PHONY: terraform-run-%
terraform-run-%: check-environment pull-latest
	@docker run --rm --name $@ $(DOCKER_EXTRA_RUN_ARGS)			\
	    -e AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"				\
	    -e AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"			\
	    -e TF_CLI_ARGS_init="-upgrade=true"					\
	    -e TF_CLI_ARGS_plan="-out=terraform.plan"				\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-terraform:latest			\
	    terraform $*							\
	    -var=starterkit_database_username="$(STARTERKIT_DATABASE_USERNAME)"	\
	    -var=starterkit_database_password="$(STARTERKIT_DATABASE_PASSWORD)"	\
	    -var=starterkit_database_tcp_port="$(STARTERKIT_DATABASE_TCP_PORT)"	\
	    -var=starterkit_domain="$(STARTERKIT_DOMAIN)"			\
	    -var=starterkit_region="$(STARTERKIT_REGION)"			\
	    -var=starterkit_instance_ami_id="$(STARTERKIT_INSTANCE_AMI_ID)"	\
	    $(TERRAFORM_EXTRA_RUN_ARGS)						\
	    .

.PHONY: terraform-short-run-%
terraform-short-run-%: check-environment pull-latest
	@docker run --rm --name $@ $(DOCKER_EXTRA_RUN_ARGS)			\
	    -e AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"				\
	    -e AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"			\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-terraform:latest			\
	    terraform $*							\
	    $(TERRAFORM_EXTRA_SHORT_RUN_ARGS)

.PHONY: init
init: DOCKER_EXTRA_RUN_ARGS=
init: TERRAFORM_EXTRA_RUN_ARGS=-backend-config=bucket="$(STARTERKIT_DOMAIN)" -backend-config=region="$(STARTERKIT_REGION)"
init: create-remote-state-bucket terraform-run-init

.PHONY: lint
lint: DOCKER_EXTRA_RUN_ARGS=
lint: TERRAFORM_EXTRA_RUN_ARGS=
lint: init terraform-run-validate

.PHONY: maybe-create
maybe-create: lint terraform-run-plan
	@[[ $${ASSUME_YES:-0} == 1 ]] && true || bash --init-file .helpers.sh -i -c 'unless_yes "Apply this plan?"'
	@docker run --rm --name $@ $(DOCKER_EXTRA_RUN_ARGS)			\
	    -e AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"				\
	    -e AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"			\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-terraform:latest			\
	    terraform apply terraform.plan

.PHONY: create
create: DOCKER_EXTRA_RUN_ARGS=
create: TERRAFORM_EXTRA_RUN_ARGS=
create: maybe-create

.PHONY: create-nameservers
create-nameservers: DOCKER_EXTRA_RUN_ARGS=
create-nameservers: TERRAFORM_EXTRA_RUN_ARGS=-target=aws_route53_zone.starterkit_route53_zone
create-nameservers: maybe-create

.PHONY: create-database
create-database: DOCKER_EXTRA_RUN_ARGS=
create-database: TERRAFORM_EXTRA_RUN_ARGS=-target=aws_db_instance.starterkit_database_instance
create-database: maybe-create

.PHONY: destroy
destroy: DOCKER_EXTRA_RUN_ARGS=-it
destroy: TERRAFORM_EXTRA_RUN_ARGS=
destroy: lint terraform-run-destroy

.PHONY: show-outputs
show-outputs: DOCKER_EXTRA_RUN_ARGS=
show-outputs: TERRAFORM_EXTRA_SHORT_RUN_ARGS=-module=starterkit-mirror
show-outputs: lint terraform-short-run-output

.PHONY: format
format: DOCKER_EXTRA_RUN_ARGS=
format: TERRAFORM_EXTRA_RUN_ARGS=
format: lint terraform-short-run-fmt

.sshrc: is-defined-STARTERKIT_BASTION_IP_ADDR is-defined-STARTERKIT_INSTANCE_IP_ADDR
	@echo -en							       "\
	Host *                                                               \\n\
	  LogLevel quiet                                                     \\n\
	  StrictHostKeyChecking no                                           \\n\
	  UserKnownHostsFile /dev/null                                       \\n\
	Host starterkit-bastion                                              \\n\
	  HostName $(STARTERKIT_BASTION_IP_ADDR)                             \\n\
	  User ec2-user                                                      \\n\
	Host starterkit-instance                                             \\n\
	  HostName $(STARTERKIT_INSTANCE_IP_ADDR)                            \\n\
	  User core                                                          \\n\
	  ProxyCommand ssh -F .sshrc starterkit-bastion -W %h:%p             \\n\
	" > $@

.PHONY: ssh-add-keys
ssh-add-keys: is-defined-STARTERKIT_BASTION_SSH_PRIVKEY is-defined-STARTERKIT_INSTANCE_SSH_PRIVKEY
	@for SSH_PRIVKEY in "$$STARTERKIT_BASTION_SSH_PRIVKEY" "$$STARTERKIT_INSTANCE_SSH_PRIVKEY";	\
	do									\
	  echo "$$SSH_PRIVKEY" | grep . - | ssh-add - > /dev/null 2>&1;		\
	done

.PHONY: ssh-%
ssh-%: .sshrc ssh-add-keys
	@ssh -F .sshrc starterkit-$*
