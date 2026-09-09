# 로컬 LLM 설치 가이드 (RTX 5090, Ubuntu 22.04)

> 대상 환경: Ubuntu 22.04 LTS / NVIDIA RTX 5090 24GB (CUDA 13.0) / RAM 62GB / 24코어
> 작성일: 2026-09-09

---

## 1. 현재 환경에서 사용 가능한 로컬 LLM 총망라

아래는 **24GB VRAM** 기준으로 실제로 쾌적하게 돌릴 수 있는 로컬 LLM 목록입니다.
(VRAM 수치는 Q4_K_M 양자화, 약간의 컨텍스트 헤드룸 포함 기준)

### 🏆 추천 모델 (24GB VRAM에 최적)

| 모델 | 파라미터 | VRAM(Q4) | 특징 | 사용 사례 |
|------|---------|----------|------|-----------|
| **Qwen3.6 27B** | 27B (dense) | ~17-22GB | 최고 성능 대표, 다국어·추론 강함 | **일반/종합 최고** |
| **Qwen 2.5 Coder 32B** | 32B (dense) | ~20GB | SOTA급 코딩 (HumanEval 92.7%) | 전문 코딩 |
| **Qwen3-Coder 30B** | 30B MoE (3B active) | ~17-19GB | 에이전트 코딩, 256K 컨텍스트 | 코딩 에이전트 |
| **DeepSeek-R1 32B** | 32B (dense) | ~20GB | 최고 추론/사고 사슬 모델 | 복잡한 논리 추론 |
| **Qwen 2.5 32B** | 32B (dense) | ~20GB | 다용도 일반 채팅/RAG/다국어 | 일반 목적 |

### 추가 옵션 (더 작은 모델 - 빠르고 가벼움)

| 모델 | 파라미터 | VRAM(Q4) | 특징 |
|------|---------|----------|------|
| Qwen 2.5 14B | 14B | ~9GB | 12GB 카드급 |
| Gemma 3 27B | 27B | ~16GB | Google, 모델파일 라이선스 |
| Llama 3.1 8B | 8B | ~5GB | 가벼운 기본 모델 |
| DeepSeek-R1 14B | 14B | ~9GB | 경량 추론 모델 |

### ❌ 24GB VRAM으로는 무리한 모델
- Llama 3.3 70B, Qwen 2.5 72B, DeepSeek-R1 70B → Q4 기준 **~40GB** 필요 (2×RTX 5090 또는 48GB 이상 GPU 필요)

---

## 2. 성능이 가장 좋은 LLM은?

**결론: Qwen3.6 27B**

| 항목 | 판단 기준 |
|------|----------|
| **권장 모델** | Qwen3.6 27B (Q4_K_M) |
| 이유 | 24GB에서 돌릴 수 있는 실제 최상위 모델. <br> 에이전트 코딩 벤치마크(SWE-bench)에서 훨씬 큰 모델(397B)과 견줄 만큼 높은 성능(68.9%)을 <br> 기록하면서도 VRAM을 여유롭게 사용 (약 17-22GB, 최대 30 tok/s) |
| 용도별 최고 | 코딩 → Qwen 2.5 Coder 32B, 추론 → DeepSeek-R1 32B, 에이전트 코딩 → Qwen3-Coder 30B |

> 💡 **왜 27B를 추천하나?**
> - 32B 모델은 ~20GB로 24GB에 딱 맞지만 컨텍스트 헤드룸이 부족
> - 27B는 ~17-22GB로 컨텍스트 여유까지 확보
> - 풀 파라미터(dense) 모델이라 MoE 오버헤드 없음
> - 2026년 기준 최신 dense 로컬 모델 중 최고 성능

---

## 3. 최고 성능 LLM(Qwen3.6 27B) 설치 가이드

### 방법 A: Ollama (가장 쉽고 권장)

Ollama는 PDF·이미지 지원 없이도 모델 다운로드/실행/API 서버를 한 번에 처리하는 가장 간편한 도구입니다.

#### 1) Ollama 설치

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

#### 2) Qwen3.6 27B 다운로드

```bash
ollama pull qwen3.6:27b
```

#### 3) GPU 인식 확인

```bash
nvidia-smi
# 설치 후 첫 실행 시 GPU가 로드되는지 확인
ollama run qwen3.6:27b
```

#### 4) 실행

```bash
# 인터랙티브 실행
ollama run qwen3.6:27b

# API 서버 백그라운드 실행 (기본 포트 11434)
ollama serve
```

#### 5) API 서버 테스트

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3.6:27b",
  "prompt": "안녕하세요!"
}'
```

#### 6) 자동시작 (서버 부팅 시)

```bash
sudo systemctl enable ollama
sudo systemctl start ollama
```

---

### 방법 B: llama.cpp (고급, 최대 속도 튜닝)

더 세밀한 제어가 필요하거나 최대 성능을 원할 때 사용합니다.

#### 1) 사전 요구사항 설치

```bash
sudo apt update
sudo apt install -y build-essential cmake git ninja-build
```

#### 2) llama.cpp 빌드 (CUDA 활성화)

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=120
cmake --build build --config Release -j $(nproc)
```

> `-DCMAKE_CUDA_ARCHITECTURES=120` 은 RTX 5090 (Blackwell, sm_120) 용입니다. (드라이버 580+ 와 CUDA 12.8+ 필요)

#### 3) GGUF 모델 다운로드 (Hugging Face)

```bash
# Qwen3.6 27B GGUF (Q4_K_M)
wget https://huggingface.co/Qwen/Qwen3.6-27B-GGUF/resolve/main/qwen3.6-27b-q4_k_m.gguf
```

#### 4) 실행

```bash
# 인터랙티브
./build/bin/llama-cli -m qwen3.6-27b-q4_k_m.gguf -ngl 999

# OpenAI 호환 서버
./build/bin/llama-server -m qwen3.6-27b-q4_k_m.gguf -ngl 999 --port 8080
```

- `-ngl 999` = 모든 레이어를 GPU로 오프로드

---

### 방법 C: LM Studio (GUI, 초보자 친화)

- 웹사이트: https://lmstudio.ai
- 앱 다운로드 후 UI에서 "Qwen3.6 27B" 검색 → 다운로드 → 실행
- GGUF 형식을 자동 처리, OpenAI 호환 로컬 서버도 내장

---

## 4. 환경 검증 및 권장 사항

### 드라이버/툴 확인
```bash
nvidia-smi                    # 드라이버 확인 (580.159.04 ✅)
python3 --version             # Python 3.10 확인
```

### 권장 추가 모델 (용도별 병행 설치)

| 용도 | 명령어 |
|------|--------|
| 코딩 | `ollama pull qwen2.5-coder:32b` |
| 추론/사고 | `ollama pull deepseek-r1:32b` |
| 가벼운 작업 | `ollama pull qwen3:8b` |

### 성능 튜닝 팁
- 컨텍스트 문제 시 `OLLAMA_CONTEXT_LENGTH` 또는 `--num-ctx` 조정 (기본 2048-4096)
- VRAM 부족 시 더 작은 양자화(Q3) 또는 더 작은 모델 사용
- 서버형 운영이라면 `/etc/systemd/system/ollama.service` 에서 `Environment="OLLAMA_HOST=0.0.0.0"` 설정

---

## 5. 요약

1. **최고 성능 로컬 LLM**: Qwen3.6 27B
2. **추천 설치 도구**: Ollama (간편·강력)
3. **설치 명령**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ollama pull qwen3.6:27b
   ollama run qwen3.6:27b
   ```
4. **용도별 병행**: Qwen 2.5 Coder 32B (코딩), DeepSeek-R1 32B (추론)
