"""
MySQL 데이터베이스의 데이터 확인 스크립트
"""

import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

# MySQL 연결 정보
conn = pymysql.connect(
    host=os.getenv('DATABASE_URL'),
    port=int(os.getenv('DATABASE_port')),
    user=os.getenv('DATABASE_user'),
    password=os.getenv('DATABASE_password'),
    database=os.getenv('DATABASE_name')
)

cursor = conn.cursor()

print("\n" + "="*60)
print("MySQL 데이터베이스 확인")
print("="*60)

# 테이블별 데이터 개수 확인
tables = ['cafes', 'users', 'reservations', 'orders']

for table in tables:
    try:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"\n📊 {table}: {count}개")

        if count > 0 and table == 'cafes':
            # 카페 샘플 데이터 3개 출력
            cursor.execute(f"SELECT id, name, address FROM {table} LIMIT 3")
            rows = cursor.fetchall()
            print("   샘플 데이터:")
            for row in rows:
                print(f"   - ID {row[0]}: {row[1]} ({row[2][:30]}...)")
    except Exception as e:
        print(f"❌ {table}: 오류 - {e}")

print("\n" + "="*60)
print("✅ 확인 완료!")
print("="*60 + "\n")

cursor.close()
conn.close()
