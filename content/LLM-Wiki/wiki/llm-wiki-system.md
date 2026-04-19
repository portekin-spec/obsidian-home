---
<!-- 마지막 수정: 2026-04-19 05:16:09 -->
topic: "llm-wiki-system"
dg-publish: true
dg-home: true
created: 2026-04-10
updated: 2026-04-18
sources:
  - "raw/2026-04-10/001-llm-wiki-setup-and-synology.md"
  - "raw/2026-04-10/006-stop-hook-fix.md"
  - "raw/2026-04-10/llm_wiki_claude_code_obsidian_전체_설계_정리.md"
  - "raw/2026-04-10/LLM_Wiki_Full_Trace.md"
  - "raw/2026-04-12/2026-04-12-1105.md"
tags: [llm-wiki, obsidian, powershell, claude-code, hooks, architecture]
---

# LLM-Wiki 시스템 구조

## Summary

Claude와의 모든 대화를 Obsidian vault에 날짜별로 저장하고, 지식으로 정제하는 자동화 시스템.
`raw/` 에 원본 대화를 보존하고, `wiki/` 에 주제별 지식 문서를 생성·병합하는 Core Loop 구조.

---

## Details

### 폴더 구조

```
D:\project\Home-obsidian-vault\Home-obsidian\LLM-Wiki\
├── raw/                      ← 대화 원본 (불변)
│   └── YYYY-MM-DD/
│       └── NNN-title.md      ← 표준 형식
├── wiki/                     ← 정제된 지식
│   ├── _wiki-index.md
│   └── {topic}.md
├── schema/
│   └── wiki-template.md
├── AGENTS.md
├── state.json
├── _index.md                 ← 자동 생성
└── _log.md

D:\project\llm-wiki\          ← 운영 스크립트
├── config.json
├── save-session.ps1
├── update-status.ps1
├── build-index.ps1
├── wiki.ps1 / wiki.bat
└── skills/
    ├── ingest/        ← raw → wiki (3모드: 대화/임의파일/날짜지정)
    ├── query/         ← wiki 기반 검색
    ├── lint/          ← 품질 점검
    ├── index/         ← 인덱스 재생성
    ├── refactor/      ← 중복 병합
    ├── gc/            ← 오래된 항목 정리
    ├── feedback/      ← wiki 수정
    ├── contradiction/ ← 상충 탐지
    ├── self-ingest/   ← 개인 프로파일 → wiki (2026-04-19 추가)
    └── diary/         ← 일기·회고 생성 (2026-04-19 추가)

C:\Users\FT\.claude\skills\wiki\  ← 전역 디스패처 (2026-04-12 생성)
└── SKILL.md          ← "wiki" 명령 통합 라우터
```

### Core Loop

```
대화 종료 (Stop 훅 or 수동 "저장해")
    ↓
raw/YYYY-MM-DD/ 저장
    ↓
[수동] "인제스트"
    ↓
wiki/ 생성·병합
    ↓
[주기적] lint / refactor / gc
    ↓
[질문] "wiki에서 찾아봐" → query
    ↓
[오류] "틀렸어" → feedback
```

### raw 파일 frontmatter 표준 형식

```yaml
---
date: YYYY-MM-DD
title: "제목"
status: reviewing        # reviewing | success | failed | stopped
source: telegram         # telegram | cli | manual | claude-code
session_id: "..."
tags: []
saved_at: "YYYY-MM-DDThh:mm:ss+09:00"
---
```

### Status 의미

| Status | 의미 |
|--------|------|
| `reviewing` | 기본값, 검토 필요 |
| `success` | 목표 달성, 완전 해결 |
| `failed` | 해결 실패 또는 잘못된 정보 |
| `stopped` | 중간 중단, 방향 변경 |

### PowerShell 스크립트

#### save-session.ps1
Stop 훅에서 호출되어 JSONL → raw/.md 저장.
- stdin JSON의 `session_id`로 JSONL 파일 특정
- 날짜 폴더 + NNN 순번 + ASCII-safe 파일명
- frontmatter + 대화 전문 UTF-8 NoBOM 저장

**구현 시 발견된 버그:**

| 버그 | 원인 | 수정 |
|------|------|------|
| 한글 파일명 깨짐 | Console.InputEncoding 기본값 문제 | `[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)` 추가, 파일명에서 한글 제거 (title은 frontmatter에 보존) |
| `-replace` 3인자 오류 | PowerShell `-replace`는 2인자만 지원 | `[System.Text.RegularExpressions.Regex]::Replace()` 방식으로 변경 |

#### update-status.ps1
```powershell
pwsh -File D:/project/llm-wiki/update-status.ps1 `
  -Date "2026-04-10" -Number "001" -Status "success"
```

#### build-index.ps1
`raw/` 전체 스캔 → `_index.md` 날짜별 테이블 + status 통계 자동 생성.

#### wiki.ps1 / wiki.bat 명령어

| 명령어 | 설명 |
|--------|------|
| `wiki status` | 전체 상태 요약 |
| `wiki index` | 인덱스 재생성 |
| `wiki lint` | 품질 점검 |
| `wiki gc` | 오래된 항목 탐지 |
| `wiki ingest` | raw → wiki 변환 |
| `wiki query <키워드>` | wiki 검색 |
| `wiki update <date> <num> <status>` | status 변경 |

### Stop 훅 등록 위치

```
C:\Users\FT\.claude\settings.local.json   ← 전역 (현재 사용)
D:\project\claudeclaw-setup-telegram\.claude\settings.json  ← 프로젝트
```

> ⚠️ 두 곳 동시 등록 시 충돌 주의. 전역 settings.local.json 쪽이 우선.
> 전역에 `pm2 restart` Stop 훅이 있으면 save-session.ps1 stdin이 비어버림 → 제거 필요.

#### Stop 훅 미등록 진단 & 수정 (2026-04-10)

- **문제**: `debug-hook.txt` 분석 결과 stdin = 0~2바이트 → 훅 자체가 미호출 상태
- **원인**: `settings.local.json`에 `hooks` 섹션 자체가 없었음
- **수정**: `settings.local.json`에 아래 블록 추가

```json
"hooks": {
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "pwsh -ExecutionPolicy Bypass -File D:/project/llm-wiki/save-session.ps1"
        }
      ]
    }
  ]
}
```

- **검증**: 다음 세션 종료 후 debug-hook.txt에 stdin 내용 확인

### AGENTS.md 핵심 원칙

- `raw/` 파일은 절대 수정하지 않는다
- `wiki/` 는 ingest로만 생성/병합
- 같은 topic wiki가 있으면 merge (덮어쓰기 금지)

---

## Conflicts

### 시놀로지 Time Machine 정보 오류 (2026-04-10)
- **Claude 제공 정보**: DSM 7 제어판 → 파일 서비스 → SMB → Bonjour Time Machine
- **실제 결과**: 사용자가 직접 해결 (Claude 안내가 부정확)
- **교훈**: 기술 질문은 공식 문서 먼저 확인 후 답변, 기억에 의존 금지

---

## Source

- [[raw/2026-04-10/001-llm-wiki-setup-and-synology.md|LLM-Wiki 구축 + 시놀로지 대화 원본]]
- [[raw/2026-04-10/006-stop-hook-fix.md|Stop 훅 미등록 발견 및 수정]]
- [[raw/2026-04-10/llm_wiki_claude_code_obsidian_전체_설계_정리.md|전체 설계 정리 문서]]
- [[raw/2026-04-10/LLM_Wiki_Full_Trace.md|Full Trace 참조 문서]]

## Links

- [[claude-obsidian-save]]
- [[claude-environment-backup]]
- [[heartbeat-dms-setup]]
- [[telegram-session-control]]
