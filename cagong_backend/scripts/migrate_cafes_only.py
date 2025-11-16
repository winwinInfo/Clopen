"""
SQLite에서 MySQL로 카페 데이터만 마이그레이션하는 스크립트
"""

import sqlite3
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

# SQLite 데이터베이스 연결
SQLITE_DB_PATH = 'instance/db.sqlite3'

# MySQL 연결 정보
MYSQL_CONFIG = {
    'host': os.getenv('DATABASE_URL'),
    'port': int(os.getenv('DATABASE_port', 3306)),
    'user': os.getenv('DATABASE_user'),
    'password': os.getenv('DATABASE_password'),
    'database': os.getenv('DATABASE_name'),
    'charset': 'utf8mb4'
}

print("\n" + "="*60)
print("SQLite → MySQL 카페 데이터 마이그레이션")
print("="*60)

# 데이터베이스 연결
sqlite_conn = sqlite3.connect(SQLITE_DB_PATH)
sqlite_cursor = sqlite_conn.cursor()
print("✓ SQLite 연결 성공")

mysql_conn = pymysql.connect(**MYSQL_CONFIG)
mysql_cursor = mysql_conn.cursor()
print(f"✓ MySQL 연결 성공 ({MYSQL_CONFIG['database']}@{MYSQL_CONFIG['host']})")

try:
    # Cafes 테이블 마이그레이션
    cafe_columns = [
        'id', 'name', 'address', 'latitude', 'longitude', 'message',
        'hours_weekday', 'hours_weekend', 'price', 'video_url', 'last_order',
        'monday_begin', 'monday_end', 'tuesday_begin', 'tuesday_end',
        'wednesday_begin', 'wednesday_end', 'thursday_begin', 'thursday_end',
        'friday_begin', 'friday_end', 'saturday_begin', 'saturday_end',
        'sunday_begin', 'sunday_end', 'operating_hours',
        'reservation_enabled', 'total_seats', 'total_consents',
        'reservation_start_time', 'reservation_end_time', 'hourly_rate',
        'created_at', 'updated_at'
    ]

    print(f"\n{'='*60}")
    print("카페 데이터 마이그레이션 시작...")
    print(f"{'='*60}\n")

    # SQLite에서 데이터 조회
    column_str = ', '.join(cafe_columns)
    sqlite_cursor.execute(f"SELECT {column_str} FROM cafes")
    rows = sqlite_cursor.fetchall()

    print(f"총 {len(rows)}개의 카페 데이터 발견")

    if rows:
        # MySQL에 데이터 삽입
        placeholders = ', '.join(['%s'] * len(cafe_columns))
        insert_query = f"INSERT INTO cafes ({column_str}) VALUES ({placeholders})"

        success_count = 0
        for row in rows:
            try:
                mysql_cursor.execute(insert_query, row)
                success_count += 1
                print(f"✓ {success_count}/{len(rows)} 카페 삽입 완료 (ID: {row[0]}, {row[1]})", end='\r')
            except Exception as e:
                print(f"\n 오류: {e}")
                print(f"   카페 ID: {row[0]}, 이름: {row[1]}")

        print(f"\n\n완료: {success_count}개 카페 마이그레이션 성공!")

        # 커밋
        mysql_conn.commit()
        print("\n 데이터베이스 커밋 완료!")

        # 확인
        mysql_cursor.execute("SELECT COUNT(*) FROM cafes")
        count = mysql_cursor.fetchone()[0]
        print(f"\n MySQL cafes 테이블: 총 {count}개")

        # 샘플 데이터 확인
        mysql_cursor.execute("SELECT id, name, address FROM cafes LIMIT 5")
        sample_rows = mysql_cursor.fetchall()
        print("\n샘플 데이터:")
        for sample in sample_rows:
            print(f"  - ID {sample[0]}: {sample[1]}")

except Exception as e:
    print(f"\n 마이그레이션 중 오류 발생: {e}")
    mysql_conn.rollback()
    import traceback
    traceback.print_exc()

finally:
    sqlite_cursor.close()
    sqlite_conn.close()
    mysql_cursor.close()
    mysql_conn.close()
    print("\n" + "="*60)
    print("데이터베이스 연결 종료")
    print("="*60 + "\n")