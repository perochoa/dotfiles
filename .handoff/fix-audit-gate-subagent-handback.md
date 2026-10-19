# fix/audit-gate-subagent-handback

## Goal
audit-gate must record auditor reports that subagents return through the `SubagentHandback` tool
call instead of a final text message. Before this fix, the implementer was always rejected after
a background auditor run.

## Status
- [x] `audit-gate.py`: `record()` falls back to the auditor's transcript when
      `last_assistant_message` lacks the four sections; `last_text()` reads `SubagentHandback` input
- [x] replayed the two real auditor runs from the CS4411 project session (bc097c0d): old hook
      recorded neither, new hook recorded both
- [x] check.sh regression test (fails on the old hook, passes on the new)
- [ ] live run: auditor → implementer end to end in a real session
- [ ] push and open the PR (only when the user asks)

## Decisions
- Use `agent_transcript_path` before `transcript_path`: on SubagentStop, `transcript_path` is the
  parent session's transcript, and the parent doesn't contain the subagent's hand-back.
- Keep `last_assistant_message` as the first source when it has the sections (foreground runs and
  `claude --agent` sessions).

## Gotchas
- Background subagents (`requestShape: background`) end with a `SubagentHandback` tool_use whose
  `input.message` is the report; the parent sees it as an "[Subagent hand-back]" agent-message.
- Subagent transcripts: `~/.claude/projects/<proj>/<session>/subagents/agent-<id>.jsonl` (+ `.meta.json`
  with agentType); some are symlinks into another session's dir.
- What `last_assistant_message` holds when a hand-back ends the run hasn't been observed; the
  replay assumed it was empty.

## Key files
- `ai/claude/hooks/audit-gate.py`, `scripts/check.sh`
