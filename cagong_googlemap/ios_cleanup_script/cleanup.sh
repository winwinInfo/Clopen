#!/bin/bash

# iOS 빌드 정리 스크립트

echo "iOS 프로젝트 정리 시작..."

# 현재 디렉토리 확인
cd /Users/yannoo/Desktop/winwinInfo/Clopen_repo/Clopen/cagong_googlemap

# Pods 캐시 정리
echo "1. Pods 캐시 정리 중..."
cd ios
pod deintegrate
rm -rf Pods
rm -rf Podfile.lock

# DerivedData 정리
echo "2. DerivedData 정리 중..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# iOS 빌드 폴더 정리
echo "3. 빌드 폴더 정리 중..."
cd ..
rm -rf build/ios

# 파일 시스템 메타데이터 정리
echo "4. 파일 시스템 메타데이터 정리 중..."
# resource fork, Finder 정보 등 제거
find . -name "._*" -type f -delete
find . -name ".DS_Store" -type f -delete

# @-attributes 제거
xattr -rc ios/

# Pod 재설치
echo "5. Pods 재설치 중..."
cd ios
pod install --repo-update

# 플러터 clean
echo "6. 플러터 프로젝트 정리 중..."
cd ..
flutter clean
flutter pub get

echo "🎉 정리 완료! 이제 다시 실행해보세요: flutter run"
