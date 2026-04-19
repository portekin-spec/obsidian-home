---
dg-publish: true
topic: "claude-obsidian-save"
created: 2026-04-10
updated: 2026-04-12
sources:
  - "raw/2026-04-10/005-075249.md"
  - "raw/2026-04-10/006-stop-hook-fix.md"
  - "raw/2026-04-10/007-114007.md"
  - "raw/2026-04-10/2026-04-10-1847.md"
  - "raw/2026-04-10/2026-04-10-1848.md"
  - "raw/2026-04-10/2026-04-10-1851.md"
  - "raw/2026-04-10/2026-04-10_184257.md"
  - "raw/2026-04-10/2026-04-10_184317.md"
  - "raw/2026-04-10/2026-04-10_184358.md"
  - "raw/2026-04-10/2026-04-10_184432.md"
  - "raw/2026-04-12/2026-04-12-1008.md"
  - "raw/2026-04-10/2026-04-10-1855.md"
  - "raw/2026-04-10/2026-04-10-1856.md"
tags: [claude-code, obsidian, automation, python, stop-hook, bugfix]
---

# Claude 대화 Obsidian 저장 시스템

## Summary

Claude 대화를 Obsidian raw 폴더에 저장하는 시스템.
Stop 훅 자동저장 방식을 시도했으나 stdin transcript 비어있는 문제로 실패,
최종적으로 "저장해" 수동 트리거 + Python JSONL 파싱 방식으로 구현.

---

## Details

### 시도 히스토리

#### ① Stop 훅 + transcript stdin 방식 (실패)
- **시도**: Stop 훅 stdin으로 전달되는 `transcript` 필드를 파싱해 저장
- **실패 원인**: `--channels` 모드(텔레그램 연동)에서 stdin transcript가 비어있음
- **증거**: `debug-hook.txt` — 실제 훅 실행 시 stdin 0~2바이트

#### ② Stop 훅 미등록 문제 (버그)
- **현상**: 자동 저장 전혀 안 됨
- **원인**: `settings.local.json`에 `hooks` 섹션 자체 없음
- **추가 원인**: 전역 settings.local.json에 `pm2 restart telegram-claude` Stop 훅이 있어 Claude 프로세스 재시작 → save-session.ps1 stdin 수신 불가
- **수정**: 전역 `pm2 restart` Stop 훅 제거, 프로젝트 훅만 유지

#### ③ Stop 훅 + JSONL 직접 읽기 방식 (부분 성공)
- **시도**: Stop 훅 stdin의 `session_id`로 JSONL 파일 특정 후 직접 읽기
- **한계**: 매 응답마다 저장되어 너무 잦은 실행, 사용자 요구와 맞지 않음

#### ④ 수동 트리거 + Python JSONL 파싱 (최종 채택) ✅
- **트리거**: "저장해" (Claude Code 또는 텔레그램)
- **스크립트**: `C:\Users\FT\.claude\scripts\save_conversation.py`

---

### 최종 구현: save_conversation.py

#### 저장 경로 구조

```
D:\project\Home-obsidian-vault\Home-obsidian\LLM-Wiki\raw\
└── YYYY-MM-DD\
    ├── YYYY-MM-DD-HHMM.md   ← 당일 첫 저장: 전체 대화
    ├── YYYY-MM-DD-HHMM.md   ← 이후 저장: 직전 파일 시간 +1분 이후만
    └── ...
```

#### 증분 저장 로직

1. 날짜 폴더에서 `????-??-??-????.md` 패턴 파일 중 최신 파일 탐색
2. 파일명에서 시간 파싱: `2026-04-10-1848.md` → `18:48` → cutoff = `18:49:00` (로컬)
3. JSONL의 UTC timestamp를 로컬 변환 후 cutoff 이후 메시지만 포함

#### JSONL 탐색 경로 인코딩

```
cwd (예: D:\project) → D--project
규칙: ":\" → "--", "\" → "-"
경로: ~/.claude/projects/D--project/*.jsonl (최신 파일)
```

#### 저장 내용

대화 텍스트 + 도구 사용 내역:

| 도구 | 저장 내용 |
|------|----------|
| `Write` | `> **[Write]** 파일경로` |
| `Edit` | `> **[Edit]** 파일경로` + 변경 전/후 100자 |
| `Bash` | `> **[Bash]** 명령어` + 실행 결과 500자 |
| `Read/Glob/Grep` | 도구명 + 경로/패턴 |

#### 트리거 (CLAUDE.md)

```
`저장해` → python "C:/Users/FT/.claude/scripts/save_conversation.py" 실행
텔레그램에서 온 경우 reply로 결과 전달
```

#### frontmatter 형식 (현재)

```yaml
---
tags: [llm-conversation, claude]
date: YYYY-MM-DD
saved_at: HH:MM:SS
session_id: {uuid}
---
```

> ⚠️ 기존 LLM-Wiki 표준 형식(`status`, `title`, `source`)과 다름.
> 인제스트 자동 연계를 원할 경우 스크립트 frontmatter 수정 필요.

---

### 다양한 raw 파일 형식 처리 (ingest)

오늘 현재 존재하는 raw 파일 형식이 3종류:

| 형식 | 특징 | 처리 방법 |
|------|------|----------|
| 표준형 (`NNN-title.md`) | status, title, source 포함 | frontmatter 그대로 사용 |
| 신규형 (`YYYY-MM-DD-HHMM.md`) | tags, date, saved_at만 있음 | title=첫 User 메시지 50자, status=reviewing 추론 |
| 자유형 (frontmatter 없음) | 순수 마크다운 설계 문서 | H1 제목 추출, 내용 기반 topic 추론 |

ingest는 형식 자동 감지 후 필드 보완하여 처리.

---

## Source

- [[raw/2026-04-10/005-075249.md|Stop 훅 자동저장 디버그]]
- [[raw/2026-04-10/006-stop-hook-fix.md|Stop 훅 미등록 수정]]
- [[raw/2026-04-10/007-114007.md|JSONL 직접 읽기 시도]]
- [[raw/2026-04-10/2026-04-10-1847.md|Python 저장 시스템 구현 원본]]

## Links

- [[llm-wiki-system]]
- [[telegram-session-control]]
- [[claude-environment-backup]]
- [[heartbeat-dms-setup]]
