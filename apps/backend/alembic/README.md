Alembic is the source of truth for backend schema changes.

Production-style flow:

`cd apps/backend`

`python -m alembic upgrade head`

The API startup no longer calls `create_all`. If migrations have not been applied, startup will fail with a message telling you to run Alembic first.
