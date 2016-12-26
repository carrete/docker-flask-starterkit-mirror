# -*- coding: utf-8 -*-

import os

from functools import partial, wraps

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


def _create_app(environment):
    app = Flask(__name__, template_folder="../templates")
    app.config.from_object("starterkit.settings.{}".format(environment))
    signals.amend_settings.send(app, environment=environment)

    app.url_map.strict_slashes = False

    app.wsgi_app = partial(_wrap_wsgi_app, app.wsgi_app)

    from .blueprints.healthcheck import healthcheck_blueprint

    app.register_blueprint(healthcheck_blueprint, url_prefix="/healthcheck")

    homepage_blueprint_url_prefix = app.config["STARTERKIT_HOMEPAGE_BLUEPRINT_URL_PREFIX"]

    from .blueprints.homepage import homepage_blueprint

    app.register_blueprint(homepage_blueprint, url_prefix=homepage_blueprint_url_prefix)

    signals.add_blueprints.send(app)

    return app


def _init_app(app):
    babel.init_app(app)
    db.init_app(app)
    hashed_assets.init_app(app)
    migrate.init_app(app, db)
    sentry.init_app(app, db)

    signals.add_extensions.send(app)

    return app


def create_app(environment=os.environ["STARTERKIT_ENVIRONMENT"]):
    return _init_app(_create_app(environment))


def wrap_create_app(fn):
    app = create_app()

    @wraps(fn)
    def _wrap_create_app(*args, **kwargs):
        return app(*args, **kwargs)

    return _wrap_create_app


application = wrap_create_app(create_app)
