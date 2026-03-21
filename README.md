# claude-skills

A personal collection of agent skills for [Cursor](https://cursor.com), publishable to [ClawHub](https://clawhub.ai) — the skill marketplace for OpenClaw AI agents.

## Skills

| Skill | Description |
|-------|-------------|
| [english-word-coach](./english-word-coach/) | English vocabulary coach with word analysis, library management, and spaced-repetition daily review |
| [extract-youtube-transcript](./extract-youtube-transcript/) | Fetch plain-text transcripts from YouTube videos using a local Python script |
| [perplexity-research](./perplexity-research/) | Deep research via Perplexity Agent API with web search and multi-model analysis |

---

## Publishing Skills to ClawHub

`publish_to_clawhub.sh` publishes one or all skills from this repo to [clawhub.ai](https://clawhub.ai).

### Prerequisites

1. **Install clawhub CLI**
   ```bash
   npm install -g clawhub
   ```

2. **Log in to ClawHub**
   ```bash
   clawhub login
   ```
   This opens a browser OAuth flow. A GitHub account at least one week old is required.

---

### Publish a single skill

```bash
./publish_to_clawhub.sh <skill-folder> [options]
```

Pass the skill folder name (relative to repo root) or a full path:

```bash
# By folder name
./publish_to_clawhub.sh extract-youtube-transcript

# By full path
./publish_to_clawhub.sh /path/to/claude-skills/perplexity-research

# With version bump and changelog
./publish_to_clawhub.sh extract-youtube-transcript --bump minor --changelog "Added cookie auth support"
```

---

### Publish / sync all skills

Omit the skill folder to scan and publish all skills that are new or updated:

```bash
./publish_to_clawhub.sh
```

---

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--bump patch\|minor\|major` | `patch` | Semver bump type (sync-all mode only) |
| `--changelog <text>` | — | Release notes for this version |
| `--tags <t1,t2>` | `latest` | Comma-separated registry tags |
| `--dry-run` | off | Preview what would be published; no upload |
| `--all` | off | Non-interactive; publish all without prompts |
| `-h, --help` | — | Show usage |

---

### Examples

```bash
# Preview all changes without uploading
./publish_to_clawhub.sh --dry-run

# Publish one skill silently (CI-friendly)
./publish_to_clawhub.sh perplexity-research --all --bump patch

# Publish all with a minor bump and changelog
./publish_to_clawhub.sh --all --bump minor --changelog "Improved error handling"

# First-time publish of a new skill
./publish_to_clawhub.sh my-new-skill --bump minor --changelog "Initial release"
```

---

## Adding a New Skill

Each skill is a folder containing at minimum a `SKILL.md` file with YAML front-matter:

```markdown
---
name: my-skill-name
description: One-sentence description shown in search results.
---

# My Skill

...instructions for the AI agent...
```

Once the folder is ready, publish it:

```bash
./publish_to_clawhub.sh my-skill-name
```
