# Synology NAS Git Server 설치 및 활용 가이드

> DSM 7.x 기준으로 작성 (DSM 6.x와 다른 부분은 별도 표기)
> 목적: 시놀로지 NAS를 팀/개인용 Git 서버로 구축하고, 초기 설정부터 실제 사용·자동 배포까지 전 과정을 정리

---

## 목차

1. [개요](#1-개요)
2. [사전 준비](#2-사전-준비)
3. [Git Server 패키지 설치](#3-git-server-패키지-설치)
4. [사전 환경 설정 (SSH / 홈 디렉토리 / 사용자 / 공유 폴더)](#4-사전-환경-설정)
5. [Git 저장소(Repository) 생성](#5-git-저장소-생성)
6. [로컬 PC에서 Git 저장소 사용하기](#6-로컬-pc에서-git-저장소-사용하기)
7. [SSH 키 인증 설정 (비밀번호 없이 사용)](#7-ssh-키-인증-설정)
8. [사용자 및 권한 관리](#8-사용자-및-권한-관리)
9. [Git Hooks를 이용한 자동 배포](#9-git-hooks를-이용한-자동-배포)
10. [HTTP/HTTPS로 접속하기 (선택)](#10-httphttps로-접속하기-선택)
11. [보안 설정](#11-보안-설정)
12. [백업 및 이전](#12-백업-및-이전)
13. [트러블슈팅](#13-트러블슈팅)
14. [부록: Git LFS / Gitea 등 대안](#14-부록)

---

## 1. 개요

### 1.1 Git Server란?

시놀로지 패키지 센터에서 제공하는 공식 Git 서버 패키지입니다. NAS를 **SSH 기반 Git 원격 저장소 서버**로 만들어 줍니다.

- GitHub/GitLab 같은 웹 UI(코드 브라우징, 이슈, PR)는 제공하지 않음
- SSH 프로토콜을 통해 `clone`, `push`, `pull` 등 Git 기본 동작을 지원
- 팀 규모가 작고, 사내/홈 네트워크에서 코드를 안전하게 보관하려는 용도에 적합

### 1.2 동작 방식

```
[로컬 PC] --(SSH)--> [Synology NAS]
   git push           Git Server 패키지
   git pull           + /usr/bin/git (bare 저장소)
```

| 구성 요소 | 역할 |
|---|---|
| Git Server 패키지 | 사용자별 Git 접근 허용/차단 |
| SSH 서비스 (터미널) | 원격 접속 채널 |
| 사용자 홈 서비스 | 사용자별 홈 디렉토리 (`.ssh`, 저장소 보관) |
| 공유 폴더 (선택) | 저장소를 모아두는 전용 폴더 |

---

## 2. 사전 준비

| 항목 | 내용 |
|---|---|
| DSM 버전 | DSM 7.0 이상 권장 (DSM 6.2도 동일하게 동작하나 메뉴 경로가 일부 다름) |
| 계정 | 관리자(admin) 계정 또는 관리자 그룹 계정 |
| 네트워크 | NAS 고정 IP 권장 (SSH 키 인증 시 IP 변경 주의) |
| 클라이언트 | Windows(Git for Windows), macOS, Linux 중 원하는 환경 |
| 대역폭 | 사내/외부 접속 여부에 따라 포트 포워딩 고려 |

> **TIP** DSM 7부터는 `admin` 기본 계정이 비활성화되어 있는 경우가 많습니다.
> `Administrators` 그룹에 속한 별도 관리자 계정으로 로그인하세요.

---

## 3. Git Server 패키지 설치

1. **패키지 센터** 실행
2. 검색창에 `Git` 입력
3. **Git Server** 선택 → **설치**
4. (선택) 저장소 코드를 NAS에서 직접 편집하고 싶다면 **Text Editor** 패키지도 설치

> DSM 6.x 이하에서는 **"개발" 카테고리**에서 찾을 수 있습니다.
> Git Server는 독립 실행형 GUI가 아니라, 설치 후 "메인 메뉴"에 아이콘이 생기며 접근 권한 설정용으로만 사용합니다.

---

## 4. 사전 환경 설정

Git Server를 실제로 쓰기 전에 다음 4가지를 반드시 설정해야 합니다.

### 4.1 SSH 서비스 활성화

1. **제어판 → 터미널 및 SNMP → 터미널 탭**
2. **SSH 서비스 활성화** 체크
3. **포트** 지정 (기본 22. 보안을 위해 2222 등으로 변경 권장 — [11장 참고](#11-보안-설정))
4. **적용** 클릭

> SSH가 활성화되면 DSM 로그인 화면에 경고 문구가 뜨는데, 정상입니다.
> 이후 Git 접속은 모두 이 SSH 포트를 통해 이루어집니다.

### 4.2 사용자 홈 서비스(홈 디렉토리) 활성화

SSH 키 인증과 저장소 권한 관리를 위해 **반드시** 필요합니다.

1. **제어판 → 사용자 및 그룹 → 고급 설정 탭**
2. **사용자 홈 서비스 활성화** 체크 → **적용**

- 활성화하면 `/home/사용자명` 형태로 각 사용자에게 개인 폴더가 생깁니다
- 실제 경로: `/volume1/homes/사용자명`
- 이 폴더에 `.ssh/` 디렉토리(SSH 키), git 저장소 등을 보관합니다

### 4.3 전용 Git 사용자 생성 (권장)

보안과 권한 관리를 위해 **Git 전용 계정**을 만들 것을 권장합니다.

1. **제어판 → 사용자 및 그룹 → 사용자 탭 → 생성**
2. 사용자 이름 예: `gituser`
3. **권한 설정 시 주의**:
   - Git 저장소용 공유 폴더에만 **읽기/쓰기** 권한 부여
   - 나머지 공유 폴더는 접근 불가로 설정
4. 비밀번호는 강력한 것으로 설정 (외부 노출 대비)

### 4.4 Git 저장소 전용 공유 폴더 생성 (권장)

저장소를 한곳에 모아 관리하면 백업·권한 관리가 쉬워집니다.

1. **제어판 → 공유 폴더 → 생성**
2. 이름: `git` (또는 `gitrepos`)
3. 생성 후 해당 폴더의 **권한 탭**에서:
   - 관리자 그룹: 읽기/쓰기
   - `gituser`: 읽기/쓰기
   - 기타 사용자: 없음
4. **적용**

> DSM 7의 공유 폴더 권한은 **"사용자 및 그룹 → 권한"** 과 **공유 폴더 속성의 권한** 두 곳을 모두 확인해야 합니다.
> Git 사용자가 push할 때 쓰기 실패가 나면 이 권한을 먼저 점검하세요.

### 4.5 Git Server에서 사용자 접근 허용

1. 메인 메뉴에서 **Git Server** 실행
2. **사용자 탭**에서 Git 사용을 허용할 계정 체크 (예: `gituser`)
3. **Guest**, **admin**은 체크 해제 권장 (보안)
4. **적용** 클릭

> 이 설정을 빼먹으면 SSH 접속은 되지만 Git 명령이
> `git-upload-pack: command not found` 같은 오류로 실패합니다.

---

## 5. Git 저장소 생성

### 5.1 SSH로 NAS에 접속

**Windows (Git Bash / PowerShell)**

```bash
ssh gituser@192.168.0.10 -p 22
# 포트를 변경했다면:
ssh gituser@192.168.0.10 -p 2222
```

**macOS / Linux**

```bash
ssh gituser@192.168.0.10
```

### 5.2 bare 저장소 생성

Git 서버에는 **bare 저장소**(워킹 디렉토리가 없는 저장소)를 만들어야 합니다.

```bash
# 1) 저장소용 공유 폴더로 이동
cd /volume1/git

# 2) bare 저장소 생성 (저장소명.git 형식 권장)
git init --bare myproject.git
```

- `myproject.git` 디렉토리 안에 실제 Git 데이터(`HEAD`, `objects/`, `refs/`)가 생성됩니다
- 여러 저장소가 필요하면 같은 방식으로 반복 생성

### 5.3 권한 설정

사용자가 push할 수 있도록 소유자/권한을 맞춰줍니다.

```bash
# 저장소 폴더 전체를 gituser에게 부여
sudo chown -R gituser:users /volume1/git

# 디렉토리 권한 (755 = 읽기/실행, 소유자만 쓰기)
sudo chmod -R 755 /volume1/git

# 저장소 내부 쓰기 권한 보장
sudo chmod -R g+w /volume1/git/myproject.git
```

> **권한 실패의 90%는 이 단계의 소유자/권한 문제입니다.**
> `push` 시 `insufficient permission for adding an object` 오류가 나면
> `chown -R gituser:users` 를 다시 실행하세요.

---

## 6. 로컬 PC에서 Git 저장소 사용하기

### 6.1 저장소 복제 (clone)

**빈 저장소는 그대로 clone하면 아무 파일도 없으므로**, 먼저 초기 커밋을 push하는 방식으로 시작합니다.

```bash
# 1) 로컬에서 작업 폴더 생성
mkdir myproject
cd myproject

# 2) Git 초기화 및 첫 커밋
git init
git config user.name "홍길동"
git config user.email "hong@example.com"
echo "# My Project" > README.md
git add README.md
git commit -m "first commit"
```

**이미 원격에 저장소가 있는 경우 (clone)**

```bash
git clone ssh://gituser@192.168.0.10:2222/volume1/git/myproject.git
```

### 6.2 원격 저장소 등록 및 push

```bash
# 원격 저장소 등록 (git init으로 시작한 경우)
git remote add origin ssh://gituser@192.168.0.10:2222/volume1/git/myproject.git

# 기본 브랜치 이름 통일 (최신 git은 main 권장)
git branch -M main

# 처음 push (업스트림 설정)
git push -u origin main
```

> **TIP** 저장소가 완전히 비어 있으면(커밋 0개) `git push` 시
> `error: src refspec main does not match any` 오류가 날 수 있습니다.
> 반드시 로컬에서 **최소 1개 커밋**을 만든 후 push하세요.

### 6.3 일상 워크플로우

```bash
# 작업 전 최신 상태 가져오기
git pull

# 파일 수정 후
git add .
git commit -m "기능 추가: 로그인 페이지"
git push
```

### 6.4 기본적인 Git 명령어 요약

| 명령어 | 설명 |
|---|---|
| `git clone <url>` | 원격 저장소 복제 |
| `git status` | 작업 상태 확인 |
| `git add <파일>` | 스테이징 |
| `git commit -m "메시지"` | 커밋 |
| `git push` | 원격에 업로드 |
| `git pull` | 원격에서 내려받기 |
| `git log --oneline` | 커밋 이력 확인 |
| `git branch -a` | 브랜치 목록 확인 |

---

## 7. SSH 키 인증 설정

매번 비밀번호를 입력하지 않고 **공개키 기반 인증**으로 접속할 수 있습니다.

### 7.1 SSH 키 생성 (로컬 PC)

```bash
ssh-keygen -t ed25519 -C "gituser@nas" -f ~/.ssh/id_ed25519
# 또는 RSA (구형 시스템 호환용):
ssh-keygen -t rsa -b 4096 -C "gituser@nas"
```

- 기본값으로 Enter 입력하면 `~/.ssh/id_ed25519`(개인키)와 `~/.ssh/id_ed25519.pub`(공개키)가 생성됩니다
- 비밀번호(passphrase) 설정을 권장합니다 (키 유출 시 2중 보호)

### 7.2 공개키를 NAS에 등록

**방법 A — ssh-copy-id (가장 간단, macOS/Linux/Windows Git Bash)**

```bash
ssh-copy-id -p 2222 -i ~/.ssh/id_ed25519.pub gituser@192.168.0.10
```

**방법 B — 수동 등록 (Windows PowerShell 등)**

```bash
# 1) 공개키 내용을 복사
cat ~/.ssh/id_ed25519.pub

# 2) NAS에 접속
ssh gituser@192.168.0.10 -p 2222

# 3) 홈 디렉토리에 .ssh 폴더와 authorized_keys 생성
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "복사한_공개키_내용" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 7.3 sshd_config 확인 (DSM 7)

대부분 기본 활성화되어 있지만, 안 되면 확인합니다.

```bash
sudo vi /etc/ssh/sshd_config
```

다음 두 줄이 주석 처리(`#`)되어 있다면 해제합니다.

```
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

수정 후 SSH 재시작:

```bash
sudo synoservicectl --restart sshd
```

### 7.4 홈 디렉토리 권한 조정 (DSM 7 필수)

DSM 7에서는 **홈 디렉토리의 권한이 너무 넓으면 SSH 키 인증이 거부**됩니다
(`Authentication refused: bad ownership or modes` 오류).

1. **File Station → homes → gituser 폴더** 우클릭 → **속성 → 권한 탭**
2. **고급 옵션 → 상속된 권한 제외**
3. 하단 **"이 폴더, 하위 폴더 및 파일에 적용"** 체크
4. **저장**
   - 경고 메시지가 나와도 진행 (다른 관리자 계정의 접근이 제한될 수 있으나 정상)
5. 최종적으로 `gituser` 본인만 자신의 홈 폴더에 접근 가능한 상태가 되어야 함

### 7.5 접속 테스트

```bash
# 비밀번호 없이 접속되어야 정상
ssh -p 2222 gituser@192.168.0.10
```

### 7.6 Windows에서 SSH config 활용 (선택)

`C:\Users\사용자명\.ssh\config` 파일에 아래 내용을 넣으면 접속이 간편해집니다.

```
Host nas
    HostName 192.168.0.10
    Port 2222
    User gituser
    IdentityFile ~/.ssh/id_ed25519
```

이후 사용:

```bash
ssh nas
git clone ssh://nas/volume1/git/myproject.git
```

---

## 8. 사용자 및 권한 관리

### 8.1 사용자 추가

1. **제어판 → 사용자 및 그룹 → 사용자 → 생성**
2. 각 개발자별 계정 생성
3. 권한:
   - `git` 공유 폴더에 **읽기/쓰기**
   - Git Server 패키지에서 **접근 허용**

### 8.2 그룹으로 관리 (권장)

1. **사용자 및 그룹 → 그룹 → 생성** (예: `developers`)
2. 개발자들을 그룹에 추가
3. 공유 폴더 `git`의 권한을 그룹 단위로 부여

### 8.3 저장소별 접근 제한

특정 저장소만 특정 사용자에게 허용하려면 **폴더 권한**으로 조정합니다.

```bash
# 예: secret-project.git 은 gituser(관리자)만 접근
sudo chown -R gituser:users /volume1/git/secret-project.git
sudo chmod -R 750 /volume1/git/secret-project.git
```

> Git Server 패키지의 "사용자 접근 허용"은 **패키지 자체의 사용 여부**를 결정하며,
> 저장소 단위 세밀한 권한은 **공유 폴더/폴더 권한**으로 제어합니다.

---

## 9. Git Hooks를 이용한 자동 배포

`post-receive` 훅을 이용하면 **push와 동시에 웹 서버(Web Station)로 자동 배포**할 수 있습니다.

### 9.1 시나리오

```
[개발자 PC] --git push--> [NAS: /volume1/git/site.git] --(post-receive)--> [NAS: /volume1/web/site]
```

### 9.2 준비: 웹 배포 폴더

```bash
# 웹 루트에 배포 폴더 생성 (Web Station의 가상 호스트 문서 루트로 지정)
mkdir -p /volume1/web/site
sudo chown -R gituser:users /volume1/web/site
```

### 9.3 post-receive 훅 작성

```bash
# 저장소 hooks 폴더로 이동
cd /volume1/git/site.git/hooks

# 훅 파일 생성 (텍스트 에디터 사용)
vi post-receive
```

```bash
#!/usr/bin/env bash

TARGET="/volume1/web/site"          # 배포 대상 (워킹 트리)
GIT_DIR="/volume1/git/site.git"     # bare 저장소 경로
BRANCH="main"                       # 배포할 브랜치

while read oldrev newrev ref
do
    # main 브랜치 push일 때만 배포
    if [[ $ref = refs/heads/$BRANCH ]];
    then
        echo "== $BRANCH 브랜치 수신, 배포를 시작합니다. =="
        git --work-tree=$TARGET --git-dir=$GIT_DIR checkout -f $BRANCH
        echo "== 배포 완료: $TARGET =="
    else
        echo "== $BRANCH 외 브랜치는 배포하지 않습니다. ($ref) =="
    fi
done
```

### 9.4 실행 권한 부여 및 테스트

```bash
chmod +x /volume1/git/site.git/hooks/post-receive

# 실행 가능 여부 확인
ls -l /volume1/git/site.git/hooks/post-receive
# -rwxr-xr-x 1 gituser users ... post-receive
```

이제 로컬에서:

```bash
git push origin main
```

push할 때 NAS 터미널에 배포 로그가 표시되고, `/volume1/web/site`에 파일이 반영됩니다.

### 9.5 주의사항

| 주의점 | 설명 |
|---|---|
| 후크 파일에 CRLF 사용 금지 | Windows에서 편집 시 줄바꿈을 **LF**로 저장 (CRLF면 스크립트 오류) |
| 체크아웃 대상 비우기 | 배포 전 `rm -rf /volume1/web/site/*` 추가 시 잔여 파일 관리 가능 |
| 브랜치명 확인 | `master`인지 `main`인지 훅 안의 `BRANCH` 변수 확인 |
| 단순 pull 방식 대안 | 웹 폴더에 일반 clone 후 `git pull` 방식도 가능하나, bare+checkout이 더 안전 |

---

## 10. HTTP/HTTPS로 접속하기 (선택)

SSH 대신 **브라우저/HTTP 클라이언트로 접속**하고 싶다면 Web Station + Apache를 이용해
`git-http-backend`를 노출할 수 있습니다.

### 10.1 설치

- **패키지 센터**에서 **Web Station**, **Apache HTTP Server 2.x** 설치

### 10.2 Apache 가상 호스트 설정

Web Station → **웹 서비스 포털 → 생성 → 가상 호스트 → 포트 기반** 선택:

- **문서 루트**: `/volume1/git`
- **HTTP 백엔드 서버**: Apache 2.x
- **포트**: 예) `8080`

### 10.3 httpd 설정 파일 추가

Apache 구성 디렉토리에 다음 내용을 포함하는 파일을 만듭니다.

```apache
SetEnv GIT_PROJECT_ROOT /volume1/git
SetEnv GIT_HTTP_EXPORT_ALL
ScriptAlias /git/ /volume1/@appstore/Git/libexec/git-core/git-http-backend/

AuthType Basic
AuthName "Git Access"
AuthUserFile /volume1/git/.htpasswd
Require expr !(%{QUERY_STRING} -strmatch '*service=git-receive-pack*' || %{REQUEST_URI} =~ m#/git-receive-pack$#)
Require valid-user
```

- `GIT_PROJECT_ROOT`: 실제 저장소 루트 경로로 변경
- `ScriptAlias`의 Git 경로: 설치 볼륨 확인 후 조정 (`/volume1/@appstore/Git/...`)
- `AuthUserFile`: Basic 인증용 비밀번호 파일 경로

### 10.4 인증 파일 생성

```bash
# Apache 경로에서 htpasswd 유틸리티 사용 (또는 온라인 htpasswd 생성기)
/usr/syno/apache/bin/htpasswd -c /volume1/git/.htpasswd gituser
```

### 10.5 사용법

```bash
git clone http://gituser:비밀번호@192.168.0.10:8080/git/myproject.git
# 또는 사용자명만 입력 후 비밀번호 프롬프트:
git clone http://gituser@192.168.0.10:8080/git/myproject.git
```

> **주의** Basic 인증은 평문 전송이므로, 외부망에서 쓸 때는 **DSM의 역방향 프록시 + HTTPS** 또는
> **Synology DDNS + Let's Encrypt 인증서**를 조합하세요.

---

## 11. 보안 설정

### 11.1 SSH 포트 변경 및 방화벽

1. **제어판 → 터미널 및 SNMP**에서 SSH 포트를 22 → 예) `2222`로 변경
2. **제어판 → 보안 → 방화벽**에서:
   - 외부망에서 오는 `2222` 포트는 **특정 IP만 허용**하거나 차단
   - 내부망(192.168.x.x)에서만 접속 허용 권장

### 11.2 기본 계정 비활성화

- DSM 7에서는 기본 `admin` 계정 비활성화 권장
- 관리자는 별도 계정 + **2단계 인증(TOTP)** 활성화

### 11.3 Git 전용 계정 권한 최소화

- `gituser`는 Git 저장소 폴더와 자기 홈 디렉토리 **외에는 접근 불가**
- `sudo` 권한 없음 (저장소 생성은 관리자가 대신 수행)
- 비밀번호 정책: **제어판 → 보안 → 비밀번호**에서 최소 길이·복잡도 강제

### 11.4 자동 차단

**제어판 → 보안 → 보호**에서 로그인 실패 횟수 기반 자동 차단 활성화.

### 11.5 외부망 노출 최소화

- 가급적 **VPN(QuickConnect/Synology VPN Server) 내부에서만 Git 접속**
- 반드시 외부 노출 시: SSH 포트 변경 + 키 인증 강제 + 방화벽 IP 제한 3종 세트 적용

---

## 12. 백업 및 이전

### 12.1 저장소 백업 (Hyper Backup)

1. **Hyper Backup** 실행
2. 백업 대상에 **공유 폴더 `git`** 포함
3. 외장 드라이브/클라우드/다른 NAS로 **예약 백업** 설정

### 12.2 저장소 이전 (다른 NAS로)

```bash
# 대상 NAS에서
cd /volume1/git
git clone --mirror ssh://gituser@구NAS_IP:2222/volume1/git/myproject.git
```

- `--mirror`는 bare 저장소의 모든 브랜치·태그·ref를 그대로 복제
- 이전 후 `chown -R gituser:users` 로 권한만 다시 맞춰주면 됨

### 12.3 git bundle로 단일 파일 백업 (선택)

```bash
cd /volume1/git/myproject.git
git bundle create /volume1/backup/myproject.bundle --all
```

---

## 13. 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `git-upload-pack: command not found` | Git Server에서 사용자 접근 미허용 | Git Server 앱 → 해당 사용자 체크 |
| `insufficient permission for adding an object to repository database` | 저장소 소유자/권한 문제 | `sudo chown -R gituser:users /volume1/git/myproject.git` |
| `Authentication refused: bad ownership or modes for ~/.ssh` | 홈 디렉토리 권한 과다 (DSM 7) | [7.4절](#74-홈-디렉토리-권한-조정-dsm-7-필수) 상속 권한 제외 |
| `Permission denied (publickey)` | 키 미등록 / sshd 설정 | `ssh-copy-id` 재실행, `sshd_config` 확인 |
| `error: src refspec main does not match any` | 빈 저장소에 push | 로컬에서 커밋 1개 이상 후 push |
| `The current branch main has no upstream branch` | 업스트림 미설정 | `git push -u origin main` |
| `failed to push some refs` / `unpacker error` | 저장소 쓰기 권한 문제 | `chmod -R g+w 저장소.git` |
| SSH 접속은 되는데 push만 느림 | 홈 디렉토리/저장소가 NFS·외장 볼륨 | 저장소를 로컬 볼륨(`/volume1`)에 배치 |
| post-receive 훅 실행 안 됨 | 실행 권한 없음 / CRLF 줄바꿈 | `chmod +x post-receive`, 줄바꿈 LF로 저장 |
| Windows에서 `git` 명령 없음 | Git 미설치 | Git for Windows 설치, Git Bash 사용 |
| SSH 접속이 간헐적으로 끊김 | 방화벽/타임아웃 | 방화벽에서 SSH 포트 허용, `ClientAliveInterval 60` 설정 |

---

## 14. 부록

### 14.1 Git LFS (대용량 파일 관리)

Git Server 패키지에 LFS가 포함되어 있지 않은 경우, 저장소에 대용량 바이너리를 올리면
저장소가 비대해집니다. 다음을 권장합니다.

- **Git LFS 도입**: 클라이언트에 `git lfs install` 후 `.gitattributes`에 대용량 확장자 지정
  - 단, **NAS 측 서버에 git-lfs 실행 파일이 필요**하므로 SSH로 설치: `sudo synopkg install git-lfs` 또는 직접 바이너리 배포
- **또는 별도 파일 서버 활용**: 대용량 파일은 NAS의 공유 폴더에 두고, Git에는 경로/메타데이터만 관리

### 14.2 웹 UI가 필요하다면? (Gitea / GitLab)

Git Server 패키지의 한계(웹 UI 없음)를 보완하려면 **Docker로 Gitea**를 구축하는 방법이 표준입니다.

```
패키지 센터 → Docker(Container Manager) → Gitea 이미지 → 컨테이너 실행
```

장점:

- 웹 브라우저에서 코드 열람, 이슈, PR, 사용자 관리 가능
- SSH 포트를 Gitea 컨테이너로 매핑해 기존 git 클라이언트와 호환

> Git Server 패키지가 가볍고 빠른 반면, Gitea는 기능이 풍부합니다.
> "코드 저장이 목적" → Git Server / "협업 플랫폼이 목적" → Gitea(Docker)

### 14.3 참고 링크

- Synology 지식 센터 (Git Server): `https://kb.synology.com/ko-kr/DSM/help/Git/git?version=7`
- Synology 다운로드 센터: `https://www.synology.com/ko-kr/support/download`
- Git 공식 문서: `https://git-scm.com/doc`

---

## 체크리스트 (요약)

**초기 설정**
- [ ] Git Server 패키지 설치
- [ ] SSH 서비스 활성화 (포트 확인)
- [ ] 사용자 홈 서비스 활성화
- [ ] Git 전용 사용자 생성
- [ ] 저장소용 공유 폴더 생성 + 권한 부여
- [ ] Git Server 앱에서 사용자 접근 허용

**저장소 생성**
- [ ] SSH 접속 확인
- [ ] `git init --bare` 로 저장소 생성
- [ ] `chown -R gituser:users` 권한 설정

**클라이언트 사용**
- [ ] 로컬에서 첫 커밋 후 `git push -u origin main`
- [ ] SSH 키 인증 설정 완료
- [ ] 홈 디렉토리 권한 조정 (DSM 7)

**운영**
- [ ] post-receive 훅으로 자동 배포 (선택)
- [ ] 방화벽/SSH 포트 보안 설정
- [ ] Hyper Backup으로 `git` 폴더 예약 백업
