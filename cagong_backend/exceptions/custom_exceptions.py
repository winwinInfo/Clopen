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

class UserNotFoundException(BaseAppException):
    """요청한 ID의 유저를 찾을 수 없을 때"""
    def __init__(self, message="사용자를 찾을 수 없습니다."):
        super().__init__(
            http_status=404,  # 404 Not Found
            error_code=ErrorCode.USER_NOT_FOUND,
            message=message
        )


## 결제 관련
class OrderNotFoundException(BaseAppException):
    """주문을 찾을 수 없을 때"""
    def __init__(self, message="주문을 찾을 수 없습니다."):
        super().__init__(
            http_status=404,  # 404 Not Found
            error_code=ErrorCode.ORDER_NOT_FOUND,
            message=message
        )

class PaymentMismatchException(BaseAppException):
    """결제 금액 등이 불일치할 때 (위변조 의심)"""
    def __init__(self, message="결제 정보가 일치하지 않습니다."):
        super().__init__(
            http_status=400,  # 400 Bad Request
            error_code=ErrorCode.PAYMENT_MISMATCH,
            message=message
        )

class DuplicatePaymentException(BaseAppException):
    """이미 처리된 결제를 중복 요청할 때"""
    def __init__(self, message="이미 처리된 결제입니다."):
        super().__init__(
            http_status=409,  # 409 Conflict (요청이 현재 리소스 상태와 충돌)
            error_code=ErrorCode.DUPLICATE_PAYMENT,
            message=message
        )

class PaymentApiCallException(BaseAppException):
    """외부 결제 API(토스) 호출에 실패했을 때"""
    def __init__(self, message="결제 서비스(API) 호출에 실패했습니다."):
        super().__init__(
            http_status=503,  # 503 Service Unavailable (외부 서비스 문제)
            error_code=ErrorCode.PAYMENT_API_ERROR,
            message=message
        )

class DatabaseUpdateException(BaseAppException):
    """DB 업데이트/저장에 실패했을 때"""
    def __init__(self, message="데이터베이스 처리에 실패했습니다."):
        super().__init__(
            http_status=500,  # 500 Internal Server Error
            error_code=ErrorCode.DATABASE_ERROR,
            message=message
        )

