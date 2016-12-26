# -*- coding: utf-8 -*-

import socket

from flask import Blueprint, jsonify

from flask_babel import lazy_gettext as _

healthcheck_blueprint = Blueprint("healthcheck", __name__)


@healthcheck_blueprint.route("/")
def index():
    return jsonify({"hostname": socket.getfqdn(), "message": _("Everything is OK!")})
