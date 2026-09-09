# 국내(한국) 개발 LLM 종합 가이드

> 대상 하드웨어: Ubuntu 22.04.5 LTS / **NVIDIA RTX 5090 24GB (CUDA 13.0)** / RAM 62GB / 24코어
> 작성일: 2026-09-09

---

## 1. 국내 개발 주요 LLM 총망라 및 유료/무료 구분

### 1-1. 네이버 (NAVER) — HyperCLOVA X
| 모델 | 파라미터 | 무료/유료 | 오픈소스 | 상업 사용 |
|------|---------|-----------|----------|-----------|
| HyperCLOVA X (플래그십) | 초대형 (수백B~) | **유료 API** | ❌ 폐쇄 | 계약 필요 |
| **HyperCLOVA X SEED Think 32B** | 32B (dense) | ✅ **무료** | ✅ 오픈 | ✅ 상업 무제한 |
| **HyperCLOVA X SEED Think 14B** | 14B (dense) | ✅ **무료** | ✅ 오픈 | ✅ 상업 무제한 |
| **HyperCLOVA X SEED Omni 8B** | ~8B (다중모달) | ✅ **무료** | ✅ 오픈 | ✅ 상업 무제한 |
| HyperCLOVA X SEED 3B / 1.5B / 0.5B | 소형 | ✅ **무료** | ✅ 오픈 | ✅ |
| HyperCLOVA X THINK (추론) | 대형 | **유료 API** | ❌ | 계약 필요 |

- 강점: **한국어 최적화의 대표 주자**, 한국어 토크나이저 최적화(한국어 처리 최대 2배 빠름), 한국 문화·상식 학습량은 GPT-4 대비 6,500배. 커뮤니티 다운로드 최다.

### 1-2. LG AI연구원 — EXAONE / K-EXAONE
| 모델 | 파라미터 | 무료/유료 | 오픈소스 | 상업 사용 |
|------|---------|-----------|----------|-----------|
| EXAONE 3.5 (2.4B / 7.8B / 32B) | 소~32B | ✅ **무료** | ✅ 오픈 | ⚠️ **NC(비상업)만** |
| EXAONE 4.0 (32B / 1.2B) | 32B | ✅ **무료** | ✅ 오픈 | ⚠️ **NC(비상업)만** |
| EXAONE 4.5 (33B, 비전-언어 VLM) | 33B | ✅ **무료** | ✅ 오픈 | ⚠️ NC |
| EXAONE Deep (2.4/7.8/32B) | 32B | ✅ **무료** | ✅ 오픈 | ⚠️ NC |
| **K-EXAONE 1.0** | 236B MoE (23B 활성) | ✅ **무료** | ✅ 오픈 | ✅ 상업 무제한(GitHub) |
| **K-EXAONE 2.0** | **750B MoE** (37B 활성) | ✅ **무료** | ✅ 오픈(**Apache 2.0**) | ✅ 상업 무제한 |
| EXAONE 엔터프라이즈 특화(엑스퍼트 등) | 대형 | **유료/계약** | ❌ | 계약 필요 |

- 강점: 산업 특화(제약, 신소재, 금융, 보안). EXAONE 4.0은 한국 전문자격시험(의사, 치과의사, 관세사 등) 6종 통과. **K-EXAONE 2.0(750B)은 국내 최대 규모**, 세계 프론티어 오픈웨이트 수준.

### 1-3. Upstage — Solar
| 모델 | 파라미터 | 무료/유료 | 오픈소스 | 상업 사용 |
|------|---------|-----------|----------|-----------|
| **SOLAR 10.7B** | 10.7B | ✅ **무료** | ✅ 오픈(**Apache 2.0**) | ✅ |
| Solar Open 100B | 100B | ✅ **무료** | ✅ 오픈 | ✅ |
| Solar Open 2 (250B) | 250B | ✅ **무료** | ✅ 오픈(Upstage Solar License) | ✅ 상업 허용 |
| Solar Pro / Solar Pro 2 | 대형 | **유료/폐쇄** | ❌ (일부) | 계약 필요 |

- 강점: 개발자 친화. 2023년 HuggingFace 오픈 LLM 리더보드 1위 기록(10.7B로 Mixtral 8x7B, Llama 2, Qwen 72B 능가).

### 1-4. SKT / KT (통신사)
| 모델 | 파라미터 | 무료/유료 | 오픈소스 |
|------|---------|-----------|----------|
| SKT **A.X (Aix)** | 대형 | **유료/전용** | ❌ 폐쇄 |
| KT **Mi:dm (믿:음)** | 대형 | **유료/전용** | ❌ 폐쇄 |

- 통신 특화·B2B. 오픈 웨이트를 공개하지 않아 **개인으로는 설치 불가** (API/계약만).

### 1-5. 카카오
| 모델 | 파라미터 | 무료/유료 | 오픈소스 |
|------|---------|-----------|----------|
| KoGPT | 6B | **무료** | ✅ 커뮤니티 오픈 |
| Kanana / 기타 | - | 일부 오픈 | ⚠️ 혼합 |

### 1-6. 크래프톤 — KORani
| 모델 | 파라미터 | 무료/유료 | 오픈소스 |
|------|---------|-----------|----------|
| **KORani** | 13B | ✅ **무료** | ✅ 오픈 웨이트 |

### 1-7. 기타 한국어 특화 오픈 모델
| 모델 | 파라미터 | 라이선스 |
|------|---------|----------|
| EEVE-Korean 10.8B | 10.8B | 오픈(Apache 등) |
| Polyglot-Ko 계열 | 1.3B~12.8B | 오픈 |

---

## 2. 세계 수준에서의 위치 비교

국내 오픈웨이트 모델의 대표 성능 지표(Artificial Analysis 지능지수 등)와 세계 최상위권 비교입니다.

### 지능 지수 (Intelligence Index, 높을수록 좋음)
| 모델 | 지능지수 | 규모 | 세계적 위치 |
|------|---------|------|-------------|
| **K-EXAONE 2.0 (750B)** | (프론티어급) | 750B MoE | **세계 오픈웨이트 최상위권**. 장문이해 OpenAI-MRCR 94.4로 GLM-5.1(71.5) 압도 |
| **K-EXAONE 1.0 (236B)** | **22** | 236B MoE | 한국어+추론 오픈웨이트 상위권 (예: Qwen3.5급에 근접) |
| **HyperCLOVA X SEED Think 32B** | **17** | 32B | 경량 추론 모델 중 우수. 대형(GPT-4o/Qwen3.5 등)에는 못 미침 |
| EXAONE 4.0 32B | 11 | 32B | 중상위권. 32B급에서는 경쟁력 |
| SOLAR 10.7B | - | 10.7B | 소형(SLM) 부문 최상위 (2023~당시) |

### 핵심 결론 (국내 LLM의 세계적 위상)
1. **한국어 성능은 세계 최고 수준** — K-EXAONE, HyperCLOVA X는 한국어 벤치(KMMLU, KoBALT, Ko-LongBench etc.)에서 글로벌 모델을 능가.
2. **규모·일반 성능은 아직 1군(OpenAI·Google·Meta·DeepSeek·Qwen)에 격차** — 국내 최대 K-EXAONE 2.0(750B)이 프론티어 오픈웨이트급에 근접하지만, 데이터센터급 하드웨어 필요.
3. **장문 이해·안전(안전성)은 세계 선두 경쟁** — K-EXAONE 2.0은 256K 컨텍스트 장문 검색에서 글로벌 모델보다 우위.
4. **한국어 서비스/에이전트 용도로는 최적** — 세계 1위는 못 되지만 **"한국어 용도 세계 1위"** 는 국내 모델이 지향.

---

## 3. 이 하드웨어(RTX 5090 24GB) 에 설치 가능한지 검토

**핵심 규칙**: 24GB VRAM에는 대략 **32~33B 이하의 모델을 Q4 양자화(~19-20GB)** 로만 구동 가능.
70B·236B·250B·750B 등 국내 대형 모델은 **24GB로는 구동 불가** (수백 GB 필요).

### ✅ 설치 가능한 국내 LLM
| 모델 | 크기(Q4) | VRAM | 설치 가능? |
|------|----------|------|-----------|
| **HyperCLOVA X SEED Think 32B** | ~19-20GB | 24GB | ✅ **가능 (상업 무제한) — 최고 성능** |
| **HyperCLOVA X SEED Think 14B** | ~9GB | 24GB | ✅ 가능 (추론, 여유로움) |
| **HyperCLOVA X SEED Omni 8B** | ~6GB | 24GB | ✅ 가능 (다중모달) |
| **EXAONE 4.5 (33B VLM)** | ~20GB | 24GB | ✅ 가능 (비전+언어, ⚠️비상업) |
| **EXAONE 4.0 / 3.5 / Deep 32B** | ~19GB | 24GB | ✅ 가능 (⚠️비상업) |
| EXAONE 7.8B / 2.4B | ~5-7GB | 24GB | ✅ 가능 |
| **SOLAR 10.7B** | ~7GB | 24GB | ✅ 가능 (Apache 2.0) |
| **KORani 13B** | ~8GB | 24GB | ✅ 가능 |
| EEVE 10.8B | ~7GB | 24GB | ✅ 가능 |

### ❌ 이 하드웨어로는 불가능한 국내 LLM
| 모델 | 필요 VRAM | 이유 |
|------|-----------|------|
| K-EXAONE 2.0 (750B) | 수백 GB | Q4 기준 ~400GB 이상. 데이터센터급 GPU(예: H100×8, 512GB+ Mac) 필요 |
| K-EXAONE 1.0 (236B) | ~130GB+ | Q4 기준 약 130GB. 24GB로 불가 |
| Solar Open 250B / 100B | ~55GB+ | Q4로도 24GB 초과 |
| HyperCLOVA X 플래그십 / EXAONE 엑스퍼트 | 폐쇄 | API/계약 필요 (설치 불가) |

> 💡 참고: RTX 5090은 일반적으로 32GB 제품입니다. 표에 기재하신 **24GB** 기준으로 판단했으며, 만약 실제 32GB라면 70B급 Q4(약 40GB는 여전히 불가)보다는 큰 MoE 일부(예: Solar Open 100B Q4 ~55GB는 여전히 초과)도 어렵습니다. **실질적으로 32B급 Q4가 이 하드웨어의 상한**입니다.

---

## 4. 이 하드웨어로 설치 가능한 국내 LLM별 설치 방법

> 권장 도구: **Ollama** (가장 간편, CUDA 지원 내장) + **vLLM** (고성능 서빙)
> 사전: NVIDIA 드라이버 580.159.04 ✅, CUDA 가능 ✅

### 사전 준비 (Ollama 설치)
```bash
curl -fsSL https://ollama.com/install.sh | sh
# GPU 인식 확인
ollama run llama3.2:1b   # (설치 테스트)
nvidia-smi               # VRAM 사용 확인
```

---

### 4-1. HyperCLOVA X SEED Think 32B (권장·최고 성능, 상업 무제한)

> 한국어 추론에 특화된 국내 최고 성능의 24GB 구동 가능 모델.

```bash
# Ollama로 다운로드 (공식 또는 커뮤니티 태그)
ollama pull hcseki/hyperclova-x-seed-think-32b
# 또는 HuggingFace 기반
ollama run hcseki/hyperclova-x-seed-think-32b --num-ctx 8192
```

HuggingFace 직접 다운로드 (llama.cpp/vLLM용):
```bash
pip install huggingface_hub
huggingface-cli download naver-hyperclovax/HyperCLOVAX-SEED-Think-32B --local-dir ./HCX-Think-32B
```

GGUF (llama.cpp/Ollama용) 사용 시:
```bash
# GGUF Q4_K_M 파일 확보 후
ollama create hcx-32b -f Modelfile
# Modelfile:
#   FROM ./hyperclova-seed-think-32b.Q4_K_M.gguf
```

vLLM 서버 (고성능·병렬):
```bash
pip install vllm
vllm serve naver-hyperclovax/HyperCLOVAX-SEED-Think-32B \
  --max-model-len 8192 --gpu-memory-utilization 0.92
# -> http://localhost:8000/v1  (OpenAI 호환)
```

---

### 4-2. HyperCLOVA X SEED Think 14B (경량 추론, 여유로운 구동)

```bash
ollama pull hcseki/hyperclova-x-seed-think-14b
ollama run hcseki/hyperclova-x-seed-think-14b
```

vLLM:
```bash
vllm serve naver-hyperclovax/HyperCLOVAX-SEED-Think-14B --gpu-memory-utilization 0.9
```

---

### 4-3. HyperCLOVA X SEED Omni 8B (다중모달: 텍스트+이미지+음성)

```bash
ollama pull hcseki/hyperclova-x-seed-omni-8b
ollama run hcseki/hyperclova-x-seed-omni-8b
```

HuggingFace:
```bash
huggingface-cli download naver-hyperclovax/HyperCLOVAX-SEED-Omni-8B --local-dir ./HCX-Omni-8B
```

---

### 4-4. EXAONE 3.5 32B / 7.8B (LG, ⚠️ 비상업용 라이선스)

Ollama (공식 태그 존재):
```bash
ollama pull exaone3.5:32b     # ~19GB Q4_K_M → 24GB VRAM에 구동
ollama run exaone3.5:32b

ollama pull exaone3.5:7.8b
ollama run exaone3.5:7.8b
```

HuggingFace/vLLM (GGUF 또는 transformers):
```bash
pip install vllm
vllm serve LGAI-EXAONE/EXAONE-3.5-32B-Instruct --gpu-memory-utilization 0.92
```

---

### 4-5. EXAONE 4.0 32B (LG, ⚠️ 비상업용)

```bash
# Ollama에 아직 없으면 GGUF 사용
ollama create exaone4-32b -f Modelfile
# vLLM
vllm serve LGAI-EXAONE/EXAONE-4.0-32B-Instruct --gpu-memory-utilization 0.92
```

---

### 4-6. EXAONE 4.5 33B (LG 최신 비전-언어 VLM, ⚠️ 비상업용)

```bash
pip install vllm
# 비전 입력 이미지 처리 지원
vllm serve LGAI-EXAONE/EXAONE-4.5-33B --gpu-memory-utilization 0.92
```
> 33B에 비전 인코더 포함 → 24GB에 Q4로 꽉 차게 로드되며, 컨텍스트를 줄여야 여유 확보 가능.

---

### 4-7. SOLAR 10.7B (Upstage, Apache 2.0 상업 무료)

```bash
# Ollama (커뮤니티 GGUF)
ollama pull upstage/solar-10.7b-instruct-v1.0
# 또는
ollama run upstage/solar-10.7b-instruct-v1.0

# vLLM
vllm serve upstage/SOLAR-10.7B-Instruct-v1.0 --gpu-memory-utilization 0.5
```

---

### 4-8. KORani 13B (크래프톤)

```bash
huggingface-cli download ...KoRani-13B...
# GGUF Q4 변환/다운로드 후 Ollama 또는 llama.cpp로 실행
ollama create korani -f Modelfile
ollama run korani
```

---

## 5. 최종 추천 (이 24GB 하드웨어 기준)

| 목적 | 권장 국내 모델 | 라이선스 | 비고 |
|------|---------------|----------|------|
| **한국어 추론 (최고)** | **HyperCLOVA X SEED Think 32B** | 상업 무제한 | 32B, ~19GB, 24GB에 최적 |
| 경량 추론 | HyperCLOVA X SEED Think 14B | 상업 무제한 | 여유로운 구동 |
| 다중모달(이미지·음성) | HyperCLOVA X SEED Omni 8B | 상업 무제한 | |
| 비전+언어 (최신 성능) | EXAONE 4.5 33B | ⚠️ 비상업 | 연구/개인용 |
| LG 일반 (비상업) | EXAONE 3.5 32B | ⚠️ 비상업 | |
| 소형·빠른 배포 | SOLAR 10.7B | Apache 2.0 | 상업 OK |

### 🏆 이 하드웨어에서 가장 성능 좋은 국내 모델
**HyperCLOVA X SEED Think 32B** — 24GB에 구동 가능한 국내 모델 중 지능지수 최고(17), 한국어 추론 특화 + 상업 무제한 라이선스.
> 단, **국내 모델 전체 최고 성능은 K-EXAONE 2.0(750B)**이지만 이 하드웨어로는 메모리가 부족해 구동 불가.

---

## 6. 참고: 설치 확인 및 트러블슈팅

```bash
# Ollama 서비스 확인
systemctl status ollama
# GPU에 모델이 올라갔는지
nvidia-smi
# VRAM 부족 시 컨텍스트 줄이기
ollama run <모델> --num-ctx 2048
```

vLLM 설치 시 CUDA 호환:
```bash
pip install vllm
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```
> RTX 5090(Blackwell)은 최신 PyTorch + CUDA 12.8+ 필요. 표기된 CUDA 13.0 환경이면 최신 vLLM/PyTorch 사용 권장.

---

## 7. 요약

1. **국내 개발 LLM**: 네이버(HyperCLOVA X)·LG(EXAONE/K-EXAONE)·Upstage(Solar)·SKT(A.X)·KT(Mi:dm)·카카오(KoGPT)·크래프톤(KORani) 등.
2. **무료/유료**: HyperCLOVA SEED·EXAONE·SOLAR·KORani → **무료 오픈**, 통신사(A.X·Mi:dm)·플래그십·Solar Pro → **유료/폐쇄**. EXAONE 일부는 **비상업용(NC)**.
3. **세계적 위상**: 한국어 성능 세계 최고, 장문이해·안전성 선두. 그러나 일반·규모는 1군(OpenAI등)에 아직 근접 단계. **K-EXAONE 2.0(750B)이 국내 최대·프론티어급.**
4. **24GB 설치 가능**: 32B급 Q4까지(SEED Think 32B, EXAONE 4.5/4.0 32B 등). 70B·236B·750B는 불가.
5. **24GB 최고 성능**: **HyperCLOVA X SEED Think 32B** (상업 무제한, 한국어 추론 최고).
