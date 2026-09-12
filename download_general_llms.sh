#!/bin/bash
# ============================================================
# 범용(일반) LLM 전체 다운로드 스크립트
# 대상: Ubuntu 22.04 / RTX 5090 24GB
# ============================================================

set -e

# 설정
DOWNLOAD_DIR="$HOME/Desktop/general-llms"
ARIA2_OPTS="-x 16 -s 16 -k 1M"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} 범용(일반) LLM 다운로드 스크립트${NC}"
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
# 1. Qwen3.6 27B (최고 성능 추천)
# ============================================================
download_qwen36_27b() {
    print_section "1. Qwen3.6 27B (24GB에서 성능 최고)"

    echo -e "${BLUE}[1/1] Qwen3.6 27B Q4_K_M (~17-22GB)${NC}"
    echo "  라이선스: Apache 2.0"
    echo "  특징: 24GB에서 돌릴 수 있는 최상위 모델"
    echo "  벤치마크: SWE-bench 68.9% (397B급과 견줄 만큼)"
    mkdir -p "$DOWNLOAD_DIR/qwen3.6-27b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/qwen3.6-27b" \
        "https://huggingface.co/Qwen/Qwen3.6-27B-GGUF/resolve/main/qwen3.6-27b-q4_k_m.gguf"
}

# ============================================================
# 2. DeepSeek-R1 32B (최고 추론/사고사슬)
# ============================================================
download_deepseek_r1_32b() {
    print_section "2. DeepSeek-R1 32B (최고 추론/사고사슬)"

    echo -e "${BLUE}[1/1] DeepSeek-R1 32B Q4_K_M (~20GB)${NC}"
    echo "  라이선스: MIT"
    echo "  특징: 최고 수준 추론/사고사델 모델"
    echo "  벤치마크: AIME 72.6%, MATH-500 94.3%"
    mkdir -p "$DOWNLOAD_DIR/deepseek-r1-32b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/deepseek-r1-32b" \
        "https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
}

# ============================================================
# 3. Qwen 2.5 Coder 32B (전문 코딩)
# ============================================================
download_qwen25_coder_32b() {
    print_section "3. Qwen 2.5 Coder 32B (전문 코딩)"

    echo -e "${BLUE}[1/1] Qwen 2.5 Coder 32B Q4_K_M (~20GB)${NC}"
    echo "  라이선스: Apache 2.0"
    echo "  특징: SOTA급 코딩 (HumanEval 92.7%)"
    mkdir -p "$DOWNLOAD_DIR/qwen2.5-coder-32b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/qwen2.5-coder-32b" \
        "https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/qwen2.5-coder-32b-instruct-q4_k_m.gguf"
}

# ============================================================
# 4. Qwen3 8B (가벼운 기본 모델)
# ============================================================
download_qwen3_8b() {
    print_section "4. Qwen3 8B (가벼운 기본 모델)"

    echo -e "${BLUE}[1/1] Qwen3 8B Q4_K_M (~5GB)${NC}"
    echo "  라이선스: Apache 2.0"
    echo "  특징: 가벼운 기본 모델, 빠른 추론"
    mkdir -p "$DOWNLOAD_DIR/qwen3-8b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/qwen3-8b" \
        "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
}

# ============================================================
# 5. Llama 3.1 8B (가벼운 기본 모델)
# ============================================================
download_llama31_8b() {
    print_section "5. Llama 3.1 8B (가벼운 기본 모델)"

    echo -e "${BLUE}[1/1] Llama 3.1 8B Q4_K_M (~5GB)${NC}"
    echo "  라이선스: Llama 3.1 Community License"
    echo "  특징: Meta의 검증된 기본 모델"
    mkdir -p "$DOWNLOAD_DIR/llama3.1-8b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/llama3.1-8b" \
        "https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct-GGUF/resolve/main/llama-3.1-8b-instruct-q4_k_m.gguf"
}

# ============================================================
# 6. Gemma 3 27B (Google)
# ============================================================
download_gemma3_27b() {
    print_section "6. Gemma 3 27B (Google)"

    echo -e "${BLUE}[1/1] Gemma 3 27B Q4_K_M (~16GB)${NC}"
    echo "  라이선스: Gemma Terms of Use"
    echo "  특징: Google의 소스 모델파일 라이선스"
    mkdir -p "$DOWNLOAD_DIR/gemma3-27b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/gemma3-27b" \
        "https://huggingface.co/google/gemma-3-27b-it-GGUF/resolve/main/gemma-3-27b-it-q4_k_m.gguf"
}

# ============================================================
# 7. DeepSeek-R1 14B (경량 추론)
# ============================================================
download_deepseek_r1_14b() {
    print_section "7. DeepSeek-R1 14B (경량 추론)"

    echo -e "${BLUE}[1/1] DeepSeek-R1 14B Q4_K_M (~9GB)${NC}"
    echo "  라이선스: MIT"
    echo "  특징: 경량 추론 모델"
    mkdir -p "$DOWNLOAD_DIR/deepseek-r1-14b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/deepseek-r1-14b" \
        "https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-14B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf"
}

# ============================================================
# 8. Qwen 2.5 14B (다용도)
# ============================================================
download_qwen25_14b() {
    print_section "8. Qwen 2.5 14B (다용도)"

    echo -e "${BLUE}[1/1] Qwen 2.5 14B Q4_K_M (~9GB)${NC}"
    echo "  라이선스: Apache 2.0"
    echo "  특징: 다용도 일반 채팅/RAG/다국어"
    mkdir -p "$DOWNLOAD_DIR/qwen2.5-14b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/qwen2.5-14b" \
        "https://huggingface.co/Qwen/Qwen2.5-14B-Instruct-GGUF/resolve/main/qwen2.5-14b-instruct-q4_k_m.gguf"
}

# ============================================================
# 9. Qwen3-Coder 30B (에이전트 코딩)
# ============================================================
download_qwen3_coder_30b() {
    print_section "9. Qwen3-Coder 30B (에이전트 코딩)"

    echo -e "${BLUE}[1/1] Qwen3-Coder 30B Q4_K_M (~17-19GB)${NC}"
    echo "  라이선스: Apache 2.0"
    echo "  특징: 에이전트 코딩, 256K 컨텍스트"
    mkdir -p "$DOWNLOAD_DIR/qwen3-coder-30b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/qwen3-coder-30b" \
        "https://huggingface.co/Qwen/Qwen3-Coder-30B-A3B-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Q4_K_M.gguf"
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
    download_qwen36_27b
    download_deepseek_r1_32b
    download_qwen25_coder_32b
    download_qwen3_8b
    download_llama31_8b
    download_gemma3_27b
    download_deepseek_r1_14b
    download_qwen25_14b
    download_qwen3_coder_30b

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  모든 다운로드 완료!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "다운로드된 모델: $DOWNLOAD_DIR"
    echo ""
    echo "모델별 크기 및 용도:"
    echo "  - Qwen3.6 27B: ~17-22GB (24GB에서 최고 성능)"
    echo "  - DeepSeek-R1 32B: ~20GB (최고 추론/사고사슬)"
    echo "  - Qwen 2.5 Coder 32B: ~20GB (전문 코딩)"
    echo "  - Qwen3 8B: ~5GB (가벼운 기본 모델)"
    echo "  - Llama 3.1 8B: ~5GB (Meta의 검증된 기본 모델)"
    echo "  - Gemma 3 27B: ~16GB (Google 소스 모델파일)"
    echo "  - DeepSeek-R1 14B: ~9GB (경량 추론)"
    echo "  - Qwen 2.5 14B: ~9GB (다용도)"
    echo "  - Qwen3-Coder 30B: ~17-19GB (에이전트 코딩)"
    echo ""
    echo "총 예상 용량: ~120-140GB"
    echo ""
    echo "라이선스:"
    echo "  - Apache 2.0: Qwen3.6 27B, Qwen 2.5 Coder 32B, Qwen3 8B, Qwen 2.5 14B, Qwen3-Coder 30B"
    echo "  - MIT: DeepSeek-R1 32B, DeepSeek-R1 14B"
    echo "  - Llama 3.1: Meta Llama 3.1 Community License"
    echo "  - Gemma: Google Gemma Terms of Use"
}

# 스크립트 실행
main "$@"
