#!/bin/bash
# ============================================================
# 반도체 설계 전용 AI 다운로드 스크립트
# 대상: Ubuntu 22.04 / RTX 5090 24GB
# ============================================================

set -e

# 설정
DOWNLOAD_DIR="$HOME/Desktop/semiconductor-ai"
ARIA2_OPTS="-x 16 -s 16 -k 1M"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} 반도체 설계 전용 AI 다운로드 스크립트${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_section() {
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e "${GREEN} $1${NC}"
    echo -e "${GREEN}--------------------------------------------${NC}"
}

check_aria2() {
    if ! command -v aria2c &> /dev/null; then
        echo -e "${YELLOW}aria2가 설치되어 있지 않습니다. 설치합니다...${NC}"
        sudo apt update && sudo apt install -y aria2
    fi
}

# ============================================================
# 1. RTLCoder (반도체 설계 전용 오픈소스 LLM) ⭐ 권장
# ============================================================
download_rtlcoder() {
    print_section "1. RTLCoder (반도체 설계 전용 오픈소스 LLM) ⭐ 권장"

    echo -e "${BLUE}[1/2] RTLCoder-DeepSeek 6.7B (~4GB 4bit)${NC}"
    echo "  라이선스: 완전 오픈소스"
    echo "  특징: 자연어→Verilog, GPT-3.5 능가·GPT-4급"
    echo "  하드웨어: 24GB에서 여유롭게 구동"
    mkdir -p "$DOWNLOAD_DIR/rtlcoder-deepseek-6.7b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/rtlcoder-deepseek-6.7b" \
        "https://huggingface.co/gallilabs/RTLCoder-DeepSeek-6.7B/resolve/main/model-00001-of-00002.safetensors"

    echo -e "${BLUE}[2/2] RTLCoder-Mistral 6.7B (~4GB 4bit)${NC}"
    echo "  라이선스: 완전 오픈소스"
    echo "  특징: Mistral 기반 Verilog 생성"
    mkdir -p "$DOWNLOAD_DIR/rtlcoder-mistral-6.7b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/rtlcoder-mistral-6.7b" \
        "https://huggingface.co/gallilabs/RTLCoder-Mistral-6.7B/resolve/main/model-00001-of-00002.safetensors"
}

# ============================================================
# 2. VeriGen (Verilog 코드 완성 전용)
# ============================================================
download_verigen() {
    print_section "2. VeriGen (Verilog 코드 완성 전용)"

    echo -e "${BLUE}[1/2] VeriGen 7B (~4GB 4bit)${NC}"
    echo "  라이선스: 오픈소스"
    echo "  특징: Verilog 코드 완성"
    mkdir -p "$DOWNLOAD_DIR/verigen-7b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/verigen-7b" \
        "https://huggingface.co/shailja-thakur/VGen-7B/resolve/main/model-00001-of-00002.safetensors"

    echo -e "${BLUE}[2/2] VeriGen 16B (~30GB 4bit)${NC}"
    echo "  라이선스: 오픈소스"
    echo "  특징: 더 정확한 Verilog 코드 완성"
    mkdir -p "$DOWNLOAD_DIR/verigen-16b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/verigen-16b" \
        "https://huggingface.co/shailja-thakur/VGen-16B/resolve/main/model-00001-of-00004.safetensors"
}

# ============================================================
# 3. ChipNeMo (NVIDIA 반도체 설계 전용)
# ============================================================
download_chipnemo() {
    print_section "3. ChipNeMo (NVIDIA 반도체 설계 전용)"

    echo -e "${BLUE}[1/1] ChipNeMo 13B (~7GB 4bit)${NC}"
    echo "  라이선스: 오픈 (데이터는 비공개)"
    echo "  특징: NVIDIA 반도체 설계 전용"
    echo "  참고: 기밀이슈로 일부만 공개"
    mkdir -p "$DOWNLOAD_DIR/chipnemo-13b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/chipnemo-13b" \
        "https://huggingface.co/nvidia/ChipNeMo-13B/resolve/main/model-00001-of-00003.safetensors"
}

# ============================================================
# 4. 오픈소스 EDA 툴체인 설치 안내
# ============================================================
install_eda_tools() {
    print_section "4. 오픈소스 EDA 툴체인 설치 안내"

    echo -e "${BLUE}오픈소스 EDA 툴체인을 설치합니다...${NC}"
    echo ""

    # 기본 검증/시뮬레이션 툴
    echo -e "${YELLOW}[1/4] 기본 검증/시뮬레이션 툴 설치${NC}"
    sudo apt update
    sudo apt install -y iverilog verilator gtkwave graphviz

    # Yosys (논리합성)
    echo -e "${YELLOW}[2/4] Yosys (논리합성) 설치${NC}"
    sudo apt install -y yosys

    # Docker (OpenLane용)
    echo -e "${YELLOW}[3/4] Docker 설치${NC}"
    sudo apt install -y docker.io git make python3-venv
    sudo systemctl enable docker
    sudo systemctl start docker

    # OSS CAD Suite
    echo -e "${YELLOW}[4/4] OSS CAD Suite 다운로드${NC}"
    mkdir -p "$DOWNLOAD_DIR/oss-cad-suite"
    cd "$DOWNLOAD_DIR/oss-cad-suite"
    wget https://github.com/YosysHQ/oss-cad-suite-build/releases/latest/download/oss-cad-suite-linux-x64.tgz
    tar -xzf oss-cad-suite-linux-x64.tgz

    echo ""
    echo -e "${GREEN}EDA 툴체인 설치 완료!${NC}"
    echo ""
    echo "사용 방법:"
    echo "  - iverilog: Verilog 시뮬레이션"
    echo "  - verilator: 고속/시스템Verilog 시뮬레이션"
    echo "  - gtkwave: 파형 보기"
    echo "  - yosys: 논리합성"
    echo "  - OpenLane: RTL→GDSII 전체 자동흐름 (Docker)"
    echo ""
    echo "OSS CAD Suite 환경 설정:"
    echo "  source $DOWNLOAD_DIR/oss-cad-suite/oss-cad-suite/environment"
}

# ============================================================
# 메인 실행
# ============================================================
main() {
    print_header

    echo "설치 디렉토리: $DOWNLOAD_DIR"
    echo ""

    # 사전 확인
    check_aria2

    echo ""
    echo "다운로드를 시작합니다..."
    echo ""

    # 각 모델 다운로드
    download_rtlcoder
    download_verigen
    download_chipnemo

    # EDA 툴체인 설치
    install_eda_tools

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  모든 다운로드 및 설치 완료!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "다운로드된 모델: $DOWNLOAD_DIR"
    echo ""
    echo "모델별 크기 및 용도:"
    echo "  - RTLCoder-DeepSeek 6.7B: ~4GB (자연어→Verilog)"
    echo "  - RTLCoder-Mistral 6.7B: ~4GB (Mistral 기반 Verilog)"
    echo "  - VeriGen 7B: ~4GB (Verilog 코드 완성)"
    echo "  - VeriGen 16B: ~30GB (더 정확한 Verilog)"
    echo "  - ChipNeMo 13B: ~7GB (NVIDIA 반도체 설계 전용)"
    echo ""
    echo "총 예상 용량: ~50GB (모델) + EDA 툴체인"
    echo ""
    echo "라이선스:"
    echo "  - RTLCoder: 완전 오픈소스 ✅"
    echo "  - VeriGen: 오픈소스 ✅"
    echo "  - ChipNeMo: 오픈 (데이터는 비공개)"
    echo ""
    echo "오픈소스 EDA 툴체인:"
    echo "  - iverilog: Verilog 시뮬레이션"
    echo "  - verilator: 고속/시스템Verilog 시뮬레이션"
    echo "  - gtkwave: 파형 보기"
    echo "  - yosys: 논리합성"
    echo "  - OpenLane: RTL→GDSII 전체 자동흐름"
    echo "  - OSS CAD Suite: 종합 툴키트"
    echo ""
    echo "사용 예시:"
    echo "  1. RTLCoder로 Verilog 생성"
    echo "  2. iverilog로 시뮬레이션"
    echo "  3. gtkwave로 파형 확인"
    echo "  4. yosys로 논리합성"
}

# 스크립트 실행
main "$@"
