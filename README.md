# Qwen3-8B 로컬 설치 가이드

> **생성일:** 2026-09-07  
> **대상 시스템:** Ubuntu 22.04 LTS | RTX 5090 24GB | 64GB RAM | 24 Cores

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

## 2. Qwen3-8B란?

- **모델 크기:** 8.2B (82억) 파라미터
- **컨텍스트 윈도우:** 32,768 토큰 (YaRN 확장 시 131,072 토큰)
- **라이선스:** Apache 2.0 (상업적 사용 가능)
- **언어:** 119개 언어 지원, 한국어 포함
- **특징:** Think/No-Think 하이브리드 추론 모드
- **HuggingFace:** `Qwen/Qwen3-8B`

---

## 3. 설치 방법 (4가지 경로)

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

## 4. 설치 방법 비교

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

## 5. 추천 양자화 (Quantization) 가이드

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

## 6. Think 모드 (추론 모드) 사용법

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

## 7. 검증 및 테스트

### 7.1 기본 동작 확인

```bash
# Ollama 설치 확인
ollama list
# qwen3:8b  should be listed

# vLLM 헬스 체크
curl http://localhost:8000/health

# GPU 사용량 확인 (별도 터미널)
watch -n 1 nvidia-smi
```

### 7.2 프롬프트 테스트

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

### 7.3 성능 벤치마크

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

## 8. 문제 해결 (트러블슈팅)

### 8.1 CUDA 관련 오류

```bash
# CUDA 버전 확인
nvcc --version
nvidia-smi

# PyTorch CUDA 버전 확인
python3 -c "import torch; print(torch.cuda.is_available()); print(torch.version.cuda)"
```

### 8.2 Ollama 연결 오류

```bash
# Ollama 서비스 상태 확인
systemctl status ollama

# 로그 확인
journalctl -u ollama -f

# 수동 시작
ollama serve &
```

### 8.3 GPU 메모리 부족

```bash
# 현재 GPU 메모리 사용량 확인
nvidia-smi

# 다른 프로세스가 GPU를 사용 중이면 종료
# 또는 양자화를 더 작은 버전으로 변경:
# Q4_K_M -> Q4_K_S 또는 Q3_K_M
```

### 8.4 모델 다운로드 실패

```bash
# HuggingFace 캐시 확인
ls ~/.cache/huggingface/hub/

# 수동 다운로드
pip install huggingface-hub
huggingface-cli download Qwen/Qwen3-8B
```

---

## 9. 유용한 명령어 모음

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

## 10. 디렉토리 구조 (권장)

```
/home/gotree94/Desktop/
├── Qwen3-8B_설치가이드.md          ← 이 파일
├── qwen3-env/                      ← Python 가상환경 (방법 2, 3용)
├── llama.cpp/                      ← llama.cpp 소스 (방법 4용)
├── qwen3-8b-gguf/                  ← GGUF 모델 파일 (방법 4용)
└── test_qwen3.py                   ← 테스트 스크립트 (방법 3용)
```

---

## 11. 빠른 시작 (3줄 요약)

```bash
# 가장 빠른 시작 (Ollama)
curl -fsSL https://ollama.com/install.sh | sh
ollama run qwen3:8b
```

```bash
# 프로덕션 API 서버 (vLLM)
pip install "vllm>=0.9.0"
vllm serve Qwen/Qwen3-8B
```

---

## 참고 자료

- [Qwen3 GitHub](https://github.com/QwenLM/Qwen3)
- [Qwen3-8B HuggingFace](https://huggingface.co/Qwen/Qwen3-8B)
- [Ollama 공식 문서](https://ollama.com)
- [vLLM 공식 문서](https://docs.vllm.ai)
- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [Qwen 공식 문서](https://qwen.readthedocs.io)
