from flask import Blueprint, jsonify
import json
import os

cafe_bp = Blueprint('cafes', __name__)

@cafe_bp.route('/')
def get_cafe_list():
    """카페 목록 조회"""
    try:
        # JSON 파일 경로 찾기  
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(current_dir))
        json_path = os.path.join(project_root, 'cagong_googlemap', 'assets', 'json', 'cafe_info.json')
        
        # JSON 파일 읽기
        with open(json_path, 'r', encoding='utf-8') as f:
            cafes = json.load(f)
        
        return jsonify({
            "success": True,
            "count": len(cafes),
            "data": cafes[:5]  # 처음 5개만 보여주기
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"오류 발생: {str(e)}"
        })

@cafe_bp.route('/<int:cafe_id>')
def get_cafe_by_id(cafe_id):
    """특정 카페 조회"""
    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(current_dir))
        json_path = os.path.join(project_root, 'cagong_googlemap', 'assets', 'json', 'cafe_info.json')
        
        with open(json_path, 'r', encoding='utf-8') as f:
            cafes = json.load(f)
        
        # ID로 카페 찾기
        cafe = next((c for c in cafes if c.get('ID') == cafe_id), None)
        
        if cafe:
            return jsonify({
                "success": True,
                "data": cafe
            })
        else:
            return jsonify({
                "success": False,
                "error": "카페를 찾을 수 없어요"
            })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"오류 발생: {str(e)}"
        })