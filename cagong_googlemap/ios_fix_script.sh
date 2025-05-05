#!/bin/bash

# iOS 빌드 문제 해결 스크립트

cd /Users/yannoo/Desktop/winwinInfo/Clopen_repo/Clopen/cagong_googlemap

echo "=== iOS 빌드 문제 해결 시작 ==="

# 1. 기존 빌드 정리
echo "1. 빌드 폴더 정리..."
rm -rf build/ios
flutter clean

# 2. 파일 시스템 메타데이터 문제 해결
echo "2. 파일 시스템 메타데이터 정리..."
find . -name "._*" -type f -delete
find . -name ".DS_Store" -type f -delete
xattr -rc ios/
xattr -rc .

# 3. Pod 재설치
echo "3. Pod 재설치..."
cd ios
pod deintegrate
rm -rf Pods
rm -rf Podfile.lock
pod install --repo-update

# 4. Pod 프로젝트 수정하여 최소 iOS 버전 통일
echo "4. Pod 프로젝트 설정 수정..."
cd ..

# post_install을 Podfile에 추가하여 자동으로 최소 iOS 버전을 13.0으로 설정
cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
EOF

# 5. Pod 재설치
echo "5. 새로운 설정으로 Pod 재설치..."
cd ios
pod install

# 6. 프로젝트 다시 빌드
echo "6. 프로젝트 다시 실행..."
cd ..
flutter run

echo "=== 완료 ==="
