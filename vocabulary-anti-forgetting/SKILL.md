---
name: vocabulary-anti-forgetting
version: 1.1.0
description: >-
  Anti-forgetting vocabulary review using spaced repetition. Selects 10 words
  from asset/vocabulary_bank.md, shows a summary first, then quizzes with 30
  shuffled questions (3 per word: MCQ, fill-blank, translation) presented in
  batches of 3 (one batch per reply). Records review history to memory.
  Use when the user says "单词复习", "复习", "review words", or any similar
  command indicating they want to do vocabulary review or practice.
---

# Vocabulary Anti-Forgetting

Daily vocabulary review using spaced repetition. Reviews 10 words per session with 30 questions, presented **3 per reply** (each batch covers 3 different words).

---

## Trigger

Activate when user says: `单词复习` / `复习` / `review` / `开始复习` / `背单词` / `单词练习`

---

## Session Flow

```
1. Load vocabulary bank + review history
2. Select 10 words (spaced repetition logic)
3. Show Word Summary (all 10 words + meanings)
4. Quiz: 30 questions (3 per word, shuffled), presented 3 at a time
5. Save session record to memory
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

## Step 3 — Word Summary

Before any questions, output a summary table:

```
📚 今日复习单词 (10个)

| # | 单词/短语 | 词性 | 中文含义 |
|---|----------|------|---------|
| 1 | resilience | n. | 韧性；恢复力 |
| 2 | take the high road | 短语 | 采取高姿态；走正道 |
...
```

Then say: **准备好了吗？复习开始！** and immediately present the first batch of 3 questions.

---

## Step 4 — Quiz (30 Questions, 3 per Batch)

### Question Generation

Generate **30 questions** — 3 per word (one of each type):

| Type | 中文 | Description |
|------|------|-------------|
| MCQ | 选择题 | 4 options A–D; test meaning or usage in context |
| Fill-blank | 填空题 | Sentence with `___`; answer is the word/phrase |
| Translation | 翻译题 | Chinese sentence → write English using the target word |

### Shuffle Rule

Arrange 30 questions into 10 groups of 3 so that:
- Each group has questions from **3 different words**
- No group has 2+ questions about the same word
- Each group has one of each type (MCQ, Fill-blank, Translation)

Example layout for words W1–W10:
```
Group 1:  W1-MCQ,   W2-Fill,  W3-Trans
Group 2:  W2-MCQ,   W3-Fill,  W4-Trans
Group 3:  W3-MCQ,   W4-Fill,  W5-Trans
...
Group 10: W10-MCQ,  W1-Fill,  W2-Trans
```

### Conducting the Quiz

Present **one group (3 questions) per reply**:

1. Output all 3 questions of the current group at once, numbered `**Question N/30**`, each with its type label (hide answers)
2. Wait for the user to answer all 3
3. For each answer respond:
   - ✅ **正确！** + one-sentence explanation (Chinese ok)
   - ❌ **不对。** 正确答案是 `[X]`。[one-sentence explanation]
   - Translation: accept any grammatically correct sentence using the target word; give a brief comment
4. After giving feedback for all 3, automatically present the next group of 3 questions

**Example — one batch output:**
```
**Question 1/30** [选择题]

She showed great ___ after losing her job, bouncing back within weeks.

A. resilience　B. arrogance　C. lethargy　D. compliance

---

**Question 2/30** [填空题]

He decided to ___ and apologize instead of fighting back.
（提示：意为"采取高姿态"）

---

**Question 3/30** [翻译题]

请用 "devour" 翻译以下句子：
她一口气把那本小说读完了。
```

---

## Step 5 — Complete Session

After Q30 is answered:

### 5a — Update review history

For each of the 10 reviewed words, upsert a row in `memory/vocab_history.md`:

| Review Count (after session) | Next Review Interval |
|------------------------------|----------------------|
| 1 | 3 days |
| 2 | 7 days |
| 3 | 14 days |
| 4 | 30 days |
| ≥ 5 | 60 days |

Update fields: `Review Count += 1`, `Last Review = today`, `Next Review = today + interval`, `Interval = new interval`

### 5b — Append to session log

Append to `memory/vocab_sessions.md` (create if absent):

```markdown
## Session: YYYY-MM-DD HH:MM

**Words reviewed:** word1, word2, word3, word4, word5, word6, word7, word8, word9, word10
**Score:** [correct]/30
**Duration:** ~[N] minutes
```

### 5c — Output summary

```
🎉 复习完成！

📊 本次成绩: [X]/30 ([pct]%)
📝 复习单词: 10 个
⏭️ 下次复习: [date of soonest next review]

[Encouragement line based on score]
```

Score encouragement:
- ≥ 27: 太棒了！记忆力一流，继续保持！
- 20–26: 不错！有几个还需要多练习，加油！
- < 20: 还需努力！这些词会在近期再次出现，多复习几遍就好。

---

## Memory Files Reference

| File | Purpose |
|------|---------|
| `memory/vocab_history.md` | Per-word spaced repetition tracking |
| `memory/vocab_sessions.md` | Session log (date, words, score) |

Both files are relative to the **current working directory** (not the skill directory).

---

## Rules

- Always **read** files before writing to avoid overwriting existing content
- Never show answers before the user responds
- The vocabulary bank path is absolute: `/Users/hushenglang/Development/workspace/2026/claude-skills/vocabulary-anti-forgetting/asset/vocabulary_bank.md`
- For phrases/idioms in the bank (e.g. "take the high road"), treat the full phrase as the vocabulary item
- If a word/phrase has a type hint in the bank (e.g. "devour v"), use it; otherwise infer from context
- Use your knowledge to provide Chinese meanings and generate questions — the bank lists only the English entries
- If `memory/` directory does not exist in cwd, create it before writing
