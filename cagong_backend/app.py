from flask import Flask
from routes import register_blueprints



# 간단한 Flask 앱 생성
app = Flask(__name__)
app.config['SECRET_KEY'] = 'simple-secret-key'



# 블루프린트 등록 (routes/__init__.py에서 관리)
register_blueprints(app)


if __name__ == '__main__':
    
    app.run(debug=True, port=5000)
