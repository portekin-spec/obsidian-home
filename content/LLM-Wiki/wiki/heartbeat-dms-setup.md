---
dg-publish: true
topic: "heartbeat-dms-setup"
created: 2026-04-12
updated: 2026-04-12
sources:
  - "raw/2026-04-12/2026-04-12-1049.md"
tags: [heartbeat, dms, cron, task-scheduler, windows, powershell, claude-code]
---

# 하트비트 크론 + DMS Task Scheduler 설정

## Summary

하트비트 L1/L2/L3 크론 3개 등록 + DMS(Dead Man's Switch) Windows Task Scheduler 등록.
DMS는 관리자 권한이 필요해 Claude Code에서 자동 실행 불가 — 사용자가 직접 관리자 PowerShell에서 실행 필요.

---

## Details

### 초기 상태 (문제)

| 항목 | 상태 | 원인 |
|------|------|------|
| L1/L2/L3 크론 | 미등록 | STARTUP 미실행 |
| `heartbeat/alive.txt` | 없음 | L1 크론 없어서 생성 안 됨 |
| DMS Task Scheduler | 미등록 | `ClaudeDMS` 작업 없음 |
| PM2 | waiting 상태 | 수동 실행 모드 |

### 수행 작업

#### Step 1 — alive.txt 생성
```powershell
echo (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") > heartbeat/alive.txt
```

#### Step 2 — 하트비트 크론 등록 (Claude Code CronCreate)
| 레이어 | 주기 | 설명 |
|--------|------|------|
| L1 | `*/29 * * * *` | bun/pm2 생존 체크 |
| L2 | `57 8 * * *` | 일일 다이제스트 |
| L3 | `53 7 * * 1` | 주간 메모리 감사 |

#### Step 3 — DMS Task Scheduler 등록
```powershell
# 관리자 PowerShell에서 실행
.\heartbeat\dms-setup.ps1
```

> ⚠️ UAC 자동 승인 불가 — Claude Code에서 실행 안 됨. 사용자가 직접 실행 필요.

### dms-setup.ps1 버그 수정 (2026-04-12)

| 버그 | 원인 | 수정 내용 |
|------|------|----------|
| `DisallowStartIfOnBatteries` 파라미터 오류 | Windows 버전 호환성 문제 | 파라미터 제거 |
| `RepetitionDuration [TimeSpan]::MaxValue` 오류 | 허용 범위 초과 | `New-TimeSpan -Days 365`로 변경 |

### DMS 등록 최종 절차

```powershell
# 관리자 PowerShell에서
cd D:\project\claudeclaw-setup-telegram
.\heartbeat\dms-setup.ps1
```

작업 이름: `ClaudeDMS`
반복 주기: 30분
지속 기간: 365일

### 결과

```
✅ alive.txt — 생성 완료
✅ 크론 3개 — L1/L2/L3 모두 등록 완료
✅ dms-setup.ps1 — 버그 2개 수정
⚠️ DMS Task Scheduler — 관리자 권한 필요, 수동 실행 필요
```

---

## Source

- [[raw/2026-04-12/2026-04-12-1049.md|하트비트 + DMS 설정 작업 원본]]

## Links

- [[llm-wiki-system]]
- [[claude-environment-backup]]
- [[telegram-session-control]]
