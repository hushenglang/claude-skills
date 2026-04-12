---
name: vocabulary-anti-forgetting
version: 3.0.0
---

# Vocabulary Anti-Forgetting Skill

Use **spaced repetition** (based on the Ebbinghaus forgetting curve) to help the user memorize English phrases from the vocabulary bank.

## Trigger

Activate this skill when the user says any of: `复习`, `单词复习`, `review vocabulary`, `review words`.

## Files

| File | Purpose |
|---|---|
| `vocabulary-anti-forgetting/asset/vocabulary_bank.md` | Master list of 2087 English phrases with Chinese translations |
| `/root/.openclaw/workspace/gaby-english-coach/memory/review_log.md` | Tracks every word's review history, level, and next review date (stored in OpenClaw memory, outside skill folder to survive upgrades) |
| `vocabulary-anti-forgetting/review.py` | CLI script for non-interactive spaced-repetition review sessions |

## Spaced Repetition Algorithm

Each word has a **level** that determines when it should be reviewed next:

| Level | Interval | Status |
|---|---|---|
| 0 | New word, never reviewed | new |
| 1 | Review again in **1 day** | learning |
| 2 | Review again in **2 days** | learning |
| 3 | Review again in **4 days** | reviewing |
| 4 | Review again in **7 days** | reviewing |
| 5 | Review again in **15 days** | reviewing |
| 6 | Review again in **30 days** | mastered |
| 7 | Review again in **60 days** | mastered |

- **Correct answer** → level + 1, schedule next review per table above.
- **Wrong answer** → reset level to 1, schedule review for tomorrow.

## Daily Review Session Flow (10 words)

When triggered, follow these steps:

### Step 1: Read state

1. Read `/root/.openclaw/workspace/gaby-english-coach/memory/review_log.md`.
2. Read today's date.

### Step 2: Select 10 words

Pick words using this priority:

1. **Due for review**: words where `next_review_date <= today`, sorted by oldest `next_review_date` first (most overdue gets priority).
2. **New words**: if fewer than 10 are due, fill the remaining slots with words from `vocabulary_bank.md` that have NO entry in `review_log.md` yet (pick sequentially by ID).

Aim for a healthy mix — at least 3 new words per session when possible, but always prioritize overdue reviews.

### Step 3: Quiz the user

For each word, present a flashcard in this format:

```
📖 Word [N/10]

**English:** ___________
**Chinese:** 依偎；蜷缩；紧贴着抱

Do you know this word? Try to recall the English phrase, then say "show" or tell me your answer.
```

Alternate direction each session:
- **Odd sessions**: Show Chinese → ask user to recall English.
- **Even sessions**: Show English → ask user to recall Chinese.

Track the session count in `review_log.md` header.

### Step 4: Score and respond

After the user responds to each card:
- If **correct** (or close enough — minor typos are OK): congratulate briefly, mark correct.
- If **wrong** or user says "不会" / "skip": reveal the answer, mark wrong.

### Step 5: Update review_log.md

After all 10 words are done:
1. Update each word's entry in `review_log.md`:
   - Correct → increment level, compute new `next_review_date`.
   - Wrong → reset level to 1, set `next_review_date` to tomorrow.
   - Update `last_reviewed` to today.
   - Increment `review_count`.
2. Update the session counter in the file header.
3. Print a summary:

```
📊 Session Summary
✅ Correct: 7/10
❌ Wrong: 3/10
📅 Next review: 3 words due tomorrow, 2 words due in 2 days

Wrong words (review again tomorrow):
  - snuggle (依偎；蜷缩；紧贴着抱)
  - fleeting (短暂的；转瞬即逝的)
  - ultimatum (最后通牒)
```

## review_log.md Format

The file uses a markdown table with these columns:

```markdown
| id | vocabulary | level | review_count | last_reviewed | next_review_date |
```

- `id`: matches the # column in `vocabulary_bank.md`
- `vocabulary`: the English word/phrase
- `level`: current spaced repetition level (0-7)
- `review_count`: total number of times reviewed
- `last_reviewed`: YYYY-MM-DD of last review
- `next_review_date`: YYYY-MM-DD when this word is next due

The file header also stores:
- `total_sessions`: running count of completed sessions
- `last_session_date`: date of the most recent session

## Important Rules

- NEVER skip the update to `review_log.md` — this is the memory of the system.
- The review log lives at `/root/.openclaw/workspace/gaby-english-coach/memory/review_log.md`, NOT in the skill folder. Create the directory if it doesn't exist.
- If the user only wants a partial session (e.g., 5 words), that's fine — update only those words.
- If the user asks for stats (e.g., "复习统计"), read `review_log.md` and report: total words reviewed, mastered count, learning count, upcoming due words.
- The user can also run `python vocabulary-anti-forgetting/review.py` for a non-interactive session, or `python vocabulary-anti-forgetting/review.py --stats` for stats.
