SHELL = bash

.PHONY: .shell .watch all build check-dependencies check-quality check-style check-vulnerabilities compile-messages create-assets create-db create-locale extract-messages format is-defined-% is-in-container lint minify-css minify-js serve set-perms setup-tests shell test update-messages watch

all: lint test

is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

define CONTAINER_REQUIRED_MESSAGE

This command must be run *inside* the container. Please use the Makefile in
the top-level directory of this project instead
endef

is-in-container:
	@$(if $(wildcard /.docker*),,$(error $(CONTAINER_REQUIRED_MESSAGE)))

MIN_CSS = $(subst src/,build/,$(patsubst %.css,%.min.css,$(wildcard static/src/**/*.css)))

static/build/css/%.min.css: static/src/css/%.css
	@uglifycss $< > $@

minify-css: is-in-container $(MIN_CSS)

MIN_JS = $(subst src/,build/,$(patsubst %.js,%.min.js,$(wildcard static/src/**/*.js)))

static/build/js/%.min.js: static/src/js/%.js
	@uglifyjs $< > $@

minify-js: is-in-container $(MIN_JS)

create-assets: minify-css minify-js
	@mkdir -p /srv/www/site/static
	@python3 manage.py hashassets
	@chown -R www-data:www-data /srv/www/site/static

create-db: is-in-container
	@python3 manage.py createdb

build: create-assets create-db
	@cp unit-conf.json /var/lib/unit/conf.json

format: is-in-container
	@find . -name "*.py" | grep -v "^./migrations"				\
	    | xargs black -q -l 110

check-style: is-in-container
	@find . -name "*.py" | grep -v "^./migrations"				\
	    | xargs black -q -l 110 --check

check-quality: is-in-container
	@bandit -r .

check-dependencies: is-in-container is-defined-GITLAB_PASSWORD
	@pyup --provider gitlab --repo=tvaughan/docker-flask-starterkit		\
	    --user-token="$(GITLAB_PASSWORD)"

check-vulnerabilities: is-in-container
	@safety check

lint: check-style check-quality check-dependencies check-vulnerabilities

setup-tests: is-in-container is-defined-POSTGRES_HOSTNAME is-defined-POSTGRES_PASSWORD
	@PGPASSWORD="$(POSTGRES_PASSWORD)" psql -h $(POSTGRES_HOSTNAME) -U starterkit \
	    -c "DROP DATABASE IF EXISTS testing;"
	@PGPASSWORD="$(POSTGRES_PASSWORD)" psql -h $(POSTGRES_HOSTNAME) -U starterkit \
	    -c "CREATE DATABASE testing;"

test: build setup-tests
	@pytest

serve: build
	@unitd --no-daemon

set-perms: is-in-container is-defined-HOST_UID is-defined-HOST_GID
	@chown -R $(HOST_UID):$(HOST_GID) .

.shell: is-in-container
	@bash -l || true

shell: .shell set-perms

.watch: is-in-container
	@reflex -g '*' -G "*coverage*" -G "*htmlcov*" -s --			\
	    $(SHELL) -c "$(MAKE) serve"

watch: .watch set-perms

create-locale: is-in-container is-defined-LANGUAGE
	@pybabel init -d translations -i messages.pot -l $(LANGUAGE)

extract-messages: is-in-container
	@pybabel extract --no-wrap -F babel.cfg -o messages.pot .

update-messages: is-in-container
	@pybabel update --no-wrap -d translations -i messages.pot

compile-messages: is-in-container
	@pybabel compile -d translations
