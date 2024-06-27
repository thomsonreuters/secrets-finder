"""Create scans table

Revision ID: 9fab027609bc
Revises: ac05203c65bd
Create Date: 2024-06-17 20:29:24.694581

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "9fab027609bc"
down_revision: Union[str, None] = "ac05203c65bd"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "scans",
        sa.Column("uuid", sa.String(), primary_key=True),
        sa.Column("job_uuid", sa.String(), nullable=False),
        sa.Column("scan_identifier", sa.String(), nullable=False),
        sa.Column("scm", sa.String(), nullable=False),
        sa.Column("organization", sa.String(), nullable=True),
        sa.Column("repository", sa.String(), nullable=False),
        sa.Column("scan_context", sa.String(), nullable=False),
        sa.Column("started_on", sa.DateTime(), nullable=False),
        sa.Column("completed_on", sa.DateTime(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("scan_mode", sa.String(), nullable=True),
        sa.Column("scan_type", sa.String(), nullable=False),
        sa.Column("metadata", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("scans")
