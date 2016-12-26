# -*- coding: utf-8 -*-

import os.path
from tempfile import NamedTemporaryFile

from flask import render_template
from flask_script import Manager

import pytest

from starterkit.hashedassets import HashAssetsCommand, HashedAssetNotFoundError, HashedAssets

from .helpers import with_tst_request_context


def mktempfile():
    with NamedTemporaryFile() as fd:
        name = fd.name
    return name


@with_tst_request_context
def test_hashed_assets(*args, **kwargs):
    test_app = kwargs["test_app"]

    HashedAssets(test_app)

    assert render_template("tests/starterkit/hashedassets/hashedassets.html")


@pytest.mark.xfail(raises=HashedAssetNotFoundError)
@with_tst_request_context
def test_hashed_asset_not_found_error(*args, **kwargs):
    test_app = kwargs["test_app"]

    test_app.config["HASHEDASSETS_CATALOG"] = ""
    HashedAssets(test_app)

    assert render_template("tests/starterkit/hashedassets/hashedassets.html")


@with_tst_request_context
def test_hash_assets_command(*args, **kwargs):
    test_app = kwargs["test_app"]

    catalog_name = mktempfile()
    assert os.path.exists(catalog_name) is False
    test_app.config["HASHEDASSETS_CATALOG"] = catalog_name
    manager = Manager(test_app)
    manager.add_command("hashassets", HashAssetsCommand())
    manager.handle("what-the-hell-is-this?", ["hashassets"])
    assert os.path.exists(catalog_name) is True
