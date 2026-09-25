# Windows 모델 다운로드 스크립트

`D:\github\Qwen3.8`의 Linux 셸 스크립트(`.sh`) 4개를 **Windows PowerShell**에서 실행할 수 있도록 변환한 버전입니다.

## 파일 목록

| 파일 | 대상 모델 | 총 용량 | 원본 sh |
|------|-----------|---------|---------|
| `download_all_qwen3.ps1` | Qwen3 전체 (0.6B~30B-A3B) 7개 GGUF | ~53GB | `download_all_qwen3.sh` |
| `download_general_llms.ps1` | 범용 LLM (Qwen3.6 27B, DeepSeek-R1, Coder 등) 9개 | ~120-140GB | `download_general_llms.sh` |
| `download_korean_llms.ps1` | 한국 LLM (HyperCLOVA X, EXAONE, SOLAR 등) 10개 | ~120GB | `download_korean_llms.sh` |
| `download_semiconductor_ai.ps1` | 반도체 AI (RTLCoder, VeriGen) 4개 + EDA 툴체인 | ~50GB | `download_semiconductor_ai.sh` |
| `run_all.ps1` | 위 4개를 순서대로 실행 | ~350GB+ | - |

## 실행 방법

### 1) PowerShell 열기

시작 메뉴 → **PowerShell** 검색 → 실행 (관리자 권한 **불필요**)

### 2) 폴더로 이동 후 실행

```powershell
cd D:\github\Qwen3.8\windows
```

스크립트 실행 차단 오류(`running scripts is disabled`)가 나오면:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

그 후 원하는 스크립트 실행:

```powershell
.\download_all_qwen3.ps1        # Qwen3 전체만
.\download_general_llms.ps1     # 범용 LLM만
.\download_korean_llms.ps1      # 한국 LLM만
.\download_semiconductor_ai.ps1 # 반도체 AI만
.\run_all.ps1                   # 전부 다운로드 (약 350GB+, 신중히!)
```

### 3) 필요 도구 (자동 설치됨)

- **aria2c**: 16중 연결로 최대 5~8배 빠른 다운로드 도구.
  스크립트가 자동으로 `winget install aria2.aria2`를 시도합니다.
  설치 실패 시 https://github.com/aria2/aria2/releases 에서
  `aria2-*-win-64bit-build1.zip`을 받아 PATH에 추가하세요.

## 다운로드 위치 (바탕화면)

```
바탕화면\
├── qwen3-all-models\     ← download_all_qwen3.ps1
├── general-llms\         ← download_general_llms.ps1
├── korean-llms\          ← download_korean_llms.ps1
└── semiconductor-ai\     ← download_semiconductor_ai.ps1
    └── oss-cad-suite\    ← EDA 툴체인 (Windows용 .tgz, 아래 개선점 3 참고)
```

> 참고: 원본 sh는 `~/Desktop`에 저장하므로, Windows에서는 실제 바탕화면 경로
> (`[Environment]::GetFolderPath('Desktop')`)에 저장합니다.

## 원본 sh 대비 개선점

1. **safetensors 멀티샤드 전체 다운로드**: 원본 `download_korean_llms.sh`와
   `download_semiconductor_ai.sh`는 각 모델의 **첫 번째 shard만** 받아 모델이
   완성되지 않는 문제가 있었습니다. Windows 버전은 `model-00001-of-0000N` ~
   `model-0000N-of-0000N` **전체 shard**를 받습니다.
2. **이어받기 지원**: 중단된 다운로드를 다시 실행하면 이어서 받습니다
   (aria2c `-c` 옵션 + 1MB 초과 파일 건너뛰기).
3. **EDA 툴체인 Windows 안내**: Linux `apt` 설치 대신
   **OSS CAD Suite Windows 버전**(yosys/verilator/gtkwave 포함)을 다운로드합니다.
   버전 정보는 GitHub API로 실시간 조회하며, 받은 `.tgz`는 PowerShell에서
   `tar -xzf oss-cad-suite-windows-x64-*.tgz`로 풀고
   `oss-cad-suite\environment.bat`를 실행하면 사용할 수 있습니다.
   Icarus Verilog, Docker Desktop(OpenLane용) 설치 안내도 함께 표시됩니다.
4. **한국어 콘솔 표시**: PowerShell 5.1이 한글을 정확히 표시하도록
   UTF-8 BOM으로 저장되어 있습니다.
5. **저장소 실시간 검증**: 다운로드 전 HF API로 실제 파일 목록을 조회해
   shard 개수·파일명을 자동 감지합니다. 하드코딩된 URL/shard 수가
   저장소와 어긋나면 그 모델은 `[건너뜀]` 처리하고 안내합니다.
6. **ChipNeMo 제외**: 원본 sh에 있던 `gallilabs/ChipNeMo-13B`는 존재하지 않는
   공개 저장소라 스크립트에서 제외하고, 공개 모델(RTLCoder 2종, VeriGen 6B/16B)만
   받도록 정리했습니다.

## ⚠️ 라이선스 주의

- **EXAONE 시리즈** (3.5 / 4.0 / 4.5): **비상업용(NC)** — 개인/연구용만 사용
- HyperCLOVA X SEED: 상업 무제한 ✅
- SOLAR 10.7B: Apache 2.0 ✅
- 범용 LLM: Apache 2.0 / MIT / Llama 3.1 / Gemma Terms (각각 조건 확인)

## FAQ

**Q1. "이 시스템에서 스크립트를 실행할 수 없습니다" 오류?**
```powershell
Set-ExecutionPolicy -Scope Process Bypass
```
또는 `powershell -ExecutionPolicy Bypass -File .\download_all_qwen3.ps1`

**Q2. aria2 설치가 자동으로 안 되나요?**
`winget`이 없거나 설치가 실패하면 수동으로 받으세요:
https://github.com/aria2/aria2/releases → `aria2-*-win-64bit-build1.zip`
압축 풀고 `aria2c.exe`가 있는 폴더를 환경변수 PATH에 추가.

**Q3. 다운로드가 중간에 끊겼어요.**
같은 스크립트를 다시 실행하세요. aria2c가 이어받기(`-c`)를 수행합니다.

**Q4. 한국어가 깨져 보여요.**
스크립트는 UTF-8 BOM으로 저장되어 있어 PowerShell 5.1에서 정상 표시됩니다.
그래도 깨지면 콘솔 폰트를 '맑은 고딕' 등 한글 지원 폰트로 바꿔보세요.