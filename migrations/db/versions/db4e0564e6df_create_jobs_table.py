"""create jobs table

Revision ID: db4e0564e6df
Revises: 9fab027609bc
Create Date: 2024-06-22 13:09:36.346009

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "db4e0564e6df"
down_revision: Union[str, None] = "9fab027609bc"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "jobs",
        sa.Column("uuid", sa.String(), primary_key=True),
        sa.Column("scan_identifier", sa.String(), nullable=False),
        sa.Column("scm", sa.String(), nullable=False),
        sa.Column("scan_context", sa.String(), nullable=False),
        sa.Column("started_on", sa.DateTime(), nullable=False),
        sa.Column("completed_on", sa.DateTime(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("scan_mode", sa.String(), nullable=True),
        sa.Column("scan_type", sa.String(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("jobs")
