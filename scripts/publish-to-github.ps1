$ErrorActionPreference = 'Stop'

# Run from any directory. The script uses the root of this materials package.
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
$repoFullName = 'Huh-HAH-heh/uch-mat'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git не найден. Установи Git for Windows и повтори запуск.'
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) не найден. Установи GitHub CLI: https://cli.github.com/ и повтори запуск.'
}

gh auth status
if ($LASTEXITCODE -ne 0) {
    throw 'Нет активной авторизации GitHub CLI. Выполни gh auth login и затем повтори запуск.'
}

# Avoid accidentally overwriting a repository that already exists.
gh repo view $repoFullName *> $null
if ($LASTEXITCODE -eq 0) {
    throw "Репозиторий $repoFullName уже существует. Скрипт остановлен, чтобы не перезаписывать его автоматически."
}

if (-not (Test-Path (Join-Path $repoRoot '.git'))) {
    git init --initial-branch=main
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось инициализировать локальный Git-репозиторий.' }
}

if (-not (git config user.name)) {
    $authorName = Read-Host 'Имя автора Git-коммита'
    if ([string]::IsNullOrWhiteSpace($authorName)) { throw 'Имя автора не может быть пустым.' }
    git config --local user.name $authorName
}
if (-not (git config user.email)) {
    $authorEmail = Read-Host 'Email автора Git-коммита (можно использовать GitHub noreply email)'
    if ([string]::IsNullOrWhiteSpace($authorEmail)) { throw 'Email автора не может быть пустым.' }
    git config --local user.email $authorEmail
}

git add --all
if ($LASTEXITCODE -ne 0) { throw 'Не удалось подготовить файлы к коммиту.' }

git rev-parse --verify HEAD *> $null
$hasHead = ($LASTEXITCODE -eq 0)
git diff --cached --quiet
$stagedDiffExitCode = $LASTEXITCODE
if (-not $hasHead -or $stagedDiffExitCode -eq 1) {
    git commit -m 'Add simplex method lecture and practice'
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось создать Git-коммит.' }
}

gh repo create $repoFullName --private --source . --remote origin --push
if ($LASTEXITCODE -ne 0) {
    throw 'GitHub CLI не смог создать репозиторий или отправить коммит. Проверь права аккаунта и сообщения выше.'
}

Write-Host ''
Write-Host "Готово: https://github.com/$repoFullName" -ForegroundColor Green
Write-Host 'Репозиторий создан приватным; изменить видимость можно в Settings → Danger Zone.'
