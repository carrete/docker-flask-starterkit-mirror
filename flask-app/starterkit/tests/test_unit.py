# -*- coding: utf-8 -*-

from starterkit.unit import application


def _start_response(*args, **kwargs):
    pass


def test_application():
    assert application(
        {"SERVER_NAME": "localhost.localdomain", "SERVER_PORT": "8443", "REQUEST_METHOD": "GET"},
        _start_response,
    )
