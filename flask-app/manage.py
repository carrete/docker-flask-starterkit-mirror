# -*- coding: utf-8 -*-

from flask_migrate import MigrateCommand
from flask_script import Manager

from starterkit.app import create_app
from starterkit.commands import create_db
from starterkit.db import db
from starterkit.hashedassets import HashAssetsCommand

app = create_app()
manager = Manager(app)

manager.add_command("hashassets", HashAssetsCommand)
manager.add_command("db", MigrateCommand)


@manager.command
def createdb():
    """Create SQL database tables."""
    create_db(db, app)


if __name__ == "__main__":
    manager.run()
