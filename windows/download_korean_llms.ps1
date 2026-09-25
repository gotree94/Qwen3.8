# ============================================================
# 한국(국내) 개발 LLM 전체 다운로드 스크립트 (Windows)
# 원본: download_korean_llms.sh
# 사용법:  .\download_korean_llms.ps1
# 실행정책 오류 시:
#   powershell -ExecutionPolicy Bypass -File .\download_korean_llms.ps1
#
# ⚠️ 원본 sh의 저장소 ID 중 오래된/잘못된 것이 많아 실제 존재하는 것으로 교체했습니다.
#    - EXAONE-4.0-32B-Instruct -> LGAI-EXAONE/EXAONE-4.0-32B (Instruct 형식 제외)
#    - krafton/KoRani-13B      -> KRAFTON/KORani-v3-13B (최신 v3)
#    - Y%C3%BCksei-Dilleri/EEVE -> yanolja/YanoljaNEXT-EEVE-Instruct-10.8B
# ⚠️ 실행 시 HF API로 실제 파일 목록을 조회해 shard 수치 오류 없이 전체 다운로드합니다.
# ⚠️ EXAONE 시리즈는 비상업용(NC) 라이선스입니다. 개인/연구용만 사용하세요.
# ============================================================

#requires -Version 5.1
$ErrorActionPreference = 'Continue'

$DesktopDir = [Environment]::GetFolderPath('Desktop')
$DOWNLOAD_DIR = Join-Path $DesktopDir 'korean-llms'

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

# --- HF 저장소의 실제 파일 전체 다운로드 (API로 shard 목록 자동 감지) ---
function Invoke-HFModelDownload {
    param([string]$Repo, [string]$OutDir)

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

    # 1) 저장소 메타데이터 조회 -> 실제 파일 목록 획득
    try {
        $api = Invoke-RestMethod -Uri "https://huggingface.co/api/models/$Repo" -TimeoutSec 30
    } catch {
        Write-Err "  [건너뜀] 저장소에 접근할 수 없습니다: $Repo"
        Write-Err "  (존재하지 않거나, 비공개/gated이거나, 오타일 수 있습니다. URL을 확인하세요.)"
        return $false
    }

    $allFiles = @($api.siblings | ForEach-Object { $_.rfilename })

    # 2) 가중치 파일 추출: model-*.safetensors / pytorch_model-*.bin / 단일 pytorch_model.bin
    $weightPat = '^(model(\.safetensors|-\d{5}-of-\d{5}\.safetensors)|pytorch_model(\.bin|-\d{5}-of-\d{5}\.bin))$'
    $weights = @($allFiles | Where-Object { $_ -match $weightPat })
    if ($weights.Count -eq 0) {
        Write-Err "  [건너뜀] $Repo 에서 가중치 파일(model-*.safetensors / pytorch_model-*.bin)을 찾지 못했습니다."
        return $false
    }
    $weights = @($weights | Sort-Object { [int]([regex]::Match($_, '\d{5}').Value) })

    # 3) 필수 설정/토크나이저 파일 (작음, config 없으면 모델 로드 불가)
    $auxPat = '^(config\.json|generation_config\.json|tokenizer\.json|tokenizer_config\.json|tokenizer\.model|special_tokens_map\.json|added_tokens\.json|vocab\.json|merges\.txt|chat_template\.jinja|model\.safetensors\.index\.json|pytorch_model\.bin\.index\.json)$'
    $auxs = @($allFiles | Where-Object { $_ -match $auxPat })

    Write-Host ("  가중치 {0}개 + 설정/토크나이저 {1}개 발견 (API 실시간 조회)" -f $weights.Count, $auxs.Count)

    # 4) 전체 다운로드
    $allOk = $true
    foreach ($f in (@($weights) + @($auxs))) {
        $url = "https://huggingface.co/$Repo/resolve/main/$f"
        $ok = Invoke-Aria2c -Url $url -OutDir $OutDir -FileName $f
        if (-not $ok) { $allOk = $false }
    }

    if ($allOk) {
        Write-OK "  [OK] $Repo - 모든 파일 다운로드 완료"
    } else {
        Write-Err "  [부분 실패] $Repo - 빠진 파일은 다시 실행하면 이어받기 됩니다"
    }
    return $allOk
}

# --- 모델 목록 (HuggingFace에 실존하는 저장소로 최종 확정) ---
# ⚠️ shard 수를 하드코딩하지 않습니다: 실행 시 HF API로 자동 감지됩니다.
$script:Models = @(
    @{ Label = 'HyperCLOVA X SEED Think 32B';  Sub = 'hyperclova-x-seed-think-32b'; Repo = 'naver-hyperclovax/HyperCLOVAX-SEED-Think-32B' },
    @{ Label = 'HyperCLOVA X SEED Think 14B';  Sub = 'hyperclova-x-seed-think-14b'; Repo = 'naver-hyperclovax/HyperCLOVAX-SEED-Think-14B' },
    @{ Label = 'HyperCLOVA X SEED Omni 8B';    Sub = 'hyperclova-x-seed-omni-8b';   Repo = 'naver-hyperclovax/HyperCLOVAX-SEED-Omni-8B' },
    @{ Label = 'EXAONE 3.5 32B (NC)';          Sub = 'exaone-3.5-32b';              Repo = 'LGAI-EXAONE/EXAONE-3.5-32B-Instruct' },
    @{ Label = 'EXAONE 3.5 7.8B (NC)';         Sub = 'exaone-3.5-7.8b';             Repo = 'LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct' },
    @{ Label = 'EXAONE 4.0 32B (NC)';          Sub = 'exaone-4.0-32b';              Repo = 'LGAI-EXAONE/EXAONE-4.0-32B' },
    @{ Label = 'EXAONE 4.5 33B (NC)';          Sub = 'exaone-4.5-33b';              Repo = 'LGAI-EXAONE/EXAONE-4.5-33B' },
    @{ Label = 'SOLAR 10.7B';                  Sub = 'solar-10.7b';                 Repo = 'upstage/SOLAR-10.7B-Instruct-v1.0' },
    @{ Label = 'KORani v3 13B';               Sub = 'korani-13b';                  Repo = 'KRAFTON/KORani-v3-13B' },
    @{ Label = 'EEVE YanoljaNEXT 10.8B';      Sub = 'eeve-korean-10.8b';           Repo = 'yanolja/YanoljaNEXT-EEVE-Instruct-10.8B' }
)

# ============================================
# 실행
# ============================================
New-Item -ItemType Directory -Force -Path $DOWNLOAD_DIR | Out-Null

Write-Info '============================================'
Write-Info '  한국(국내) 개발 LLM 다운로드 (Windows)'
Write-Info '============================================'
Write-Host ''
Write-Warn "저장 위치: $DOWNLOAD_DIR"
Write-Host ''
Write-Err '⚠️ EXAONE 시리즈(3.5/4.0/4.5)는 비상업용(NC) 라이선스 - 개인/연구용만 사용'
Write-Host ''

if (-not (Ensure-aria2)) { exit 1 }

Write-Host ''
Write-Info '실행 시 HF API로 저장소의 실제 파일 목록을 조회해 전체 shard를 다운로드합니다.'
Write-Host ''

$idx = 0
foreach ($m in $script:Models) {
    $idx++
    $sub = Join-Path $DOWNLOAD_DIR $m.Sub
    Write-Info ('--- {0}. {1} ---' -f $idx, $m.Label)
    $null = Invoke-HFModelDownload -Repo $m.Repo -OutDir $sub
    Write-Host ''
}

Write-Info '============================================'
Write-OK   '  모든 다운로드 완료!'
Write-Info '============================================'
Write-Host ''

Write-Info "저장 위치: $DOWNLOAD_DIR"
Write-Host ''

$allModels = Get-ChildItem -Path $DOWNLOAD_DIR -Directory -ErrorAction SilentlyContinue
$totalSize = 0
foreach ($d in $allModels) {
    $size = (Get-ChildItem -Path $d.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($size) {
        Write-Host ('  {0,-32} {1:N2} GB' -f $d.Name, ($size / 1GB))
        $totalSize += $size
    }
}
if ($totalSize) {
    Write-Host ''
    Write-Host ('총 용량: {0:N2} GB' -f ($totalSize / 1GB))
}
Write-Host ''