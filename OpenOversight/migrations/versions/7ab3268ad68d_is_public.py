"""Add is_public boolean to departments table

Revision ID: 7ab3268ad68d
Revises: 562bd5f1bc1f
Create Date: 2020-06-09 23:36:37.852520

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '7ab3268ad68d'
down_revision = '562bd5f1bc1f'
branch_labels = None
depends_on = None


def upgrade():
    """
    All departments thus far were by public, so we'll
    set the currently deployed departments as public.
    """
    op.add_column(
        'departments',
        sa.Column('is_public', sa.Boolean(), nullable=True)
    )
    op.execute("UPDATE departments SET is_public = TRUE")
    op.alter_column('departments', 'is_public', nullable=False)


def downgrade():
    op.drop_column('departments', 'is_public')
