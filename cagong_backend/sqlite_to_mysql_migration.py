"""
SQLite에서 MySQL로 데이터 마이그레이션하는 스크립트

사용법:
    python sqlite_to_mysql_migration.py
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


def migrate_table(sqlite_cursor, mysql_cursor, table_name, columns):
    """
    특정 테이블의 데이터를 SQLite에서 MySQL로 마이그레이션

    Args:
        sqlite_cursor: SQLite 커서
        mysql_cursor: MySQL 커서
        table_name: 테이블 이름
        columns: 복사할 컬럼 리스트
    """
    print(f"\n{'='*60}")
    print(f"테이블 '{table_name}' 마이그레이션 시작...")
    print(f"{'='*60}")

    # SQLite에서 데이터 조회
    column_str = ', '.join(columns)
    sqlite_cursor.execute(f"SELECT {column_str} FROM {table_name}")
    rows = sqlite_cursor.fetchall()

    if not rows:
        print(f"⚠️  테이블 '{table_name}'에 데이터가 없습니다.")
        return 0

    # MySQL에 데이터 삽입
    placeholders = ', '.join(['%s'] * len(columns))
    insert_query = f"INSERT INTO {table_name} ({column_str}) VALUES ({placeholders})"

    success_count = 0
    error_count = 0

    for row in rows:
        try:
            mysql_cursor.execute(insert_query, row)
            success_count += 1
            print(f"✓ {success_count}개 행 삽입 완료", end='\r')
        except Exception as e:
            error_count += 1
            print(f"\n❌ 오류 발생: {e}")
            print(f"   데이터: {row}")

    print(f"\n완료: {success_count}개 성공, {error_count}개 실패")
    return success_count


def main():
    print("\n" + "="*60)
    print("SQLite → MySQL 데이터 마이그레이션")
    print("="*60)

    # SQLite 연결 확인
    if not os.path.exists(SQLITE_DB_PATH):
        print(f"\n❌ 오류: SQLite 데이터베이스 파일을 찾을 수 없습니다: {SQLITE_DB_PATH}")
        return

    print(f"\n✓ SQLite DB 경로: {SQLITE_DB_PATH}")

    # 데이터베이스 연결
    try:
        sqlite_conn = sqlite3.connect(SQLITE_DB_PATH)
        sqlite_cursor = sqlite_conn.cursor()
        print("✓ SQLite 연결 성공")
    except Exception as e:
        print(f"❌ SQLite 연결 실패: {e}")
        return

    try:
        mysql_conn = pymysql.connect(**MYSQL_CONFIG)
        mysql_cursor = mysql_conn.cursor()
        print(f"✓ MySQL 연결 성공 ({MYSQL_CONFIG['database']}@{MYSQL_CONFIG['host']})")
    except Exception as e:
        print(f"❌ MySQL 연결 실패: {e}")
        sqlite_conn.close()
        return

    try:
        # 1. Users 테이블 마이그레이션
        # SQLite의 실제 컬럼명에 맞춤
        user_columns = ['id', 'google_id', 'email', 'name', 'photo_url', 'role',
                       'provider', 'provider_id', 'created_at', 'updated_at']

        # SQLite에 users 테이블이 있는지 확인
        sqlite_cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='users'"
        )
        if sqlite_cursor.fetchone():
            # MySQL 테이블의 컬럼명 확인 (profile_image_url vs photo_url)
            mysql_cursor.execute(
                "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = 'users'",
                (MYSQL_CONFIG['database'],)
            )
            mysql_user_columns = [row[0] for row in mysql_cursor.fetchall()]

            # SQLite와 MySQL 컬럼 매핑
            sqlite_cols = ['id', 'google_id', 'email', 'name', 'photo_url', 'role',
                          'provider', 'provider_id', 'created_at', 'updated_at']

            # MySQL에 있는 컬럼만 선택
            valid_columns = []
            select_cols = []
            for s_col in sqlite_cols:
                # photo_url -> profile_image_url 매핑
                m_col = 'profile_image_url' if s_col == 'photo_url' else s_col
                if m_col in mysql_user_columns:
                    valid_columns.append(m_col)
                    select_cols.append(s_col)

            # 데이터 복사
            if select_cols:
                print(f"\n매핑: SQLite {select_cols} -> MySQL {valid_columns}")

                select_str = ', '.join(select_cols)
                sqlite_cursor.execute(f"SELECT {select_str} FROM users")
                rows = sqlite_cursor.fetchall()

                if rows:
                    insert_str = ', '.join(valid_columns)
                    placeholders = ', '.join(['%s'] * len(valid_columns))
                    insert_query = f"INSERT INTO users ({insert_str}) VALUES ({placeholders})"

                    success_count = 0
                    for row in rows:
                        try:
                            mysql_cursor.execute(insert_query, row)
                            success_count += 1
                            print(f"✓ {success_count}개 사용자 삽입 완료", end='\r')
                        except Exception as e:
                            print(f"\n❌ 오류: {e}")
                    print(f"\n완료: users {success_count}개 마이그레이션")
                else:
                    print("\n⚠️  users 테이블에 데이터가 없습니다.")
        else:
            print("\n⚠️  'users' 테이블이 SQLite에 없습니다. 건너뜁니다.")

        # 2. Cafes 테이블 마이그레이션
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

        sqlite_cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='cafes'"
        )
        if sqlite_cursor.fetchone():
            migrate_table(sqlite_cursor, mysql_cursor, 'cafes', cafe_columns)
        else:
            print("\n⚠️  'cafes' 테이블이 SQLite에 없습니다. 건너뜁니다.")

        # 3. Reservations 테이블 마이그레이션
        reservation_columns = [
            'id', 'user_id', 'cafe_id', 'reservation_date', 'start_time',
            'end_time', 'seats_count', 'total_price', 'status',
            'created_at', 'updated_at'
        ]

        sqlite_cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='reservations'"
        )
        if sqlite_cursor.fetchone():
            migrate_table(sqlite_cursor, mysql_cursor, 'reservations', reservation_columns)
        else:
            print("\n⚠️  'reservations' 테이블이 SQLite에 없습니다. 건너뜁니다.")

        # 4. CafeTimeSlots 테이블 마이그레이션
        timeslot_columns = [
            'id', 'cafe_id', 'date', 'time_slot', 'available_seats',
            'reserved_seats', 'created_at', 'updated_at'
        ]

        sqlite_cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='cafe_time_slots'"
        )
        if sqlite_cursor.fetchone():
            migrate_table(sqlite_cursor, mysql_cursor, 'cafe_time_slots', timeslot_columns)
        else:
            print("\n⚠️  'cafe_time_slots' 테이블이 SQLite에 없습니다. 건너뜁니다.")

        # 5. Orders 테이블 마이그레이션 (있다면)
        sqlite_cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='orders'"
        )
        if sqlite_cursor.fetchone():
            # orders 테이블의 컬럼을 확인
            sqlite_cursor.execute("PRAGMA table_info(orders)")
            order_columns = [row[1] for row in sqlite_cursor.fetchall()]
            migrate_table(sqlite_cursor, mysql_cursor, 'orders', order_columns)
        else:
            print("\n⚠️  'orders' 테이블이 SQLite에 없습니다. 건너뜁니다.")

        # 커밋
        mysql_conn.commit()
        print("\n" + "="*60)
        print("✅ 모든 데이터 마이그레이션 완료!")
        print("="*60)

    except Exception as e:
        print(f"\n❌ 마이그레이션 중 오류 발생: {e}")
        mysql_conn.rollback()
        import traceback
        traceback.print_exc()

    finally:
        # 연결 종료
        sqlite_cursor.close()
        sqlite_conn.close()
        mysql_cursor.close()
        mysql_conn.close()
        print("\n데이터베이스 연결 종료")


if __name__ == '__main__':
    # 사용자 확인
    print("\n⚠️  주의: 이 스크립트는 SQLite의 데이터를 MySQL로 복사합니다.")
    print("MySQL 데이터베이스에 이미 데이터가 있다면 충돌이 발생할 수 있습니다.")

    response = input("\n계속하시겠습니까? (yes/no): ")
    if response.lower() in ['yes', 'y']:
        main()
    else:
        print("마이그레이션을 취소했습니다.")
