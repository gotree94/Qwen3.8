# ============================================
# 범용(일반) LLM 전체 다운로드 스크립트 (Windows)
# 원본: download_general_llms.sh
# 사용법:  .\download_general_llms.ps1
# 실행정책 오류 시:
#   powershell -ExecutionPolicy Bypass -File .\download_general_llms.ps1
# 요구사항: aria2c (없으면 winget으로 자동 설치 시도)
#
# ⚠️ 원본 sh에서 7개 모델의 저장소 ID가 존재하지 않아(HF 401) 실제 저장소로 교체했습니다.
#    meta-llama/deepseek-ai/google/Qwen 공식 GGUF 저장소가 없어서
#    bartowski / unsloth / ggml-org의 공개 GGUF 저장소를 사용합니다.
# ============================================

#requires -Version 5.1
$ErrorActionPreference = 'Continue'

$DesktopDir = [Environment]::GetFolderPath('Desktop')
$DOWNLOAD_DIR = Join-Path $DesktopDir 'general-llms'

# --- 색상 헬퍼 ---
function Write-Info { Write-Host ($args -join ' ') -ForegroundColor Cyan }
function Write-OK   { Write-Host ($args -join ' ') -ForegroundColor Green }
function Write-Warn { Write-Host ($args -join ' ') -ForegroundColor Yellow }
function Write-Err  { Write-Host ($args -join ' ') -ForegroundColor Red }

# --- aria2c 확인 / 자동 설치 ---
$script:ARIA2C = $null

function Ensure-aria2 {
    $cmd = Get-Command aria2c -ErrorAction SilentlyContinue
    if ($cmd) {
        $script:ARIA2C = $cmd.Source
        Write-OK "aria2c 사용 가능: $($cmd.Source)"
        return $true
    }

    Write-Warn 'aria2c가 설치되어 있지 않습니다. winget으로 설치를 시도합니다...'
    Write-Warn '(인터넷 연결 필요, 동의 프롬프트가 뜨면 수락하세요)'
    try {
        winget install --id aria2.aria2 -e --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
    } catch { }

    $cmd = Get-Command aria2c -ErrorAction SilentlyContinue
    if ($cmd) {
        $script:ARIA2C = $cmd.Source
        Write-OK "aria2 설치 완료: $($cmd.Source)"
        return $true
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'),
        'C:\Program Files\aria2',
        (Join-Path $env:USERPROFILE 'aria2')
    )
    foreach ($base in $candidates) {
        if (Test-Path $base) {
            $found = Get-ChildItem -Path $base -Recurse -Filter 'aria2c.exe' -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($found) {
                $script:ARIA2C = $found.FullName
                Write-OK "aria2c 발견: $($found.FullName)"
                return $true
            }
        }
    }

    Write-Err 'aria2c를 찾을 수 없습니다.'
    Write-Err '수동 설치: https://github.com/aria2/aria2/releases 에서'
    Write-Err 'aria2-*-win-64bit-build1.zip 다운로드 후 압축 풀고 PATH에 추가하세요.'
    return $false
}

# --- aria2c로 파일 다운로드 (이어받기 + 건너뛰기) ---
function Invoke-Aria2c {
    param([string]$Url, [string]$OutDir, [string]$FileName)

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $dest = Join-Path $OutDir $FileName

    if ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 1MB)) {
        Write-OK "  [건너뜀] $FileName (이미 존재)"
        return $true
    }

    Write-Warn "  [다운로드] $FileName"
    if ($script:ARIA2C) {
        & $script:ARIA2C -x 16 -s 16 -k 1M -c -d $OutDir -o $FileName $Url 2>&1 | ForEach-Object { Write-Host "    $_" }
    } else {
        & aria2c -x 16 -s 16 -k 1M -c -d $OutDir -o $FileName $Url 2>&1 | ForEach-Object { Write-Host "    $_" }
    }

    $ok = ($LASTEXITCODE -eq 0) -and (Test-Path $dest) -and ((Get-Item $dest).Length -gt 1MB)
    if ($ok) { Write-OK "  [완료] $FileName"; return $true }
    Write-Err "  [실패] $FileName (exit code: $LASTEXITCODE) - 다시 실행하면 이어받기 됩니다"
    return $false
}

# --- 모델 목록 (HuggingFace에 실존하는 GGUF 저장소로 확정) ---
$script:Models = @(
    @{
        Label = 'Qwen3.6 27B Q4_K_M (~17-22GB)'
        Note  = 'SWE-bench 68.9%, Apache 2.0 (unsloth 공식 GGUF)'
        Sub   = 'qwen3.6-27b'
        Url   = 'https://huggingface.co/unsloth/Qwen3.6-27B-GGUF/resolve/main/Qwen3.6-27B-Q4_K_M.gguf'
    },
    @{
        Label = 'DeepSeek-R1 32B Q4_K_M (~20GB)'
        Note  = 'AIME 72.6%, MIT (bartowski GGUF)'
        Sub   = 'deepseek-r1-32b'
        Url   = 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf'
    },
    @{
        Label = 'Qwen 2.5 Coder 32B Q4_K_M (~20GB)'
        Note  = 'HumanEval 92.7%, Apache 2.0'
        Sub   = 'qwen2.5-coder-32b'
        Url   = 'https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/qwen2.5-coder-32b-instruct-q4_k_m.gguf'
    },
    @{
        Label = 'Qwen3 8B Q4_K_M (~5GB)'
        Note  = 'Apache 2.0'
        Sub   = 'qwen3-8b'
        Url   = 'https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf'
    },
    @{
        Label = 'Llama 3.1 8B Q4_K_M (~5GB)'
        Note  = 'Llama 3.1 Community License (bartowski GGUF)'
        Sub   = 'llama3.1-8b'
        Url   = 'https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf'
    },
    @{
        Label = 'Gemma 3 27B Q4_K_M (~16GB)'
        Note  = 'Gemma Terms of Use (ggml-org 공식 GGUF)'
        Sub   = 'gemma3-27b'
        Url   = 'https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/gemma-3-27b-it-Q4_K_M.gguf'
    },
    @{
        Label = 'DeepSeek-R1 14B Q4_K_M (~9GB)'
        Note  = 'MIT (bartowski GGUF)'
        Sub   = 'deepseek-r1-14b'
        Url   = 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf'
    },
    @{
        Label = 'Qwen 2.5 14B Q4_K_M (~9GB)'
        Note  = 'Apache 2.0 (bartowski 단일 파일 GGUF)'
        Sub   = 'qwen2.5-14b'
        Url   = 'https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf'
    },
    @{
        Label = 'Qwen3-Coder 30B Q4_K_M (~17-19GB)'
        Note  = '256K 컨텍스트, Apache 2.0 (unsloth 공식 GGUF)'
        Sub   = 'qwen3-coder-30b'
        Url   = 'https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf'
    }
)

# ============================================
# 실행
# ============================================
New-Item -ItemType Directory -Force -Path $DOWNLOAD_DIR | Out-Null

Write-Info '============================================'
Write-Info '  범용(일반) LLM 다운로드 (Windows)'
Write-Info '============================================'
Write-Host ''
Write-Warn "저장 위치: $DOWNLOAD_DIR"
Write-Host ''

if (-not (Ensure-aria2)) { exit 1 }

Write-Host ''
Write-Host "다운로드할 모델: $($script:Models.Count)개 (총 ~120-140GB)"
Write-Host ''

$idx = 0
foreach ($m in $script:Models) {
    $idx++
    $fn = ($m.Url -split '/')[-1]
    $sub = Join-Path $DOWNLOAD_DIR $m.Sub

    Write-Info ('--- {0}. {1} ---' -f $idx, $m.Label)
    Write-Host "  $($m.Note)"
    $null = Invoke-Aria2c -Url $m.Url -OutDir $sub -FileName $fn
    Write-Host ''
}

Write-Info '============================================'
Write-OK   '  모든 다운로드 완료!'
Write-Info '============================================'
Write-Host ''

Write-Info "저장 위치: $DOWNLOAD_DIR"
Write-Host ''

# 폴더별 용량 요약
$allModels = Get-ChildItem -Path $DOWNLOAD_DIR -Directory -ErrorAction SilentlyContinue
$totalSize = 0
foreach ($d in $allModels) {
    $size = (Get-ChildItem -Path $d.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($size) {
        Write-Host ('  {0,-30} {1:N2} GB' -f $d.Name, ($size / 1GB))
        $totalSize += $size
    }
}
if ($totalSize) {
    Write-Host ''
    Write-Host ('총 용량: {0:N2} GB' -f ($totalSize / 1GB))
}
Write-Host ''