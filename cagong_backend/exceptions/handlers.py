# handlers.py

from flask import Flask
from werkzeug.exceptions import NotFound, InternalServerError, BadRequest
from common.api_response import ApiResponse, ErrorCode  # 1. ApiResponse와 ErrorCode 임포트
from exceptions.custom_exceptions import BaseAppException  # 2. 우리가 만든 기본 예외 임포트


def register_handlers(app: Flask):
    """
    Flask 앱 인스턴스에 전역 에러 핸들러를 등록합니다.
    app.py에서 이 함수를 호출할 것입니다.
    """

    # --- 1. 우리가 직접 정의한 예외 (BaseAppException) 처리 ---
    @app.errorhandler(BaseAppException)
    def handle_base_app_exception(e: BaseAppException):
        """
        BaseAppException을 상속받은 모든 커스텀 예외를 처리합니다.
        """
        app.logger.warning(f"커스텀 예외 발생: {e.message} (Code: {e.error_code.value})")
        return ApiResponse.fail(
            error_code=e.error_code,
            message=e.message,
            http_status=e.http_status
        )

    # --- 2. Flask가 기본으로 제공하는 HTTP 예외 처리 ---
    @app.errorhandler(NotFound)  # 404 Not Found
    def handle_not_found(e: NotFound):
        app.logger.info(f"404 Not Found: {e.description}")
        return ApiResponse.fail(
            error_code=ErrorCode.BAD_REQUEST,  # 또는 ErrorCode에 NOT_FOUND를 추가하셔도 됩니다.
            message="요청하신 리소스를 찾을 수 없습니다.",
            http_status=404
        )

    @app.errorhandler(BadRequest)  # 400 Bad Request
    def handle_bad_request(e: BadRequest):
        app.logger.info(f"400 Bad Request: {e.description}")
        return ApiResponse.fail(
            error_code=ErrorCode.BAD_REQUEST,
            message=e.description if e.description else "잘못된 요청입니다.",
            http_status=400
        )

    # --- 3. 기타 처리되지 않은 모든 500 에러 처리 ---
    @app.errorhandler(InternalServerError)  # 500 Internal Server Error
    @app.errorhandler(Exception)  # 그 외 모든 예측 못한 예외
    def handle_internal_server_error(e):
        """
        로직 상의 오류나 예측하지 못한 모든 예외를 500으로 처리합니다.
        """
        # 500 에러는 심각한 문제이므로, logger.error로 전체 추적 내용을 기록해야 합니다.
        app.logger.error(f"예측하지 못한 오류 발생: {e}", exc_info=True)

        return ApiResponse.fail(
            error_code=ErrorCode.INTERNAL_ERROR,
            message="서버 내부 오류가 발생했습니다. 관리자에게 문의하세요.",
            http_status=500
        )