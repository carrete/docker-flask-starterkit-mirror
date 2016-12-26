# -*- coding: utf-8; mode: python -*-

import json

from flask import url_for

from ..helpers import check_is_equal, with_tst_client, with_tst_request_context


@with_tst_request_context
@with_tst_client
def test_healthcheck_is_en(*args, **kwargs):
    test_client = kwargs["test_client"]

    response = test_client.get(url_for("healthcheck.index"))
    check_is_equal(response.status_code, 200)
    check_is_equal(response.headers["Content-Type"], "application/json")

    message = json.loads(response.get_data(as_text=True))
    assert message["hostname"]
    check_is_equal(message["message"], "Everything is OK!")


@with_tst_request_context
@with_tst_client
def test_healthcheck_is_es(*args, **kwargs):
    test_client = kwargs["test_client"]

    response = test_client.get(url_for("healthcheck.index"), headers={"Accept-Language": "es"})
    check_is_equal(response.status_code, 200)
    check_is_equal(response.headers["Content-Type"], "application/json")

    message = json.loads(response.get_data(as_text=True))
    assert message["hostname"]
    check_is_equal(message["message"], "¡Todo está bien!")
