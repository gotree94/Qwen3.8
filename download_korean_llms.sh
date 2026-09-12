#!/bin/bash
# ============================================================
#国产(한국) 개발 LLM 전체 다운로드 스크립트
# 대상: Ubuntu 22.04 / RTX 5090 24GB
# 라이선스 확인 후 사용하세요.
# ============================================================

set -e

# 설정
DOWNLOAD_DIR="$HOME/Desktop/korean-llms"
ARIA2_OPTS="-x 16 -s 16 -k 1M"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} 国产(한국) 개발 LLM 다운로드 스크립트${NC}"
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

check_huggingface_cli() {
    if ! command -v huggingface-cli &> /dev/null; then
        echo -e "${YELLOW}huggingface-cli가 설치되어 있지 않습니다. 설치합니다...${NC}"
        pip install -U huggingface-hub
    fi
}

# ============================================================
# 1. HyperCLOVA X SEED 시리즈 (네이버) - 상업 무제한
# ============================================================
download_hyperclova() {
    print_section "1. HyperCLOVA X SEED 시리즈 (네이버) - 상업 무제한"

    # HyperCLOVA X SEED Think 32B
    echo -e "${BLUE}[1/3] HyperCLOVA X SEED Think 32B (~19GB Q4)${NC}"
    echo "  라이선스: 상업 무제한"
    echo "  특징: 한국어 추론 특화, 24GB에 최적"
    mkdir -p "$DOWNLOAD_DIR/hyperclova-x-seed-think-32b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/hyperclova-x-seed-think-32b" \
        "https://huggingface.co/naver-hyperclovax/HyperCLOVAX-SEED-Think-32B/resolve/main/model-00001-of-00004.safetensors"

    # HyperCLOVA X SEED Think 14B
    echo -e "${BLUE}[2/3] HyperCLOVA X SEED Think 14B (~9GB Q4)${NC}"
    echo "  라이선스: 상업 무제한"
    echo "  특징: 경량 추론, 여유로운 구동"
    mkdir -p "$DOWNLOAD_DIR/hyperclova-x-seed-think-14b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/hyperclova-x-seed-think-14b" \
        "https://huggingface.co/naver-hyperclovax/HyperCLOVAX-SEED-Think-14B/resolve/main/model-00001-of-00002.safetensors"

    # HyperCLOVA X SEED Omni 8B
    echo -e "${BLUE}[3/3] HyperCLOVA X SEED Omni 8B (~6GB)${NC}"
    echo "  라이선스: 상업 무제한"
    echo "  특징: 다중모달 (텍스트+이미지+음성)"
    mkdir -p "$DOWNLOAD_DIR/hyperclova-x-seed-omni-8b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/hyperclova-x-seed-omni-8b" \
        "https://huggingface.co/naver-hyperclovax/HyperCLOVAX-SEED-Omni-8B/resolve/main/model-00001-of-00002.safetensors"
}

# ============================================================
# 2. EXAONE 시리즈 (LG AI연구원) - ⚠️ 비상업용(NC)
# ============================================================
download_exaone() {
    print_section "2. EXAONE 시리즈 (LG AI연구원) - ⚠️ 비상업용(NC)"

    # EXAONE 3.5 32B
    echo -e "${BLUE}[1/4] EXAONE 3.5 32B (~19GB Q4)${NC}"
    echo "  라이선스: ⚠️ 비상업용 (NC)"
    echo "  특징: 한국어+추론, 24GB에 구동"
    mkdir -p "$DOWNLOAD_DIR/exaone-3.5-32b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/exaone-3.5-32b" \
        "https://huggingface.co/LGAI-EXAONE/EXAONE-3.5-32B-Instruct/resolve/main/model-00001-of-00007.safetensors"

    # EXAONE 3.5 7.8B
    echo -e "${BLUE}[2/4] EXAONE 3.5 7.8B (~5GB Q4)${NC}"
    echo "  라이선스: ⚠️ 비상업용 (NC)"
    echo "  특징: 소형·빠른 배포"
    mkdir -p "$DOWNLOAD_DIR/exaone-3.5-7.8b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/exaone-3.5-7.8b" \
        "https://huggingface.co/LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct/resolve/main/model-00001-of-00002.safetensors"

    # EXAONE 4.0 32B
    echo -e "${BLUE}[3/4] EXAONE 4.0 32B (~19GB Q4)${NC}"
    echo "  라이선스: ⚠️ 비상업용 (NC)"
    echo "  특징: 한국 전문자격시험 통과 모델"
    mkdir -p "$DOWNLOAD_DIR/exaone-4.0-32b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/exaone-4.0-32b" \
        "https://huggingface.co/LGAI-EXAONE/EXAONE-4.0-32B-Instruct/resolve/main/model-00001-of-00007.safetensors"

    # EXAONE 4.5 33B (비전-언어 VLM)
    echo -e "${BLUE}[4/4] EXAONE 4.5 33B (~20GB Q4)${NC}"
    echo "  라이선스: ⚠️ 비상업용 (NC)"
    echo "  특징: 비전+언어, 최신 성능"
    mkdir -p "$DOWNLOAD_DIR/exaone-4.5-33b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/exaone-4.5-33b" \
        "https://huggingface.co/LGAI-EXAONE/EXAONE-4.5-33B/resolve/main/model-00001-of-00007.safetensors"
}

# ============================================================
# 3. SOLAR 10.7B (Upstage) - Apache 2.0 상업 무료
# ============================================================
download_solar() {
    print_section "3. SOLAR 10.7B (Upstage) - Apache 2.0 상업 무료"

    echo -e "${BLUE}[1/1] SOLAR 10.7B (~7GB Q4)${NC}"
    echo "  라이선스: Apache 2.0 (상업 무료)"
    echo "  특징: 소형·빠른 배포, 2023년 리더보드 1위"
    mkdir -p "$DOWNLOAD_DIR/solar-10.7b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/solar-10.7b" \
        "https://huggingface.co/upstage/SOLAR-10.7B-Instruct-v1.0/resolve/main/model-00001-of-00002.safetensors"
}

# ============================================================
# 4. KORani 13B (크래프톤)
# ============================================================
download_korani() {
    print_section "4. KORani 13B (크래프톤)"

    echo -e "${BLUE}[1/1] KORani 13B (~8GB Q4)${NC}"
    echo "  라이선스: 오픈 웨이트"
    echo "  특징: 한국어 특화"
    mkdir -p "$DOWNLOAD_DIR/korani-13b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/korani-13b" \
        "https://huggingface.co/krafton/KoRani-13B/resolve/main/model-00001-of-00003.safetensors"
}

# ============================================================
# 5. EEVE-Korean 10.8B
# ============================================================
download_eeve() {
    print_section "5. EEVE-Korean 10.8B"

    echo -e "${BLUE}[1/1] EEVE-Korean 10.8B (~7GB Q4)${NC}"
    echo "  라이선스: Apache 2.0"
    echo "  특징: 한국어 특화, 소형"
    mkdir -p "$DOWNLOAD_DIR/eeve-korean-10.8b"
    aria2c $ARIA2_OPTS \
        -d "$DOWNLOAD_DIR/eeve-korean-10.8b" \
        "https://huggingface.co/Yüksei-Dilleri/EEVE-Korean-10.8B/resolve/main/model-00001-of-00002.safetensors"
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
    download_hyperclova
    download_exaone
    download_solar
    download_korani
    download_eeve

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  모든 다운로드 완료!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "다운로드된 모델: $DOWNLOAD_DIR"
    echo ""
    echo "모델별 크기 및 용도:"
    echo "  - HyperCLOVA X SEED Think 32B: ~19GB (한국어 추론 최고)"
    echo "  - HyperCLOVA X SEED Think 14B: ~9GB (경량 추론)"
    echo "  - HyperCLOVA X SEED Omni 8B: ~6GB (다중모달)"
    echo "  - EXAONE 3.5 32B: ~19GB (⚠️ 비상업용)"
    echo "  - EXAONE 3.5 7.8B: ~5GB (⚠️ 비상업용)"
    echo "  - EXAONE 4.0 32B: ~19GB (⚠️ 비상업용)"
    echo "  - EXAONE 4.5 33B: ~20GB (⚠️ 비상업용, 비전-언어)"
    echo "  - SOLAR 10.7B: ~7GB (Apache 2.0, 상업 무료)"
    echo "  - KORani 13B: ~8GB (한국어 특화)"
    echo "  - EEVE-Korean 10.8B: ~7GB (한국어 특화)"
    echo ""
    echo "총 예상 용량: ~120GB"
    echo ""
    echo "라이선스 확인:"
    echo "  - HyperCLOVA X SEED: 상업 무제한 ✅"
    echo "  - EXAONE: ⚠️ 비상업용 (NC) - 개인/연구용만 가능"
    echo "  - SOLAR: Apache 2.0 (상업 무료) ✅"
    echo "  - KORani: 오픈 웨이트"
    echo "  - EEVE: Apache 2.0"
}

# 스크립트 실행
main "$@"
