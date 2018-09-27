# -*- coding: utf-8; mode: python -*-

from bs4 import BeautifulSoup as BS

from django.test import Client

from .helpers import check_is_equal


def test_homepage_is_en(*args, **kwargs):
    test_client = Client()

    response = test_client.get("/")
    check_is_equal(response.status_code, 200)
    check_is_equal(response["Content-Type"], "text/html; charset=utf-8")
    bs = BS(response.content, "html5lib")
    check_is_equal(bs.find(id="hello").string.strip(), "Hello, World!")

    response = test_client.get("/?hello={}".format("foo+bar"))
    check_is_equal(response.status_code, 200)
    check_is_equal(response["Content-Type"], "text/html; charset=utf-8")
    bs = BS(response.content, "html5lib")
    check_is_equal(bs.find(id="hello").string.strip(), "Hello, Foo Bar!")


def test_homepage_is_es(*args, **kwargs):
    test_client = Client()

    response = test_client.get("/", HTTP_ACCEPT_LANGUAGE="es")
    check_is_equal(response.status_code, 200)
    check_is_equal(response["Content-Type"], "text/html; charset=utf-8")
    bs = BS(response.content, "html5lib")
    check_is_equal(bs.find(id="hello").string.strip(), "¡Hola, Mundo!")

    response = test_client.get("/?hello={}".format("foo+bar"), HTTP_ACCEPT_LANGUAGE="es")
    check_is_equal(response.status_code, 200)
    check_is_equal(response["Content-Type"], "text/html; charset=utf-8")
    bs = BS(response.content, "html5lib")
    check_is_equal(bs.find(id="hello").string.strip(), "¡Hola, Foo Bar!")
