from enum import Enum
from flask import jsonify

class ApiStatus(Enum):
    SUCCESS = "SUCCESS"
    FAIL = "FAIL"

class ErrorCode(Enum):
    # 공통
    BAD_REQUEST = "BAD_REQUEST"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    # 도메인
    USER_NOT_FOUND = "USER_NOT_FOUND"
    INVALID_INPUT = "INVALID_INPUT"

class ApiResponse:
    def __init__(self, status: ApiStatus, message: str, data=None, error_code: ErrorCode = None):
        self.status = status
        self.message = message
        self.data = data
        self.error_code = error_code

    def to_dict(self):
        response = {
            "status": self.status.value,
            "message": self.message,
            "data": self.data
        }
        if self.error_code:
            response["errorCode"] = self.error_code.value
            response["data"] = None
        return response

    @staticmethod
    def success(data=None, message: str = "요청이 성공적으로 처리되었습니다.", http_status: int = 200):
        response = ApiResponse(status=ApiStatus.SUCCESS, message=message, data=data)
        return jsonify(response.to_dict()), http_status

    @staticmethod
    def fail(error_code: ErrorCode, message: str, http_status: int):
        response = ApiResponse(status=ApiStatus.FAIL, message=message, error_code=error_code)
        return jsonify(response.to_dict()), http_status