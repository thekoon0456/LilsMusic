# LilsMusic
`Simple, Beautiful Music App` <br>
`UIKit + MVVM-C + RxSwift + MusicKit + Swift Concurrency` <br>

## 🔗 Links
### [📱 AppStore](https://추가하기)
### [🧑🏻‍💻 Blog](https://thekoon0456.tistory.com/127)

## 📝 핵심 키워드
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![UIKit](https://img.shields.io/badge/UIkit-2396F3?style=for-the-badge&logo=UIKit&logoColor=white)
![RxSwift](https://img.shields.io/badge/RxSwift-fa4db3?style=flat&logo=ReactiveX&logoColor=white)
![MusicKit](https://img.shields.io/badge/MusicKit-FA243C?style=for-the-badge&logo=MusicKit&logoColor=white)
![SwiftConcurrency](https://img.shields.io/badge/SwiftConcurrency-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![Realm](https://img.shields.io/badge/realm-39477F?style=for-the-badge&logo=Realm&logoColor=white)
![SnapKit](https://img.shields.io/badge/SnapKit-4285F4?style=for-the-badge&logo=SnapKit&logoColor=white)

## 📌 주요 기능
- 최신 인기 음악과 개인화된 추천 음악 제공
- 곡에 따라 배경색이 변경되는 예쁜 음악 플레이어
- 최신 뮤직비디오를 둘러보며 좋아하는 노래를 바로 플레이리스트에 저장
- 편리한 플로팅 미니 뮤직 플레이어 사용
- 다양한 애니메이션과 햅틱 반응
<br>


## 📱시연 영상
|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/e2310b70-0b10-4c95-b161-731807d37950"></img>|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/87b36b00-853f-4ee3-843d-70c24fe81649"></img>|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/a0107164-28f7-416d-863a-2241aa12e7c3"></img>|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/41fc960e-83c0-4d95-88eb-27f4923ecfa2"></img>|
|:-:|:-:|:-:|:-:|
|`알림 뷰`|`메인 뷰`|`위젯 뷰`|`온보딩 뷰`|
|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/e863ab80-ea5a-43c9-a999-19d638d2a5c3"></img>|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/fd86103e-c18d-4338-9d34-41dcbf62aff8"></img>|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/d031ed7e-d037-4267-992e-ddca6cf91cb4"></img>|<img src="https://github.com/thekoon0456/WeatherI_Refactor/assets/106993057/bddfaf18-1453-4b21-8d60-5e000e247be9"></img>|
|`설정 뷰`|`웹, 메일 뷰`|`꾸준한 업데이트`|`긍정적 리뷰`|
<br>

## 💡 기술 소개





## ✅ 트러블 슈팅

### MusicVideo타입에 연관된 Song타입을 제공해주지 않아서 뮤직비디오의 노래를 못 찾는 문제
<div markdown="1">
        
```
뮤직비디오를 보다가 좋아하는 노래를 누르면 해당 뮤직비디오의 노래를 플레이리스트에 저장해야하는데
MusicKit의 요청함수로 MusicVideo타입에 연관된 Song을 요청해도 nil만 리턴을 받았습니다.
그래서 뮤직비디오의 아티스트와 노래 이름으로 MusicKit의 Song을 검색한 뒤, 둘 다 일치하는 이름이 있는 Song이 있으면 반환하도록 구현했습니다.
```

```swift
    //MusicKit의 요청 방식으로 MusicVideo타입의 Song을 요청해도 nil만 리턴
    func requestSearchMVIDCatalog(id: MusicItemID?) async throws -> Song? {
        guard let id else { return nil }
        let response = try await MusicCatalogResourceRequest<MusicVideo>(matching: \.id, equalTo: id).response()
        guard let item = response.items.first else { return nil }
        let songs = try await item.with(.songs).songs
        let song = songs?.first
        return song
    }
    
    => 뮤직비디오의 아티스트와 노래 이름으로 Song을 검색한 뒤, 일치하는 이름이 있는 Song이 있으면 반환
    func MusicVideoToSong(_ item: MusicVideo) async throws -> Song? {
        let song = try await requestMVToSongCatalog(term: "\(item.artistName), \(item.title)")
        return song
    }
    
    func requestMVToSongCatalog(term: String) async throws -> Song? {
        let songs = try await MusicCatalogSearchRequest(term: term, types: [Song.self]).response().songs
        let result = songs.filter { term.contains($0.title) && term.contains($0.artistName) }.first
        return result
    }
```
</div>
<br>

### 애플뮤직 권한 요청 -> 사용자의 구독권장까지의 분기처리
<div markdown="1">
        
```
처음 앱을 시작하면 
1. 애플뮤직 권한 요청 
    -> 권한 승인시 -> 앱을 사용하다가 노래 재생버튼을 눌렀을 때 -> 애플뮤직 구독 확인
    -> 권한 거부시 -> 아이폰의 앱 권한설정 화면으로 이동
    
2. 애플뮤직 구독 확인 후
    -> 구독자라면 노래 재생. 구독자 추천 플레이리스트 가져오기
    -> 구독자가 아니라면 구독 제안 화면 Present
의 분기처리를 Coordinator를 통해 구현했습니다.
    
```

```swift
//AppCoordinator
    func requestMusicAuthorization() {
        SKCloudServiceController.requestAuthorization { [weak self] status in
            guard let self else { return }
            switch status {
            case .authorized:
                print("승인됨")
                makeTabbar() //탭바 만들고, 앱 시작
                break
            default:
                moveToUserSetting() //아이폰의 세팅 설정으로
                break
            }
        }
    }

    //아이폰의 세팅 설정으로 이동을 유도하는 Alert
    func moveToUserSetting() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "Access to Apple Music is required to use the app.",
                                          message: 
                                            "Please allow permission in settings to access the music library.",
                                          preferredStyle: .alert)
            alert.view.tintColor = .label
            
            let primaryButton = UIAlertAction(title: "Go to Settings", style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            
            alert.addAction(primaryButton)
            navigationController?.present(alert, animated: true)
        }
    }
```

```Swift
//MusicPlayerViewModel에서 노래 클릭시
    //StoreKit을 활용해 구독 확인 
    func checkAppleMusicSubscriptionEligibility() {
        let controller = SKCloudServiceController()
        controller.requestCapabilities { [weak self] (capabilities, error) in
            guard let self else { return }
            if let error {
                print(error.localizedDescription)
                return
            }
            
            //구독자가 아니라면 애플뮤직 가입 권유화면 present
            if capabilities.contains(.musicCatalogSubscriptionEligible) && !capabilities.contains(.musicCatalogPlayback) {
                coordinator?.presentAppleMusicSubscriptionOffer()
            }
        }
    }
    
    //MusicListCoordinator의 애플뮤직 가입권유화면
    func presentAppleMusicSubscriptionOffer() {
        var options: [SKCloudServiceSetupOptionsKey: Any] = [.action: SKCloudServiceSetupAction.subscribe]
        options[.messageIdentifier] = SKCloudServiceSetupMessageIdentifier.addMusic
        
        let setupViewController = SKCloudServiceSetupViewController()
        setupViewController.delegate = self
        
        setupViewController.load(options: options) { (result, error) in
            if result {
                DispatchQueue.main.async {  [weak self] in
                    guard let self else { return }
                    navigationController?.present(setupViewController, animated: true)
                }
            } else if let error = error {
                print("Error presenting Apple Music subscription offer: \(error.localizedDescription)")
            }
        }
    }
```
</div>
<br>


### Swift Concurrency, Combine과 RxSwift를 함께 연동하며 스레드, 비동기 시점 문제
<div markdown="1">
        
```
설명
```

```swift
코드
```
</div>
<br>


### 뮤직비디오를 AVPlayer로 재생시에 cell을 넘길때마다 로딩이 발생하던 문제
<div markdown="1">
        
```
설명
```

```swift
코드
```
</div>
<br>


### 뮤직비디오 로딩시점을 파악해 인디케이터 표시해주기
<div markdown="1">
        
```
설명
```

```swift
코드
```
</div>
<br>

### realm에 좋아요 누른 데이터가 저장되거나 삭제될때 화면의 새로고침
<div markdown="1">
        
```
설명
```

```swift
코드
```
</div>
<br>

### 코디네이터 해제 시점 조절 
<div markdown="1">
        
```
설명
```

```swift
코드
```
</div>
<br>


## 💻 앱 개발 환경

- 최소 지원 버전: iOS 16.4+
- Xcode Version 15.0.0
- iPhone 15 Pro에서 최적화됨, iPhone SE3까지 호환 가능
<br>


## 🧑🏻‍💻회고
긍정적인 점
- 짧은 시간 내에 기획한 앱을 만들었다는 점
- MusicKit과 AVFoundation 등 평소에 접하기 힘들었던 기술스택을 도전하고, 구현했다는 점
- RxSwift, MVVMC 등을 사용하면서 해당 기술에 대해 더 고민하고, 이해하며 구현했다는 점
- MusicKit의 Swift Concurrency와 Combine을 UIKit, RxSwift로 구현했다는 점입니다.
  
아쉬운 점
- 중간에 아파서 약 5일간 개발을 하지 못했던 점... ㅠㅠ 건강이 최고입니다!!
- 처음에 기획했던 다양한 플레이리스트를 추가 하지 못했습니다.
- 검색이 현재 개별 곡만 검색되고 앨범이나 아티스트 전체가 검색되지 않습니다.
- 사용자의 취향을 파악하고, Charts를 통해 그래프로 표현하려했지만 덜어냈고, 애플뮤직의 사용자 추천 플레이리스트로 대체했습니다.
 
