# -*- coding: utf-8 -*-

import os

from .common import *


DEBUG = True
TESTING = True

SERVER_NAME = "localhost.localdomain:8443"

SQLALCHEMY_DATABASE_URI = "postgresql://starterkit:{}@{}/testing".format(
    os.environ["POSTGRES_PASSWORD"], os.environ["POSTGRES_HOSTNAME"]
)

SENTRY_ENVIRONMENT = "testing"
