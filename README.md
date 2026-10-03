# Six Run — Forerunner 165 / 165 Music

포러너 165용 Connect IQ 데이터 필드 소스 초안입니다.
현재 환경에 Garmin SDK가 없어 컴파일, 시뮬레이터, 실기기 검증을 수행하지 못했습니다.
실행 파일(.prg)은 포함되어 있지 않습니다. 배포 전 아래 검증을 완료하세요.

## 화면

상단 전체 너비: 거리 DIST (km)

| 가운데 왼쪽 | 가운데 오른쪽 |
| --- | --- |
| 평균 페이스 AVG (분:초/km) | 현재 랩 평균 페이스 LAP |
| 운동 타이머 TIME | 현재 페이스 PACE |

하단 전체 너비: 현재 심박수 HR (bpm)

검은 배경, 흰 숫자, 현재 페이스는 노란색입니다.
둥근 화면 가장자리의 잘림을 줄이도록 상단 거리와 하단 심박수를 중앙에 배치했습니다. 가운데 영역만 좌우로 나눕니다.
표시는 영문 약어로 구현했습니다. preview.png는 배치 참고 이미지이며 SDK 렌더링은 아닙니다.

## 데이터 정의

- 거리: Activity.Info.elapsedDistance를 km로 변환.
- 평균/현재 페이스: Garmin averageSpeed/currentSpeed(m/s)를 1000/speed로 변환.
  평균은 Garmin 제공 평균속도의 정의를 따릅니다. Garmin 기본 페이스 표시와 반올림/필터 차이가 있을 수 있습니다.
- 시간: timerTime(ms). 일시정지 구간을 제외하는 운동 타이머이며 현재 시각이 아닙니다.
- 랩 페이스: 랩 시작 이후 거리 증가량 / 타이머 증가량으로 속도를 계산한 뒤 변환.
  onTimerLap에서 Activity.getActivityInfo()로 기준을 갱신합니다. 자동/수동 랩을 따릅니다.
  새 활동 시작 전부터 필드를 사용하세요. 운동 도중 필드가 처음 로드/재로드되면
  이전 랩 시작 지점을 복원할 수 없어 다음 랩까지 LAP를 --:--로 표시합니다.
  랩 이벤트와 기기 누적값 갱신 순서는 시뮬레이터/워치에서 검증해야 합니다.
- 누락된 값, 0 속도, 99:59/km보다 느린 속도는 -- 또는 --:--.
- 속도에 추가 이동평균 필터는 적용하지 않았습니다. km 및 /km 고정.
- 기록은 Garmin 기본 러닝 앱이 담당하며 이 필드는 화면만 제공합니다.

## 준비

1. PC에 VS Code, Garmin 공식 Monkey C 확장, Java 및 Connect IQ SDK Manager를 설치합니다.
   https://developer.garmin.com/connect-iq/overview/
2. SDK Manager에서 SDK와 Forerunner 165 / 165 Music 기기 정의를 내려받습니다.
3. VS Code에서 이 폴더를 엽니다. Monkey C 확장의 설치 검증과 개발자 키 생성 기능으로 설정합니다.
4. 키는 프로젝트 밖에 보관하고 공개하지 마세요.

## 빌드

SDK의 bin을 PATH에 추가하고 프로젝트 폴더에서 실행합니다. bin 폴더는 먼저 생성하세요.

```sh
mkdir -p bin
monkeyc -f monkey.jungle -d fr165 -o bin/SixRun.prg -y /absolute/path/developer_key.der
```

165 Music이면 -d fr165m을 사용합니다. SDK Manager가 제공하는 실제 기기 ID도 확인하세요.
일반 165와 Music 빌드 파일은 서로 바꿔 넣지 마세요.

시뮬레이터를 시작한 뒤 해당 모델로 실행합니다:

```sh
monkeydo bin/SixRun.prg fr165
```

## 워치에 설치

컴파일과 시뮬레이터 검증 후 USB로 PC와 워치를 연결합니다.
빌드한 SixRun.prg를 워치의 기존 GARMIN/APPS 폴더에 복사하고 안전하게 분리합니다.
Mac에서 MTP 방식 워치가 Finder에 보이지 않으면 MTP 파일 전송 도구가 필요할 수 있습니다.

워치 러닝 활동 설정에서 데이터 화면을 추가/편집하고:

1. 레이아웃을 **1칸**으로 선택합니다.
2. 그 칸의 데이터 항목에서 **Connect IQ → Six Run**을 선택합니다.
3. 일반 6칸 레이아웃을 찾는 것이 아니라 하나의 필드가 내부에서 6개 값을 그리는 방식입니다.

소스 ZIP을 iPhone의 Connect IQ 앱에서 바로 설치할 수는 없습니다.
이 경로는 PC 컴파일/USB 설치가 필요합니다. 휴대폰 설치를 지원하려면
별도로 Connect IQ Store에 등록·심사를 거쳐 배포해야 합니다.

## 검증 체크리스트

- 165 및 165 Music 타깃 컴파일 오류 없이 통과.
- 시뮬레이터 1칸 전체 화면에서 0.00, 42.20, 100.00 km와 0:00, 59:59, 3:15:00, 10:00:00 표시가 잘리지 않는지 확인.
- 4 m/s 입력 → 4:10/km, 1000m/250초 랩 → 4:10/km.
- 자동 1km 랩 및 수동 랩 후 LAP가 새 랩 기준으로 계산되는지 확인.
- 일시정지/재개 중 TIME 및 LAP에 정지 시간이 더해지지 않는지 확인.
- 운동 종료/폐기 후 새 운동에서 누적값 및 랩 기준 초기화 확인.
- 운동 도중 로드되면 LAP가 다음 랩까지 --:--인지 확인.
- GPS/심박 값 null 및 속도 0에서 예외가 없는지 확인.
- 실기기에서 읽기 쉬운 숫자 크기, 센서값 비교, 장시간 동작 확인.

## 공식 API 참고

https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity/Info.html
https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/DataField.html
https://developer.garmin.com/connect-iq/monkey-c/compiler-options/
