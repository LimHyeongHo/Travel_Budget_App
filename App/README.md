# 앱 타깃 (XcodeGen) 과 TestFlight

`.xcodeproj`는 저장소에 없고 루트의 `project.yml`에서 생성한다. 로직은 모두 루트의 Swift Package(`TravelBudgetCore`)에 있다.

## Mac에서
```
brew install xcodegen
xcodegen generate
open TravelBudget.xcodeproj
```
Signing & Capabilities에서 Team을 고르고 실행한다.

## TestFlight 배포 (Windows + GitHub Actions)
필요: 유료 Apple Developer Program 계정.

1. **번들 ID 결정**: 번들 ID는 전 세계에서 고유해야 하므로 `com.travelbudget.app`이 이미 쓰이고 있으면 등록에 실패한다. 다르게 쓰려면 저장소 Settings > Secrets and variables > Actions > **Variables**에 `BUNDLE_ID`를 등록한다. (예: `com.내이름.travelbudget`)
2. **App Store Connect에 앱 만들기**: appstoreconnect.apple.com > 앱 > + > 새로운 앱. 플랫폼 iOS, 번들 ID는 1번 값. (Developer 사이트 Identifiers에 번들 ID가 없으면 먼저 등록한다.)
3. **API 키 발급**: App Store Connect > 사용자 및 액세스 > 통합 > App Store Connect API > 키 생성, 역할은 **관리자(Admin)**. `.p8` 파일(한 번만 다운로드 가능), Key ID, Issuer ID를 기록한다.
4. **Team ID 확인**: developer.apple.com > 멤버십 세부 정보.
5. **GitHub Secrets 등록** (Settings > Secrets and variables > Actions > Secrets)
   | 이름 | 값 |
   |---|---|
   | `APPLE_TEAM_ID` | Team ID |
   | `APP_STORE_CONNECT_KEY_ID` | API 키 Key ID |
   | `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
   | `APP_STORE_CONNECT_KEY_P8` | `.p8` 파일 내용 전체 (BEGIN/END 줄 포함) |
   | `EXCHANGE_RATE_API_KEY` | ExchangeRate-API v6 키 |
6. Actions 탭 > CI > Run workflow > `testflight` 잡이 성공하면 업로드된다. 빌드 번호는 실행 번호로 자동 증가한다.
7. App Store Connect > TestFlight에서 처리(약 5~30분)가 끝나면 내부 테스터(본인 Apple ID)를 추가하고, 아이폰의 TestFlight 앱에서 설치한다.

## 기타
- CloudKit은 기본 OFF다. 켜려면 `project.yml`에 iCloud/CloudKit entitlements를 추가하고 `ENABLE_CLOUDKIT`을 `"YES"`로 바꾼다.
- 영수증 AI 분석(`FoundationModels`)은 iOS 26+ 및 Apple Intelligence 지원 기기에서만 동작하고, 그 외에는 안내 메시지를 표시한다.
- 앱 아이콘(`Assets.xcassets/AppIcon.appiconset/icon.png`)은 임시 이미지다. 1024x1024, 알파 채널 없는 PNG로 교체하면 된다.
- 백그라운드 환율 갱신, 카메라 권한은 `project.yml`의 Info.plist 설정에 이미 들어 있다.
