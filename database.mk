SHELL = bash

REGISTRY = registry.hub.docker.com
CONTAINER = library/postgres
VERSION = 11

.PHONY: all serve

all: serve

include .starterkit.mk

.PHONY: pull-latest
pull-latest: network-create-starterkit
	@docker pull $(REGISTRY)/$(CONTAINER):$(VERSION)

serve: is-defined-STARTERKIT_DATABASE_HOSTNAME is-defined-STARTERKIT_DATABASE_TCP_PORT is-defined-STARTERKIT_DATABASE_USERNAME is-defined-STARTERKIT_DATABASE_PASSWORD pull-latest
ifneq ($(shell docker ps -q --filter name="$(STARTERKIT_DATABASE_HOSTNAME)" --format RUNNING),RUNNING)
	@docker run --network starterkit-network --rm				\
	    --name "$(STARTERKIT_DATABASE_HOSTNAME)"				\
	    -e POSTGRES_DB=starterkit						\
	    -e POSTGRES_USER="$(STARTERKIT_DATABASE_USERNAME)"			\
	    -e POSTGRES_PASSWORD="$(STARTERKIT_DATABASE_PASSWORD)"		\
	    -v database-volume:/var/lib/databaseql/data				\
	    $(REGISTRY)/$(CONTAINER):$(VERSION)					\
	    postgres -p "$(STARTERKIT_DATABASE_TCP_PORT)"
else
	@true
endif
