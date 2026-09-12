# Qwen3 로컬 설치 가이드

> **생성일:** 2026-09-07  
> **최종 업데이트:** 2026-09-12  
> **대상 시스템:** Ubuntu 22.04 LTS | RTX 5090 24GB | 64GB RAM | 24 Cores

---

## 목차

| 섹션 | 내용 |
|------|------|
| [1. 시스템 환경 요약](#1-시스템-환경-요약) | 하드웨어/소프트웨어 확인 |
| [2. Qwen3란?](#2-qwen3란) | 모델 소개 |
| [3. Qwen3 전체 모델 라인업](#3-qwen3-전체-모델-라인업) | 0.6B~235B 전체 목록 |
| [4. Qwen3 공통 기능](#4-qwen3-공통-기능) | Think, 도구호출 등 |
| [5. 설치 방법](#5-설치-방법-4가지-경로) | Ollama, vLLM, Transformers, llama.cpp |
| [6. 설치 방법 비교](#6-설치-방법-비교) | 4가지 방법 비교표 |
| [7. 추천 양자화 가이드](#7-추천-양자화-quantization-가이드) | BF16~Q4 선택 |
| [8. Think 모드](#8-think-모드-추론-모드-사용법) | 추론 모드 활용 |
| [9. 검증 및 테스트](#9-검증-및-테스트) | 동작 확인 |
| [10. 문제 해결](#10-문제-해결-트러블슈팅) | DNS, 404, 속도 문제 |
| [11. 유용한 명령어](#11-유용한-명령어-모음) | Ollama/vLLM/GPU |
| [12. Qwen3 전체 모델 다운로드](#12-qwen3-전체-모델-다운로드) | 7개 모델 53GB |
| [13. 추가 모델 다운로드 스크립트](#13-추가-모델-다운로드-스크립트) | 한국 LLM, 범용 LLM, 반도체 AI |
| [14. 디렉토리 구조](#14-디렉토리-구조-권장) | 폴더 배치 |
| [15. 빠른 시작](#15-빠른-시작) | 3줄 요약 |

---

## 1. 시스템 환경 요약

| 항목 | 현재 상태 | 권장 사항 | 판정 |
|------|-----------|-----------|------|
| OS | Ubuntu 22.04.5 LTS | Ubuntu 22.04+ | ✅ |
| GPU | NVIDIA RTX 5090 24GB (CUDA 13.0) | 8GB+ VRAM | ✅ 여유 |
| RAM | 62GB | 16GB+ | ✅ 여유 |
| CPU | 24 cores | 4+ cores | ✅ 여유 |
| 디스크 | 2.5TB 사용 가능 | 20GB+ | ✅ 여유 |
| Python | 3.10.12 / 3.13.2 | 3.9+ | ✅ |
| NVIDIA Driver | 580.159.04 | 535+ | ✅ |

> **결론:** 하드웨어가 매우 여유롭습니다. RTX 5090 24GB에서는 BF16(전정밀도)으로도 실행 가능하며, 양자화 없이도 ~150-180 tok/s 예상됩니다.

---

## 2. Qwen3란?

Qwen3는 Alibaba Qwen 팀이 개발한 오픈소스 대규모 언어 모델 패밀리입니다.  
36조 개의 토큰으로 학습되었으며, 119개 언어를 지원합니다.

- **라이선스:** Apache 2.0 (상업적 사용 가능)
- **특징:** Think/No-Think 하이브리드 추론 모드 (모든 모델 공통)
- **컨텍스트:** 32K~128K 토큰 지원

---

## 3. Qwen3 전체 모델 라인업

### 3.1 Dense (밀집) 모델

| 모델 | 파라미터 수 | 컨텍스트 | Q4 VRAM | BF16 VRAM | Ollama 명령어 | 추천 용도 |
|------|-------------|----------|---------|-----------|---------------|-----------|
| **Qwen3-0.6B** | 0.6B | 32K | ~1GB | ~1.2GB | `ollama run qwen3:0.6b` | 엣지/IoT, 라즈베리파이 |
| **Qwen3-1.7B** | 1.7B | 32K | ~1.5GB | ~3.4GB | `ollama run qwen3:1.7b` | 모바일, 빠른 프로토타입 |
| **Qwen3-4B** | 4B | 128K | ~3GB | ~8GB | `ollama run qwen3:4b` | 소비자 GPU, 가벼운 에이전트 |
| **Qwen3-8B** | 8.2B | 128K | ~5-6GB | ~16GB | `ollama run qwen3:8b` | 개발 워크스테이션 (추천) |
| **Qwen3-14B** | 14B | 128K | ~10GB | ~28GB | `ollama run qwen3:14b` | 중급 서버, 고품질 추론 |
| **Qwen3-32B** | 32.8B | 128K | ~20GB | ~64GB | `ollama run qwen3:32b` | 고성능 서버, 크리에이티브 |

### 3.2 MoE (혼합 전문가) 모델

| 모델 | 총 파라미터 | 활성 파라미터 | 컨텍스트 | Q4 VRAM | Ollama 명령어 | 추천 용도 |
|------|-------------|---------------|----------|---------|---------------|-----------|
| **Qwen3-30B-A3B** | 30.5B | ~3.3B | 128K | ~20GB | `ollama run qwen3:30b-a3b` | 빠른 추론, 30B급 품질 |
| **Qwen3-235B-A22B** | 235B | ~22B | 128K | ~120GB+ | `ollama run qwen3:235b-a22b` | 오픈소스 플래그십 |

### 3.3 2507 업데이트 모델 (2025년 7월)

일정 크기에 대해 성능이 개선된 2507 버전이 출시되었습니다:

| 모델 | 변형 | 특징 |
|------|------|------|
| Qwen3-4B-Thinking-2507 | Think 모드 특화 | AIME25에서 81.3점 (Qwen2.5-72B 수준) |
| Qwen3-30B-A3B-2507 | MoE 개선版 | 더 정확한 추론 |
| Qwen3-235B-A22B-2507 | 플래그십 개선版 | 벤치마크 전체 상향 |

> **팁:** 2507 버전이 존재하는 모델은 반드시 2507 버전을 사용하세요.

### 3.4 하드웨어별 추천 모델

| GPU / 환경 | 추천 모델 | Q4 시 예상 속도 |
|------------|-----------|-----------------|
| **CPU only (16GB RAM)** | Qwen3-4B Q4 | 5-8 tok/s |
| **GTX 1660 / 6GB VRAM** | Qwen3-1.7B | 30-45 tok/s |
| **RTX 3060 12GB** | Qwen3-8B Q4 | 25-35 tok/s |
| **RTX 3090 / 4080 16GB+** | Qwen3-14B Q4 | 20-30 tok/s |
| **RTX 4090 / 5090 24GB** | Qwen3-32B Q4 또는 Qwen3-8B BF16 | 15-25 tok/s / 150+ tok/s |
| **A100 40GB** | Qwen3-30B-A3B BF16 | 40-60 tok/s |
| **4x A100 80GB / H100** | Qwen3-235B-A22B | 10-20 tok/s |

### 3.5 RTX 5090 24GB에서 실행 가능한 모델

| 모델 | 양자화 | VRAM 사용 | 예상 성능 | 추천도 |
|------|--------|-----------|-----------|--------|
| Qwen3-8B | BF16 (전정밀도) | ~16GB | ~150-180 tok/s | ⭐⭐⭐ **최고 추천** |
| Qwen3-8B | Q4_K_M | ~5-6GB | ~100-130 tok/s | ⭐⭐ |
| Qwen3-14B | BF16 | ~28GB | 메모리 초과 | ❌ |
| Qwen3-14B | Q4_K_M | ~10GB | ~50-70 tok/s | ⭐⭐⭐ **추천** |
| Qwen3-32B | Q4_K_M | ~20GB | ~25-35 tok/s | ⭐⭐ 가능 |
| Qwen3-30B-A3B | Q4_K_M | ~20GB | ~30-45 tok/s | ⭐⭐ 가능 |

> **RTX 5090 24GB에서는 Qwen3-8B를 BF16으로 실행하는 것이 최고의 선택입니다.**  
> 더 높은 품질이 필요하면 Qwen3-14B Q4를, 더 빠른 속도가 필요하면 Qwen3-4B BF16을 고려하세요.

### 3.6 모델별 벤치마크 비교

| 모델 | MMLU-Redux | MATH-500 | Think 모드 품질 |
|------|------------|----------|-----------------|
| Qwen3-4B | 83.7 | 97.0 | 양호 |
| Qwen3-8B | 84.9 | 97.4 | 우수 |
| Qwen3-14B | 86.7 | 97.4 | 매우 우수 |
| Qwen3-32B | 87.8 | 97.4 | 최고 |
| Qwen3-235B-A22B | - | - | 플래그십 (DeepSeek-R1 상회) |

---

## 4. Qwen3 공통 기능

모든 Qwen3 모델(0.6B~235B)에 공통으로 적용되는 기능:

| 기능 | 0.6B / 1.7B | 4B~32B Dense | 30B-A3B / 235B-A22B MoE |
|------|-------------|--------------|-------------------------|
| Think 모드 | ✅ | ✅ | ✅ |
| 도구 호출 (Tool Calling) | ✅ | ✅ | ✅ |
| 컨텍스트 윈도우 | 32K | 128K | 128K |
| 언어 지원 | 119개 | 119개 | 119개 |
| JSON/구조화된 출력 | ✅ | ✅ | ✅ |
| 라이선스 | Apache 2.0 | Apache 2.0 | Apache 2.0 |

---

## 5. 설치 방법 (4가지 경로)

### 방법 1: Ollama (가장 간단, 5분)

```bash
# 1) Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 2) 설치 확인
ollama --version

# 3) Qwen3-8B 다운로드 및 실행 (Q4_K_M 양자화, ~5.2GB)
ollama run qwen3:8b

# 4) 테스트
>>> Hello, who are you?
```

**Ollama 태그 옵션:**
| 태그 | 크기 | 설명 |
|------|------|------|
| `qwen3:8b` | ~5.2GB | 기본 Q4_K_M 양자화 (권장) |
| `qwen3:8b-q8_0` | ~8.5GB | Q8 양자화 (더 정확) |
| `qwen3:8b-fp16` | ~16GB | 전정밀도 (최고 품질) |

**API 서버로 실행:**
```bash
ollama serve
# 기본 포트: http://localhost:11434
curl http://localhost:11434/api/chat -d '{
  "model": "qwen3:8b",
  "messages": [{"role": "user", "content": "Hello!"}]
}'
```

---

### 방법 2: vLLM (프로덕션 서빙, OpenAI 호환 API)

```bash
# 1) 가상환경 생성
python3.10 -m venv ~/qwen3-env
source ~/qwen3-env/bin/activate

# 2) PyTorch + CUDA 설치 (이미 설치되어 있지 않은 경우)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# 3) vLLM 설치
pip install "vllm>=0.9.0"

# 4) vLLM 서버 시작 (OpenAI 호환 API)
vllm serve Qwen/Qwen3-8B --host 0.0.0.0 --port 8000

# 5) 테스트 (다른 터미널에서)
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-8B",
    "messages": [{"role": "user", "content": "안녕하세요!"}],
    "temperature": 0.6,
    "top_p": 0.95,
    "max_tokens": 512
  }'
```

> **참고:** RTX 5090 24GB에서는 BF16으로 전체 모델을 GPU에 올릴 수 있습니다.

---

### 방법 3: HuggingFace Transformers (개발용)

```bash
# 1) 가상환경 생성
python3.10 -m venv ~/qwen3-env
source ~/qwen3-env/bin/activate

# 2) 필수 패키지 설치
pip install --upgrade transformers>=4.51.0 accelerate torch

# 3) Python 스크립트로 실행
```

```python
# test_qwen3.py
from transformers import AutoModelForCausalLM, AutoTokenizer

model_name = "Qwen/Qwen3-8B"

# 토크나이저 및 모델 로드
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",        # GPU 자동 감지
    torch_dtype="auto",       # 자동 타입 선택
)

# 대화 템플릿 적용
messages = [
    {"role": "user", "content": "대한민국의 수도는 어디인가요?"}
]
inputs = tokenizer.apply_chat_template(
    messages,
    add_generation_prompt=True,
    tokenize=True,
    return_dict=True,
    return_tensors="pt",
).to(model.device)

# 텍스트 생성
outputs = model.generate(
    **inputs,
    max_new_tokens=256,
    temperature=0.7,
    top_p=0.9,
)
response = tokenizer.decode(outputs[0][inputs["input_ids"].shape[-1]:], skip_special_tokens=True)
print(response)
```

```bash
python test_qwen3.py
```

---

### 방법 4: llama.cpp (GGUF 양자화 모델)

```bash
# 1) llama.cpp 빌드
cd ~/Desktop
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# 2) 빌드 (CUDA 지원)
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)

# 3) Qwen3-8B GGUF 다운로드 (HuggingFace에서)
# https://huggingface.co/Qwen/Qwen3-8B-GGUF 에서 다운로드
# 또는 Ollama에서 추출:
ollama pull qwen3:8b
ollama cp qwen3:8b qwen3-8b-backup

# 직접 다운로드 시:
pip install huggingface-hub
huggingface-cli download Qwen/Qwen3-8B-GGUF --include "*.gguf" --local-dir ~/Desktop/qwen3-8b-gguf

# 4) 실행
./build/bin/llama-cli -m ~/Desktop/qwen3-8b-gguf/Qwen3-8B-Q4_K_M.gguf \
  -p "안녕하세요!" \
  -n 256 \
  -ngl 99 \          # GPU 레이어 수 (전부 GPU로)
  --temp 0.7 \
  --top-p 0.9

# 5) API 서버로 실행
./build/bin/llama-server -m ~/Desktop/qwen3-8b-gguf/Qwen3-8B-Q4_K_M.gguf \
  --host 0.0.0.0 --port 8080 \
  -ngl 99 \
  -c 32768
```

---

### 5.1 빠른 다운로드 방법 (25Mbps 제한적 네트워크 환경)

> **인터넷 속도 25Mbps = 약 3.12 MB/s 기준**

#### 다운로드 소요 시간 비교

| 방법 | 파일 크기 | 소요 시간 | 안정성 | 중단 후 재개 |
|------|-----------|-----------|--------|-------------|
| Ollama (단일 연결) | 5.2GB | 약 28분 | ⭐⭐⭐ | ✅ 자동 |
| **aria2 (16 연결)** | **5.0GB** | **약 3-5분** | **⭐⭐⭐** | **✅ 자동** |
| wget (단일 연결) | 5.0GB | 약 28분 | ⭐⭐ | 수동 |
| vLLM BF16 (전체 모델) | 16.3GB | 약 1시간 29분 | ⭐⭐ | 모델이 너무 큼 |

> **결론: aria2 + HuggingFace 다중 연결 다운로드가 5~8배 빠름**

####Step 1: aria2 설치

```bash
sudo apt update && sudo apt install -y aria2
```

#### Step 2: GGUF 모델 다운로드 (Q4_K_M, ~5GB)

**방법 A: HuggingFace 직접 다운로드 (추천)**
```bash
mkdir -p ~/Desktop/qwen3-8b-gguf

aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-8b-gguf \
  -o "Qwen3-8B-Q4_K_M.gguf" \
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

**방법 B: HuggingFace 미러 사이트 (아시아에서 더 빠름)**
```bash
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-8b-gguf \
  -o "Qwen3-8B-Q4_K_M.gguf" \
  "https://hf-mirror.com/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

**방법 C: BF16 전체 모델 다운로드 (~16GB, 약 1시간 29분)**
```bash
mkdir -p ~/Desktop/qwen3-8b-model

aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-8b-model \
  -o "Qwen3-8B-00001-of-00004.safetensors" \
  "https://huggingface.co/Qwen/Qwen3-8B/resolve/main/model-00001-of-00004.safetensors"
```

#### aria2 옵션 설명

| 옵션 | 의미 |
|------|------|
| `-x 16` | 최대 16개 연결 동시 다운로드 |
| `-s 16` | 파일을 16개 조각으로 분할 |
| `-k 1M` | 조각당 1MB 캐시 (재시작 시 활용) |
| `-d <경로>` | 저장 디렉토리 지정 |

#### 다운로드 후 llama.cpp로 실행

```bash
# llama.cpp 빌드 (이미 있다면 건너뛰기)
cd ~/Desktop
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)

# 다운로드 받은 GGUF로 실행
./build/bin/llama-cli \
  -m ~/Desktop/qwen3-8b-gguf/Qwen3-8B-Q4_K_M.gguf \
  -p "안녕하세요!" \
  -n 256 \
  -ngl 99 \
  --temp 0.7 \
  --top-p 0.9
```

#### 다운로드 진행 상황 확인

```bash
# 다운로드 중 파일 크기 확인
ls -lh ~/Desktop/qwen3-8b-gguf/

# 다운로드 프로세스 확인
ps aux | grep aria2c
```

---

### 5.2 윈도우 다운로드 방법

> **Windows 10/11 환경에서 Qwen3-8B 다운로드**

#### 방법 A: Ollama (가장 간단)

```powershell
# 1) Ollama 설치
# https://ollama.com/download/windows 에서 설치 파일 다운로드
# 또는 PowerShell에서:
winget install Ollama.Ollama

# 2) 터미널 재시작 후 실행
ollama run qwen3:8b
```

#### 방법 B: aria2로 빠른 다운로드 (16 연결)

```powershell
# 1) aria2 설치 (winget 사용)
winget install aria2.aria2

# 또는 Scoop 사용:
scoop install aria2

# 또는 수동 다운로드:
# https://github.com/aria2/aria2/releases 에서 aria2-*-win-64bit-build1.zip 다운로드
# 압축 해제 후 C:\Program Files\aria2 에 복사
# 시스템 PATH에 추가

# 2) 설치 확인
aria2c --version

# 3) 다운로드 (PowerShell)
mkdir C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf

aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf `
  -o "Qwen3-8B-Q4_K_M.gguf" `
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

#### 방법 C: HuggingFace CLI (Python 필요)

```powershell
# 1) Python 설치 (이미 있다면 건너뛰기)
winget install Python.Python.3.11

# 2) HuggingFace CLI 설치
pip install huggingface-hub

# 3) 모델 다운로드 (이어받기 지원)
huggingface-cli download Qwen/Qwen3-8B --local-dir C:\Users\$env:USERNAME\Desktop\qwen3-8b-model
```

#### 방법 D: PowerShell Invoke-WebRequest (기본 도구)

```powershell
# PowerShell 5.0+ 내장 다운로드 (단일 연결, 느림)
$url = "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
$output = "C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf\Qwen3-8B-Q4_K_M.gguf"

Invoke-WebRequest -Uri $url -OutFile $output
```

#### 윈도우에서 Ollama 모델 위치 확인

```powershell
# 설치된 모델 목록
ollama list

# 모델 파일 위치 (기본값)
# C:\Users\<사용자名>\.ollama\models\

# 디스크 사용량 확인
du -sh C:\Users\$env:USERNAME\.ollama\models\
```

#### 윈도우에서 llama.cpp 실행

```powershell
# 1) llama.cpp 다운로드 (이미 빌드된 바이너리)
# https://github.com/ggerganov/llama.cpp/releases 에서
# llama.cpp-bin-windows-x64.zip 다운로드

# 2) 압축 해제 후 실행
.\llama-cli.exe -m C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf\Qwen3-8B-Q4_K_M.gguf -p "안녕하세요!" -n 256 -ngl 99

# 3) API 서버로 실행
.\llama-server.exe -m C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf\Qwen3-8B-Q4_K_M.gguf --host 0.0.0.0 --port 8080 -ngl 99
```

#### 윈도우 vs 리눅스 다운로드 속도 비교

| 환경 | 방법 | 5GB 다운로드 시간 |
|------|------|-------------------|
| Windows | Ollama (단일 연결) | 약 28분 |
| Windows | **aria2 (16 연결)** | **약 3-5분** |
| Windows | HuggingFace CLI | 약 28분 |
| Linux | Ollama (단일 연결) | 약 28분 |
| Linux | **aria2 (16 연결)** | **약 3-5분** |

> **팁:** 윈도우에서도 aria2가 가장 빠르습니다. `winget install aria2.aria2`로 간편 설치 가능합니다.

---

## 6. 설치 방법 비교

| 항목 | Ollama | vLLM | Transformers | llama.cpp |
|------|--------|------|--------------|-----------|
| **설치 난이도** | ⭐ 매우 쉬움 | ⭐⭐ 보통 | ⭐⭐ 보통 | ⭐⭐⭐ 어려움 |
| **시작 시간** | 5분 | 15분 | 15분 | 30분+ |
| **API 서버** | ✅ 내장 | ✅ OpenAI 호환 | ❌ 별도 구현 | ✅ 내장 |
| **양자화 선택** | 태그로 선택 | 자동 | 자동 | 자유도 높음 |
| **GPU 활용도** | 우수 | 최적 | 우수 | 우수 |
| **프로덕션** | 적합 | 최적 | 개발용 | 적합 |
| **추천 대상** | 초보자/개인 | 서버/서비스 | 연구/개발 | 고급 사용자 |

---

## 7. 추천 양자화 (Quantization) 가이드

RTX 5090 24GB 기준:

| 양자화 | VRAM 사용 | 속도 | 품질 | 추천 |
|--------|-----------|------|------|------|
| **BF16 (FP16)** | ~16GB | 최고 | 최고 | ✅ **추천** (24GB이므로 여유) |
| **Q8_0** | ~9GB | 빠름 | 매우 높음 | 좋음 |
| **Q6_K** | ~7GB | 빠름 | 높음 | 좋음 |
| **Q4_K_M** | ~5GB | 매우 빠름 | 양호 | 기본값 |
| **Q4_K_S** | ~5GB | 매우 빠름 | 보통 | RAM 부족 시 |

> **RTX 5090 24GB에서는 양자화 없이 BF16으로 실행하는 것을 권장합니다.**

---

## 8. Think 모드 (추론 모드) 사용법

Qwen3-8B는 추론(Chain-of-Thought) 모드를 지원합니다:

```
# Think 모드 활성화 (복잡한 수학, 코딩 문제용)
/think
1 + 1은 얼마인가요? 내 풀이 과정을 보여주세요.

# No-Think 모드 (빠른 일반 대화용)
/no_think
서울 날씨 알려줘.
```

**Python에서 제어:**
```python
# Think 모드
messages = [
    {"role": "user", "content": "<think>\n1 + 1은?\n</think>\n답변해줘."}
]

# No-Think 모드
messages = [
    {"role": "user", "content": "/no_think 서울 날씨 알려줘."}
]
```

> **중요:** Think 모드에서는 반드시 `temperature=0.6, top_p=0.95, top_k=20`을 사용하세요.  
> Greedy decoding(temperature=0)은 Think 모드에서 무한 루프에 빠질 수 있습니다.

---

## 9. 검증 및 테스트

### 9.1 기본 동작 확인

```bash
# Ollama 설치 확인
ollama list
# qwen3:8b  should be listed

# vLLM 헬스 체크
curl http://localhost:8000/health

# GPU 사용량 확인 (별도 터미널)
watch -n 1 nvidia-smi
```

### 9.2 프롬프트 테스트

```bash
# Ollama 테스트
ollama run qwen3:8b "Python에서 리스트를 뒤집는 3가지 방법을 알려줘."

# vLLM 테스트
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-8B",
    "messages": [
      {"role": "system", "content": "당신은 한국어에 능통한 AI 어시스턴트입니다."},
      {"role": "user", "content": "피보나치 수열의 10번째 값을 Python 코드로 구해줘."}
    ],
    "temperature": 0.6,
    "top_p": 0.95,
    "max_tokens": 1024
  }'
```

### 9.3 성능 벤치마크

```bash
# RTX 5090에서 예상 성능 (참고용)
# BF16: ~150-180 tok/s
# Q4_K_M: ~100-130 tok/s

# 실제로 측정하려면 vLLM 벤치마크 사용
pip install vllm-benchmark
python -m vllm.entrypoints.benchmark \
  --model Qwen/Qwen3-8B \
  --num-prompts 100 \
  --input-len 512 \
  --output-len 256
```

---

## 10. 문제 해결 (트러블슈팅)

### 10.1 DNS 오류 (가장 흔한 문제)

```bash
# 증상: dial tcp: lookup registry.ollama.ai: i/o timeout
# 원인: 로컬 DNS 서버(127.0.0.53) 미응답

# 해결 방법 1: Google DNS 추가
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'

# 해결 방법 2: systemd-resolved 재시작
sudo systemctl restart systemd-resolved

# 해결 방법 3: 영구적 DNS 설정
sudo bash -c 'echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > /etc/resolv.conf'

# DNS 테스트
nslookup huggingface.co 8.8.8.8
nslookup registry.ollama.ai 8.8.8.8
```

### 10.2 aria2 "Resource not found" 오류 (404)

```bash
# 원인: 파일명 대소문자 오류
# 잘못된 예: qwen3-8b-q4_k_m.gguf
# 올바른 예: Qwen3-8B-Q4_K_M.gguf

# 파일명 확인 방법
curl -s "https://huggingface.co/api/models/Qwen/Qwen3-8B-GGUF/tree/main" | \
  python3 -c "import sys,json; [print(f['path']) for f in json.load(sys.stdin) if 'Q4' in f['path']]"
```

### 10.3 다운로드 속도 느림 (30KB/s 이하)

```bash
# 원인: 미국 CDN으로 리다이렉트됨
#해결: 미러 사이트 사용 또는 직접 다운로드

# 방법 1: 미러 사이트
aria2c -x 16 -s 16 -d ~/Desktop/qwen3-8b-gguf \
  "https://hf-mirror.com/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"

# 방법 2: aria2로 16 연결 사용 (기존 다운로드 이어받기)
aria2c -x 16 -s 16 -k 1M -c \
  -d ~/Desktop/qwen3-8b-gguf \
  -o "Qwen3-8B-Q4_K_M.gguf" \
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

### 10.4 CUDA 관련 오류

```bash
# CUDA 버전 확인
nvcc --version
nvidia-smi

# PyTorch CUDA 버전 확인
python3 -c "import torch; print(torch.cuda.is_available()); print(torch.version.cuda)"
```

### 10.5 Ollama 연결 오류

```bash
# Ollama 서비스 상태 확인
systemctl status ollama

# 로그 확인
journalctl -u ollama -f

# 수동 시작
ollama serve &
```

### 10.6 GPU 메모리 부족

```bash
# 현재 GPU 메모리 사용량 확인
nvidia-smi

# 다른 프로세스가 GPU를 사용 중이면 종료
# 또는 양자화를 더 작은 버전으로 변경:
# Q4_K_M -> Q4_K_S 또는 Q3_K_M
```

### 10.7 모델 다운로드 실패

```bash
# DNS 오류 해결 (Ollama, aria2 모두 적용)
# 로컬 DNS 서버가 응답하지 않을 때 Google DNS 사용
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'

# 또는 systemd-resolved 재시작
sudo systemctl restart systemd-resolved

# DNS 테스트
nslookup huggingface.co 8.8.8.8
```

```bash
# HuggingFace 캐시 확인
ls ~/.cache/huggingface/hub/

# 방법 1: HuggingFace CLI로 재다운로드 (이어받기 지원)
pip install huggingface-hub
huggingface-cli download Qwen/Qwen3-8B

# 방법 2: aria2로 빠른 재다운로드 (16 연결)
# 파일명은 반드시 대소문자 구분: Qwen3-8B-Q4_K_M.gguf
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-8b-gguf \
  -o "Qwen3-8B-Q4_K_M.gguf" \
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"

# 방법 3: 미러 사이트 시도
aria2c -x 16 -s 16 \
  -d ~/Desktop/qwen3-8b-gguf \
  "https://hf-mirror.com/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

---

## 11. 유용한 명령어 모음

```bash
# === Ollama ===
ollama list                    # 설치된 모델 목록
ollama show qwen3:8b           # 모델 정보
ollama rm qwen3:8b             # 모델 삭제
ollama cp qwen3:8b my-model    # 모델 복사

# === vLLM ===
# 서버 시작
vllm serve Qwen/Qwen3-8B --host 0.0.0.0 --port 8000 --max-model-len 131072

# === GPU 모니터링 ===
watch -n 1 nvidia-smi           # 실시간 GPU 사용량
nvidia-smi --query-gpu=memory.used,memory.total --format=csv  # 메모리만
```

---

## 12. Qwen3 전체 모델 다운로드

### 12.1 전체 모델 목록 및 크기 (25Mbps 기준)

| 모델 | 파일명 | 크기 | 예상 시간 |
|------|--------|------|-----------|
| Qwen3-0.6B | Qwen3-0.6B-Q8_0.gguf | 0.60GB | 약 3분 |
| Qwen3-1.7B | Qwen3-1.7B-Q8_0.gguf | 1.71GB | 약 9분 |
| Qwen3-4B | Qwen3-4B-Q4_K_M.gguf | 2.33GB | 약 13분 |
| **Qwen3-8B** | **Qwen3-8B-Q4_K_M.gguf** | **4.68GB** | **약 26분** |
| Qwen3-14B | Qwen3-14B-Q4_K_M.gguf | 8.38GB | 약 46분 |
| Qwen3-32B | Qwen3-32B-Q4_K_M.gguf | 18.40GB | 약 100분 |
| Qwen3-30B-A3B | Qwen3-30B-A3B-Q4_K_M.gguf | 17.28GB | 약 94분 |
| **합계** | | **53.38GB** | **약 4.9시간** |

> **참고:** Qwen3-0.6B, 1.7B는 Q4_K_M 양자화가 없어 Q8_0으로 다운로드됩니다.

### 12.2 자동 다운로드 스크립트

```bash
# 스크립트 실행 (전체 모델 자동 다운로드)
cd ~/Desktop
chmod +x download_all_qwen3.sh
./download_all_qwen3.sh
```

### 12.3 개별 모델 다운로드

```bash
# 저장 디렉토리 생성
mkdir -p ~/Desktop/qwen3-all-models

# Qwen3-0.6B
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf"

# Qwen3-1.7B
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  "https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q8_0.gguf"

# Qwen3-4B
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  "https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf"

# Qwen3-8B (이미 다운로드된 경우 건너뛰기)
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  -o "Qwen3-8B-Q4_K_M.gguf" \
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"

# Qwen3-14B
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  "https://huggingface.co/Qwen/Qwen3-14B-GGUF/resolve/main/Qwen3-14B-Q4_K_M.gguf"

# Qwen3-32B
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  "https://huggingface.co/Qwen/Qwen3-32B-GGUF/resolve/main/Qwen3-32B-Q4_K_M.gguf"

# Qwen3-30B-A3B (MoE)
aria2c -x 16 -s 16 -k 1M \
  -d ~/Desktop/qwen3-all-models \
  "https://huggingface.co/Qwen/Qwen3-30B-A3B-GGUF/resolve/main/Qwen3-30B-A3B-Q4_K_M.gguf"
```

### 12.4 윈도우 전체 다운로드

```powershell
# PowerShell에서 실행
mkdir C:\Users\$env:USERNAME\Desktop\qwen3-all-models

# Qwen3-0.6B
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-all-models `
  "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf"

# Qwen3-4B
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-all-models `
  "https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf"

# Qwen3-8B
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-all-models `
  -o "Qwen3-8B-Q4_K_M.gguf" `
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"

# Qwen3-14B
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-all-models `
  "https://huggingface.co/Qwen/Qwen3-14B-GGUF/resolve/main/Qwen3-14B-Q4_K_M.gguf"

# Qwen3-32B
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-all-models `
  "https://huggingface.co/Qwen/Qwen3-32B-GGUF/resolve/main/Qwen3-32B-Q4_K_M.gguf"

# Qwen3-30B-A3B
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-all-models `
  "https://huggingface.co/Qwen/Qwen3-30B-A3B-GGUF/resolve/main/Qwen3-30B-A3B-Q4_K_M.gguf"
```

### 12.5 다운로드 확인

```bash
# 파일 목록 확인
ls -lh ~/Desktop/qwen3-all-models/

# 총 사용량 확인
du -sh ~/Desktop/qwen3-all-models/

# 파일별 크기 검증
for f in ~/Desktop/qwen3-all-models/*.gguf; do
  echo "$(basename $f): $(du -h "$f" | cut -f1)"
done
```

### 12.6 다운로드 받은 모델로 llama.cpp 실행

```bash
# 모델별 실행 예시
./build/bin/llama-cli \
  -m ~/Desktop/qwen3-all-models/Qwen3-14B-Q4_K_M.gguf \
  -p "안녕하세요!" \
  -n 256 \
  -ngl 99 \
  --temp 0.7 \
  --top-p 0.9

# API 서버로 실행 (포트 지정 가능)
./build/bin/llama-server \
  -m ~/Desktop/qwen3-all-models/Qwen3-32B-Q4_K_M.gguf \
  --host 0.0.0.0 --port 8080 \
  -ngl 99 \
  -c 32768
```

---

## 13. 추가 모델 다운로드 스크립트

> **Qwen3 외에 다른 모델도 다운로드할 수 있는 스크립트들입니다.**

### 13.1 스크립트 목록

| 스크립트 | 대상 모델 | 총 용량 | 라이선스 |
|----------|-----------|---------|----------|
| `download_all_qwen3.sh` | Qwen3 전체 (0.6B~235B) | ~53GB | Apache 2.0 |
| `download_korean_llms.sh` | HyperCLOVA X, EXAONE, SOLAR, KORani, EEVE | ~120GB | 혼합 |
| `download_general_llms.sh` | Qwen3.6 27B, DeepSeek-R1 32B, Coder 32B 등 | ~120-140GB | 혼합 |
| `download_semiconductor_ai.sh` | RTLCoder, VeriGen, ChipNeMo + EDA 툴체인 | ~50GB | 오픈소스 |

### 13.2 한국(국내) 개발 LLM 다운로드

**스크립트:** `download_korean_llms.sh`

```bash
# 실행 방법
cd ~/Desktop/qwen
chmod +x download_korean_llms.sh
./download_korean_llms.sh
```

**포함된 모델:**

| 모델 | 크기 | 용도 | 라이선스 | 비고 |
|------|------|------|----------|------|
| HyperCLOVA X SEED Think 32B | ~19GB | 한국어 추론 최고 | 상업 무제한 ✅ | 24GB에 최적 |
| HyperCLOVA X SEED Think 14B | ~9GB | 경량 추론 | 상업 무제한 ✅ | 여유로운 구동 |
| HyperCLOVA X SEED Omni 8B | ~6GB | 다중모달 | 상업 무제한 ✅ | 텍스트+이미지+음성 |
| EXAONE 3.5 32B | ~19GB | 한국어+추론 | ⚠️ 비상업용 | LG AI연구원 |
| EXAONE 3.5 7.8B | ~5GB | 소형·빠른 배포 | ⚠️ 비상업용 | LG AI연구원 |
| EXAONE 4.0 32B | ~19GB | 한국 전문자격시험 | ⚠️ 비상업용 | LG AI연구원 |
| EXAONE 4.5 33B | ~20GB | 비전+언어 | ⚠️ 비상업용 | LG AI연구원 |
| SOLAR 10.7B | ~7GB | 소형·빠른 배포 | Apache 2.0 ✅ | Upstage |
| KORani 13B | ~8GB | 한국어 특화 | 오픈 웨이트 | 크래프톤 |
| EEVE-Korean 10.8B | ~7GB | 한국어 특화 | Apache 2.0 | |

> **⚠️ 주의:** EXAONE 시리즈는 **비상업용(NC)** 라이선스입니다. 개인/연구용으로만 사용하세요.

### 13.3 범용(일반) LLM 다운로드

**스크립트:** `download_general_llms.sh`

```bash
# 실행 방법
cd ~/Desktop/qwen
chmod +x download_general_llms.sh
./download_general_llms.sh
```

**포함된 모델:**

| 모델 | 크기 | 용도 | 라이선스 | 벤치마크 |
|------|------|------|----------|----------|
| Qwen3.6 27B | ~17-22GB | 24GB에서 최고 성능 | Apache 2.0 | SWE-bench 68.9% |
| DeepSeek-R1 32B | ~20GB | 최고 추론/사고사슬 | MIT | AIME 72.6% |
| Qwen 2.5 Coder 32B | ~20GB | 전문 코딩 | Apache 2.0 | HumanEval 92.7% |
| Qwen3 8B | ~5GB | 가벼운 기본 모델 | Apache 2.0 | - |
| Llama 3.1 8B | ~5GB | Meta의 검증된 기본 모델 | Llama 3.1 | - |
| Gemma 3 27B | ~16GB | Google 소스 모델파일 | Gemma Terms | - |
| DeepSeek-R1 14B | ~9GB | 경량 추론 | MIT | - |
| Qwen 2.5 14B | ~9GB | 다용도 | Apache 2.0 | - |
| Qwen3-Coder 30B | ~17-19GB | 에이전트 코딩 | Apache 2.0 | 256K 컨텍스트 |

### 13.4 반도체 설계 전용 AI 다운로드

**스크립트:** `download_semiconductor_ai.sh`

```bash
# 실행 방법
cd ~/Desktop/qwen
chmod +x download_semiconductor_ai.sh
./download_semiconductor_ai.sh
```

**포함된 모델:**

| 모델 | 크기 | 용도 | 라이선스 | 특징 |
|------|------|------|----------|------|
| RTLCoder-DeepSeek 6.7B | ~4GB | 자연어→Verilog | 완전 오픈소스 ✅ | GPT-3.5 능가·GPT-4급 |
| RTLCoder-Mistral 6.7B | ~4GB | Mistral 기반 Verilog | 완전 오픈소스 ✅ | - |
| VeriGen 7B | ~4GB | Verilog 코드 완성 | 오픈소스 ✅ | - |
| VeriGen 16B | ~30GB | 더 정확한 Verilog | 오픈소스 ✅ | - |
| ChipNeMo 13B | ~7GB | NVIDIA 반도체 설계 전용 | 오픈 (데이터 비공개) | - |

**EDA 툴체인 포함:**
- `iverilog`: Verilog 시뮬레이션
- `verilator`: 고속/시스템Verilog 시뮬레이션
- `gtkwave`: 파형 보기
- `yosys`: 논리합성
- `OpenLane`: RTL→GDSII 전체 자동흐름 (Docker)
- `OSS CAD Suite`: 종합 툴키트

### 13.5 라이선스 요약

| 라이선스 | 모델 | 상업 사용 |
|----------|------|-----------|
| Apache 2.0 | Qwen3 전체, Qwen3.6 27B, Qwen 2.5 Coder 32B, SOLAR 10.7B | ✅ 가능 |
| MIT | DeepSeek-R1 32B, DeepSeek-R1 14B | ✅ 가능 |
| Llama 3.1 | Llama 3.1 8B | ✅ 가능 (조건부) |
| Gemma Terms | Gemma 3 27B | ✅ 가능 (조건부) |
| 상업 무제한 | HyperCLOVA X SEED 시리즈 | ✅ 가능 |
| ⚠️ 비상업용 (NC) | EXAONE 시리즈 | ❌ 불가 (개인/연구용만) |
| 완전 오픈소스 | RTLCoder, VeriGen | ✅ 가능 |

```
/home/gotree94/Desktop/
├── README.md                          ← 이 파일
├── download_all_qwen3.sh              ← Qwen3 전체 다운로드 스크립트
├── download_korean_llms.sh            ← 한국 LLM 다운로드 스크립트
├── download_general_llms.sh           ← 범용 LLM 다운로드 스크립트
├── download_semiconductor_ai.sh       ← 반도체 설계 AI 다운로드 스크립트
├── qwen3-env/                         ← Python 가상환경 (방법 2, 3용)
├── llama.cpp/                         ← llama.cpp 소스 (방법 4용)
├── qwen3-8b-gguf/                     ← 개별 GGUF (방법 4용)
├── qwen3-all-models/                  ← Qwen3 전체 모델 GGUF
│   ├── Qwen3-0.6B-Q8_0.gguf          (0.60GB)
│   ├── Qwen3-1.7B-Q8_0.gguf          (1.71GB)
│   ├── Qwen3-4B-Q4_K_M.gguf          (2.33GB)
│   ├── Qwen3-8B-Q4_K_M.gguf          (4.68GB)
│   ├── Qwen3-14B-Q4_K_M.gguf         (8.38GB)
│   ├── Qwen3-32B-Q4_K_M.gguf         (18.40GB)
│   └── Qwen3-30B-A3B-Q4_K_M.gguf     (17.28GB)
├── korean-llms/                       ← 한국 LLM 모델
│   ├── hyperclova-x-seed-think-32b/  (HyperCLOVA X SEED Think 32B)
│   ├── hyperclova-x-seed-think-14b/  (HyperCLOVA X SEED Think 14B)
│   ├── hyperclova-x-seed-omni-8b/    (HyperCLOVA X SEED Omni 8B)
│   ├── exaone-3.5-32b/               (EXAONE 3.5 32B)
│   ├── exaone-3.5-7.8b/              (EXAONE 3.5 7.8B)
│   ├── exaone-4.0-32b/               (EXAONE 4.0 32B)
│   ├── exaone-4.5-33b/               (EXAONE 4.5 33B)
│   ├── solar-10.7b/                  (SOLAR 10.7B)
│   ├── korani-13b/                   (KORani 13B)
│   └── eeve-korean-10.8b/            (EEVE-Korean 10.8B)
├── general-llms/                      ← 범용 LLM 모델
│   ├── qwen3.6-27b/                  (Qwen3.6 27B)
│   ├── deepseek-r1-32b/              (DeepSeek-R1 32B)
│   ├── qwen2.5-coder-32b/            (Qwen 2.5 Coder 32B)
│   ├── qwen3-8b/                     (Qwen3 8B)
│   ├── llama3.1-8b/                  (Llama 3.1 8B)
│   ├── gemma3-27b/                   (Gemma 3 27B)
│   ├── deepseek-r1-14b/              (DeepSeek-R1 14B)
│   ├── qwen2.5-14b/                  (Qwen 2.5 14B)
│   └── qwen3-coder-30b/              (Qwen3-Coder 30B)
├── semiconductor-ai/                  ← 반도체 설계 AI 모델
│   ├── rtlcoder-deepseek-6.7b/       (RTLCoder-DeepSeek 6.7B)
│   ├── rtlcoder-mistral-6.7b/        (RTLCoder-Mistral 6.7B)
│   ├── verigen-7b/                    (VeriGen 7B)
│   ├── verigen-16b/                   (VeriGen 16B)
│   ├── chipnemo-13b/                  (ChipNeMo 13B)
│   └── oss-cad-suite/                (오픈소스 EDA 툴체인)
└── test_qwen3.py                      ← 테스트 스크립트 (방법 3용)
```

---

## 15. 빠른 시작

### 리눅스

```bash
# 방법 A: Ollama (가장 간단)
curl -fsSL https://ollama.com/install.sh | sh
ollama run qwen3:8b
```

```bash
# 방법 B: aria2 빠른 다운로드 (25Mbps 네트워크 추천)
sudo apt install -y aria2
mkdir -p ~/Desktop/qwen3-8b-gguf
aria2c -x 16 -s 16 -d ~/Desktop/qwen3-8b-gguf \
  -o "Qwen3-8B-Q4_K_M.gguf" \
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

```bash
# 방법 C: 전체 모델 자동 다운로드 스크립트
cd ~/Desktop/qwen
chmod +x download_all_qwen3.sh
./download_all_qwen3.sh
```

```bash
# 방법 D: 추가 모델 다운로드 (한국 LLM, 범용 LLM, 반도체 AI)
cd ~/Desktop/qwen
chmod +x download_korean_llms.sh download_general_llms.sh download_semiconductor_ai.sh
./download_korean_llms.sh      # 한국 LLM (HyperCLOVA X, EXAONE, SOLAR 등)
./download_general_llms.sh     # 범용 LLM (Qwen3.6 27B, DeepSeek-R1 32B 등)
./download_semiconductor_ai.sh # 반도체 설계 AI (RTLCoder, VeriGen 등)
```

### 윈도우

```powershell
# 방법 A: Ollama (가장 간단)
winget install Ollama.Ollama
ollama run qwen3:8b
```

```powershell
# 방법 B: aria2 빠른 다운로드 (16 연결)
winget install aria2.aria2
mkdir C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf
aria2c -x 16 -s 16 -k 1M `
  -d C:\Users\$env:USERNAME\Desktop\qwen3-8b-gguf `
  -o "Qwen3-8B-Q4_K_M.gguf" `
  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
```

```bash
# 방법 C: 프로덕션 API 서버 (vLLM, 리눅스만)
pip install "vllm>=0.9.0"
vllm serve Qwen/Qwen3-8B
```

---

## 참고 자료

### 공식 문서
- [Qwen3 GitHub](https://github.com/QwenLM/Qwen3)
- [Qwen3-8B HuggingFace](https://huggingface.co/Qwen/Qwen3-8B)
- [Ollama 공식 문서](https://ollama.com)
- [vLLM 공식 문서](https://docs.vllm.ai)
- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [Qwen 공식 문서](https://qwen.readthedocs.io)

### 관련 가이드 문서
| 문서 | 내용 |
|------|------|
| [로컬_LLM_가이드.md](로컬_LLM_가이드.md) | RTX 5090에서 사용 가능한 로컬 LLM 총망라 (Qwen3.6 27B, DeepSeek-R1 32B 등) |
| [국내_LLM_가이드.md](국내_LLM_가이드.md) | 국내 개발 LLM 종합 가이드 (HyperCLOVA X, EXAONE, SOLAR, KORani 등) |
| [M5_Ultra_로컬_LLM_가이드.md](M5_Ultra_로컬_LLM_가이드.md) | Apple Mac Studio M5 Ultra용 로컬 LLM 가이드 (256GB/512GB) |
| [반도체_설계_AI_가이드.md](반도체_설계_AI_가이드.md) | 반도체 설계 전용 AI 가이드 (RTLCoder, VeriGen, ChipNeMo 등) |
