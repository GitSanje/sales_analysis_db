from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError


engine_postgresql = create_engine(
    "postgresql+psycopg2://postgres:postgres@localhost:5432/sales_db"
)

try:
    with engine_postgresql.connect() as connection:
        print("Connection succeeded to PSQL")
except SQLAlchemyError as e:
    print("Unable to connect to PSQL")
    print("Error:", e)