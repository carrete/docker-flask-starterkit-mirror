# -*- coding: utf-8 -*-


def create_db(db, app):
    """Create SQL tables in db for the current app.

    Args:
      db - An instance of `flask.ext.sqlalchemy.SQLAlchemy`.
      app - The current Flask app instance.

    """
    with app.app_context():
        db.create_all()
