# -*- coding: utf-8; mode: make; -*-

SHELL = bash

.PHONY: all
all: create

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

.PHONY: create-remote-state-bucket
create-remote-state-bucket: is-defined-AWS_ACCESS_KEY_ID is-defined-AWS_SECRET_ACCESS_KEY is-defined-STARTERKIT_REGION
	@if aws s3 --region="$(STARTERKIT_REGION)" ls s3://"$(STARTERKIT_DOMAIN)" 2>&1 | grep -q "NoSuchBucket";	\
	then									\
	    aws s3 --region="$(STARTERKIT_REGION)" mb s3://"$(STARTERKIT_DOMAIN)" 2>&1;				\
	else									\
	    true;								\
	fi

.PHONY: delete-remote-state-bucket
delete-remote-state-bucket: is-defined-AWS_ACCESS_KEY_ID is-defined-STARTERKIT_REGION is-defined-AWS_SECRET_ACCESS_KEY
	@if aws s3 --region="$(STARTERKIT_REGION)" ls s3://"$(STARTERKIT_DOMAIN)" 2>&1 | grep -q "NoSuchBucket";	\
	then									\
	    true;								\
	else									\
	    for BUCKET in production;						\
	    do									\
		aws s3 --region="$(STARTERKIT_REGION)" rm --recursive		\
		    s3://"$(STARTERKIT_DOMAIN)"/$$BUCKET 2>&1;			\
	    done;								\
	    aws s3 --region="$(STARTERKIT_REGION)" rb s3://"$(STARTERKIT_DOMAIN)" 2>&1;				\
	fi

.PHONY: init
init: is-defined-AWS_ACCESS_KEY_ID is-defined-AWS_SECRET_ACCESS_KEY is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-POSTGRES_TCP_PORT is-defined-STARTERKIT_DOMAIN is-defined-STARTERKIT_REGION is-defined-STARTERKIT_INSTANCE_AMI_ID create-remote-state-bucket
	@terraform init								\
	    -backend-config=bucket="$(STARTERKIT_DOMAIN)"			\
	    -backend-config=region="$(STARTERKIT_REGION)"			\
	    -var=postgres_username="$(POSTGRES_USERNAME)"			\
	    -var=postgres_password="$(POSTGRES_PASSWORD)"			\
	    -var=postgres_tcp_port="$(POSTGRES_TCP_PORT)"			\
	    -var=starterkit_domain="$(STARTERKIT_DOMAIN)"			\
	    -var=starterkit_region="$(STARTERKIT_REGION)"			\
	    -var=starterkit_instance_ami_id="$(STARTERKIT_INSTANCE_AMI_ID)"	\
	    -upgrade								\
	    .

.PHONY: lint
lint: init
	@terraform validate							\
	    -var=postgres_username="$(POSTGRES_USERNAME)"			\
	    -var=postgres_password="$(POSTGRES_PASSWORD)"			\
	    -var=postgres_tcp_port="$(POSTGRES_TCP_PORT)"			\
	    -var=starterkit_domain="$(STARTERKIT_DOMAIN)"			\
	    -var=starterkit_region="$(STARTERKIT_REGION)"			\
	    -var=starterkit_instance_ami_id="$(STARTERKIT_INSTANCE_AMI_ID)"	\
	    .

.PHONY: create
create: lint
	@terraform plan -out=terraform.plan					\
	    -var=postgres_username="$(POSTGRES_USERNAME)"			\
	    -var=postgres_password="$(POSTGRES_PASSWORD)"			\
	    -var=postgres_tcp_port="$(POSTGRES_TCP_PORT)"			\
	    -var=starterkit_domain="$(STARTERKIT_DOMAIN)"			\
	    -var=starterkit_region="$(STARTERKIT_REGION)"			\
	    -var=starterkit_instance_ami_id="$(STARTERKIT_INSTANCE_AMI_ID)"	\
	    .
	@bash --init-file .helpers.sh -i -c 'unless_yes "Apply this plan?"'
	@terraform apply terraform.plan

.PHONY: destroy
destroy: lint
	@terraform destroy							\
	    -var=postgres_username="$(POSTGRES_USERNAME)"			\
	    -var=postgres_password="$(POSTGRES_PASSWORD)"			\
	    -var=postgres_tcp_port="$(POSTGRES_TCP_PORT)"			\
	    -var=starterkit_domain="$(STARTERKIT_DOMAIN)"			\
	    -var=starterkit_region="$(STARTERKIT_REGION)"			\
	    -var=starterkit_instance_ami_id="$(STARTERKIT_INSTANCE_AMI_ID)"	\
	    .

.PHONY: format
format:
	@terraform fmt

.PHONY: show-outputs
show-outputs:
	@terraform refresh							\
	    -var=postgres_username="$(POSTGRES_USERNAME)"			\
	    -var=postgres_password="$(POSTGRES_PASSWORD)"			\
	    -var=postgres_tcp_port="$(POSTGRES_TCP_PORT)"			\
	    -var=starterkit_domain="$(STARTERKIT_DOMAIN)"			\
	    -var=starterkit_region="$(STARTERKIT_REGION)"			\
	    -var=starterkit_instance_ami_id="$(STARTERKIT_INSTANCE_AMI_ID)"	\
	    .
	@terraform output -module=starterkit-mirror

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
