# -*- coding: utf-8 -*-

import os

from flask_migrate import MigrateCommand
from flask_script import Manager

from starterkit.app import create_app
from starterkit.commands import create_db, delete_db
from starterkit.db import db
from starterkit.hashedassets import HashAssetsCommand

app = create_app(os.environ["STARTERKIT_ENVIRONMENT"])
manager = Manager(app)

manager.add_command("hashassets", HashAssetsCommand)
manager.add_command("db", MigrateCommand)


@manager.command
def createdb():
    """Create database and create all tables."""
    create_db(db, app)


@manager.command
def deletedb():
    """Delete all tables and delete database."""
    delete_db(db, app)


if __name__ == "__main__":
    manager.run()
