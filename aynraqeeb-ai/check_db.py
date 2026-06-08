import sqlite3
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

conn = sqlite3.connect('aynraqeeb.db')
conn.row_factory = sqlite3.Row
cur = conn.cursor()

cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [t[0] for t in cur.fetchall()]
print('=== Tables ===')
for t in tables:
    cur.execute(f'SELECT COUNT(*) FROM "{t}"')
    print(f' - {t}: {cur.fetchone()[0]} rows')

for t in tables:
    print(f'\n=== {t} ===')
    cur.execute(f'SELECT * FROM "{t}" LIMIT 10')
    rows = cur.fetchall()
    for row in rows:
        print(dict(row))

conn.close()
