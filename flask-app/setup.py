# -*- coding: utf-8 -*-

from setuptools import setup, find_packages

meta = {
    "name": "flask-starterkit",
    "version": "0.2.0",
    "url": "https://www.starterkit.xyz",
    "author": "The Starterkit Corporation",
    "author_email": "hello@starterkit.xyz",
    "packages": find_packages(),
    "include_package_data": True,
    "install_requires": [
        # Flask Starterkit
        "blinker==1.4",
        "flask-admin==1.5.4",
        "flask-babel==0.12.2",
        "flask-migrate==2.5.2",
        "flask-script==2.0.6",
        "flask-sqlalchemy==2.4.1",
        "flask==1.1.1",
        "psycopg2-binary==2.8.4",
        "pyyaml==5.2",
        "raven[flask]==6.10.0",
        "sqlalchemy-utils==0.36.0",
    ],
}

setup(**meta)
