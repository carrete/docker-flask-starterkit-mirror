SHELL = bash

REGISTRY = registry.gitlab.com
CONTAINER = tvaughan/docker-nginx-proxy-unit
VERSION = latest

.PHONY: all serve

all: serve

include .starterkit.mk

serve: is-defined-ADMIN_USERNAME is-defined-ADMIN_PASSWORD network-create-starterkit volume-create-default-site volume-create-ssl-cert
ifneq ($(shell docker ps -q --filter name=nginx-proxy-unit --format RUNNING),RUNNING)
	@docker run --network starterkit-network --rm				\
	    -e CANONICAL_HOST=localhost.localdomain				\
	    -e CANONICAL_PORT=8443						\
	    -e UNIT_HOST=flask-app                                              \
	    -e UNIT_PORT=3000                                                   \
	    -v default-site-volume:/mnt/workdir					\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    create-default-site
	@docker run --network starterkit-network --rm				\
	    -v ssl-cert-volume:/mnt/workdir					\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    create-snakeoil-cert
	@docker run --network starterkit-network --rm				\
	    -e USERNAME="$(ADMIN_USERNAME)"					\
	    -e PASSWORD="$(ADMIN_PASSWORD)"					\
	    -v www-volume:/mnt/workdir						\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    create-htpasswd
	@docker run --network starterkit-network --rm				\
	    --name nginx-proxy-unit						\
	    -p 8080:80 -p 8443:443						\
	    -v default-site-volume:/etc/nginx/sites-enabled:ro			\
	    -v ssl-cert-volume:/srv/ssl:ro					\
	    -v www-volume:/srv/www:ro						\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)
else
	@true
endif
