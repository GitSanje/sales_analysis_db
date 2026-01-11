from sqlalchemy import text
import re
from db_config import engine_postgresql
import pandas as pd


def clean_sql(sql):
    # Remove single-line comments (-- ...)
    sql = re.sub(r'--.*','',sql)
     # Remove multi-line comments (/* ... */)
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
    return sql



def run_sql_file(file_path):
    with open(file_path, "r") as f:
        raw_sql = f.read()
    
    clean_sql_text = clean_sql(raw_sql)
    queries = [q.strip().rstrip(',') for q in clean_sql_text.split(';') if q.strip()]
    results = {}
  
    with engine_postgresql.connect() as conn:
        for i, query in enumerate(queries,start=1):
            try:
                if query.lower().startswith(("select", "with")):
                    df = pd.read_sql(text(query), conn)

                    results[f"query_{i}"] = df
                    print(f"📊 Query {i} loaded")
                else:
                    conn.execute(text(query))
                    conn.commit()
                    print(f"⚙️ Query {i} executed")
                     
            except Exception as e:
                print(f"❌ Query {i} failed: {e}")
    return results
        
results = run_sql_file('../sql/walmart_analysis.sql')