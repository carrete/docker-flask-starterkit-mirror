# -*- coding: utf-8 -*-

import os

from functools import partial

from flask import Flask

import starterkit.signals as signals

from .babel import babel
from .db import db
from .hashedassets import hashed_assets
from .migrate import migrate
from .sentry import sentry


def _wrap_wsgi_app(wsgi_app, environ, start_response):
    environ["wsgi.url_scheme"] = "https"
    return wsgi_app(environ, start_response)


def _create_app(namespace, environment):
    app = Flask(namespace)
    app.config.from_object("{}.settings.{}".format(namespace, environment))

    app.url_map.strict_slashes = False
    app.wsgi_app = partial(_wrap_wsgi_app, app.wsgi_app)

    from .blueprints.healthcheck import healthcheck_blueprint

    app.register_blueprint(healthcheck_blueprint, url_prefix="/healthcheck")

    from .blueprints.homepage import homepage_blueprint

    app.register_blueprint(
        homepage_blueprint, url_prefix=app.config["STARTERKIT_HOMEPAGE_BLUEPRINT_URL_PREFIX"]
    )

    signals.add_blueprints.send(app)

    babel.init_app(app)
    db.init_app(app)
    hashed_assets.init_app(app)
    migrate.init_app(app, db)
    sentry.init_app(app, db)

    signals.add_extensions.send(app)

    return app


create_app = partial(_create_app, __name__.split(".")[0])
