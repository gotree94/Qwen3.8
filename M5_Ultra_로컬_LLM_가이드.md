# M5 Ultra 로컬 LLM 가이드 (256GB / 512GB)

> 대상: Apple Mac Studio M5 Ultra
> 스펙: 36코어 CPU / 80코어 GPU / **1.2 TB/s** 메모리 대역폭 / 유니파이드 메모리 256GB 또는 512GB
> 작성일: 2026-09-09

---

## 0. Apple Silicon에서 LLM이 잘 돌아가는 이유

- **유니파이드 메모리**: GPU VRAM이 따로 없고 CPU·GPU가 하나의 메모리 풀을 공유 → 모델 전체가 메모리에 들어가면 "VRAM 제한"이 사라짐
- **대용량 상시 로드**: 256GB면 70B 모델을 **무손실(FP8)** 로, 512GB면 **235B급 MoE**까지 로드 가능
- **MoE 최적**: Apple Silicon 대역폭(1.2TB/s)이 MoE의 활성 전문가(active expert)만 빠르게 읽는 구조와 잘 맞음

> 💡 **한계**: 생성 속도는 "메모리 용량"이 아니라 "메모리 대역폭(1.2TB/s)"이 결정. RTX만큼 tok/s는 빠르지 않지만, **훨씬 큰 모델을 한 번에** 돌릴 수 있음이 최대 강점.

---

## 1. 256GB에서 가능한 LLM 리스트

**규칙**: 256GB에선 보통 Q4_K_M 양자화 기준으로 로드. 70B급은 Q8~FP8로도 여유롭게 가능.

### 🏆 최고 성능 모델

| 모델 | 종류 | 활성 파라미터 | 로드 크기 | 속도(예상) | 특징 |
|------|------|--------------|-----------|-----------|------|
| **Qwen3 235B-A22B MoE** | MoE | 22B | Q4 ~132GB / FP8 ~249GB | Q4 ~40-52 tok/s | **최고의 종합 성능**(추론+코딩), Apache-2.0 |
| **Llama 3.3 70B** | Dense | 70B | Q4 ~48GB / FP8 ~78GB | Q8 ~28-35 tok/s | 검증된 표준 고성능 모델 |
| **DeepSeek-R1 70B** | Dense | 70B | Q4 ~48GB | ~30 tok/s | 최고 수준 추론/사고사슬 |
| **Qwen 2.5 72B** | Dense | 72B | Q4 ~49GB | ~30 tok/s | 다국어·일반 종합 |
| **gpt-oss-120b** | MoE | ~3.6B | ~61GB | 빠름 | OpenAI 오픈웨이트, 고속 |

### 추가 옵션 (중형/소형)
- **Qwen 2.5 Coder 32B** — 전문 코딩 (HumanEval 92.7%)
- **DeepSeek-R1 32B** — 경량 추론
- **Qwen3-Coder 30B / Qwen3.6 27B** — 코딩/일반 고속
- **Llama 4 Scout 109B-A17B** — **10M 토큰 초장문 컨텍스트** (Q4 ~55GB, 초장문 문서 처리 특화)

### ❌ 256GB로는 여유롭게 무리인 것
- **Qwen3.5-397B-A17B** — Q4 기준 ~200GB+로 256GB에 빡빡/불가
- **DeepSeek V4 Flash 284B-A13B** — Q4 ~150GB+ (돌릴 순 있으나 컨텍스트 헤드룸 부족)
- **DeepSeek V4 Pro 1.6T** — 불가 (데이터센터급)

---

## 2. 512GB에서 가능한 LLM 리스트

512GB는 **더 큰 모델을 더 높은 정밀도(무손실)** 로, 그리고 **여러 모델을 동시에** 띄울 수 있는 구성.

### 🏆 최고 성능 모델

| 모델 | 종류 | 활성 파라미터 | 로드 크기 | 특징 |
|------|------|--------------|-----------|------|
| **Qwen3 235B-A22B MoE (FP8)** | MoE | 22B | ~249GB | **최고 종합 성능 + 무손실 품질**, 128K 컨텍스트까지 헤드룸 |
| **Qwen3.5-397B-A17B** | MoE | 17B | Q4 ~200GB | **기존 오픈웨이트 최상위 종합 모델**(AIME 91.3, GPQA 88.4), 다중모달(텍스트·이미지·비디오) |
| **DeepSeek V4 Flash 284B-A13B** | MoE | 13B | Q4 ~150GB | 가성비 높은 대형 코딩/에이전트, 1M 컨텍스트, MIT |
| **GLM-5.x / Nemotron** | MoE | 다양 | 다양 | 엔터프라이즈/에이전트 특화 옵션 |

### 착실한 대형 Dense 모델 (무손실 가능)
- **Llama 3.3 70B (FP8/Q8)** — 512GB에선 완전 무손실로 여유롭게 구동
- **DeepSeek-R1 70B, Qwen 2.5 72B (FP8)** — 무손실 수준으로 구동

### ❌ 512GB로도 어려운 것
- **DeepSeek V4 Pro 1.6T, GLM-5.x 753B, MiniMax, Qwen3.8 2.4T** — 데이터센터급, 512GB로는 부족

---

## 3. 성능이 가장 좋은 LLM 결론

**✅ M5 Ultra에서 성능이 가장 좋은 모델: Qwen3 235B-A22B MoE**

| 구분 | 판단 |
|------|------|
| 256GB 구성 | Qwen3 235B MoE **Q4_K_M** (~132GB) — 256GB에 여유있게 로드, 가장 성능 좋음 |
| 512GB 구성 | Qwen3 235B MoE **FP8** (~249GB) — 무손실 품질로 최고 성능 |
| 이유 | 2026년 24~512GB 로컬 환경에서 **추론·코딩 종합 최상위**. 절대 파라미터는 크지만 MoE(22B 활성)라 생성 속도도 빠름(배치 시 100-200+ tok/s) |
| '절대 원질량 최상'이 궁금하면 | Qwen3.5-397B-A17B (512GB, Q4) — 일반·다중모달 성능은 더 높으나 로드 여유가 적음 |

> **요약**: 
> - **512GB 최강**: Qwen3 235B-A22B (FP8, 무손실)
> - **256GB 최강**: Qwen3 235B-A22B (Q4) — 품질 손실 단 2-3%로 최대 성능
> - **초장문/문서**: Llama 4 Scout
> - **순수 코딩**: DeepSeek V4 Flash / Qwen Coder 계열

---

## 4. 메모리 여유 시 여러 LLM 동시 실행 검토

**결론: 가능하다. Apple Silicon은 모델 여러 개를 한 메모리 풀에 동시에 로드해 각각 별도로 실행할 수 있다.**

### 원리
- 하나의 GPU가 아니라 유니파이드 메모리 풀을 쓰므로, 메모리만 빠듯하지 않으면 **여러 모델이 동시 상주** 가능
- 대역폭(1.2TB/s)이 공유되므로 **동시 실행 시 개별 속도는 나눠짐** — 부하가 큰 작업 여러 개를 동시에 돌리면 서로 느려질 수 있음
- 동시에 로드만 해두고 **번갈아 사용**하는 패턴이 이상적 (RAG·코딩·추론·다중모달 각각 전용 모델)

### 동시 실행 권장 구성 예시

#### 예시 1: 512GB — 풀 세트 동시 상주 (총 ~460GB 사용)
| 용도 | 모델 | 크기 |
|------|------|------|
| 종합/추론 (메인) | Qwen3 235B-A22B (FP8) | ~249GB |
| 코딩 | DeepSeek V4 Flash 284B (Q4) | ~150GB |
| 소형 고속 | Qwen3 8B (BF16) | ~16GB |
| **합계** | | **~415GB** (여유 ~100GB) |

#### 예시 2: 256GB — 핵심 2-3개 동시 상주 (총 ~205GB)
| 용도 | 모델 | 크기 |
|------|------|------|
| 종합 (메인) | Qwen3 235B-A22B (Q4) | ~132GB |
| 가벼운 코딩/보조 | Qwen3-Coder 30B (Q4) | ~17GB |
| 고속 보조 | Qwen3 8B (Q4) | ~5GB |
| **합계** | | **~154GB** (여유 여유로움) |

> ⚠️ 주의사항
> - **미리 다 로드**해두는 편이 전환 시간 없이 빠름 (LM Studio/Ollama는 요청 모델을 자동 로드/언로드)
> - 실제 **동시 추론**(두 모델이 동시에 답 생성)을 원하면 대역폭 분할로 속도 하락 감수
> - macOS는 앱용 메모리도 필요하므로 **전체를 모델에 다 쓰지 말고 ~15-20%는 비워둘 것**

---

## 5. 설치 가이드

Apple Silicon에서 로컬 LLM을 돌리는 대표적 방법 3가지입니다.
(기본적으로 **MLX 포맷**이 Apple Silicon에서 가장 빠르고 권장됨)

### 사전 준비
```bash
# Xcode 명령줄 도구 (컴파일러)
xcode-select --install

# (선택) Homebrew가 없으면
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

### 방법 A: MLX (Apple 전용, 최고 성능·권장)

Apple의 공식 오픈소스 머신러닝 프레임워크. Apple Silicon에서 llama.cpp보다 20-50% 더 빠름.

#### 1) Python 환경 + 설치
```bash
# Python 3.10+ 필요. 가상환경 권장
python3 -m venv ~/mlx-venv
source ~/mlx-venv/bin/activate

pip install --upgrade pip
pip install mlx mlx-lm
```

#### 2) Qwen3 235B-A22B MoE 다운로드·실행
```bash
# 512GB 권장: FP8 (무손실)
python -m mlx_lm.generate \
  --model mlx-community/Qwen3-235B-A22B-Instruct-mlx-fp8 \
  --prompt "한국어로 자기소개를 해줘"

# 256GB 권장: Q4 (여유 있는 품질)
python -m mlx_lm.generate \
  --model mlx-community/Qwen3-235B-A22B-Instruct-mlx-4bit \
  --prompt "한국어로 자기소개를 해줘"
```

#### 3) 대화형 챗(쉘 인터랙티브)
```bash
python -m mlx_lm generate \
  --model mlx-community/Qwen3-235B-A22B-Instruct-mlx-fp8 \
  --prompt "안녕"
```

#### 4) API 서버로 실행 (OpenAI 호환, vs 여러 앱 연동)
```bash
python -m mlx_lm.server --model mlx-community/Qwen3-235B-A22B-Instruct-mlx-fp8
# -> http://localhost:8080/v1  (OpenAI API 형식)
```

#### 5) 동시 실행 (여러 모델 서버 각각 백그라운드)
```bash
# 서버 1: 메인 (FP8)
python -m mlx_lm.server --model mlx-community/Qwen3-235B-A22B-Instruct-mlx-fp8 --port 8080 &

# 서버 2: 코딩 (Q4)
python -m mlx_lm.server --model mlx-community/DeepSeek-V4-Flash-...-mlx-4bit --port 8081 &

# 서버 3: 소형 고속
python -m mlx_lm.server --model mlx-community/Qwen3-8B-Instruct-mlx-bf16 --port 8082 &
```
> 각 포트를 다른 앱이 가리키면 됨. 필요 모델만 메모리에 상주.

#### 6) 메모리 사용 확인
```bash
# 각 프로세스의 메모리 확인
ps aux | grep mlx_lm
```

---

### 방법 B: Ollama (가장 간편, 자동 관리)

모델 다운로드/실행/자동 언로드를 한 번에 처리. 초보자에게 가장 추천.

#### 1) 설치
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

#### 2) 대형 MoE 모델 다운로드·실행
```bash
# Llama 3.3 70B (256GB/512GB 모두 여유)
ollama pull llama3.3:70b
ollama run llama3.3:70b

# Qwen 72B
ollama pull qwen2.5:72b
ollama run qwen2.5:72b
```

> ⚠️ Ollama의 큰 MoE(235B/397B)는 공식 태그가 없을 수 있어, 그 경우 **MLX(방법 A)** 권장.

#### 3) 여러 모델 동시 사용 (auto-load)
Ollama는 요청 모델이 있으면 자동으로 메모리에 로드하고, 다른 모델 요청 시 전환합니다.
```bash
# 서버를 백그라운드로
ollama serve &

# 모델 전환 실험: llama3.3:70b 2개 띄워 동시 응답(별도 서버) 가능
```

#### 4) API (OpenAI 호환, 기본 포트 11434)
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.3:70b",
  "prompt": "안녕!"
}'
```

---

### 방법 C: LM Studio (GUI, 가장 사용자 친화적)

Apple이 공식적으로 M5 Ultra 데모에 사용한 앱. 시각적으로 모델을 다운로드·실행.

#### 1) 다운로드
- https://lmstudio.ai 에서 macOS 버전 설치

#### 2) 모델 찾기·다운로드
- 좌측 검색창에서 **"Qwen3 235B"** 또는 **"Llama 3.3 70B"** 검색
- **Apple Silicon용(MLX .mlx)** 또는 **GGUF** 버전 선택
- 512GB → FP8/FP16, 256GB → Q4/Q4_K_M 버전 권장

#### 3) 실행
- 다운로드된 모델 클릭 → "Load" → 채팅
- 우측 하단에서 GPU 오프로드(%) 등 조절

#### 4) 로컬 서버 모드 (다른 앱 연동)
- 채팅창 옆 서버 아이콘 열기 → Start server → `http://localhost:1234/v1` (OpenAI 호환)

#### 5) 여러 모델 동시 실행
- LM Studio는 **여러 모델을 동시에 로드** 가능 (메모리 허용 시)
- `My Models`에서 각 모델을 로드 상태로 유지하고 채팅 탭을 전환하며 사용

---

## 6. 최종 요약

| 구분 | 내용 |
|------|------|
| **256GB 최고 모델** | Qwen3 235B-A22B MoE (Q4, ~132GB) |
| **512GB 최고 모델** | Qwen3 235B-A22B MoE (FP8, ~249GB, 무손실) |
| 절대 최상 다중모달 | Qwen3.5-397B-A17B (512GB, Q4) |
| 초장문 특화 | Llama 4 Scout (10M 컨텍스트) |
| 전문 코딩 | DeepSeek V4 Flash / Qwen Coder 계열 |
| **동시 실행** | ✅ 가능. 512GB에선 메인(FP8)+코딩(Q4)+소형까지 약 415GB 동시 상주 가능. 속도는 대역폭 공유로 분할 |
| **권장 도구** | 초보: LM Studio / 간편: Ollama / 최고 성능·대형 MoE: MLX |

### 512GB 권장 설치 명령 (MLX, 최종)
```bash
xcode-select --install
python3 -m venv ~/mlx-venv && source ~/mlx-venv/bin/activate
pip install mlx mlx-lm

# 메인 모델 실행
python -m mlx_lm.generate --model mlx-community/Qwen3-235B-A22B-Instruct-mlx-fp8 \
  --prompt "한국어로 자기소개를 해줘"
```

> ⚠️ 위 명령의 정확한 MLX 모델명(Hugging Face 리포지토리명)은 **실제로 검색해 확인**하세요.
> `mlx-community/Qwen3-235B-A22B-Instruct-mlx-fp8` 은 기준 예시이며, 출시 상태에 따라 `-4bit`, `-fp8`, 또는 다른 이름으로 게시되어 있을 수 있습니다. https://huggingface.co/mlx-community 에서 검색 후 사용하시면 됩니다.
