def register_blueprints(app):
    """블루프린트들을 앱에 등록"""
    
    # 헬스체크 API
    from .health import health_bp
    app.register_blueprint(health_bp, url_prefix='/api')
    
    # 카페 관련 API
    from .cafes import cafe_bp
    app.register_blueprint(cafe_bp, url_prefix='/api/cafes')
    
    return app