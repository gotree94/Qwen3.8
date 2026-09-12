# ============================================
# Qwen3 전체 모델 다운로드 스크립트 (Windows)
# 원본: download_all_qwen3.sh
# 사용법:  .\download_all_qwen3.ps1
# 실행정책 오류 시:
#   powershell -ExecutionPolicy Bypass -File .\download_all_qwen3.ps1
# 요구사항: aria2c (없으면 winget으로 자동 설치 시도)
# ============================================

#requires -Version 5.1
$ErrorActionPreference = 'Continue'

# 저장 위치: 바탕화면\qwen3-all-models
$DesktopDir = [Environment]::GetFolderPath('Desktop')
$DOWNLOAD_DIR = Join-Path $DesktopDir 'qwen3-all-models'
$LOG_FILE = Join-Path $DOWNLOAD_DIR 'download.log'

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

    # winget 설치 직후 PATH 미반영 대비: 알려진 설치 위치 검색
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

# --- aria2c로 파일 다운로드 (이어받기 + 건너뛰기 지원) ---
function Invoke-Aria2c {
    param([string]$Url, [string]$OutDir, [string]$FileName)

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $dest = Join-Path $OutDir $FileName

    # 이미 다운로드된 파일(1MB 초과)이면 건너뛰기
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
    if ($ok) {
        Write-OK "  [완료] $FileName"
        return $true
    }
    Write-Err "  [실패] $FileName (aria2c exit code: $LASTEXITCODE) - 다시 실행하면 이어받기 됩니다"
    return $false
}

# --- 모델 목록 (이름, 레포, 파일명) ---
$script:Models = @(
    @{ Name = '0.6B';    Repo = 'Qwen/Qwen3-0.6B-GGUF';    File = 'Qwen3-0.6B-Q8_0.gguf' },
    @{ Name = '1.7B';    Repo = 'Qwen/Qwen3-1.7B-GGUF';    File = 'Qwen3-1.7B-Q8_0.gguf' },
    @{ Name = '4B';      Repo = 'Qwen/Qwen3-4B-GGUF';      File = 'Qwen3-4B-Q4_K_M.gguf' },
    @{ Name = '8B';      Repo = 'Qwen/Qwen3-8B-GGUF';      File = 'Qwen3-8B-Q4_K_M.gguf' },
    @{ Name = '14B';     Repo = 'Qwen/Qwen3-14B-GGUF';     File = 'Qwen3-14B-Q4_K_M.gguf' },
    @{ Name = '32B';     Repo = 'Qwen/Qwen3-32B-GGUF';     File = 'Qwen3-32B-Q4_K_M.gguf' },
    @{ Name = '30B-A3B'; Repo = 'Qwen/Qwen3-30B-A3B-GGUF'; File = 'Qwen3-30B-A3B-Q4_K_M.gguf' }
)

# ============================================
# 실행
# ============================================
New-Item -ItemType Directory -Force -Path $DOWNLOAD_DIR | Out-Null

Write-Info '============================================'
Write-Info '  Qwen3 전체 모델 GGUF 다운로드 (Windows)'
Write-Info '============================================'
Write-Host ''
Write-Warn "저장 위치: $DOWNLOAD_DIR"
Write-Host ''

if (-not (Ensure-aria2)) { exit 1 }

Write-Host ''
Write-Info 'Q4_K_M 버전 다운로드 시작 (권장)'
Write-Host ''

foreach ($m in $script:Models) {
    $url = "https://huggingface.co/$($m.Repo)/resolve/main/$($m.File)"
    Write-Info "--- Qwen3-$($m.Name) ---"
    Add-Content -Path $LOG_FILE -Value "URL: $url" -Encoding UTF8
    $null = Invoke-Aria2c -Url $url -OutDir $DOWNLOAD_DIR -FileName $m.File
    Write-Host ''
}

Write-Info '============================================'
Write-OK   '  다운로드 종료!'
Write-Info '============================================'
Write-Host ''

Write-Info "저장 위치: $DOWNLOAD_DIR"
$ggufs = Get-ChildItem -Path $DOWNLOAD_DIR -Filter '*.gguf' -ErrorAction SilentlyContinue
foreach ($f in $ggufs) {
    Write-Host ('  {0}  ({1:N2} GB)' -f $f.Name, ($f.Length / 1GB))
}
$sum = ($ggufs | Measure-Object Length -Sum).Sum
if ($sum) {
    Write-Host ''
    Write-Host ('총 용량: {0:N2} GB' -f ($sum / 1GB))
}
Write-Host ''