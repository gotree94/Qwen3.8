# 반도체 설계 전용 AI (AI for Chip Design / LLM for EDA) 종합 가이드

> 대상 환경: Ubuntu 22.04.5 LTS / NVIDIA RTX 5090 24GB (CUDA 13.0) / RAM 62GB / 24코어
> 작성일: 2026-09-09

---

## 1. 반도체 설계 전용 AI란 무엇인가?

### 1-1. 핵심 개념
반도체 설계는 **EDA(Electronic Design Automation)** 소프트웨어로 진행됩니다. 칩 설계는 크게:
1. **스펙 정의** (자연어/사양)
2. **HDL 작성** (Verilog/VHDL로 하드웨어 기술)
3. **논리합성** (RTL → 게이트 넷리스트)
4. **물리설계** (Place & Route, 배치/배선)
5. **검증/시뮬레이션** (테스트벤치, 타이밍 분석)
6. **테이프아웃** (GDSII, 양산 공정 전달)

**"반도체 설계 전용 AI"** 는 이 전 과정에 LLM(대규모 언어모델)과 ML(머신러닝)을 적용해 자동화·최적화하는 기술입니다.

### 1-2. 왜 필요한가?
- 첨단 공정(2nm, HBM 등)은 설계 복잡도가 급증 → 수동 설계 한계
- 고급 반도체 설계 엔지니어 **공급 부족**
- 설계 주기가 빨라지며 생산성 혁신 필요

### 1-3. 주요 적용 분야
| 분야 | LLM/AI 역할 |
|------|-------------|
| **HDL 생성** | 자연어 스펙 → Verilog/VHDL 자동 생성 |
| **테스트벤치 생성** | 설계 검증용 테스트 자동 생성 |
| **버그 탐지·수정** | RTL 코드 오류 탐지·수정 |
| **PPA 최적화** | 성능(Performance)·전력(Power)·면적(Area) 최적화 |
| **EDA 스크립트 생성** | Tcl/도구 명령 자동 생성 |
| **검증(Verification)** | 에이전트형 자동 검증 |
| **문서·지식 관리** | 설계 문서/데이터시트 정리, RAG |

---

## 2. 어떻게 진행 중인가? (진행 방향)

### 2-1. 단계별 진화 (스마트 EDA 0~4단계)
| 단계 | 명칭 | 내용 |
|------|------|------|
| L0-L1 | 수동/CAD 시대 | 인간이 직접 스크립트·설계 |
| L2 | **AI-네이티브 EDA / Copilot** | LLM이 설계자의 **보조자(어시스턴트)** 역할. HDL 생성·코드 제안 |
| L3+ | **에이전틱 EDA (Agentic EDA)** | LLM이 **자율적으로** 도구 호출→실행→피드백 반영하며 독립 설계 |

**현재 업계는 L2(코파일럿) → L3(에이전트) 전환 중입니다.**

### 2-2. 업계 주요 움직임
| 기업/주체 | 진행 내용 |
|-----------|-----------|
| **Synopsys DSO.ai** | AI 기반 EDA 대표 주자. 삼성전자(AP), SK하이닉스(HBM), LG전자, 가온칩스 등 국내 전체 반도체 설계에 도입. 2026년 약 1,600~1,700건 테이프아웃(2nm 첨단공정 필수화). 경량 DSO.ai도 출시 |
| **삼성전자** | GTC 2026에서 "설계→제조 전과정 에이전트 AI" 발표. 시놉시스 EDA 툴 연동. **HBM4 리드타임 50% 단축, 성능 13% 개선** |
| **ChipAgents (Renoir)** | 오픈웨이트 MoE LLM을 반도체 데이터로 파인튜닝. 온프레미스(회사 내부)에서 기밀 IP 보호하며 실행. Claude Opus 4.6급 성능, 비용 절반. **"AI가 AI 칩 설계" 방향** |
| **NVIDIA** | 디지털 트윈(Omniverse)으로 반도체 공장·공정 가상화 |
| 학계(DAC, arXiv) | VerilogEval, RTLCoder, VeriGen, ChipNeMo, ChatEDA, AutoChip 등 연구 활발 |

### 2-3. 핵심 기술 방향
1. **오픈데이터셋 구축**: VeriGen(대규모 Verilog 말뭉치), RTLCoder(27,000+ 문제/답변), ChipVerilog(OpenCores 기반 벤치마크) 등
2. **소형·경량 모델**: 별도 LLM 서버 없이 로컬 GPU에서 돌리는 7B급 전용 모델로 **데이터 보안(기밀 IP) 해결**
3. **에이전트·다중에이전트**: 한 모델이 설계 전 단계를 스스로 실행(OpenClaw, CODMAS, MARVEL 등)
4. **신경-상징적 접근**: LLM + 검증(시뮬레이션) 피드백 반복 → 정확도 확보 (하드웨어는 불가피한 오류 제로 수용)

---

## 3. 오픈소스 솔루션 (사용 가능 여부)

반도체 설계 AI를 **오픈소스로** 사용하는 방법은 크게 두 갈래:
- **A. LLM(모델) 측면**: Verilog/RTL 생성에 특화된 오픈소스 모델
- **B. 도구(툴체인) 측면**: 오픈소스 EDA 합성·검증 도구

### 3-1. 오픈소스 LLM (HDL/RTL 생성 전용)
| 모델 | 크기 | VRAM | 라이선스 | 특징 |
|------|------|------|----------|------|
| **RTLCoder** (HKUST) | 7B / 6.7B | ~4GB(4bit) | 완전 오픈소스 | 자연어→Verilog, GPT-3.5 능가·GPT-4급. **이 하드웨어 24GB에 여유롭게 구동 가능** |
| **VeriGen** (UIUC) | 70M~16B | 16B는 ~30GB | 오픈소스 | 5개 CodeGen 파인튜닝 모델. Verilog 코드 완성 |
| **ChipNeMo** (NVIDIA) | 13B | ~7GB(4bit) | 오픈(데이터는 비공개) | NVIDIA 반도체 설계 전용, 기밀이슈로 일부만 공개 |
| **ChatEDA** | (LLM 기반) | 다양 | 오픈 | 자연어로 EDA 툴 조작 자동화 |
| **OpenClaw** | 에이전트 프레임워크 | 다양 | 오픈(GitHub) | 자율 설계 실행 에이전트 |

> ✅ **실무적으로 RTLCoder가 이 하드웨어(RTX 5090 24GB)에서 가장 쉽게 쓸 수 있는 오픈소스 설계 전용 LLM** 입니다.

### 3-2. 오픈소스 EDA 툴체인 (합성·검증·배치배선)
| 도구 | 용도 | Ubuntu 설치 |
|------|------|-------------|
| **Yosys** | 오픈소스 논리합성(Verilog→게이트) | ✅ |
| **Icarus Verilog (iverilog)** | Verilog 시뮬레이터 | ✅ |
| **Verilator** | 고속 Verilog/SystemVerilog 시뮬레이터 | ✅ |
| **GTKWave** | 파형(VCD) 뷰어 | ✅ |
| **OpenLane / OpenROAD** | RTL→GDSII 전체 자동 흐름 (ASIC 테이프아웃) | ✅ (Docker) |
| **OSS CAD Suite** | Yosys·nextpnr·Verilator 등 통합 패키지 | ✅ |
| **LiteX** | FPGA SoC 구축 프레임워크 | ✅ |
| **cocotb / SymbiYosys** | Python 검증 / 형식검증 | ✅ |

---

## 4. 설계 전용 AI 오픈소스 설치·사용법 (RTX 5090 24GB 기준)

### 준비물 (공통)
```bash
sudo apt update
sudo apt install -y build-essential git python3-venv python3-pip
```

---

### 4-1. RTLCoder (반도체 설계 전용 오픈소스 LLM) ⭐ 권장

RTL(Verilog) 생성 전용 경량 모델. 24GB GPU에서 원활히 동작.

#### 1) 저장소 복제 + 환경 준비
```bash
git clone https://github.com/hkust-zhiyao/RTL-Coder
cd RTL-Coder

python3 -m venv venv
source venv/bin/activate
pip install -U pip
pip install transformers accelerate torch huggingface_hub
```

#### 2) 모델 다운로드 (HuggingFace)
```bash
# RTLCoder-DeepSeek (6.7B) — 4bit는 ~4GB로 아주 가벼움
huggingface-cli download gallilabs/RTLCoder-DeepSeek-67B --local-dir ./rtlcoder
```
> ⚠️ 정확한 리포지토리명은 https://huggingface.co 에서 **"RTLCoder"** 검색해 확인하세요.
> (허깅페이스 내 `RTLCoder` 관련 공개 모델명은 버전에 따라 `RTLCoder-DeepSeek`, `RTLCoder-Mistral` 등으로 존재)

#### 3) 자연어 → Verilog 생성 스크립트
```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

model_id = "./rtlcoder"  # 다운로드한 모델
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(
    model_id,
    torch_dtype=torch.float16,
    device_map="auto",
)

prompt = "Design a 4-bit up counter with enable and reset. Write Verilog RTL."
inputs = tokenizer(prompt, return_tensors="pt").to("cuda")

output = model.generate(**inputs, max_new_tokens=512, do_sample=False)
print(tokenizer.decode(output[0], skip_special_tokens=True))
```

#### 4) 4비트 양자화 (VRAM 절약, 선택)
```bash
pip install bitsandbytes
# 코드에서 load_in_4bit=True 사용
```

---

### 4-2. VeriGen (Verilog 코드 완성 전용)

#### 1) 설치
```bash
git clone https://github.com/shailja-thakur/VGen
cd VGen
python3 -m venv venv && source venv/bin/activate
pip install torch transformers
```
> 사전 학습된 모델 체크포인트는 GitHub/논문 안내를 따라 받고, 아래와 같이 사용합니다.

#### 2) 사용 (Verilog 코드 완성)
```python
from transformers import AutoModelForCausalLM, AutoTokenizer
model = AutoModelForCausalLM.from_pretrained("권장_체크포인트", device_map="auto")
tok = AutoTokenizer.from_pretrained("권장_체크포인트")
prompt = "module counter (input clk, input reset, output reg [3:0] count);\n"
inputs = tok(prompt, return_tensors="pt").to("cuda")
out = model.generate(**inputs, max_new_tokens=200)
print(tok.decode(out[0], skip_special_tokens=True))
```

---

### 4-3. 오픈소스 EDA 툴체인 설치 (합성·검증·파형)

#### 1) 기본 검증/시뮬레이션 툴
```bash
sudo apt install -y iverilog verilator gtkwave graphviz
```
- `iverilog` : Verilog 시뮬레이션
- `verilator` : 고속/시스템Verilog 시뮬레이션
- `gtkwave` : 파형 보기

#### 2) Yosys (논리합성)
```bash
sudo apt install -y yosys
# 또는 최신 버전은 OSS CAD Suite 사용 (아래)
```

#### 3) OSS CAD Suite (종합 툴키트) — 권장
반도체 설계용 오픈소스 툴(Yosys, nextpnr, Verilator, Icarus, GTKWave 등)을 한번에 받는 방법.

```bash
# https://github.com/YosysHQ/oss-cad-suite-build/releases 에서 최신 Linux x64 다운로드
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/latest/download/oss-cad-suite-linux-x64.tgz
mkdir -p ~/oss-cad && tar -xzf oss-cad-suite-linux-x64.tgz -C ~/oss-cad
source ~/oss-cad/oss-cad-suite/environment   # 매 셸 시작 시
# 이제 yosys, iverilog, verilator, gtkwave, nextpnr 등을 바로 사용 가능
```

#### 4) OpenLane (RTL → GDSII 전체 자동흐름, ASIC)
```bash
# Docker 설치 후
sudo apt install -y docker.io git make python3-venv
sudo systemctl enable docker && sudo systemctl start docker

cd ~
git clone https://github.com/The-OpenROAD-Project/OpenLane
cd OpenLane
make            # Docker 이미지 + 빌드
make test       # 정상 동작 확인
```
사용 예:
```bash
make mount                                                   # OpenLane 환경 진입
./flow.tcl -design spm                                        # 예제 설계 하드닝
```
- 최소 25GB 디스크 여유 필요 (환경에는 2.5TB ✅)

---

## 5. 실제 사용 예시 (AI 생성 → 검증 → 시뮬레이션)

> AI(예: RTLCoder)로 Verilog를 생성하고 → iverilog로 시뮬레이션 → GTKWave로 확인하는 완전한 흐름

### 5-1. 예제: 4-bit 카운터 생성 및 시뮬레이션

**1) RTLCoder/LLM으로 생성된 Verilog (`counter.v`):**
```verilog
module counter (
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [3:0] count
);
always @(posedge clk or posedge reset) begin
    if (reset)
        count <= 4'd0;
    else if (enable)
        count <= count + 4'd1;
end
endmodule
```

**2) 테스트벤치 (`tb_counter.v`):**
```verilog
module tb_counter;
    reg clk = 0, reset = 1, enable = 1;
    wire [3:0] count;
    counter dut (.clk(clk), .reset(reset), .enable(enable), .count(count));
    always #5 clk = ~clk;
    initial begin
        #10 reset = 0;
        #200 $finish;
    end
    initial $dumpfile("counter.vcd"); $dumpvars(0, tb_counter);
endmodule
```

**3) 시뮬레이션 + 파형:**
```bash
iverilog -o sim counter.v tb_counter.v
vvp sim            # counter.vcd 생성
gtkwave counter.vcd  # 파형 확인
```

---

### 5-2. Yosys 합성 예제 (AI 설계 → 게이트 넷리스트)
```bash
yosys -p "read_verilog counter.v; synth; write_verilog synth_counter.v"
# 게이트 레벨 넷리스트 출력
```

---

## 6. 이 하드웨어(24GB)에서 쓸 수 있는지 요약

| 솔루션 | 종류 | 하드웨어 요구 | 24GB 가능? |
|--------|------|---------------|-----------|
| **RTLCoder 7B/6.7B** | 설계전용 LLM | 4GB(4bit)~14GB | ✅ **여유** |
| **RTLCoder 4bit** | 설계전용 LLM | ~4GB | ✅ **매우 여유** |
| VeriGen 16B | 설계전용 LLM | ~30GB | ⚠️ 4bit~8bit로 가능 |
| VeriGen 6B 이하 | 설계전용 LLM | ~12GB | ✅ |
| ChipNeMo 13B | 설계전용 LLM | ~7GB(4bit) | ✅ |
| Yosys / iverilog / Verilator / GTKWave | EDA 도구 | CPU 전용 | ✅ (GPU 불필요) |
| OpenLane (RTL→GDSII) | EDA 자동흐름 | CPU+Docker, 25GB 디스크 | ✅ |
| ChatEDA / OpenClaw | 에이전트 | LLM 성능에 의존 | ✅ (소형 LLM 사용 시) |

> **결론: 이 하드웨어로 반도체 설계 전용 오픈소스 AI를 충분히 설치·운영할 수 있습니다.** 특히 RTLCoder(7B) 는 24GB에서 아주 여유롭게 구동됩니다.

---

## 7. 주요 비용/제한 고려사항

1. **정확성 한계**: LLM 생성 HDL은 불가피한 오류가 있음 → 반드시 **시뮬레이션 검증** 필요 (하드웨어는 오류 제로 요구)
2. **프로덕션 툴과의 격차**: 상용 EDA(Synopsys/Cadence)와 오픈소스는 기능 격차 존재
3. **학습 데이터 제한**: 기업 내부 IP는 공개 데이터에 없어 파인튜닝이 중요
4. **보안**: RTLCoder 등 로컬 모델은 데이터가 외부로 나가지 않아 **기밀 설계(IP) 보호**에 유리
5. **라이선스**: 대부분 오픈소스이지만, 상업 사용 전 각 모델/도구의 라이선스 확인 (RTLCoder는 오픈소스·상업 사용 가능)

---

## 8. 참고 자료
- RTLCoder: https://github.com/hkust-zhiyao/RTL-Coder
- VeriGen: https://github.com/shailja-thakur/VGen
- Yosys: https://github.com/YosysHQ/yosys
- OpenLane: https://github.com/The-OpenROAD-Project/OpenLane
- OSS CAD Suite: https://github.com/YosysHQ/oss-cad-suite-build
- ChipVerilog 벤치마크: https://github.com/HKUSTGZ-MICS-LYU/ChipVerilog
- 오픈소스 FPGA 툴체인 (Docker, Yosys·Verilator·cocotb 등): `ghcr.io/zubax/zubax-fpga-toolchain-oss:latest`

---

## 9. 최종 요약

1. **반도체 설계 AI** = 자연어/스펙으로 **HDL(Verilog) 생성 + PPA 최적화 + 검증 자동화** 하는 LLM/에이전트 기술
2. **현재 방향**: 상용(시놉시스 DSO.ai, 삼성·SK·LG 도입) + 학계 오픈소스(RTLCoder·VeriGen·ChipNeMo)가 병행. **"AI 어시스턴트(L2) → 자율 에이전트(L3)"로 진화 중**
3. **사용 가능**: ✅ 가능. **RTLCoder(7B)** 를 이 24GB 하드웨어에서 쉽게 설치·구동 가능
4. **오픈소스 설계 전용 솔루션**: RTLCoder, VeriGen, ChipNeMo, ChatEDA 등 (모델) + Yosys, iverilog, Verilator, OpenLane, OSS CAD Suite (도구)
5. **설치·사용**: 
   - LLM 생성 → `git clone RTLCoder` + transformers → 자연어로 Verilog 생성
   - 검증 → `iverilog`/`verilator` 시뮬레이션 + `GTKWave` 파형
   - 합성 → `yosys` / 전체흐름 → `OpenLane`(Docker)
