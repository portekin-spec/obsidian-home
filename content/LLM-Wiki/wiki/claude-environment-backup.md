---
dg-publish: true
topic: "claude-environment-backup"
created: 2026-04-12
updated: 2026-04-12
sources:
  - "raw/2026-04-12/2026-04-12-0755.md"
tags: [backup, claude-code, powershell, restore, portability]
---

# Claude Code 환경 백업 시스템 (D:\BACKUP)

## Summary

Claude Code + PM2 + LLM-Wiki 전체 환경을 `D:\BACKUP`에 백업하는 작업.
새 PC에서 `D:\BACKUP\README.md 읽고 복원해줘` 한 줄로 Claude Code가 자동 복원 가능하도록 구성.

---

## Details

### 백업 대상

| 항목 | 경로 | 설명 |
|------|------|------|
| Claude 설정 | `~/.claude/` | CLAUDE.md, settings.local.json, memory/, scripts/ |
| 텔레그램 채널 설정 | `~/.claude/channels/telegram/` | access.json (토큰 제외) |
| 하네스 프로젝트 | `D:/project/claudeclaw-setup-telegram/` | ecosystem.config.cjs, CLAUDE.md, skills/, heartbeat/ |
| LLM-Wiki 스크립트 | `D:/project/llm-wiki/` | save-session.ps1, wiki.ps1, config.json 등 |
| PM2 dump | `pm2 dump` | 실행 중인 프로세스 목록 저장 |

### 백업 제외 항목

- 봇 토큰 (`.env`) — 보안상 수동 복사 필요
- `node_modules/` — 설치 스크립트로 재생성
- Obsidian vault 원본 (별도 백업)

### 백업 구조

```
D:\BACKUP\
├── README.md               ← 복원 가이드 (Claude Code 자동 복원용)
├── claude-config/          ← ~/.claude/ 복사본
│   ├── CLAUDE.md
│   ├── settings.local.json
│   ├── memory/
│   └── scripts/
├── projects/
│   ├── claudeclaw-setup-telegram/
│   └── llm-wiki/
└── env-info/
    ├── pm2-dump.pm2
    ├── npm-global-list.txt
    └── path-info.txt
```

### 복원 절차 (새 PC)

```
1. D:\BACKUP 복사
2. README.md 읽고 복원해줘 → Claude Code 자동 실행
3. 봇 토큰 수동 복사: ~/.claude/channels/telegram/.env
4. pm2 restore → pm2 start ecosystem.config.cjs
```

### 전체 백업 규모

- 63.5 MB, 8417 files (2026-04-12 기준)

### 주요 확인 항목 (QA)

```
✅ settings.local.json 내용 포함
✅ CLAUDE.md 전체 포함
✅ pm2 설정 파일 (ecosystem.config.cjs)
✅ Stop hook 스크립트 (save-session.ps1)
✅ pm2 dump
```

---

## Source

- [[raw/2026-04-12/2026-04-12-0755.md|D:\BACKUP 환경 백업 작업 원본]]

## Links

- [[llm-wiki-system]]
- [[heartbeat-dms-setup]]
