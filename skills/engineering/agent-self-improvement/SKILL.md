---
name: agent-self-improvement
description: Mine recent Claude Code transcripts and memories for evidence about the agent instructions the user maintains, then remove the rules that misguide agents, refine the ones that steer weakly, and add one only where evidence demands it. Covers always-on instruction files and skills. Use for a requested improvement round or a due follow-up, not for feedback the user already supplied.
disable-model-invocation: true
---

# Agent Self-Improvement

Evidence comes from the user's own transcripts and memories rather than a supplied brief. A round mines that evidence, decides what to remove, refine, relocate, or add, and later checks whether the change held.

Transcripts contain work code, credentials, and customer data. Keep extraction and its output local, and quote from other repositories only what a finding needs.

## 1. Window, corpus, and targets

Sweep the last 14 days, or since the last recorded change. Read `~/.claude/projects/*/memory/*.md` first: the memories hold prior decisions, pending follow-ups, and rules the user already rejected.

Sweep every project directory, not only the current one. Memory and project instructions are keyed per directory, so guidance that exists may never load where the work happens.

The targets are the instructions that loaded in those sessions: `~/.claude/CLAUDE.md` and the files it imports, the skills under `~/.claude/skills/`, and the `CLAUDE.md` or `AGENTS.md` files of the projects named in the extractor's `cwd` field. Many of these are symlinks into a configuration repository. Resolve each to its real path, read its history and edit it there, and follow that repository's own maintenance instructions.

## 2. Extract

    python3 <skill-dir>/scripts/extract-user-turns.py --since YYYY-MM-DD [--until YYYY-MM-DD] [--project NAME]

It emits the user's authored turns as JSON lines with the preceding assistant turn, dropping meta, sidechain, command, and injected turns. Messages typed while the agent was working carry `mid_turn: true`; they hold many of the sharpest corrections. Read its output, never whole transcripts. Triage before reading in full: corrections live in short turns, and long pasted prompts are usually automation. Keyword filters are noisy, so a match is a candidate, not a finding.

Delegate triage to one worker per project directory when the window is wide. Give each the extractor output for its directory; require candidate quotes with their session and the preceding assistant turn in return. Keep the verdict in section 4 yourself, since it depends on memories and prior decisions a worker never sees.

## 3. Read the evidence against the rules

Read each candidate with the preceding assistant turn, then find the rule that governed that moment in the always-on instructions or the skill that fired. Sort what you find:

- **Misguiding**: the agent followed a rule and the user overrode it, argued with it, or had to repeat an instruction the rule contradicted. Also counts when guidance produced ceremony the user did not want - an avoidable question, a ritual, a document nobody asked for.
- **Weak steering**: the right rule existed and was loaded, and the failure still happened. The wording, not its absence, is the problem.
- **Unreachable**: the rule was never in context, or the skill's description never matched the situation. This is a placement or trigger problem; rewording the rule fixes nothing.
- **Uncovered**: a correction repeated across independent sessions with no rule addressing it.

Keep exact quotes and count independent sessions per theme. Once the themes are named, re-read the earlier candidates against the ones named later; a theme's session count is not final until every candidate has been checked against it, and a single forward pass undercounts themes that emerge late in the window. One incident is not a pattern; taste is not evidence.

## 4. Decide: remove, refine, relocate, add

Work in that order, and treat removal as the expected outcome rather than the rare one.

- **Remove** misguiding rules, rules superseded by another, and rules with no evidence of ever firing. A skill that never fired may be unreachable rather than unneeded: hosts consult skills only for tasks they cannot easily handle alone, so check whether the matching tasks occurred and were simple before removing it. Every always-on directive costs context in every session; measure that cost as section 5 describes.
- **Refine** weak steering in place. Prefer a concrete trigger and an observable behavior over emphasis; strong wording that already failed will fail again. Read the rule's git history before rewriting it - wording tried and reverted is evidence against repeating it.
- **Relocate** unreachable guidance, or fix the skill's description so its trigger matches the situation. Hosts select a skill from its frontmatter `name` and `description`, so a trigger stated only in the body never fires. A description that does not match how the user actually asks is the bug.
- **Add** only for an uncovered pattern, at the smallest effective layer: code, a test, or a deterministic check such as a hook or linter before any instruction; project guidance for a local convention; an existing skill for a task procedure; a new skill only when no existing trigger owns the procedure; the always-on instructions only for an essential default across repositories. State the rule as behavior, not as the incident's names, architecture, or rejected implementation. Adding a rule while the contradicting one survives creates the next misfire.

Present each candidate in one or two sentences: the problem, the proposed change and its file, and how many sessions show it. Give quotes and evidence when the user asks, then wait. "No change" is a result.

After approval, edit the real path, remove conflicting or duplicate guidance in the same change, and confirm the rule loads where the work happens; a rule that is present but cannot fire is not a fix. Commit only when the user asks.

## 5. Follow up honestly

There is no general metric for whether agents improved. Do not invent one, and do not present a quiet window as proof.

What can be checked, and belongs in a `project` memory with the commit and a date roughly two weeks out: the specific behavior the change targets, stated as something observable in a transcript; the count and window it was drawn from; and the instruction cost before and after. Measure the cost the same way both times: words (`wc -w`) and directive lines (`grep -cE '^[[:space:]]*([-*]|[0-9]+\.|\|)'`) in each always-on file, and the words in each skill `description`. Use the configuration repository's own status command instead when it has one.

At that date, re-run the extractor over the new window with the same filters and report three things together: whether the behavior recurred, how many sessions could have exposed it, and whether the user corrected the same theme in a new way. No recurrence with no exposure establishes nothing. Removal is confirmed the same way, in reverse: check that the behavior the deleted rule guarded against did not return. Record what the user declines in a `feedback` memory so it is not proposed again, and delete a memory once its question is settled.

## Do not

- Add a rule from one incident, from taste, or to answer a single frustrated message.
- Strengthen wording that was already tried and removed.
- Add a skill whose trigger an existing skill owns, or keep a skill the evidence shows never fires.
- Move a task-specific procedure into the always-on instructions.
- Compare a follow-up against a baseline mined with different filters.
- Keep a ledger, plan, or failure log in the instruction files; memory and commit messages hold that state.
