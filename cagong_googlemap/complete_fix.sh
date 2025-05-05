#!/bin/bash

echo "=== iOS 빌드 문제 완전 해결 시작 ==="

cd /Users/yannoo/Desktop/winwinInfo/Clopen_repo/Clopen/cagong_googlemap

# 1. 모든 캐시와 빌드 제거
echo "1. 전체 정리..."
flutter clean
rm -rf build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Runner.xcworkspace
rm -rf ios/Pods/
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. 모든 파일의 extended attributes 제거
echo "2. 모든 파일 속성 정리..."
xattr -rc .
find . -name "._*" -type f -delete
find . -name ".DS_Store" -type f -delete

# 3. 직접 RecaptchaInterop.framework 문제 해결
echo "3. RecaptchaInterop Framework 처리..."
if [ -d "build/ios/Debug-iphonesimulator/RecaptchaInterop/RecaptchaInterop.framework" ]; then
    xattr -rc build/ios/Debug-iphonesimulator/RecaptchaInterop/RecaptchaInterop.framework
    codesign --force --sign - --timestamp=none build/ios/Debug-iphonesimulator/RecaptchaInterop/RecaptchaInterop.framework
fi

# 4. Pod 환경 완전 리셋
echo "4. Pod 환경 리셋..."
cd ios
pod deintegrate
rm -rf ~/Library/Caches/CocoaPods
rm -rf Podfile.lock
pod cache clean --all

# 5. 새로운 Podfile로 교체 (더 안정적인 버전)
echo "5. Podfile 업데이트..."
cat > Podfile << 'EOF'
# iOS 13.0을 글로벌 플랫폼으로 설정
platform :ios, '13.0'

# CocoaPods 통계 비활성화
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
    
    # 모든 타겟의 배포 타겟을 13.0으로 설정
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}.#{target.name}"
      
      # RecaptchaInterop.framework 코드 서명 문제 해결
      if target.name == 'RecaptchaInterop'
        config.build_settings['CODE_SIGN_IDENTITY'] = ''
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end
    end
  end
end
EOF

# 6. Pod 재설치
echo "6. Pod 재설치..."
pod install --repo-update

# 7. 프로젝트 구조 확인
echo "7. 프로젝트 구조 확인..."
cd ..
tree -d -L 3 ios

# 8. Flutter 의존성 재설치
echo "8. Flutter 의존성 재설치..."
flutter pub get

# 9. 빌드 시도
echo "9. 빌드 시도..."
flutter run

echo "=== 완료 ==="
