# 🚀 CLOPEN 백엔드 (학습용)

간단한 Flask API 서버입니다.

## 🏃‍♂️ 실행하기

1. **패키지 설치**
   ```bash
   pip install Flask
   ```

2. **서버 실행**
   ```bash
   python app.py
   ```

3. **API 테스트**
   - 서버 상태: http://localhost:5000/api/health
   - 카페 목록: http://localhost:5000/api/cafes
   - 특정 카페: http://localhost:5000/api/cafes/1054975307

## 📚 학습 포인트

- **Flask 기본**: 간단한 웹 서버 만들기
- **API 개발**: JSON 응답하는 REST API
- **파일 처리**: JSON 파일 읽고 데이터 반환
- **에러 처리**: try-catch로 예외 처리

## 🛠️ 다음 단계

1. 사용자 등록/로그인 API 추가
2. 데이터베이스 연결 (SQLite → MySQL)
3. 댓글 기능 추가
4. 실시간 기능 (WebSocket)