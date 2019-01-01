SHELL = bash

STARTERKIT_VERSION = $(shell git rev-parse --short HEAD)

REGISTRY = registry.gitlab.com
IMAGE = $(REGISTRY)/tvaughan/docker-flask-starterkit

CURRENT = $(IMAGE):$(STARTERKIT_VERSION)

.PHONY: all
all: lint test

include .starterkit.mk

.PHONY: build
build:
	@docker build --pull -t $(CURRENT) .

.PHONY: lint serve test
lint serve test: is-defined-GITLAB_PASSWORD is-defined-SECRET_KEY is-defined-STARTERKIT_DATABASE_HOSTNAME is-defined-STARTERKIT_DATABASE_PASSWORD is-defined-STARTERKIT_DATABASE_TCP_PORT is-defined-STARTERKIT_DATABASE_USERNAME build network-create-starterkit
	@docker run --network starterkit-network --rm				\
	    --add-host localhost.localdomain:127.0.1.1				\
	    --name flask-app							\
	    -e GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    -e STARTERKIT_DATABASE_HOSTNAME="$(STARTERKIT_DATABASE_HOSTNAME)"	\
	    -e STARTERKIT_DATABASE_TCP_PORT="$(STARTERKIT_DATABASE_TCP_PORT)"	\
	    -e STARTERKIT_DATABASE_USERNAME="$(STARTERKIT_DATABASE_USERNAME)"	\
	    -e STARTERKIT_DATABASE_PASSWORD="$(STARTERKIT_DATABASE_PASSWORD)"	\
	    -e SECRET_KEY="$(SECRET_KEY)"					\
	    -e SENTRY_DSN="$(SENTRY_DSN)"					\
	    -e STARTERKIT_ENVIRONMENT=development				\
	    -p 3000:3000							\
	    -v www-volume:/srv/www						\
            $(CURRENT)								\
	    make $@

.PHONY: shell watch
shell watch: is-defined-GITLAB_PASSWORD is-defined-SECRET_KEY is-defined-STARTERKIT_DATABASE_HOSTNAME is-defined-STARTERKIT_DATABASE_PASSWORD is-defined-STARTERKIT_DATABASE_TCP_PORT is-defined-STARTERKIT_DATABASE_USERNAME build network-create-starterkit
	@docker run --network starterkit-network --rm -it			\
	    --add-host localhost.localdomain:127.0.1.1				\
	    --name flask-app							\
	    -e GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    -e STARTERKIT_DATABASE_HOSTNAME="$(STARTERKIT_DATABASE_HOSTNAME)"	\
	    -e STARTERKIT_DATABASE_TCP_PORT="$(STARTERKIT_DATABASE_TCP_PORT)"	\
	    -e STARTERKIT_DATABASE_USERNAME="$(STARTERKIT_DATABASE_USERNAME)"	\
	    -e STARTERKIT_DATABASE_PASSWORD="$(STARTERKIT_DATABASE_PASSWORD)"	\
	    -e SECRET_KEY="$(SECRET_KEY)"					\
	    -e SENTRY_DSN="$(SENTRY_DSN)"					\
	    -e STARTERKIT_ENVIRONMENT=development				\
	    -e TWINE_USERNAME="$(TWINE_USERNAME)"				\
	    -e TWINE_PASSWORD="$(TWINE_PASSWORD)"				\
	    -p 3000:3000							\
	    -v www-volume:/srv/www						\
	    -v "$(PWD)"/flask-app:/opt/flask-app				\
            $(CURRENT)								\
	    make $@

.PHONY: is-repo-clean
is-repo-clean:
	@git diff-index --quiet HEAD --

.PHONY: tag-current
tag-current: is-repo-clean build
	@docker tag $(CURRENT) $(IMAGE):$(shell ./symbolic-tag)

.PHONY: login
login: is-defined-GITLAB_USERNAME is-defined-GITLAB_PASSWORD
	@echo "$(GITLAB_PASSWORD)" | docker login -u "$(GITLAB_USERNAME)" --password-stdin $(REGISTRY)

.PHONY: push
push: tag-current login
	@docker push $(IMAGE)

.PHONY: create-environment-database
create-environment-database: is-defined-STARTERKIT_DATABASE_HOSTNAME is-defined-STARTERKIT_DATABASE_PASSWORD is-defined-STARTERKIT_DATABASE_TCP_PORT is-defined-STARTERKIT_DATABASE_USERNAME
	@echo -en							       "\
	GITLAB_USERNAME=\"$(GITLAB_USERNAME)\"				     \\n\
	GITLAB_PASSWORD=\"$(GITLAB_PASSWORD)\"				     \\n\
	IPV4_DEVICE=\"$(IPV4_DEVICE)\"					     \\n\
	STARTERKIT_DATABASE_USERNAME=\"$(STARTERKIT_DATABASE_USERNAME)\"     \\n\
	STARTERKIT_DATABASE_PASSWORD=\"$(STARTERKIT_DATABASE_PASSWORD)\"     \\n\
	STARTERKIT_DATABASE_HOSTNAME=\"$(STARTERKIT_DATABASE_HOSTNAME)\"     \\n\
	STARTERKIT_DATABASE_TCP_PORT=\"$(STARTERKIT_DATABASE_TCP_PORT)\"     \\n\
	REGISTRY=\"$(REGISTRY)\"					     \\n\
	" > coreos/database/var/cache/starterkit/environment

.PHONY: create-environment-instance
create-environment-instance: is-defined-ADMIN_PASSWORD is-defined-ADMIN_USERNAME is-defined-CANONICAL_HOST is-defined-CANONICAL_PORT is-defined-GITLAB_PASSWORD is-defined-GITLAB_USERNAME is-defined-REGISTRY is-defined-SECRET_KEY is-defined-STARTERKIT_DATABASE_PASSWORD is-defined-STARTERKIT_DATABASE_USERNAME is-defined-STARTERKIT_DOMAIN
	@echo -en							       "\
	ADMIN_USERNAME=\"$(ADMIN_USERNAME)\"				     \\n\
	ADMIN_PASSWORD=\"$(ADMIN_PASSWORD)\"				     \\n\
	CANONICAL_HOST=\"$(CANONICAL_HOST)\"				     \\n\
	CANONICAL_PORT=\"$(CANONICAL_PORT)\"				     \\n\
	CONTAINER=\"$(CURRENT)\"					     \\n\
	GITLAB_USERNAME=\"$(GITLAB_USERNAME)\"				     \\n\
	GITLAB_PASSWORD=\"$(GITLAB_PASSWORD)\"				     \\n\
	IPV4_DEVICE=\"$(IPV4_DEVICE)\"					     \\n\
	STARTERKIT_DATABASE_USERNAME=\"$(STARTERKIT_DATABASE_USERNAME)\"     \\n\
	STARTERKIT_DATABASE_PASSWORD=\"$(STARTERKIT_DATABASE_PASSWORD)\"     \\n\
	STARTERKIT_DATABASE_HOSTNAME=\"$(STARTERKIT_DATABASE_HOSTNAME)\"     \\n\
	STARTERKIT_DATABASE_TCP_PORT=\"$(STARTERKIT_DATABASE_TCP_PORT)\"     \\n\
	REGISTRY=\"$(REGISTRY)\"					     \\n\
	SECRET_KEY=\"$(SECRET_KEY)\"					     \\n\
	SENTRY_DSN=\"$(SENTRY_DSN)\"					     \\n\
	STARTERKIT_DOMAIN=\"$(STARTERKIT_DOMAIN)\"			     \\n\
	" > coreos/instance/var/cache/starterkit/environment

.PHONY: create-environment-balancer
create-environment-balancer: is-defined-GITLAB_PASSWORD is-defined-GITLAB_USERNAME is-defined-STARTERKIT_DOMAIN
	@echo -en							       "\
	GITLAB_USERNAME=\"$(GITLAB_USERNAME)\"				     \\n\
	GITLAB_PASSWORD=\"$(GITLAB_PASSWORD)\"				     \\n\
	IPV4_DEVICE=\"$(IPV4_DEVICE)\"					     \\n\
	REGISTRY=\"$(REGISTRY)\"					     \\n\
	STARTERKIT_DOMAIN=\"$(STARTERKIT_DOMAIN)\"			     \\n\
	" > coreos/balancer/var/cache/starterkit/environment

.PHONY: create-environment
create-environment: create-environment-database create-environment-instance create-environment-balancer

.PHONY: gitlab-runner-%
gitlab-runner-%: is-defined-ADMIN_PASSWORD is-defined-ADMIN_USERNAME is-defined-AWS_ACCESS_KEY_ID is-defined-AWS_SECRET_ACCESS_KEY is-defined-CANONICAL_HOST is-defined-CANONICAL_PORT is-defined-GITLAB_PASSWORD is-defined-GITLAB_USERNAME is-defined-SECRET_KEY is-defined-STARTERKIT_DATABASE_HOSTNAME is-defined-STARTERKIT_DATABASE_PASSWORD is-defined-STARTERKIT_DATABASE_TCP_PORT is-defined-STARTERKIT_DATABASE_USERNAME is-defined-STARTERKIT_DOMAIN is-defined-STARTERKIT_REGION
	@gitlab-runner exec docker --docker-privileged				\
	    --env ADMIN_PASSWORD="$(ADMIN_PASSWORD)"				\
	    --env ADMIN_USERNAME="$(ADMIN_USERNAME)"				\
	    --env AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"			\
	    --env AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"		\
	    --env CANONICAL_HOST="$(CANONICAL_HOST)"				\
	    --env CANONICAL_PORT="$(CANONICAL_PORT)"				\
	    --env GITLAB_USERNAME="$(GITLAB_USERNAME)"				\
	    --env GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    --env STARTERKIT_DATABASE_HOSTNAME="$(STARTERKIT_DATABASE_HOSTNAME)"	\
	    --env STARTERKIT_DATABASE_TCP_PORT="$(STARTERKIT_DATABASE_TCP_PORT)"	\
	    --env STARTERKIT_DATABASE_USERNAME="$(STARTERKIT_DATABASE_USERNAME)"	\
	    --env STARTERKIT_DATABASE_PASSWORD="$(STARTERKIT_DATABASE_PASSWORD)"	\
	    --env SECRET_KEY="$(SECRET_KEY)"					\
	    --env SENTRY_DSN="$(SENTRY_DSN)"					\
	    --env STARTERKIT_DOMAIN="$(STARTERKIT_DOMAIN)"			\
	    --env STARTERKIT_REGION="$(STARTERKIT_REGION)"			\
	    $*

.PHONY: check-cert
check-cert: is-defined-STARTERKIT_DOMAIN
	@echo QUIT | openssl s_client -connect $(STARTERKIT_DOMAIN):443 | openssl x509 -noout -dates

HERETHERE := $(shell mktemp -d)
TIMESTAMP := $(shell date -u -Iseconds)

.PHONY: volume-archive-%
volume-archive-%: export TARBALL=$*-volume-"$(TIMESTAMP)".tar.xz
volume-archive-%: is-defined-TARBALL
	@$(MAKE) -C terraform .sshrc ssh-add-keys
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl stop database.service
	@ssh -F terraform/.sshrc starterkit-instance docker run --rm --name $@	\
	    -v $(HERETHERE):$(HERETHERE)					\
	    -v $*-volume:/mnt/$*-volume:ro					\
	    $(REGISTRY)/tvaughan/docker-ubuntu:18.04				\
	    tar -C /mnt/$*-volume -cf $(HERETHERE)/$(TARBALL) -a .
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl start nginx-proxy-unit.service
	@rsync -r -e "ssh -F terraform/.sshrc" --rsync-path="sudo rsync" starterkit-instance:$(HERETHERE)/ archives/

.PHONY: volume-restore-%
volume-restore-%: export TARBALL=$(shell basename $(ARCHIVE))
volume-restore-%: is-defined-ARCHIVE is-defined-TARBALL
	@$(MAKE) -C terraform .sshrc ssh-add-keys
	@rsync -r -e "ssh -F terraform/.sshrc" --rsync-path="sudo rsync" $(ARCHIVE) starterkit-instance:$(HERETHERE)/
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl stop database.service
	@ssh -F terraform/.sshrc starterkit-instance docker run --rm --name $@	\
	    -v $(HERETHERE):$(HERETHERE)					\
	    -v $*-volume:/mnt/$*-volume						\
	    $(REGISTRY)/tvaughan/docker-ubuntu:18.04				\
	    tar -C /mnt/$*-volume -xf $(HERETHERE)/$(TARBALL)
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl start nginx-proxy-unit.service

.PHONY: bdist-%
bdist-%: is-repo-clean build
	@docker run --rm --name $@						\
	    -v "$(PWD)"/flask-app:/opt/flask-app				\
            $(CURRENT)								\
	    make $@

.PHONY: publish-whl
publish-whl: is-defined-TWINE_USERNAME is-defined-TWINE_PASSWORD bdist-whl
	@docker run --rm --name $@						\
	    -e TWINE_USERNAME="$(TWINE_USERNAME)"				\
	    -e TWINE_PASSWORD="$(TWINE_PASSWORD)"				\
	    -v "$(PWD)"/flask-app:/opt/flask-app				\
            $(CURRENT)								\
	    make $@

.PHONY: publish-pkgs
publish-pkgs: publish-whl

coreos-%.ign: coreos.yaml
	@docker pull $(REGISTRY)/tvaughan/docker-coreos-ct:latest > /dev/null
	@docker run --rm --name $@						\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-coreos-ct:latest			\
	    ct -in-file=coreos.yaml -out-file=$@ -platform=$*

.PHONY: create-%-ami
create-%-ami: is-repo-clean is-defined-AWS_ACCESS_KEY_ID is-defined-AWS_SECRET_ACCESS_KEY is-defined-STARTERKIT_REGION is-defined-STARTERKIT_VERSION create-environment coreos-ec2.ign
	@docker pull $(REGISTRY)/tvaughan/docker-packer:latest > /dev/null
	@docker run --rm --name $@						\
	    -e AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"				\
	    -e AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"			\
	    -e STARTERKIT_REGION="$(STARTERKIT_REGION)"				\
	    -e STARTERKIT_VERSION="$(STARTERKIT_VERSION)"			\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-packer:latest				\
	    packer build packer-$*.json

.PHONY: create-ami
create-ami: export IPV4_DEVICE="eth0"
create-ami: create-instance-ami

.PHONY: show-%-ami-artifact-id
show-%-ami-artifact-id:
	@docker pull $(REGISTRY)/tvaughan/docker-packer:latest > /dev/null
	@docker run --rm --name $@						\
	    -v "$(PWD)":/mnt/workdir						\
            $(REGISTRY)/tvaughan/docker-packer:latest				\
	    show-ami-artifact-id packer-$*-manifest.json

.PHONY: show-ami-artifact-id
show-ami-artifact-id: show-instance-ami-artifact-id

.PHONY: deploy-ami
deploy-ami: export STARTERKIT_INSTANCE_AMI_ID=$(shell $(MAKE) show-instance-ami-artifact-id)
deploy-ami:
	@cd terraform && ASSUME_YES=1 $(MAKE)

.PHONY: create-local-cluster
create-local-cluster: export IPV4_DEVICE="eth1"
create-local-cluster: export STARTERKIT_DATABASE_HOSTNAME="172.17.8.100"
create-local-cluster: create-environment coreos-vagrant-virtualbox.ign
	@vagrant up --provision
