# migrate_data.py

import json
import os
from app import app
from models import db, Cafe  # db 객체와 Cafe 모델을 가져옵니다.
from datetime import datetime # created_at, updated_at 필드 처리를 위해 import



######################################################################
######################################################################
##########    json -> sqlite 데이터 migrate용 스크립트(일회용)    ##########
######################################################################
######################################################################



def migrate():
    with app.app_context():
        print("데이터 이전을 시작합니다...")

        try:
            with open('cafe_info.json', 'r', encoding='utf-8') as f:
                cafe_data_list = json.load(f)
        except FileNotFoundError:
            print(f"오류: '{'cafe_info.json'}' 파일을 찾을 수 없습니다. 파일 경로를 확인해주세요.")
            return
        except json.JSONDecodeError:
            print(f"오류: '{'cafe_info.json'}' 파일이 유효한 JSON 형식이 아닙니다.")
            return

        for cafe_data in cafe_data_list:
            cafe_id = int(cafe_data.get('ID')) if cafe_data.get('ID') is not None else None
            cafe_name = cafe_data.get('Name')
            cafe_address = cafe_data.get('Address') # Address 필드 가져오기

            # 필수 필드 (ID, Name, Address)가 존재하는지 확인
            if cafe_id is None:
                print(f"경고: 'ID'가 없는 카페 데이터를 건너뜁니다: {cafe_name if cafe_name else 'Unknown Cafe'}")
                continue
            if cafe_name is None:
                print(f"경고: ID {cafe_id} 카페에 'Name'이 없습니다. 해당 데이터를 건너뜁니다.")
                continue
            if cafe_address is None: # Address 필드 존재 여부 확인 추가
                print(f"경고: ID {cafe_id} ({cafe_name}) 카페에 'Address'가 없습니다. 해당 데이터를 건너뜁니다.")
                continue

            # 이미 존재하는 카페인지 확인 (중복 삽입 방지)
            existing_cafe = Cafe.query.get(cafe_id)
            if existing_cafe:
                print(f"정보: ID {cafe_id} ({cafe_name}) 카페는 이미 존재합니다. 건너뜁니다.")
                continue

            new_cafe = Cafe(
                id=cafe_id,
                name=cafe_name,
                address=cafe_address, # 여기서 검증된 cafe_address 사용
                latitude=cafe_data.get('Position (Latitude)'),
                longitude=cafe_data.get('Position (Longitude)'),
                message=cafe_data.get('Message'),
                hours_weekday=cafe_data.get('Hours_weekday'),
                hours_weekend=cafe_data.get('Hours_weekend'),
                price=cafe_data.get('Price'),
                video_url=cafe_data.get('Video URL'),
                last_order=cafe_data.get('라스트 오더'),
                
                monday=cafe_data.get('월'),
                tuesday=cafe_data.get('화'),
                wednesday=cafe_data.get('수'),
                thursday=cafe_data.get('목'),
                friday=cafe_data.get('금'),
                saturday=cafe_data.get('토'),
                sunday=cafe_data.get('일'),
                
                operating_hours=cafe_data.get('영업 시간'),
            )
            
            db.session.add(new_cafe)
            print(f"추가 완료: ID {new_cafe.id}, 이름: {new_cafe.name}")

        try:
            db.session.commit()
            print("모든 데이터가 성공적으로 이전되었습니다!")
        except Exception as e:
            db.session.rollback()
            print(f"데이터 이전 중 오류 발생 및 롤백: {e}")

if __name__ == '__main__':
    migrate()