SHELL = bash

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

.PHONY: network-create-%
network-create-%:
	@if [[ -z "$(shell docker network inspect --format=CREATED $*-network)" ]];	\
	then									\
	    docker network create --driver bridge $*-network;			\
	fi									\
