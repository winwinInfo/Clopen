import pandas as pd
import json

# CSV 파일 읽기
df = pd.read_csv('assets/cafe_info.csv', encoding='utf-8')

# 개행 문자 처리
for column in df.columns:
    if df[column].dtype == 'object':  # 문자열 컬럼에 대해서만 처리
        df[column] = df[column].str.replace('\n', '\\n')

# JSON 형식으로 변환
json_data = df.to_json(orient='records', force_ascii=False)

# JSON 파일로 저장
with open('cafe_info.json', 'w', encoding='utf-8') as file:
    json.dump(json.loads(json_data), file, ensure_ascii=False, indent=2)

print("JSON 파일이 생성되었습니다.")