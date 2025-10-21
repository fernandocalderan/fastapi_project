import psycopg2

# Conexión
conn = psycopg2.connect(
    dbname="fastapi_db",
    user="postgres",
    password="Faccaf21$",
    host="localhost",
    port="5432"
)

cur = conn.cursor()

# Consulta
cur.execute("SELECT * FROM users;")
rows = cur.fetchall()

for row in rows:
    print(row)

cur.close()
conn.close()
