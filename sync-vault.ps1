# Obsidian → Quartz 동기화 스크립트
# dg-publish: true 인 노트만 content/ 로 복사 후 GitHub push

$VaultPath   = "D:\project\Home-obsidian-vault\Home-obsidian"
$ContentPath = "$PSScriptRoot\content"
$RepoPath    = $PSScriptRoot

# content/ 초기화 (index.md 제외)
Get-ChildItem $ContentPath -Recurse -File | Where-Object { $_.Name -ne "index.md" } | Remove-Item -Force
Get-ChildItem $ContentPath -Recurse -Directory | Sort-Object FullName -Descending | Where-Object {
    (Get-ChildItem $_.FullName).Count -eq 0
} | Remove-Item -Force

$copied = 0

Get-ChildItem $VaultPath -Recurse -Filter "*.md" | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match "dg-publish:\s*true") {
        $relativePath = $_.FullName.Substring($VaultPath.Length + 1)
        $destPath = Join-Path $ContentPath $relativePath
        $destDir  = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item $_.FullName $destPath -Force
        $copied++
    }
}

Write-Host "동기화 완료: $copied 개 노트"

# Git push
Set-Location $RepoPath
git add -A
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "sync: $timestamp ($copied notes)" 2>&1
git push origin HEAD:main 2>&1

Write-Host "GitHub push 완료"
