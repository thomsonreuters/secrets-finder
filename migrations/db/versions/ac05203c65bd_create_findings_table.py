"""Create findings/secrets table

Revision ID: ac05203c65bd
Revises:
Create Date: 2024-06-17 18:59:55.247810

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "ac05203c65bd"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "findings",
        sa.Column("uuid", sa.String(), primary_key=True),
        sa.Column("scan_uuid", sa.String(), nullable=False),
        sa.Column("job_uuid", sa.String(), nullable=False),
        sa.Column("organization", sa.String(), nullable=True),
        sa.Column("scan_context", sa.String(), nullable=False),
        sa.Column("created_on", sa.DateTime(), nullable=False),
        sa.Column("decoder_name", sa.String(), nullable=False),
        sa.Column("detector_name", sa.String(), nullable=False),
        sa.Column("detector_type", sa.Integer(), nullable=False),
        sa.Column("raw", sa.VARCHAR(), nullable=False),
        sa.Column("raw_v2", sa.VARCHAR(), nullable=True),
        sa.Column("redacted", sa.String(), nullable=True),
        sa.Column("source_name", sa.String(), nullable=False),
        sa.Column("source_type", sa.Integer(), nullable=False),
        sa.Column("verified", sa.Boolean(), nullable=False),
        sa.Column("extra_data", sa.JSON(), nullable=True),
        sa.Column("repository", sa.String(), nullable=True),
        sa.Column("filename", sa.String(), nullable=False),
        sa.Column("commit_hash", sa.String(), nullable=True),
        sa.Column("committer_email", sa.String(), nullable=True),
        sa.Column("commit_timestamp", sa.DateTime(), nullable=True),
        sa.Column("line_number", sa.Integer(), nullable=False),
        sa.Column("is_still_valid", sa.Boolean(), nullable=False),
        sa.Column("last_validated_on", sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("findings")
