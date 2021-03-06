# -*- coding: utf-8 -*-

import os


SECRET_KEY = os.environ["SECRET_KEY"]

LANGUAGES = {"en": "English", "es": "Español"}

BABEL_TRANSLATION_DIRECTORIES = "translations"

HASHEDASSETS_CATALOG = "/srv/www/hashedassets.yml"
HASHEDASSETS_SRC_DIR = "static/build"
HASHEDASSETS_OUT_DIR = "/srv/www/site/static"
HASHEDASSETS_URL_PREFIX = "/static/"

SQLALCHEMY_DATABASE_URI = "postgresql://{}:{}@{}:{}/{}".format(
    os.environ["STARTERKIT_DATABASE_USERNAME"],
    os.environ["STARTERKIT_DATABASE_PASSWORD"],
    os.environ["STARTERKIT_DATABASE_HOSTNAME"],
    os.environ["STARTERKIT_DATABASE_TCP_PORT"],
    os.environ["STARTERKIT_ENVIRONMENT"],
)
SQLALCHEMY_TRACK_MODIFICATIONS = False

SENTRY_DSN = os.environ.get("SENTRY_DSN", "")
SENTRY_USER_ATTRS = ["email"]

STARTERKIT_HOMEPAGE_BLUEPRINT_URL_PREFIX = "/"
