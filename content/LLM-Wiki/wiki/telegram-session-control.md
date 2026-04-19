---
dg-publish: true
topic: "telegram-session-control"
created: 2026-04-12
updated: 2026-04-12
sources:
  - "raw/2026-04-12/2026-04-12-1008.md"
  - "raw/2026-04-12/2026-04-12-1017.md"
tags: [telegram, claude-code, session, skill, restart, clear]
---

# 텔레그램 세션 제어 (/clear, /restart)

## Summary

텔레그램에서 `/clear` 또는 `/restart`를 보내면 Claude Code 세션을 재시작하는 스킬.
`/clear`는 CLI 내장 명령이라 텔레그램에서 직접 실행 불가 → 스킬로 구현하여 해결.

---

## Details

### 문제 배경

- `/clear`는 Claude Code CLI 내장 명령 — 텔레그램 채널에서는 실행 불가
- 해결책: `clear` 스킬 생성 → 텔레그램 `/clear` 수신 시 `restart-session.ps1` 실행

### 스킬 위치

```
~/.claude/skills/clear/SKILL.md
```

또는 프로젝트 스킬:
```
D:\project\claudeclaw-setup-telegram\skills\clear\SKILL.md (있는 경우)
```

### 실행 흐름

```
텔레그램: /clear
    ↓
Claude: clear 스킬 실행
    ↓
reply "🗑️ 대화 기록을 초기화합니다. 잠시 후 다시 연결됩니다."
    ↓
pwsh -ExecutionPolicy Bypass -File "D:/project/claudeclaw-setup-telegram/restart-session.ps1"
    ↓
세션 재시작 → STARTUP 트리거 → 텔레그램 온라인 알림
```

### CLAUDE.md 트리거 등록 (프로젝트)

```markdown
| `/clear` | reply "🗑️ 대화 기록을 초기화합니다. 잠시 후 다시 연결됩니다." → `pwsh -ExecutionPolicy Bypass -File "D:/project/claudeclaw-setup-telegram/restart-session.ps1"` |
| `/restart` | reply "🔄 재시작합니다. 잠시 후 다시 연결됩니다." → `pwsh -ExecutionPolicy Bypass -File "D:/project/claudeclaw-setup-telegram/restart-session.ps1"` |
```

### restart-session.ps1 / do-restart.ps1 체인

- `restart-session.ps1` → `do-restart.ps1` 로 체인 구성 (이미 구현됨)
- PM2 restart 방식으로 세션 재시작

### 확인 사항

- 스킬 생성 후 즉시 로드·활성화 (Claude Code 재시작 불필요)
- 텔레그램에서 `/clear` 전송 → 세션 재시작 정상 작동 확인

---

## Source

- [[raw/2026-04-12/2026-04-12-1008.md|/clear 구현 작업 원본]]
- [[raw/2026-04-12/2026-04-12-1017.md|스킬 생성 완료 원본]]

## Links

- [[llm-wiki-system]]
- [[claude-environment-backup]]
- [[heartbeat-dms-setup]]
- [[claude-obsidian-save]]
