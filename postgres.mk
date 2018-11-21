SHELL = bash

REGISTRY = registry.hub.docker.com
CONTAINER = library/postgres
VERSION = 11

.PHONY: all serve

all: serve

include .starterkit.mk

serve: is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_TCP_PORT is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD network-create-starterkit
ifneq ($(shell docker ps -q --filter name=postgres --format RUNNING),RUNNING)
	@docker pull $(REGISTRY)/$(CONTAINER):$(VERSION)
	@docker run --network starterkit-network --rm				\
	    --name "$(POSTGRES_HOSTNAME)"					\
	    -e POSTGRES_DB=starterkit						\
	    -e POSTGRES_USER="$(POSTGRES_USERNAME)"				\
	    -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"				\
	    -v postgres-volume:/var/lib/postgresql/data				\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    postgres -p "$(POSTGRES_TCP_PORT)"
else
	@true
endif
