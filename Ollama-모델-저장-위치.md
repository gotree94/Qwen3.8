# Ollama 모델 저장 위치 정리

> 작성일: 2026-09-12 | 대상 머신: `C:\Users\Administrator` | Ollama 버전: **0.34.0**
> 직접 확인한 로컬 구조 + 공식 문서를 기반으로 정리.

---

## 1. 결론 (TL;DR)

- `ollama run qwen3:8b` 로 받는 모델은 **`C:\Users\Administrator\.ollama\models`** 에 저장된다.
- `C:\Users\Administrator\AppData\Local\Programs\Ollama` 는 **바이너리(ollama.exe)와 로그만** 있는 설치 폴더다. 모델과 무관.
- 실제 가중치는 `models\blobs\` 에 `sha256-<해시>` 이름(콘텐츠 주소 방식)으로 저장되고, `models\manifests\registry.ollama.ai\library\<모델명>\<태그>` 매니페스트가 "태그 → blob 구성"을 알려준다.
- `OLLAMA_MODELS` 환경변수가 설정되어 있지 않으므로(머신/유저 레벨 모두 확인됨) **기본 경로를 사용 중**.

---

## 2. 설치 위치 vs 모델 위치

| 항목 | 경로 | 내용 |
|---|---|---|
| 바이너리/로그 | `%LOCALAPPDATA%\Programs\Ollama` | `ollama.exe`, 서버/앱/업그레이드 로그 |
| **모델 저장소** | `%USERPROFILE%\.ollama\models` | 실제 모델 가중치 + 매니페스트 |
| 구성/설정 | `%USERPROFILE%\.ollama` | `config.json`, `id_ed25519(.pub)` API 키, `history` |
| 임시 파일 | `%TEMP%\ollama*` | 런타임 임시 실행 파일 |

> 참고: `config.json` 은 현재 **존재하지 않음** — Ollama 설정(UI/CLI에서 변경)이 생긴 뒤에 생성된다.

---

## 3. 이 머신의 실제 모델 저장소 구조

```
C:\Users\Administrator\.ollama\
├── cache\
├── models\
│   ├── blobs\                          ← 실제 가중치 (18개 파일, 총 53.68 GB)
│   │   ├── sha256-3291abe7...          (19.3 GB)
│   │   ├── sha256-58574f2e...          (17.7 GB)
│   │   ├── sha256-a8cc1361...          ( 8.8 GB)
│   │   ├── sha256-a3de86cd...          ( 5.0 GB)
│   │   ├── sha256-3e4cb141...          ( 2.4 GB)
│   │   ├── sha256-3d0b7905...          ( 1.3 GB)
│   │   ├── sha256-7f403014...          (498 MB)
│   │   └── sha256-*  (11개, 0 B)       ← config/params/template/license 레이어
│   └── manifests\
│       └── registry.ollama.ai\
│           └── library\qwen3\
│               ├── 0.6b                ← 태그별 매니페스트(JSON, 확장자 없음)
│               ├── 1.7b
│               ├── 4b
│               ├── 8b
│               ├── 14b
│               ├── 30b
│               └── 32b
├── history, history.tmp
├── id_ed25519, id_ed25519.pub
└── config.json                         (아직 생성 안 됨)
```

- **`blobs/`**: 파일명이 `sha256-<해시>` 인 콘텐츠 주소 저장소. 동일 가중치 blob은 모델 간에 **공유/중복 제거**된다.
- **`manifests/`**: 경로 자체가 `registry / namespace / 모델명 / 태그` 구조. `<태그>` 파일이 그 모델을 구성하는 blob digest 목록을 담은 JSON.

---

## 4. 현재 받아둔 모델 (qwen3 변형 7종, 53.68 GB)

blob 크기 기반 매핑(정확한 digest는 manifest JSON으로 검증 가능):

| 모델 태그 | 대응 blob 크기 | 비고 |
|---|---|---|
| `qwen3:32b` | 19.3 GB | 가장 큰 blob |
| `qwen3:30b` | 17.7 GB | |
| `qwen3:14b` | 8.8 GB | |
| **`qwen3:8b`** | **5.0 GB** | 질문 시점 모델 |
| `qwen3:4b` | 2.4 GB | |
| `qwen3:1.7b` | 1.3 GB | |
| `qwen3:0.6b` | 498 MB | |

---

## 5. 저장 위치 변경 방법 (`OLLAMA_MODELS`)

기본 위치(`C:\Users\Administrator\.ollama\models`)에 용량이 부족하면 사용자 환경변수로 변경:

1. **설정(Windows 11) / 제어판(Windows 10)** → *환경 변수 편집* 검색
2. *사용자 계정의 환경 변수 편집* 실행
3. 새 변수 `OLLAMA_MODELS` → 원하는 경로(예: `D:\Ollama\Models`) 지정
4. Ollama 재시작 후 모델이 새 경로로 저장됨

> 주의: 기존 모델을 옮기려면 Ollama 종료 후 `models` 폴더를 통째로 이동해야 하며,
> 링크 방식(`mklink /D`)을 쓰면 드라이브 이동 없이 우회할 수도 있다.

---

## 6. OS별 기본 모델 경로 (공식 FAQ 기준)

| OS | 기본 경로 |
|---|---|
| Windows | `C:\Users\%username%\.ollama\models` |
| macOS | `~/.ollama/models` |
| Linux | `/usr/share/ollama/.ollama/models` |

---

## 7. 출처

- Ollama 공식 FAQ — *Where are models stored?*: <https://docs.ollama.com/faq>
- Ollama 공식 Windows 문서 — *Changing Model Location*: <https://docs.ollama.com/windows>
- 소스 문서: `ollama/ollama` → `docs/faq.mdx`, `docs/windows.mdx`
- GitHub Issue #2551 — *Can we change where the models are stored in windows*: <https://github.com/ollama/ollama/issues/2551>