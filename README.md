# LilsMusic
`Simple, Beautiful Music App` <br>
`UIKit + MVVM-C + RxSwift + MusicKit + Swift Concurrency`
<br>

## 🔗 Links
### [📱 AppStore](https://추가하기)
### [🧑🏻‍💻 Blog 회고](https://thekoon0456.tistory.com/search/lils)
<br>

## 📌 주요 기능
- 최신 인기 음악과 개인화된 추천 음악 제공
- 곡에 따라 배경색이 변경되는 예쁜 음악 플레이어
- 최신 뮤직비디오를 둘러보며 좋아하는 노래를 바로 플레이리스트에 저장
- 편리한 플로팅 미니 뮤직 플레이어 사용
- 다양한 애니메이션과 햅틱 반응
<br>

## 📱시연 영상
|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/cb2ceb18-776c-460c-b5dc-9ea4cbcbe82d"></img>|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/967715c2-63cb-4ab7-87c8-d65c09dda3a0"></img>|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/5a8338c5-1f49-4f16-b71d-b7bdd1d140ad"></img>|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/4c7ff5d9-bb76-48f6-b1df-e1d0d7c56b44"></img>|
|:-:|:-:|:-:|:-:|
|`음악 플레이어`|`뮤직비디오`|`미니 플레이어`|`라이브러리`|
|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/16848413-a69e-4322-9687-6a06b43c9d7d"></img>|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/dd07a402-1764-45e5-bf78-5ef3dee0e1f1"></img>|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/41c368bd-4ee6-476e-8ca0-8b5e10a4c10b"></img>|<img src="https://github.com/thekoon0456/LilsMusic/assets/106993057/d1b98bdb-ef1c-4181-ba7c-ebe83df1a042"></img>|
|`홈 화면`|`음악 검색`|`권한 설정`|`구독 제안`|
<br>

## 📝 핵심 키워드
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![UIKit](https://img.shields.io/badge/UIkit-2396F3?style=for-the-badge&logo=UIKit&logoColor=white)
![RxSwift](https://img.shields.io/badge/RxSwift-fa4db3?style=for-the-badge&logo=ReactiveX&logoColor=white)<br>
![MusicKit](https://img.shields.io/badge/MusicKit-FA243C?style=for-the-badge&logo=MusicKit&logoColor=white)
![AVFoundation](https://img.shields.io/badge/AVFoundation-FA243C?style=for-the-badge&logo=AVFoundation&logoColor=white)
![AVKit](https://img.shields.io/badge/AVKit-FA243C?style=for-the-badge&logo=AVKit&logoColor=white)<br>
![SwiftConcurrency](https://img.shields.io/badge/SwiftConcurrency-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![ModernCollectionView](https://img.shields.io/badge/ModernCollectionView-F54A2A?style=for-the-badge&logo=swift&logoColor=white)<br>
![Realm](https://img.shields.io/badge/realm-39477F?style=for-the-badge&logo=Realm&logoColor=white)
![SnapKit](https://img.shields.io/badge/SnapKit-4285F4?style=for-the-badge&logo=SnapKit&logoColor=white)
<br>

## 💡 기술 소개

### MVVM
- 뷰컨트롤러의 로직을 뷰와 분리하고, Input, Output 패턴을 활용해 데이터의 흐름을 일관성있게 구현
- ViewModel Protocol을 활용해 구조적으로 일관된 뷰모델 구성 
<br>

### Coordinator 패턴
- 사용자 인증, 음악 플레이어 재생과 같은 화면 전환 코드가 비대해지는 문제를 해결하기 위해 뷰 컨트롤러와 화면 전환 로직을 분리
- Coordinator 생성 -> ViewModel 생성 -> ViewController 생성하는 패턴으로 의존성 주입
- viewController에서 화면전환 input -> ViewModel을 통해 Coordinator로 전달하여 화면 전환
<br>

### RxSwift
- 앱 내의 비동기 시퀀스 및 이벤트 기반의 데이터 흐름을 관리
- 사용자의 탭과 같은 Input은 Observable로, UI바인딩하는 Ouptup은 Driver를 활용하여 일관된 데이터 흐름과 UI바인딩 구현
<br>

### MusicKit
- Apple의 MusicKit 프레임워크를 활용해 음악 플레이어 구현
- SwiftUI의 프레임워크인 MusicKit을 UIKit에 최적화하여 구현
<br>

### AVFoundation, AVKit
- AVQueuePlayer의 인스턴스를 하나만 생성하고 재생할 Item을 미리 배열로 넣어놔서 사용했지만 화면 이동시에 딜레이 발생
- 각 Cell마다 AVPlayer 인스턴스를 생생하고, cell이 configure될때 미리 재생하도록 설정해서 딜레이 줄임
- observeValue() 함수를 통해 AVPlayer의 상태를 옵저빙하고, 로딩 준비 완료시에 로딩 인디케이터 해제
<br>

### SwiftConcurrency
- 최신 API인 MusicKit의 비동기 방식
- RxSwift와 SwiftConcurrency, Combine을 연동. 스레드 관리 일관화
<br>

### ModernCollectionView
- 추천화면의 다채로운 Layout을 구현하기 위해 UICollectionView CompositionalLayout활용
- MusicVideo탭의 Cell이 화면을 가득 채우고, 페이징 스크롤 구현
- List 화면에서 Item 로드시 애니메이션을 사용하기 위해 UICollectionView CompositionalLayout의 List 활용
- 다양한 레이아웃과 애니메이션 구현
<br>

### Realm
- Repository 패턴을 사용해 데이터 계층 추상화
- Repository Protocol을 활용해 일관성있는 Repository 구조 구현
- 업데이트 내역을 실시간으로 반영하기 위해 notificationToken 사용 
- 데이터 관리를 일관성있게 유지하며, 변경사항이 발생할때마다 UI를 업데이트할 수 있도록 구현
<br>


## ✅ 트러블 슈팅

### 뮤직비디오를 AVPlayer로 재생시에 cell을 넘길때마다 로딩이 발생하던 문제
<div markdown="1">
<br>
MusicVideo 릴스 탭에서 Cell을 넘길때마다 MusicVideo의 로딩이 발생하는 문제가 있었습니다.<br>
기존에는 AVQueuePlayer에 재생할 URL들을 Queue에 넣은 뒤에 cell을 넘길때마다 하나하나 요청해서 재생했습니다.<br>
로딩이 걸리는 문제를 해결하고자, 각 Cell마다 configure시점에 URL을 넣고, 일시정지 시킨 뒤<br>
Cell이 화면에 보일때 재생하는 방식으로 딜레이를 줄였습니다.<br>

```swift
//ReelsCell
//cell을 구성할때 AVPlayer의 인스턴스를 Cell마다 각각 생성하고, URL을 넣고 일시정지 상태로 대기시킴
    func configureCell(_ data: MusicVideo, status: AVPlayer.TimeControlStatus) {
        //cell재사용할때 bind
        bind()
        mvSubject.onNext(data)
        
        guard let url = data.previewAssets?.first?.hlsURL else { return }
        let asset = AVURLAsset(url: url)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            DisplayVideoFromAssets(asset: asset, view: musicVideoView)
            setPlayerStatus(status: status)
        }
        ...
    }

    //로딩 인디케이터와 재생 완료시 반복하는 Noficifation 생성
    func DisplayVideoFromAssets(asset: AVURLAsset, view: UIView) {
        startLoadingIndicator()
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        player = AVPlayer(playerItem: playerItem).then {
            $0.isMuted = true
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        ...
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
            guard let self else { return }
            player?.seek(to: .zero)
            player?.play()
        }
    }

    //AVPlayer의 상태를 추적하고, readyToPlay시점에서 로딩인디케이터 해제
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    stopLoadingIndicator()
                case .failed, .unknown:
                    print("Failed to load the video")
                @unknown default:
                    break
                }
            }
        }
    }
```
</div>
<br>

### 애플뮤직 권한 요청 -> 사용자의 구독권장까지의 분기처리
<div markdown="1">
처음 앱을 시작하면<br>
1. 애플뮤직 권한 요청 
    -> 권한 승인시 -> 앱을 사용하다가 노래 재생버튼을 눌렀을 때 -> 애플뮤직 구독 확인
    -> 권한 거부시 -> 아이폰의 앱 권한설정 화면으로 이동
<br>
2. 애플뮤직 구독 확인 후
    -> 구독자라면 노래 재생. 구독자 추천 플레이리스트 가져오기
    -> 구독자가 아니라면 구독 제안 화면 Present
의 분기처리를 Coordinator를 통해 구현했습니다.
<br>

```swift
//StoreKit을 활용해 구독 관리
//SubscriptionManager
    func checkAppleMusicSubscriptionEligibility(completion: @escaping (Bool) -> Void) {
        let controller = SKCloudServiceController()
        
        controller.requestCapabilities { capabilities, error in
            if let error {
                print(error.localizedDescription)
                return
            }
            
            if capabilities.contains(.musicCatalogSubscriptionEligible) && !capabilities.contains(.musicCatalogPlayback) {
                completion(false)
                return
            } else {
                completion(true)
                return
            }
        }
    }

//앱 진입시 UserDefaults에 구독여부 저장
//SceneDelegate
    func sceneWillEnterForeground(_ scene: UIScene) {
        SubscriptionManager.shared.checkAppleMusicSubscriptionEligibility { bool in
            print("유저 구독\(bool)")
            UserDefaultsManager.shared.userSubscription.isSubscribe = bool
        }
    }

//노래 재생시 구독여부에 따라 구독제안 혹은 음악 플레이어 present
//MusicListViewModel
        input.playButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.tapImpact()
                Task {
                    guard let tracks = try await owner.fetchTracks(),
                          let firstItem = tracks.first else { return }
                    await owner.musicPlayer.setTrackQueue(item: tracks, startTrack: firstItem)
                    DispatchQueue.main.async {
                        owner.isUserSubscription
                        ? owner.coordinator?.presentMusicPlayer(track: firstItem)
                        : owner.coordinator?.presentAppleMusicSubscriptionOffer()
                    }
                }
            }.disposed(by: disposeBag)
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
- 중간에 아파서 약 5일간 개발을 하지 못했던 점. 건강관리 중요.
- 처음에 기획했던 다양한 플레이리스트를 추가 하지 못했습니다.
- 검색이 현재 개별 곡만 검색되고 앨범이나 아티스트 전체가 검색되지 않습니다.
- 사용자의 취향을 파악하고, Charts를 통해 그래프로 표현하려했지만 덜어냈고, 애플뮤직의 사용자 추천 플레이리스트로 대체했습니다.
 
