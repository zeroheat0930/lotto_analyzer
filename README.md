# Lotto Analyzer - AI 로또 번호 분석기

Flutter 기반 로또 번호 분석 및 생성 앱. 동행복권 API에서 실시간 데이터를 가져와 AI 알고리즘으로 최적의 번호를 추천합니다.

## Screenshots

| 번호 생성 | 분석 대시보드 | 히스토리 |
|:---------:|:------------:|:--------:|
| 홈 화면에서 전략별 번호 생성 | 출현 빈도, 추세, 홀짝 차트 | 저장된 번호 + 당첨 확인 |

## Features

### 1. AI 번호 생성 엔진
- **Hot/Cold 가중치**: 최근 출현 빈도에 지수 감소 가중치 적용
- **홀짝 비율 필터**: 3:3 또는 4:2 비율만 허용
- **연속번호 방지**: 3개 이상 연속 번호 자동 차단
- **가중 룰렛 휠**: Cold 번호도 최소 확률 보장

### 2. 순수 Dart 신경망 예측
- 외부 ML 라이브러리 없이 순수 Dart로 구현한 Feedforward Neural Network
- Xavier 초기화 + Sigmoid 활성화 + 역전파 학습
- 이전 회차 번호 시퀀스 패턴 학습 후 다음 회차 예측

### 3. 다중 전략 모드
| 전략 | 설명 |
|------|------|
| 보수적 | Hot 번호 가중치 2배 부스트 (자주 나온 번호 위주) |
| 공격적 | Cold 번호 가중치 2배 부스트 (안 나온 번호 위주) |
| 밸런스 | 기본 가중치 유지 (균형 잡힌 선택) |

각 전략별 과거 적중률 시뮬레이션 결과를 분석 탭에서 확인할 수 있습니다.

### 4. 분석 대시보드
- **빈도 차트**: 1~45번 전체 출현 횟수 BarChart
- **추세 차트**: 특정 번호의 최근 10회차 출현 여부 LineChart
- **홀짝 비율**: 전체 데이터 기반 PieChart
- **전략 비교**: 3가지 전략의 평균 일치 개수 및 적중률

### 5. 번호 저장 & 당첨 확인
- 생성된 번호를 SQLite(sqflite) 로컬 DB에 저장
- 전략명, 생성일시 자동 기록
- 최신 당첨 번호와 자동 대조 (일치 개수 표시)

## Tech Stack

- **Framework**: Flutter 3.41+
- **State Management**: Provider
- **HTTP**: http (동행복권 공식 API)
- **Charts**: fl_chart
- **Local DB**: sqflite + path_provider
- **AI/ML**: 순수 Dart 구현 (외부 의존성 없음)

## Project Structure

```
lib/
├── main.dart                         # 앱 진입점 + 탭 네비게이션
├── models/
│   └── lotto_round.dart              # 로또 회차 데이터 모델
├── services/
│   ├── lotto_api_service.dart        # 동행복권 API 연동 (CORS 프록시 지원)
│   ├── lotto_analyzer.dart           # 핵심 분석 알고리즘 + 전략 엔진
│   ├── lotto_neural_predictor.dart   # Feedforward 신경망 예측기
│   └── database_service.dart         # SQLite 로컬 저장소
├── providers/
│   └── lotto_provider.dart           # 앱 상태 관리
├── screens/
│   ├── home_screen.dart              # 번호 생성 메인 화면
│   ├── analysis_screen.dart          # 분석 대시보드
│   └── history_screen.dart           # 저장 번호 히스토리
└── widgets/
    └── lotto_ball.dart               # 골드 그라디언트 번호 공 위젯
```

## Getting Started

### Prerequisites
- Flutter SDK 3.41 이상
- Dart 3.11 이상

### Installation

```bash
git clone https://github.com/zeroheat0930/lotto_analyzer.git
cd lotto_analyzer
flutter pub get
```

### Run

```bash
# 웹 (Chrome)
flutter run -d chrome

# iOS
flutter run -d ios

# Android
flutter run -d android
```

## API

동행복권 공식 API를 사용합니다:
```
https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo={회차번호}
```

> 웹 빌드 시 CORS 제한을 우회하기 위해 `corsproxy.io` 프록시를 자동 적용합니다.

## Design

- **Theme**: 럭셔리 다크 (블랙 `#0D0D0D` + 골드 `#FFD700`)
- **Ball Widget**: 골드 그라디언트 + 글로우 그림자
- **Animation**: TweenAnimationBuilder 기반 등장 효과

## License

MIT License
