import 'package:flutter/material.dart';

void showFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,  // 반투명한 검정색 배경 설정
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('필터'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              CheckboxListTile(
                title: Text('와이파이'),
                value: false,
                onChanged: (bool? value) {
                  // 상태 업데이트 로직
                },
              ),
              CheckboxListTile(
                title: Text('콘센트'),
                value: false,
                onChanged: (bool? value) {
                  // 상태 업데이트 로직
                },
              ),
              // 추가 필터 옵션들...
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('취소'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('적용'),
            onPressed: () {
              // 필터 적용 로직
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}