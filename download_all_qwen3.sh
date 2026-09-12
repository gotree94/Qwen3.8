#!/bin/bash
# ============================================
# Qwen3 전체 모델 다운로드 스크립트
# ============================================
# 사용법: chmod +x download_all_qwen3.sh && ./download_all_qwen3.sh
# ============================================

DOWNLOAD_DIR="$HOME/Desktop/qwen3-all-models"
LOG_FILE="$DOWNLOAD_DIR/download.log"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 디렉토리 생성
mkdir -p "$DOWNLOAD_DIR"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Qwen3 전체 모델 GGUF 다운로드${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "저장 위치: ${YELLOW}$DOWNLOAD_DIR${NC}"
echo ""

# 모델 목록 (저장 위치, 파일명, URL)
declare -A MODELS
MODELS=(
    ["0.6B"]="Qwen/Qwen3-0.6B-GGUF|Qwen3-0.6B-Q8_0.gguf"
    ["1.7B"]="Qwen/Qwen3-1.7B-GGUF|Qwen3-1.7B-Q8_0.gguf"
    ["4B"]="Qwen/Qwen3-4B-GGUF|Qwen3-4B-Q4_K_M.gguf"
    ["8B"]="Qwen/Qwen3-8B-GGUF|Qwen3-8B-Q4_K_M.gguf"
    ["14B"]="Qwen/Qwen3-14B-GGUF|Qwen3-14B-Q4_K_M.gguf"
    ["32B"]="Qwen/Qwen3-32B-GGUF|Qwen3-32B-Q4_K_M.gguf"
    ["30B-A3B"]="Qwen/Qwen3-30B-A3B-GGUF|Qwen3-30B-A3B-Q4_K_M.gguf"
)

# 다운로드 함수
download_model() {
    local name=$1
    local repo=$2
    local filename=$3
    local url="https://huggingface.co/$repo/resolve/main/$filename"
    local output="$DOWNLOAD_DIR/$filename"
    
    # 이미 다운로드된 파일 확인
    if [ -f "$output" ]; then
        local size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
        if [ "$size" -gt 1000000 ]; then
            echo -e "${GREEN}  [건너뜀] $filename (이미 다운로드됨)${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}  [다운로드] $filename${NC}"
    echo "  URL: $url" >> "$LOG_FILE"
    
    # aria2로 다운로드 (16 연결, 파일명 지정)
    aria2c -x 16 -s 16 -k 1M \
        -d "$DOWNLOAD_DIR" \
        -o "$filename" \
        -c \
        "$url" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  [완료] $filename${NC}"
    else
        echo -e "${RED}  [실패] $filename - 로그 확인: $LOG_FILE${NC}"
        return 1
    fi
}

# 전체 다운로드 실행
echo -e "${BLUE}Q4_K_M 버전 다운로드 시작 (권장)${NC}"
echo ""

for name in "0.6B" "1.7B" "4B" "8B" "14B" "32B" "30B-A3B"; do
    IFS='|' read -r repo filename <<< "${MODELS[$name]}"
    echo -e "${BLUE}--- Qwen3-$name ---${NC}"
    download_model "$name" "$repo" "$filename"
    echo ""
done

echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  다운로드 완료!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "저장 위치: ${YELLOW}$DOWNLOAD_DIR${NC}"
echo ""
echo -e "파일 목록:"
ls -lh "$DOWNLOAD_DIR"/*.gguf 2>/dev/null
echo ""
echo -e "총 사용량:"
du -sh "$DOWNLOAD_DIR"
