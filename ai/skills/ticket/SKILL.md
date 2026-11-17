---
name: ticket
description: Work a ticket so the user understands and can stand behind what ships. Use when starting a ticket, feature or bug fix in a work codebase (/ticket start), explaining a branch's diff before review (/ticket explain), or checking a branch is ready for a PR/MR (/ticket check).
argument-hint: "[start <ticket> | explain | check]"
---

# Ticket workflow

The user ships this change and answers for it, so the goal is that **they understand it**, not that
it's written fast. Do the legwork; leave them the thinking that builds judgement: stating the
expected behaviour, and summarising the change. Never do those for them first.

Three phases: **start** (understand, then plan), **explain** (walk the diff), **check** (prove the
tests, plan the rollout, draft the PR). With no argument, pick by state: no brief for this branch →
start; brief with an empty *My summary* → explain; otherwise check. Say which phase you're running.

## Notes

Everything lives in `~/notes/<repo>/`, outside every repo, never in the repo or the dotfiles. Make
the folders if missing.

```bash
repo="$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")"
# ~/notes/$repo/tickets/<branch with / as ->.md   one brief per ticket
# ~/notes/$repo/areas/<area>.md                   what the user has learned about one part of the system
```

An *area* is a part of the system the user would name (`billing`, `auth`, `room-service`). Area notes
use: **What it does**, **How it works** (entry points, flow, data), **Rules** (invariants, business
rules), **Gotchas**, **Who knows it**, with an `Updated: YYYY-MM-DD` line. Write only what the code or
the user confirmed.

## start

1. **Get the ticket.** A GitHub or GitLab issue (number or URL): `gh issue view --comments` or
   `glab issue view --comments`, picked by the `origin` host. A Jira key (`ABC-123`) or URL: use
   `jira` or `acli` if installed, otherwise ask the user to paste it. Anything else: ask.
2. **Read the notes** for the areas the ticket touches.
3. **Explain how it works today**, before any plan: where requests come in, the path through the
   code, where data is stored, what else depends on it, the business rules involved. Short and
   concrete, with `file:line` references. Flag where the code disagrees with the notes.
4. **Expected behaviour.** Ask the user to list, in plain English, what should be true when this is
   done, *before* offering any of your own. Then add what they missed (error cases, permissions,
   empty and boundary input, concurrency, and existing behaviour that must not change), each marked
   *(added)*. They confirm the final list.
5. **Plan.** Each file to touch and why it has to change. Mark **high risk** anything touching auth,
   money, personal data, migrations or other hard-to-undo changes, concurrency, or a public API.
   If the plan spans several areas or needs a refactor first, propose splitting it into a prep PR
   and the feature PR.
6. **Wait for the OK.** Then branch per the global git rules (`<type>/<ticket-id>-<desc>`) and write
   the brief from the template below.

While building, follow the *Working on tickets* rules in the global instructions, and keep the
brief's **Decisions** and **Discoveries** current. For an *ask the lead* discovery, draft the
one-line question for the user to send.

## explain

1. **Diff against the plan**: `git diff "$(git merge-base origin/main HEAD)"`. List any file not in
   the plan first, with why it changed.
2. **Walk it file by file**, high-risk first: what changed, why *this* file had to change, which
   expected-behaviour item it serves. Plain language; no line-by-line narration of the obvious.
3. **Blast radius.** For each changed function, endpoint, schema, event or config key, find what
   uses it (search the code) and say which of those now behave differently.
4. **The user summarises.** Ask for 3 to 5 sentences in their own words: what the change does, why
   this approach, what could break. Don't offer a summary first. Then correct it: what's right,
   what's wrong, what's missing. Repeat until it's accurate. Save *their* corrected version under
   **My summary**; don't rewrite it in your voice.
5. **Reviewer questions.** Ask the two or three questions a reviewer is most likely to ask about this
   diff. Let the user answer, then fill in what they missed.

## check

1. **Map behaviour to tests.** Every expected-behaviour item gets a test, or a manual check with
   exact steps when automating it isn't practical. Write the missing tests.
2. **Prove each test can fail.** Per item: make the smallest code change that breaks that behaviour,
   run its test, confirm it fails, then `git restore <file>` and confirm `git status --short <file>`
   is clean. Only break files with no uncommitted changes (commit first), and never commit a broken
   file. A test that still passes is not a test: fix it. Report a table: behaviour, test, what you
   broke, failed (yes/no).
3. **The user runs it.** Give the exact commands to run the new tests and the suite; for browser E2E,
   the headed or trace mode if the repo's tool has one. They look at the output themselves.
4. **Not covered.** List plainly what no test or check covers.
5. **Shipping.** Answer from the repo, or say it's unknown: how would we notice it broke (alerts,
   logs, dashboards)? How do we undo it (is a revert safe? is there a migration)? Can exposure be
   limited (feature flag, gradual rollout)? What should the user check right after deploy?
6. **PR description.** Use the repo's template if it has one (`.github/pull_request_template.md`,
   `.gitlab/merge_request_templates/`); otherwise **What** (from *My summary*), **Why**, **Touched**,
   **Risk**, **Tests**, **Found but not fixed**, **Rollback**. Show it; open the PR or MR only when
   the user says to.
7. **Discoveries** marked *separate* without a ticket: offer to draft them; create issues only on
   the user's OK.
8. **Update the area notes** with what was learned, as a shown diff the user approves.

End with this checklist, marking anything not done:

- [ ] every file outside the plan is explained
- [ ] *My summary* is accurate and in the user's words
- [ ] every expected-behaviour item has a test shown to fail, or a manual check
- [ ] not-covered list, detection and rollback are written down

## Brief template

```markdown
# <TICKET-ID>: <title>

Branch: `<branch>` · Started: YYYY-MM-DD · Ticket: <link>

## Goal
<one or two sentences>

## How it works today
<short; link the area notes>

## Expected behaviour
- [ ] <the user's items first>
- [ ] <your additions, marked (added)>

## Plan
| File | Why it changes | Risk |
| ---- | -------------- | ---- |

## Decisions
- <picked X over Y because ...>

## Discoveries
| What | Where | Needed / separate / ask lead | Why | Ticket |
| ---- | ----- | ---------------------------- | --- | ------ |

## My summary
<written by the user in explain>

## Verification
<behaviour → test → failed when broken; not covered; how we'd notice; how to undo; what to watch>
```
