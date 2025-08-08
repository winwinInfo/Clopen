def register_blueprints(app):
    """블루프린트들을 앱에 등록"""
    
    
    from .health import health_bp
    app.register_blueprint(health_bp, url_prefix='/api')
    
    
    from .cafes import cafe_bp
    app.register_blueprint(cafe_bp, url_prefix='/api/cafes')
    

    from .auth import auth_bp
    app.register_blueprint(auth_bp, url_prefix='/api/auth')

    return app