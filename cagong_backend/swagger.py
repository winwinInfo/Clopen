from flasgger import Swagger

# Flasgger Swagger 설정 (간단 버전)
def init_swagger(app):
    """Flasgger 초기화"""
    swagger_config = {
        "headers": [],
        "specs": [
            {
                "endpoint": 'apispec',
                "route": '/apispec.json',
            }
        ],
        "static_url_path": "/flasgger_static",
        "swagger_ui": True,
        "specs_route": "/api/docs"  # Swagger UI 접속 경로
    }

    swagger_template = {
        "swagger": "2.0",
        "info": {
            "title": "Clopen Cafe API",
            "description": "카공 카페 예약 시스템 API 문서",
            "version": "1.0.0"
        },
        "basePath": "/",
        "schemes": ["http", "https"],

        "securityDefinitions": {
            "BearerAuth": {
                "type": "apiKey",
                "name": "Authorization",
                "in": "header",
                "description": "JWT Authorization header using the Bearer scheme. Example: 'Bearer {token}'"
            }
        },

        "security": [
            {
                "BearerAuth": []
            }
        ]
    }

    return Swagger(app, config=swagger_config, template=swagger_template)


