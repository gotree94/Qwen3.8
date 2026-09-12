# ============================================
# 모든 모델 다운로드 스크립트 (Windows)
# Qwen3 전체 + 범용 LLM + 한국 LLM + 반도체 AI
# 사용법:  .\run_all.ps1
# 실행정책 오류 시:
#   powershell -ExecutionPolicy Bypass -File .\run_all.ps1
# ============================================

#requires -Version 5.1
$ErrorActionPreference = 'Continue'

Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  모든 모델 다운로드 시작 (Windows)' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '⚠️ 총 예상 용량: Qwen3 53GB + 범용 120-140GB + 한국 120GB + 반도체 50GB' -ForegroundColor Yellow
Write-Host '   = 약 350GB+ (디스크 여유 공간 확인 필수)' -ForegroundColor Yellow
Write-Host ''

$scripts = @(
    @{ Name = 'download_all_qwen3.ps1';       Desc = 'Qwen3 전체 GGUF (7개, ~53GB)' },
    @{ Name = 'download_general_llms.ps1';    Desc = '범용 LLM (9개, ~120-140GB)' },
    @{ Name = 'download_korean_llms.ps1';     Desc = '한국 LLM (10개, ~120GB)' },
    @{ Name = 'download_semiconductor_ai.ps1'; Desc = '반도체 설계 AI (5개, ~50GB)' }
)

foreach ($s in $scripts) {
    $p = Join-Path $PSScriptRoot $s.Name
    Write-Host ''
    Write-Host ('========== {0} ({1}) ==========' -f $s.Name, $s.Desc) -ForegroundColor Cyan
    if (Test-Path $p) {
        & $p
    } else {
        Write-Host "  [누락] $p" -ForegroundColor Red
    }
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host '  전체 다운로드 완료!' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green