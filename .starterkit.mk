SHELL = bash

.PHONY: is-defined-% network-create-% volume-create-%

is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

network-create-%:
	@if [[ -z "$(shell docker network inspect --format=CREATED $*-network)" ]];	\
	then									\
	    docker network create --driver bridge $*-network;			\
	fi									\

volume-create-%:
	@docker volume create --name $*-volume
