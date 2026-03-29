---
name: vocabulary-anti-forgetting
version: 2.0.0
description: >-
  Anti-forgetting vocabulary review using spaced repetition. Selects 10 words
  from asset/vocabulary_bank.md and presents each with English, Chinese
  translation, usage notes, and synonyms. Records review history to memory.
  Use when the user says "单词复习", "复习", "review words", or any similar
  command indicating they want to do vocabulary review or practice.
---

# Vocabulary Anti-Forgetting

Daily vocabulary review using spaced repetition. Selects 10 words per session and presents each with full details: English, Chinese translation, usage notes, and synonyms. No quiz.

---

## Trigger

Activate when user says: `单词复习` / `复习` / `review` / `开始复习` / `背单词` / `单词练习`

---

## Session Flow

```
1. Load vocabulary bank + review history
2. Select 10 words (spaced repetition logic)
3. Present all 10 words with full details
4. Save session record to memory
```

---

## Step 1 — Load Data

**Vocabulary bank:** Read `asset/vocabulary_bank.md` from this skill.

**Review history:** Read `memory/vocab_history.md` from current agent workspace (create if absent).

Review history format:
```markdown
# Vocabulary Review History

| Word | Review Count | Last Review | Next Review | Interval (days) |
|------|--------------|-------------|-------------|-----------------|
| resilience | 2 | 2026-03-25 | 2026-04-01 | 7 |
```

---

## Step 2 — Select 10 Words

1. From review history, find words where `Next Review <= today` → these are **due words** (sorted by Next Review ascending)
2. If due words < 10: fill remaining slots from vocabulary bank words **not yet in review history** (take in order from the bank, starting from lowest entry number)
3. Pick exactly **10 words** total

---

## Step 3 — Present Words

Output each word as a card. Present all 10 in a single reply:

```
📚 今日复习单词 (10个) — YYYY-MM-DD

---

**1. resilience** *n.*

🇨🇳 **中文：** 韧性；恢复力

📖 **用法：**
She showed remarkable resilience in the face of adversity.
（她在逆境中展现出非凡的韧性。）

🔗 **近义词：** tenacity, perseverance, fortitude, grit

---

**2. take the high road** *短语*

🇨🇳 **中文：** 采取高姿态；走正道；以德报怨

📖 **用法：**
Even when criticized unfairly, she chose to take the high road and remained professional.
（即使受到不公平的批评，她仍选择以大局为重，保持专业。）

🔗 **近义词：** rise above it, turn the other cheek, be the bigger person

---

... (cards 3–10) ...

---

✅ 今日复习完成！下次复习：[date of soonest next review]
```

---

## Step 4 — Save Session Record

### 4a — Update review history

For each of the 10 reviewed words, upsert a row in `memory/vocab_history.md`:

| Review Count (after session) | Next Review Interval |
|------------------------------|----------------------|
| 1 | 3 days |
| 2 | 7 days |
| 3 | 14 days |
| 4 | 30 days |
| ≥ 5 | 60 days |

Update fields: `Review Count += 1`, `Last Review = today`, `Next Review = today + interval`, `Interval = new interval`

### 4b — Append to session log

Append to `memory/vocab_sessions.md` (create if absent):

```markdown
## Session: YYYY-MM-DD

**Words reviewed:** word1, word2, word3, word4, word5, word6, word7, word8, word9, word10
```

---

## Memory Files Reference

| File | Purpose |
|------|---------|
| `memory/vocab_history.md` | Per-word spaced repetition tracking |
| `memory/vocab_sessions.md` | Session log (date, words reviewed) |

Both files are relative to the **current working directory** (not the skill directory).

---

## Rules

- Always **read** files before writing to avoid overwriting existing content
- The vocabulary bank path is absolute: `/Users/hushenglang/Development/workspace/2026/claude-skills/vocabulary-anti-forgetting/asset/vocabulary_bank.md`
- For phrases/idioms in the bank (e.g. "take the high road"), treat the full phrase as the vocabulary item
- If a word/phrase has a type hint in the bank (e.g. "devour v"), use it; otherwise infer from context
- Use your knowledge to provide Chinese meanings, usage examples, and synonyms — the bank lists only the English entries
- If `memory/` directory does not exist in cwd, create it before writing
- Usage example must include both English sentence and Chinese translation
- Synonyms should be 3–5 closely related words or phrases
