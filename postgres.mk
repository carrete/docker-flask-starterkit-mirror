SHELL = bash

REGISTRY = registry.hub.docker.com
CONTAINER = library/postgres
VERSION = 10

.PHONY: all serve

all: serve

include .starterkit.mk

serve: is-defined-POSTGRES_PASSWORD network-create-starterkit volume-create-postgres
ifneq ($(shell docker ps -q --filter name=postgres --format RUNNING),RUNNING)
	@docker pull $(REGISTRY)/$(CONTAINER):$(VERSION)
	@docker run --network starterkit-network --rm				\
	    --name postgres							\
	    -e POSTGRES_DB=starterkit						\
	    -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)"				\
	    -e POSTGRES_USER=starterkit						\
	    -p 5432:5432							\
	    -v postgres-volume:/var/lib/postgresql/data				\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)
else
	@true
endif
