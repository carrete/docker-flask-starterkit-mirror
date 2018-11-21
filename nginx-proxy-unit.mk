SHELL = bash

REGISTRY = registry.gitlab.com
CONTAINER = tvaughan/docker-nginx-proxy-unit
VERSION = latest

.PHONY: all
all: serve

include .starterkit.mk

.PHONY: pull-latest
pull-latest: network-create-starterkit
	@docker pull $(REGISTRY)/$(CONTAINER):$(VERSION)

.PHONY: create-ssl-cert
create-ssl-cert: pull-latest
	@docker run --network starterkit-network --rm				\
	    -v ssl-cert-volume:/mnt/workdir					\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    create-snakeoil-cert

.PHONY: create-htpasswd
create-htpasswd: is-defined-ADMIN_USERNAME is-defined-ADMIN_PASSWORD pull-latest
	@docker run --network starterkit-network --rm				\
	    -e USERNAME="$(ADMIN_USERNAME)"					\
	    -e PASSWORD="$(ADMIN_PASSWORD)"					\
	    -v www-volume:/mnt/workdir						\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    create-htpasswd

.PHONY: create-default-site
create-default-site: pull-latest
	@docker run --network starterkit-network --rm				\
	    -e CANONICAL_HOST=localhost.localdomain				\
	    -e CANONICAL_PORT=8443						\
	    -e UNIT_HOST=flask-app                                              \
	    -e UNIT_PORT=3000                                                   \
	    -v default-site-volume:/mnt/workdir					\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    create-default-site

.PHONY: serve
serve: create-ssl-cert create-htpasswd create-default-site
ifneq ($(shell docker ps -q --filter name=nginx-proxy-unit --format RUNNING),RUNNING)
	@docker run --network starterkit-network --rm				\
	    --name nginx-proxy-unit						\
	    -p 8080:80 -p 8443:443						\
	    -v ssl-cert-volume:/srv/ssl:ro					\
	    -v www-volume:/srv/www:ro						\
	    -v default-site-volume:/etc/nginx/sites-enabled:ro			\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)
else
	@true
endif
