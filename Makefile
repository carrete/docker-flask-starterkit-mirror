SHELL = bash

REGISTRY = registry.gitlab.com
IMAGE = $(REGISTRY)/tvaughan/docker-flask-starterkit
CURRENT = $(IMAGE):$(shell git rev-parse --short HEAD)

.PHONY: all build check-cert create-environment gitlab-runner-% is-repo-clean lint login push serve shell ssh-% ssh-add-keys tag-current test volume-archive-% volume-restore-% watch

all: lint test

include .starterkit.mk

build:
	@docker build --pull -t $(CURRENT) .

lint serve test: is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY build network-create-starterkit
	@docker run --network starterkit-network --rm				\
	    --add-host localhost.localdomain:127.0.1.1				\
	    --name flask-app							\
	    -e GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    -e POSTGRES_HOSTNAME="$(POSTGRES_HOSTNAME)"				\
	    -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"				\
	    -e SECRET_KEY="$(SECRET_KEY)"					\
	    -e SENTRY_DSN="$(SENTRY_DSN)"					\
	    -e STARTERKIT_ENVIRONMENT=development				\
	    -p 3000:3000							\
	    -v www-volume:/srv/www						\
            $(CURRENT)								\
	    make $@

shell watch: is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY build network-create-starterkit
	@docker run --network starterkit-network --rm -it			\
	    --add-host localhost.localdomain:127.0.1.1				\
	    --name flask-app							\
	    -e GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    -e POSTGRES_HOSTNAME="$(POSTGRES_HOSTNAME)"				\
	    -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"				\
	    -e SECRET_KEY="$(SECRET_KEY)"					\
	    -e SENTRY_DSN="$(SENTRY_DSN)"					\
	    -e STARTERKIT_ENVIRONMENT=development				\
	    -p 3000:3000							\
	    -v www-volume:/srv/www						\
	    -e HOST_UID=$(shell id -u)						\
	    -e HOST_GID=$(shell id -g)						\
	    -v "$(PWD)"/flask-app:/opt/flask-app				\
            $(CURRENT)								\
	    make $@

is-repo-clean:
	@git diff-index --quiet HEAD --

tag-current: is-repo-clean build
	@docker tag $(CURRENT) $(IMAGE):$(shell ./symbolic-tag)

login: is-defined-GITLAB_USERNAME is-defined-GITLAB_PASSWORD
	@echo "$(GITLAB_PASSWORD)" | docker login -u "$(GITLAB_USERNAME)" --password-stdin $(REGISTRY)

push: tag-current login
	@docker push $(IMAGE)

create-environment: is-defined-ADMIN_USERNAME is-defined-ADMIN_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY is-defined-STARTERKIT_DOMAIN
	@echo -en							       "\
	ADMIN_USERNAME=$(ADMIN_USERNAME)				     \\n\
	ADMIN_PASSWORD=$(ADMIN_PASSWORD)				     \\n\
	CONTAINER=$(CURRENT)						     \\n\
	POSTGRES_HOSTNAME=$(POSTGRES_HOSTNAME)				     \\n\
	POSTGRES_PASSWORD=$(POSTGRES_PASSWORD)				     \\n\
	SECRET_KEY=$(SECRET_KEY)					     \\n\
	SENTRY_DSN=$(SENTRY_DSN)					     \\n\
	STARTERKIT_DOMAIN=$(STARTERKIT_DOMAIN)				     \\n\
	" > coreos/var/cache/starterkit/environment

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

ssh-add-keys: is-defined-STARTERKIT_BASTION_SSH_PRIVKEY is-defined-STARTERKIT_INSTANCE_SSH_PRIVKEY
	@for SSH_PRIVKEY in "$$STARTERKIT_BASTION_SSH_PRIVKEY" "$$STARTERKIT_INSTANCE_SSH_PRIVKEY";	\
	do									\
	  echo "$$SSH_PRIVKEY" | grep . - | ssh-add - > /dev/null 2>&1;		\
	done

ssh-%: .sshrc ssh-add-keys
	@ssh -F .sshrc starterkit-$*

deploy: is-defined-GITLAB_USERNAME is-defined-GITLAB_PASSWORD is-defined-REGISTRY create-environment .sshrc ssh-add-keys
	@rsync -r -e "ssh -F .sshrc" --rsync-path="sudo rsync" coreos/ starterkit-instance:/
	@ssh -F .sshrc starterkit-instance sudo docker login			\
	    -u "$(GITLAB_USERNAME)" -p "$(GITLAB_PASSWORD)" $(REGISTRY)
	@ssh -F .sshrc starterkit-instance sudo systemctl daemon-reload
	@ssh -F .sshrc starterkit-instance sudo systemctl enable		\
	    prune-docker-images.timer create-network.service			\
	    postgres.service flask-app.service nginx-proxy-unit.service	\
	    create-default-site.service create-htpasswd.service			\
	    create-snakeoil-cert.service
	@ssh -F .sshrc starterkit-instance sudo systemctl restart		\
	    prune-docker-images.timer create-network.service			\
	    postgres.service flask-app.service nginx-proxy-unit.service	\
	    create-default-site.service create-htpasswd.service			\
	    create-snakeoil-cert.service

gitlab-runner-%: is-defined-ADMIN_USERNAME is-defined-ADMIN_PASSWORD is-defined-GITLAB_USERNAME is-defined-GITLAB_PASSWORD is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_PASSWORD is-defined-SECRET_KEY is-defined-SENTRY_DSN is-defined-STARTERKIT_INSTANCE_IP_ADDR is-defined-STARTERKIT_INSTANCE_SSH_PRIVKEY
	@gitlab-runner exec docker --docker-privileged				\
	    --env ADMIN_PASSWORD="$(ADMIN_PASSWORD)"				\
	    --env ADMIN_USERNAME="$(ADMIN_USERNAME)"				\
	    --env GITLAB_USERNAME="$(GITLAB_USERNAME)"				\
	    --env GITLAB_PASSWORD="$(GITLAB_PASSWORD)"				\
	    --env POSTGRES_HOSTNAME="$(POSTGRES_HOSTNAME)"			\
	    --env POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"			\
	    --env SECRET_KEY="$(SECRET_KEY)"					\
	    --env SENTRY_DSN="$(SENTRY_DSN)"					\
	    --env STARTERKIT_INSTANCE_IP_ADDR=$(STARTERKIT_INSTANCE_IP_ADDR)	\
	    --env STARTERKIT_INSTANCE_SSH_PRIVKEY="$$STARTERKIT_INSTANCE_SSH_PRIVKEY"	\
	    $*

check-cert: is-defined-STARTERKIT_DOMAIN
	@echo QUIT | openssl s_client -connect $(STARTERKIT_DOMAIN):443 | openssl x509 -noout -dates

HERETHERE := $(shell mktemp -d)
TIMESTAMP := $(shell date -u -Iseconds)

volume-archive-%: TARBALL=$*-volume-"$(TIMESTAMP)".tar.xz
volume-archive-%: is-defined-TARBALL .sshrc ssh-add-keys
	@ssh -F .sshrc starterkit-instance sudo systemctl stop postgres.service
	@ssh -F .sshrc starterkit-instance docker run --rm			\
	    --name archive-volume						\
	    -v $(HERETHERE):$(HERETHERE)					\
	    -v $*-volume:/mnt/$*-volume:ro					\
	    $(REGISTRY)/tvaughan/docker-ubuntu:18.04				\
	    tar -C /mnt/$*-volume -cf $(HERETHERE)/$(TARBALL) -a .
	@ssh -F .sshrc starterkit-instance sudo systemctl start nginx-proxy-unit.service
	@rsync -r -e "ssh -F .sshrc" --rsync-path="sudo rsync" starterkit-instance:$(HERETHERE)/ archives/

volume-restore-%: TARBALL=$(shell basename $(ARCHIVE))
volume-restore-%: is-defined-ARCHIVE is-defined-TARBALL .sshrc ssh-add-keys
	@rsync -r -e "ssh -F .sshrc" --rsync-path="sudo rsync" $(ARCHIVE) starterkit-instance:$(HERETHERE)/
	@ssh -F .sshrc starterkit-instance sudo systemctl stop postgres.service
	@ssh -F .sshrc starterkit-instance docker run --rm			\
	    --name restore-volume						\
	    -v $(HERETHERE):$(HERETHERE)					\
	    -v $*-volume:/mnt/$*-volume						\
	    $(REGISTRY)/tvaughan/docker-ubuntu:18.04				\
	    tar -C /mnt/$*-volume -xf $(HERETHERE)/$(TARBALL)
	@ssh -F .sshrc starterkit-instance sudo systemctl start nginx-proxy-unit.service
