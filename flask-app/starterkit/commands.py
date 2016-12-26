# -*- coding: utf-8 -*-

from sqlalchemy_utils.functions import create_database, database_exists, drop_database


def create_db(db, app):
    """Create database and tables in db for the current app.

    Args:
      db - An instance of `flask.ext.sqlalchemy.SQLAlchemy`.
      app - The current Flask app instance.

    """
    sqlalchemy_database_uri = app.config["SQLALCHEMY_DATABASE_URI"]
    if not database_exists(sqlalchemy_database_uri):
        create_database(sqlalchemy_database_uri)

    with app.app_context():
        db.create_all()


def delete_db(db, app):
    """Delete tables and database in db for the current app.

    Args:
      db - An instance of `flask.ext.sqlalchemy.SQLAlchemy`.
      app - The current Flask app instance.

    """
    sqlalchemy_database_uri = app.config["SQLALCHEMY_DATABASE_URI"]
    if database_exists(sqlalchemy_database_uri):
        drop_database(sqlalchemy_database_uri)
