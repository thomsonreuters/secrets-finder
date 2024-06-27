# Migrations

This directory contains alembic configuration and database versions to manage database migrations. Migrations are compatible with SQLite, Postgres & MariaDB.

## Files

- `alembic.ini`: Contains alembic configuration.

- `migrate.py`: A wrapper script to programmatically run migrations. Example: using Lambdas.

- `pyproject.toml`: This is the configuration file for the `poetry` package manager, which is used to manage dependencies for the script.

- `db`: This directory contains alembic env config and versions.

## Usage

1. To run, setup the DB_URL environment variables. DB_URL environment variable value should be FQDN. Example: `postgresql://myuser:mypassword@127.0.0.1:5432/mydatabase`
2. Setup the poetry environment
   ```bash
    poetry install
   ```
3. Run migration
   ```bash
    poetry run alembic upgrade head
   ```

## Creating New Revisions

New migration revisions are needed whenever there are modifications to the database schema, such as adding a new table, adding a new column, or updating an existing column.

1. Setup the poetry environment, if not already done
   ```bash
    poetry install
   ```
2. Run command. Provide a comment for the revision
   ```bash
    poetry run alembic revision -m "<comment here>"
   ```
   This command will create a new revision file under `db/revisions`. Complete definition for `upgrade` and `downgrade` function.

## Requirements

- Python 3.9 or higher
- `poetry` package manager
- Connectivity to the database
  > By default the database created will be private, you may have to run this script from a compute resource that is authorized to connect

## Dependencies

- alembic = "^1.13.1"
- psycopg2-binary = "^2.9.9"
