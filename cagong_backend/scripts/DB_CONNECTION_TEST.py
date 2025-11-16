import pymysql, os
from dotenv import load_dotenv  
load_dotenv()

conn = pymysql.connect(
    host=os.getenv('DATABASE_URL'),
    port=int(os.getenv('DATABASE_port')),
    user=os.getenv('DATABASE_user'),
    password=os.getenv('DATABASE_password'),
    database=os.getenv('DATABASE_name')
)
print("연결 성공")
conn.close()