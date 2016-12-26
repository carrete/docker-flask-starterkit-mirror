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
lint serve test: is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_TCP_PORT is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY build network-create-starterkit
	@docker run --network starterkit-network --rm				\
	    --add-host localhost.localdomain:127.0.1.1				\
	    --name flask-app							\
	    -e GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    -e POSTGRES_HOSTNAME="$(POSTGRES_HOSTNAME)"				\
	    -e POSTGRES_TCP_PORT="$(POSTGRES_TCP_PORT)"				\
	    -e POSTGRES_USERNAME="$(POSTGRES_USERNAME)"				\
	    -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"				\
	    -e SECRET_KEY="$(SECRET_KEY)"					\
	    -e SENTRY_DSN="$(SENTRY_DSN)"					\
	    -e STARTERKIT_ENVIRONMENT=development				\
	    -p 3000:3000							\
	    -v www-volume:/srv/www						\
            $(CURRENT)								\
	    make $@

.PHONY: shell watch
shell watch: is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_TCP_PORT is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY build network-create-starterkit
	@docker run --network starterkit-network --rm -it			\
	    --add-host localhost.localdomain:127.0.1.1				\
	    --name flask-app							\
	    -e GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    -e POSTGRES_HOSTNAME="$(POSTGRES_HOSTNAME)"				\
	    -e POSTGRES_TCP_PORT="$(POSTGRES_TCP_PORT)"				\
	    -e POSTGRES_USERNAME="$(POSTGRES_USERNAME)"				\
	    -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"				\
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

.PHONY: create-environment
create-environment: is-defined-ADMIN_USERNAME is-defined-ADMIN_PASSWORD is-defined-GITLAB_USERNAME is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_TCP_PORT is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-REGISTRY is-defined-SECRET_KEY is-defined-STARTERKIT_DOMAIN
	@echo -en							       "\
	ADMIN_USERNAME=\"$(ADMIN_USERNAME)\"				     \\n\
	ADMIN_PASSWORD=\"$(ADMIN_PASSWORD)\"				     \\n\
	CONTAINER=\"$(CURRENT)\"					     \\n\
	GITLAB_USERNAME=\"$(GITLAB_USERNAME)\"				     \\n\
	GITLAB_PASSWORD=\"$(GITLAB_PASSWORD)\"				     \\n\
	POSTGRES_USERNAME=\"$(POSTGRES_USERNAME)\"			     \\n\
	POSTGRES_PASSWORD=\"$(POSTGRES_PASSWORD)\"			     \\n\
	POSTGRES_HOSTNAME=\"$(POSTGRES_HOSTNAME)\"			     \\n\
	POSTGRES_TCP_PORT=\"$(POSTGRES_TCP_PORT)\"			     \\n\
	REGISTRY=\"$(REGISTRY)\"					     \\n\
	SECRET_KEY=\"$(SECRET_KEY)\"					     \\n\
	SENTRY_DSN=\"$(SENTRY_DSN)\"					     \\n\
	STARTERKIT_DOMAIN=\"$(STARTERKIT_DOMAIN)\"			     \\n\
	" > coreos/var/cache/starterkit/environment

.PHONY: create-ami
create-ami: is-repo-clean is-defined-STARTERKIT_REGION create-environment
	@docker pull registry.gitlab.com/tvaughan/docker-packer:latest
	@docker run --rm --name $@						\
	    -e STARTERKIT_VERSION="$(STARTERKIT_VERSION)"			\
            -e AWS_ACCESS_KEY_ID="$(AWS_ACCESS_KEY_ID)"				\
            -e AWS_SECRET_ACCESS_KEY="$(AWS_SECRET_ACCESS_KEY)"			\
            -e AWS_DEFAULT_REGION="$(STARTERKIT_REGION)"			\
	    -v "$(PWD)":/mnt/workdir						\
            registry.gitlab.com/tvaughan/docker-packer:latest			\
	    packer build packer.json

.PHONY: gitlab-runner-%
gitlab-runner-%: is-defined-ADMIN_USERNAME is-defined-ADMIN_PASSWORD is-defined-GITLAB_USERNAME is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_TCP_PORT is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY is-defined-STARTERKIT_INSTANCE_IP_ADDR is-defined-STARTERKIT_INSTANCE_SSH_PRIVKEY
	@gitlab-runner exec docker --docker-privileged				\
	    --env ADMIN_PASSWORD="$(ADMIN_PASSWORD)"				\
	    --env ADMIN_USERNAME="$(ADMIN_USERNAME)"				\
	    --env GITLAB_USERNAME="$(GITLAB_USERNAME)"				\
	    --env GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    --env POSTGRES_USERNAME="$(POSTGRES_USERNAME)"			\
	    --env POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"			\
	    --env SECRET_KEY="$(SECRET_KEY)"					\
	    --env SENTRY_DSN="$(SENTRY_DSN)"					\
	    --env STARTERKIT_INSTANCE_IP_ADDR=$(STARTERKIT_INSTANCE_IP_ADDR)	\
	    --env STARTERKIT_INSTANCE_SSH_PRIVKEY="$$STARTERKIT_INSTANCE_SSH_PRIVKEY"	\
	    $*

.PHONY: check-cert
check-cert: is-defined-STARTERKIT_DOMAIN
	@echo QUIT | openssl s_client -connect $(STARTERKIT_DOMAIN):443 | openssl x509 -noout -dates

HERETHERE := $(shell mktemp -d)
TIMESTAMP := $(shell date -u -Iseconds)

.PHONY: volume-archive-%
volume-archive-%: TARBALL=$*-volume-"$(TIMESTAMP)".tar.xz
volume-archive-%: is-defined-TARBALL
	@$(MAKE) -C terraform .sshrc ssh-add-keys
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl stop postgres.service
	@ssh -F terraform/.sshrc starterkit-instance docker run --rm --name $@	\
	    -v $(HERETHERE):$(HERETHERE)					\
	    -v $*-volume:/mnt/$*-volume:ro					\
	    $(REGISTRY)/tvaughan/docker-ubuntu:18.04				\
	    tar -C /mnt/$*-volume -cf $(HERETHERE)/$(TARBALL) -a .
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl start nginx-proxy-unit.service
	@rsync -r -e "ssh -F terraform/.sshrc" --rsync-path="sudo rsync" starterkit-instance:$(HERETHERE)/ archives/

.PHONY: volume-restore-%
volume-restore-%: TARBALL=$(shell basename $(ARCHIVE))
volume-restore-%: is-defined-ARCHIVE is-defined-TARBALL
	@$(MAKE) -C terraform .sshrc ssh-add-keys
	@rsync -r -e "ssh -F terraform/.sshrc" --rsync-path="sudo rsync" $(ARCHIVE) starterkit-instance:$(HERETHERE)/
	@ssh -F terraform/.sshrc starterkit-instance sudo systemctl stop postgres.service
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
