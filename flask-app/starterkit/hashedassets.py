# -*- coding: utf-8 -*-

import hashlib
import os
import os.path
from functools import partial

from flask import current_app

from flask_script import Command

import yaml


def _get_settings(app, namespace, *names):
    return [app.config["{}_{}".format(namespace, name)] for name in names]


def _is_empty(seq):
    return False if seq else True


def _concatpaths(path, *rest):
    if _is_empty(rest):
        return os.path.normpath(path)
    return _concatpaths("{}{}{}".format(path, os.sep, rest[0]), *rest[1:])


def _trimsubpath(subpath, fullpath):
    return fullpath[len(os.path.commonpath([subpath, fullpath])) :]


def _walkdir(src_dir):
    for fullpath_dir, subdirs, filenames in os.walk(src_dir):
        for filename in filenames:
            asset_fullpath = _concatpaths(fullpath_dir, filename)
            asset_partpath = _trimsubpath(src_dir, asset_fullpath)
            yield asset_fullpath, asset_partpath


def _hash(data):
    return hashlib.sha256(data).hexdigest()[:15]


def _make_hashed_name(name, data):
    root, extn = os.path.splitext(name)
    return "{}.{}{}".format(root, _hash(data), extn)


def hash_assets(app):
    """Create hashed assets and catalog.

    Args:
      app - The current Flask app instance.

    """
    catalog = {}
    src_dir, out_dir, url_prefix, catalog_name = _get_settings(
        app, "HASHEDASSETS", "SRC_DIR", "OUT_DIR", "URL_PREFIX", "CATALOG"
    )
    for asset_fullpath, asset_partpath in _walkdir(src_dir):
        with open(asset_fullpath, "rb") as fd:
            data = fd.read()
        hashed_asset_partpath = _make_hashed_name(asset_partpath, data)
        hashed_asset_fullpath = _concatpaths(out_dir, hashed_asset_partpath)
        os.makedirs(os.path.dirname(hashed_asset_fullpath), exist_ok=True)
        with open(hashed_asset_fullpath, "wb") as fd:
            fd.write(data)
        catalog[asset_partpath] = {"url": _concatpaths(url_prefix, hashed_asset_partpath)}
    with open(catalog_name, "w") as fd:
        yaml.dump(catalog, fd)


class HashAssetsCommand(Command):
    def run(self):
        return hash_assets(current_app)


class HashedAssetNotFoundError(LookupError):
    pass


def hashed_url_for(catalog):
    def _hashed_url_for(asset_name):
        if asset_name not in catalog:
            raise HashedAssetNotFoundError("{} not found in catalog".format(asset_name))
        return catalog[asset_name]["url"]

    return dict(hashed_url_for=_hashed_url_for)


class HashedAssets(object):
    def __init__(self, app=None):
        if app is not None:
            self.init_app(app)
        self.app = app

    def init_app(self, app):
        (catalog_name,) = _get_settings(app, "HASHEDASSETS", "CATALOG")
        if os.path.exists(catalog_name):
            with open(catalog_name, "r") as fd:
                catalog = yaml.safe_load(fd)
        else:
            catalog = {}
        app.context_processor(partial(hashed_url_for, catalog))


hashed_assets = HashedAssets()
