"""
Elastic Beanstalk WSGI 엔트리포인트
EB는 'application.py' 파일의 'application' 객체를 찾습니다
"""

from app import app as application

# EB가 찾을 수 있도록 application 객체를 export
# application = app (위에서 이미 import됨)

if __name__ == '__main__':
    application.run()
