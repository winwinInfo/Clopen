"""
Google Places API v1을 사용하여 카페를 검색하는 서비스

주요 기능:
- Text Search (New)로 카페 검색
- 위치 기반 검색 지원 (locationBias)
- 검색 결과를 표준화된 형식으로 반환
"""

import requests
from flask import current_app
from exceptions.custom_exceptions import InvalidInputException


# Google Places API v1 베이스 URL
PLACES_API_V1_URL = "https://places.googleapis.com/v1/places:searchText"

# 검색 반경 기본값 (미터 단위)
DEFAULT_SEARCH_RADIUS = 5000  # 5km


def search_cafes_from_places(query, latitude=None, longitude=None, radius=None):
    """
    Google Places API Text Search (New)를 사용하여 카페 검색
    검색어는 필수고 선택적으로 위치까지 지정할 수 있다.

    Args:
        query (str): 검색어 (예: "스타벅스 강남", "커피숍")
        latitude (float, optional): 검색 중심점 위도
        longitude (float, optional): 검색 중심점 경도
        radius (float, optional): 검색 반경 (미터 단위, 기본 5000m)

    Returns:
        list: 검색된 카페 리스트
            [
                {
                    "place_id": str,
                    "name": str,
                    "latitude": float,
                    "longitude": float
                },
                ...
            ]

    Raises:
        InvalidInputException: 검색어가 비어있거나 API 호출 실패 시
    """
    # 입력값 검증
    if not query or not query.strip():
        raise InvalidInputException("검색어를 입력해주세요.")

    # API 키 가져오기
    api_key = current_app.config.get('GOOGLE_API_KEY')
    if not api_key:
        raise InvalidInputException("Google API 키가 설정되지 않았습니다.")

    # 요청 헤더 설정
    headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': api_key,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.location'
    }

    # 요청 본문 구성
    request_body = {
        'textQuery': query,
        'includedType': 'cafe',   # 카페만 검색
        'languageCode': 'ko',     # 한국어 결과
        'pageSize': 10,           # 최대 10개 결과만 반환
        'regionCode': 'KR',       # 지역 한국으로 제한
    }

    # 위치 기반 검색 추가 (선택적)
    if latitude is not None and longitude is not None:
        search_radius = radius if radius else DEFAULT_SEARCH_RADIUS
        request_body['locationBias'] = {
            'circle': {
                'center': {
                    'latitude': latitude,
                    'longitude': longitude
                },
                'radius': search_radius
            }
        }

    try:
        # API 호출 (POST 요청)
        response = requests.post(
            PLACES_API_V1_URL,
            json=request_body,
            headers=headers,
            timeout=10
        )
        response.raise_for_status()

        data = response.json()

        # 결과 파싱
        places = data.get('places', [])

        if not places:
            return []  # 검색 결과 없음

        cafes = []
        for place in places:
            # displayName 파싱
            display_name = place.get('displayName', {})
            name = display_name.get('text', '이름 없음')

            # location 파싱
            location = place.get('location', {})
            lat = location.get('latitude')
            lng = location.get('longitude')

            # place_id는 'places/ChIJ...' 형식이므로 'places/' 제거
            place_id = place.get('id', '').replace('places/', '')

            cafe_info = {
                'place_id': place_id,
                'name': name,
                'latitude': lat,
                'longitude': lng
            }

            cafes.append(cafe_info)

        return cafes

    except requests.exceptions.Timeout:
        raise InvalidInputException("Google Places API 요청 시간 초과")
    except requests.exceptions.HTTPError as e:
        error_message = f"API 요청 실패: {e.response.status_code}"
        if e.response.status_code == 400:
            error_message = "잘못된 요청입니다. 검색어와 위치 정보를 확인해주세요."
        elif e.response.status_code == 403:
            error_message = "API 키 권한이 없습니다. Places API (New)가 활성화되어 있는지 확인해주세요."
        raise InvalidInputException(error_message)
    except requests.exceptions.RequestException as e:
        raise InvalidInputException(f"Google Places API 요청 실패: {str(e)}")
