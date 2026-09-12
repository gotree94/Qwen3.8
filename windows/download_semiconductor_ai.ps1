# ============================================================
# 반도체 설계 전용 AI 다운로드 스크립트 (Windows)
# 원본: download_semiconductor_ai.sh
# 사용법:  .\download_semiconductor_ai.ps1
# 실행정책 오류 시:
#   powershell -ExecutionPolicy Bypass -File .\download_semiconductor_ai.ps1
#
# ⚠️ 원본 sh의 저장소 5개는 대부분 존재하지 않는 ID였습니다.
#    아래는 HuggingFace에 실제 존재하는 저장소로 교체한 목록입니다.
#    - RTLCoder-DeepSeek  -> ishorn5/RTLCoder-Deepseek-v1.1 (Llama 기반)
#    - RTLCoder-Mistral   -> ishorn5/RTLCoder-v1.1 (Mistral 기반)
#    - VeriGen 7B         -> shailja/fine-tuned-codegen-6B-Verilog
#    - VeriGen 16B        -> shailja/fine-tuned-codegen-16B-Verilog
#    - ChipNeMo 13B       -> NVIDIA가 공개 배포하지 않아 다운로드 불가 (제외)
# ⚠️ 실행 시 HF API로 실제 파일 목록을 조회해 shard 전체를 다운로드합니다.
# ⚠️ EDA 툴체인은 Linux apt 대신 Windows용(OSS CAD Suite)으로 안내합니다.
# ============================================================

#requires -Version 5.1
$ErrorActionPreference = 'Continue'

$DesktopDir = [Environment]::GetFolderPath('Desktop')
$DOWNLOAD_DIR = Join-Path $DesktopDir 'semiconductor-ai'

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

# --- 모델 목록 (HuggingFace에 실제 존재하는 저장소) ---
$script:Models = @(
    @{ Label = 'RTLCoder-DeepSeek 6.7B'; Sub = 'rtlcoder-deepseek-6.7b'; Repo = 'ishorn5/RTLCoder-Deepseek-v1.1' },
    @{ Label = 'RTLCoder-Mistral 6.7B';  Sub = 'rtlcoder-mistral-6.7b';  Repo = 'ishorn5/RTLCoder-v1.1' },
    @{ Label = 'VeriGen 6B (CodeGen 기반)'; Sub = 'verigen-6b';          Repo = 'shailja/fine-tuned-codegen-6B-Verilog' },
    @{ Label = 'VeriGen 16B (CodeGen 기반)'; Sub = 'verigen-16b';         Repo = 'shailja/fine-tuned-codegen-16B-Verilog' }
)
# 참고: ChipNeMo-13B(nvidia)는 NVIDIA가 모델을 공개 배포하지 않아 목록에서 제외했습니다.

# --- Windows용 오픈소스 EDA 툴체인 ---
function Get-OssCadWindowsUrl {
    # GitHub API로 최신 릴리즈의 Windows 자산명(날짜 포함)을 동적으로 조회
    try {
        $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest' -Headers @{ 'User-Agent' = 'ps-download' } -TimeoutSec 30
        $asset = @($rel.assets | Where-Object { $_.name -like 'oss-cad-suite-windows-x64-*.tgz' } | Select-Object -First 1)
        if ($asset) {
            return $asset.name, $asset.browser_download_url
        }
    } catch { }
    return $null, $null
}

function Show-EDAWindowsNotes {
    Write-Info '--------------------------------------------'
    Write-Info ' Windows용 오픈소스 EDA 툴체인 (Linux apt 대신)'
    Write-Info '--------------------------------------------'
    Write-Host ''

    # [1/3] OSS CAD Suite (Windows) - yosys / verilator / gtkwave 포함
    Write-Info '[1/3] OSS CAD Suite (Windows) 다운로드'
    Write-Host '      yosys(논리합성) / verilator(고속 검증) / gtkwave(파형) 포함'
    $ossDir = Join-Path $DOWNLOAD_DIR 'oss-cad-suite'
    New-Item -ItemType Directory -Force -Path $ossDir | Out-Null

    $assetName, $assetUrl = Get-OssCadWindowsUrl
    if (-not $assetUrl) {
        Write-Err '      최신 릴리즈 조회 실패. 공식 페이지에서 직접 받으세요:'
        Write-Err '      https://github.com/YosysHQ/oss-cad-suite-build/releases/latest'
        Write-Host ''
        return
    }

    Write-Host ("      감지된 자산: {0}" -f $assetName)
    $null = Invoke-Aria2c -Url $assetUrl -OutDir $ossDir -FileName $assetName

    $tgzPath = Join-Path $ossDir $assetName
    if ((Test-Path $tgzPath) -and ((Get-Item $tgzPath).Length -gt 1MB)) {
        Write-Warn '      압축 해제 (Windows 10+ 내장 tar 사용):'
        Write-Host ''
        Write-Host "          cd `"$ossDir`""
        Write-Host "          tar -xzf `"$assetName`""
        Write-Host ''
        Write-Warn "      그 후 'oss-cad-suite\environment.bat' 실행하면 yosys/verilator/gtkwave 사용 가능"
        $envPath = Join-Path $ossDir (Join-Path 'oss-cad-suite' 'environment.bat')
        Write-OK "      environment.bat 예상 경로: $envPath"
    } else {
        Write-Err '      OSS CAD Suite 다운로드 실패 - 위 URL을 브라우저에서 직접 받으세요.'
    }
    Write-Host ''

    # [2/3] Icarus Verilog
    Write-Info '[2/3] Icarus Verilog (iverilog) - Verilog 시뮬레이션'
    Write-Host '      Windows 설치파일: https://github.com/steveicarus/iverilog/releases'
    Write-Host '      (''iverilog-*-x64_setup.exe'' 설치 후 PATH 자동 등록)'
    Write-Host ''

    # [3/3] OpenLane
    Write-Info '[3/3] OpenLane (RTL->GDSII 전체 자동흐름)'
    Write-Host '      Windows에서는 Docker Desktop 필요'
    Write-Host '      https://www.docker.com/products/docker-desktop/'
    Write-Host '      가이드: https://github.com/The-OpenROAD-Project/OpenLane'
    Write-Host ''
}

# ============================================
# 실행
# ============================================
New-Item -ItemType Directory -Force -Path $DOWNLOAD_DIR | Out-Null

Write-Info '============================================'
Write-Info '  반도체 설계 전용 AI 다운로드 (Windows)'
Write-Info '============================================'
Write-Host ''
Write-Warn "저장 위치: $DOWNLOAD_DIR"
Write-Host ''
Write-Warn '⚠️ ChipNeMo-13B는 NVIDIA가 공개 배포하지 않아 다운로드 목록에서 제외되었습니다.'
Write-Warn '⚠️ 원본 sh의 gallilabs/shailja-thakur/nvidia 저장소는 존재하지 않아'
Write-Warn '   실제 저장소(ishorn5 RTLCoder, shailja VeriGen)로 교체했습니다.'
Write-Host ''

if (-not (Ensure-aria2)) { exit 1 }

Write-Host ''
Write-Info '실행 시 HF API로 저장소의 실제 파일 목록을 조회해 전체를 다운로드합니다.'
Write-Host ''

$idx = 0
foreach ($m in $script:Models) {
    $idx++
    $sub = Join-Path $DOWNLOAD_DIR $m.Sub
    Write-Info ('--- {0}. {1} ---' -f $idx, $m.Label)
    $null = Invoke-HFModelDownload -Repo $m.Repo -OutDir $sub
    Write-Host ''
}

# EDA 툴체인
Show-EDAWindowsNotes

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