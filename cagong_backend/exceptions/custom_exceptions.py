from common.api_response import ErrorCode # ErrorCode를 재사용

class BaseAppException(Exception):
    """
    모든 커스텀 예외의 부모 클래스입니다.
    이 예외는 http_status, error_code, message를 가집니다.
    """
    def __init__(self, http_status: int, error_code: ErrorCode, message: str):
        self.http_status = http_status
        self.error_code = error_code
        self.message = message
        super().__init__(message)



# 여기에 예외를 추가하면 됨.

class InvalidInputException(BaseAppException):
    """입력값이 유효하지 않을 때 (예: idToken이 없음)"""
    def __init__(self, message="입력값이 유효하지 않습니다."):
        super().__init__(
            http_status=400,  # 400 Bad Request
            error_code=ErrorCode.INVALID_INPUT,
            message=message
        )

class AuthTokenException(BaseAppException):
    """인증 토큰(JWT, Google idToken 등)이 유효하지 않을 때"""
    def __init__(self, message="유효하지 않은 토큰입니다."):
        super().__init__(
            http_status=401,  # 401 Unauthorized (인증 실패)
            error_code=ErrorCode.AUTHENTICATION_ERROR,
            message=message
        )