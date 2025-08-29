# === 설정 (여기만 본인 리포 주소로 교체) =========================
$REMOTE_URL = "https://github.com/mino-son/mino-repo.git"
# ==================================================================

# 0) 현재 폴더가 git 저장소가 아니면 init
git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { git init }

# 1) 기본 브랜치를 main으로 강제 전환(없으면 생성)
git checkout -B main

# 2) 모든 변경 스테이징
git add .

# 3) 스테이징된 내용이 있으면 커밋
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  git commit -m "chore: initial sync"
}

# 4) 같은 이름의 원격이 있으면 제거 후 재등록
git remote remove minotest 2>$null
git remote add minotest $REMOTE_URL

# (선택) 토큰/암호 저장하고 싶으면 주석 해제
# git config --global credential.helper store

# 5) 원격 main 존재 여부 확인용 fetch (없어도 에러 무시)
git fetch minotest main 2>$null

# 6) 푸시 시도
git push -u minotest main
if ($LASTEXITCODE -ne 0) {
  # 원격에 선행 커밋(README 등)이 있어 거절된 케이스 대응
  git pull --rebase minotest main
  if ($LASTEXITCODE -ne 0) {
    Write-Host "pull --rebase 중 충돌 또는 오류가 발생했습니다. 해결 후 다시 실행하세요." -ForegroundColor Yellow
    exit 1
  }
  git push -u minotest main
}
