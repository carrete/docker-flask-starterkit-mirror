# -*- coding: utf-8; mode: python -*-

from functools import partial

from flask import request

from flask_babel import Babel, get_locale


def _select_locale(app):
    return request.accept_languages.best_match(app.config["LANGUAGES"].keys())


class BabelEx(Babel):
    def init_app(self, app):
        super(BabelEx, self).init_app(app)

        self.locale_selector_func = partial(_select_locale, app)

        app.context_processor(lambda: {"locale": get_locale()})


babel = BabelEx()
