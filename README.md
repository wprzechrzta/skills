# skills


# Quickstart 

Run the skills.sh installer:
```shell
npx skills@latest add wprzechrzta/skills
```

Install a single skill:
```shell
npx skills@latest add wprzechrzta/skills --skill agent-self-improvement
```

# Skills

## agent-self-improvement

Source: [sephriot/agent-self-improvement](https://github.com/sephriot/agent-self-improvement) (MIT, see `skills/engineering/agent-self-improvement/LICENSE`).

Runs an improvement round over your agent instructions (`CLAUDE.md`, `AGENTS.md`, skills). It mines recent Claude Code transcripts and memories for user corrections, proposes rules to remove, refine, relocate or add, and records a follow-up check about two weeks later.

Install by symlink instead of the installer:
```shell
ln -s "$PWD/skills/engineering/agent-self-improvement" ~/.claude/skills/agent-self-improvement
ln -s "$PWD/skills/engineering/agent-self-improvement" ~/.agents/skills/agent-self-improvement
```

Run it in Claude Code (it sets `disable-model-invocation: true`, so it only runs when invoked):
```
/agent-self-improvement
```

Run the transcript extractor by hand (Python 3, standard library only):
```shell
python3 skills/engineering/agent-self-improvement/scripts/extract-user-turns.py --since YYYY-MM-DD [--until YYYY-MM-DD] [--project NAME]
```

Test the extractor:
```shell
bash tests/extract-user-turns.sh
```

Privacy: transcripts contain work code, credentials and customer data. The extractor only reads local transcripts and writes to stdout; keep its output local.
