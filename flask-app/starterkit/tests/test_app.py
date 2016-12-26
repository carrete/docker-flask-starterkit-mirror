# -*- coding: utf-8 -*-

import os

from starterkit.tests.helpers import create_app


def test_create_app():
    assert create_app(os.environ["STARTERKIT_ENVIRONMENT"])
