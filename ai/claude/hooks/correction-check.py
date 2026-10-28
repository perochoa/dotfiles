#!/usr/bin/env python3
"""UserPromptSubmit hook: when a prompt looks like a behavioural correction, remind the assistant
to compare it against the corrections log and offer to codify repeats (ai/AGENTS.md).

Prints context for the assistant on stdout (exit 0). Never blocks the prompt.
"""

import json
import re
import sys
from pathlib import Path

LOG = Path(__file__).resolve().parents[2] / "corrections.local.md"
MAX_ENTRIES = 40
CORRECTION = re.compile(
    r"\b(don'?t|do not|never|always|stop|instead|again|i told you|i said|i asked|i want|"
    r"i'?d like|i would like|i prefer|from now on|moving forward|going forward|"
    r"make sure|remember to|you should|you shouldn'?t)\b",
    re.IGNORECASE,
)


def main() -> int:
    prompt = json.load(sys.stdin).get("prompt", "")
    if not CORRECTION.search(prompt):
        return 0
    entries = []
    if LOG.is_file():
        entries = [
            line for line in LOG.read_text().splitlines() if line.startswith("- ")
        ]
    recent = "\n".join(entries[-MAX_ENTRIES:]) or "(no entries yet)"
    print(
        "[correction-check] This prompt may contain a behavioural correction or preference. "
        "If it does, follow 'Learning from corrections' in ~/.claude/CLAUDE.md: compare it with "
        f"the log below ({LOG}); if it repeats or resembles an earlier entry, or restates an "
        "existing rule you broke, ask whether to codify it as a rule or hook before finishing. "
        "Log it either way. Ignore this note if the prompt isn't a correction.\n"
        f"Recent corrections:\n{recent}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
