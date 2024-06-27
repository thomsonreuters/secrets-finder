import logging
from alembic.config import Config
from alembic import command


def migrate(event, context):
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[logging.StreamHandler()],
    )

    logging.info("Starting Alembic upgrade")
    # Set up the Alembic configuration
    alembic_cfg = Config("alembic.ini")

    # Run the Alembic upgrade command
    command.upgrade(alembic_cfg, "head")

    return {"statusCode": 200, "body": "Alembic upgrade successful!"}


if __name__ == "__main__":
    migrate({}, {})
