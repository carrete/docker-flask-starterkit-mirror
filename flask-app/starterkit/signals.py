# -*- coding: utf-8 -*-

from blinker import Namespace

_namespace = Namespace()

add_blueprints = _namespace.signal("add-blueprints")
add_extensions = _namespace.signal("add-extensions")
amend_settings = _namespace.signal("amend-settings")
