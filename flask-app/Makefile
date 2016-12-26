SHELL = bash

.PHONY: all
all: lint test

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

define CONTAINER_REQUIRED_MESSAGE

This command must be run *inside* the container. Please use the Makefile in
the top-level directory of this project instead
endef

.PHONY: is-in-container
is-in-container:
	@$(if $(wildcard /.docker*),,$(error $(CONTAINER_REQUIRED_MESSAGE)))

MIN_CSS = $(subst src/,build/,$(patsubst %.css,%.min.css,$(wildcard static/src/**/*.css)))

static/build/css/%.min.css: static/src/css/%.css
	@uglifycss $< > $@

.PHONY: minify-css
minify-css: is-in-container $(MIN_CSS)

MIN_JS = $(subst src/,build/,$(patsubst %.js,%.min.js,$(wildcard static/src/**/*.js)))

static/build/js/%.min.js: static/src/js/%.js
	@uglifyjs $< > $@

.PHONY: minify-js
minify-js: is-in-container $(MIN_JS)

.PHONY: create-assets
create-assets: minify-css minify-js
	@mkdir -p /srv/www/site/static
	@python3 manage.py hashassets
	@chown -R www-data:www-data /srv/www/site/static

.PHONY: create-db
create-db: is-in-container
	@python3 manage.py createdb

.PHONY: delete-db
delete-db: is-in-container
	@python3 manage.py deletedb

.PHONY: build
build: create-assets create-db
	@cp unit-conf.json /var/lib/unit/conf.json

.PHONY: format
format: is-in-container
	@find . -name "*.py" | grep -v "^./migrations"				\
	    | xargs black -q -l 110

.PHONY: check-style
check-style: is-in-container
	@find . -name "*.py" | grep -v "^./migrations"				\
	    | xargs black -q -l 110 --check

.PHONY: check-quality
check-quality: is-in-container
	@bandit -r .

.PHONY: check-dependencies
check-dependencies: is-in-container is-defined-GITLAB_PASSWORD
	@pyup --provider gitlab --repo=tvaughan/docker-flask-starterkit		\
	    --user-token="$(GITLAB_PASSWORD)"

.PHONY: check-vulnerabilities
check-vulnerabilities: is-in-container
	@safety check

.PHONY: lint
lint: check-style check-quality check-dependencies check-vulnerabilities

.PHONY: test
test: build
	@pytest

.PHONY: serve
serve: build
	@unitd --no-daemon

.PHONY: shell
shell: is-in-container
	@bash -l || true

.PHONY: watch
watch: is-in-container
	@reflex -g '*' -G "*coverage*" -G "*htmlcov*" -s --			\
	    $(SHELL) -c "$(MAKE) serve"

.PHONY: create-locale
create-locale: is-in-container is-defined-LANGUAGE
	@pybabel init -d starterkit/translations -i starterkit/messages.pot -l $(LANGUAGE)

.PHONY: extract-messages
extract-messages: is-in-container
	@pybabel extract --no-wrap -F babel.cfg -o starterkit/messages.pot .

.PHONY: update-messages
update-messages: is-in-container
	@pybabel update --no-wrap -d starterkit/translations -i starterkit/messages.pot

.PHONY: compile-messages
compile-messages: is-in-container
	@pybabel compile -d starterkit/translations

.PHONY: bdist-whl
bdist-whl: is-in-container
	@python3 setup.py bdist_wheel

.PHONY: publish-whl
publish-whl: is-defined-TWINE_USERNAME is-defined-TWINE_PASSWORD bdist-whl
	@twine upload dist/*

.PHONY: publish-pkgs
publish-pkgs: publish-whl
