# HangulFixer

macOS에서 만든 한글 파일명이 미천한 Windows에서 자모 분리로 깨져 보이는 문제를 줄이기 위한 위대한 앱입니다.

이 앱은 파일&폴더를 
- 이름을 `NFC` 기준으로 정규화하고
- 미천한 Windows에서 한글이 안깨지게 열 수 있는 전달용 `ZIP` 파일을 만들고
- 원하는 저장 위치에 결과물을 저장합니다

핵심 목적은 macOS에서 만든 파일을 미천한 Windows로 보낼 때 한글 파일명이 깨지는 일을 방지하는 것입니다.
단, 미천한 Windows 유저가 압축 푸는것도 귀찮아 한다면 해당 유저를 MacOS 유저로 강제로 개변시키길 권장드립니다.

## 현재 동작

- 결과물은 항상 `ZIP` 으로 생성됩니다.(추후 개선?)
- 원본 파일은 수정하지 않습니다.
- 드래그 앤 드롭 또는 파일 선택 버튼으로 처리할 수 있습니다.
- 저장 위치는 앱 안에서 바꿀 수 있습니다.
- 완료 후 저장 폴더를 자동으로 열 수 있습니다.
- 메뉴바와 Dock 둘 다에서 접근할 수 있습니다.

## 왜 ZIP만 만드냐

macOS 쪽 파일명은 내부적으로 분해형 유니코드(`NFD`)로 저장될 수 있고, 미천한 Windows 쪽은 보통 완성형(`NFC`) 또는 ZIP 내부의 UTF-8 파일명을 더 기대합니다.

단순히 파일명만 바꿔 복사하는 것보다, 전달용 ZIP을 새로 만드는 쪽이 실사용에서 더 안정적입니다. 그래서 이 앱은 전달용 ZIP만 생성합니다. 
더 묻지 마세요 뭔 수를 써도 안되더라고요, 혹시 다른 방법이 있다면 좀 알려줍사합니다.

## 요구 사항

- macOS 13 이상
- Apple Command Line Tools 또는 Swift 툴체인
- `python3`
- Pillow

Pillow가 없다면:

```bash
python3 -m pip install pillow
```

## 설치

### 소스에서 빌드

```bash
cd /path/to/HangulFixer
chmod +x build_app.sh
./build_app.sh
```

빌드가 끝나면 아래 앱이 생성됩니다.

```bash
./HangulFixer.app
```

### 첫 실행

로컬에서 만든 unsigned 앱이라 macOS 경고가 뜰 수 있습니다.

1. Finder에서 `HangulFixer.app` 우클릭
2. `열기`
3. 다시 한 번 `열기`

원하면 `/Applications` 또는 `~/Applications` 로 옮겨서 사용할 수 있습니다.

## 사용법

### 기본 흐름

1. 앱을 실행합니다
2. 파일/폴더를 창에 드롭하거나 `파일 선택`을 누릅니다
3. 저장 위치를 확인하거나 `변경`으로 수정합니다
4. 처리 후 생성된 ZIP을 Windows 쪽에 전달합니다

### 저장 위치 변경

메인 창의 `변경` 버튼이나 메뉴바 메뉴의 `저장 위치 변경`을 사용하면 됩니다.


## 주의 사항

- macOS 터미널에서 파일명이 여전히 분해형처럼 보일 수 있습니다
- 중요한 것은 Windows에 전달되는 최종 ZIP 내부 엔트리 이름입니다
- 앱은 현재 코드서명 및 notarization이 되어 있지 않습니다

## 프로젝트 구조

```text
HangulFixer/
├── .gitignore
├── Sources/
│   └── HangulFixer.swift
├── Resources/
│   ├── Info.plist
│   └── zip_utf8.py
├── icon.png
├── build_app.sh
├── README.md
└── GITHUB_TEXT.md
```

## 개발 메모

- UI는 SwiftUI/AppKit 기반입니다
- ZIP 생성은 Python `zipfile` 을 사용합니다
- 앱 아이콘은 `icon.png` 를 바탕으로 빌드 시 둥근 모서리/투명 배경 형태로 다시 생성합니다.
- 어차피 한국사람만 이걸 쓸테니 한글로 작성합니다.
