# GitHub 업로드용 메모

## 짧은 설명

macOS에서 만든 한글 파일명 깨짐 문제를 줄이기 위한 앱입니다. 파일/폴더 이름을 NFC 기준으로 정규화해서 Windows 전달용 ZIP으로 만들어줍니다.

## 저장소 설명 한 줄

macOS app that converts Korean filenames into Windows-friendly ZIP archives.

## README 첫 문단 후보

HangulFixer is a macOS app that helps reduce Korean filename corruption when transferring files from macOS to Windows. It normalizes file and folder names to NFC and creates delivery-ready ZIP archives with UTF-8/NFC entry names.

## GitHub repo About 문구 후보

- Create Windows-friendly ZIP files from macOS Korean filenames
- Normalize Hangul filenames to NFC before packaging
- SwiftUI macOS utility for Korean filename compatibility

## 태그 후보

- macos
- swiftui
- unicode
- korean
- hangul
- zip
- filename
- windows

## 릴리즈 노트 초안

### v0.1.0

- Added drag and drop file/folder processing
- Added ZIP-only export flow for Windows delivery
- Added configurable output directory
- Added Finder `Open With` support
- Added menu bar and Dock access
- Added custom app icon pipeline from `icon.png`

## 업로드 순서 예시

```bash
cd /path/to/HangulFixer
git init
git add .
git commit -m "Initial commit: Hangul filename fixer"
```
