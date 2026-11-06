import os
from dotenv import load_dotenv

from alembic import context
from sqlalchemy import create_engine

from app.models import Base

load_dotenv(override=False)
url = os.environ["FARMCARE_DATABASE_URL"]
if context.is_offline_mode():
    context.configure(url=url, target_metadata=Base.metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()
else:
    engine = create_engine(url)
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=Base.metadata)
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()
