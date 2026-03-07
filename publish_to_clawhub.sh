#!/usr/bin/env bash
# Publish a single skill (or all skills) from this repo to ClawHub.
#
# Usage:
#   ./publish_to_clawhub.sh <skill-folder> [options]   # publish one skill
#   ./publish_to_clawhub.sh [options]                  # publish all skills (sync)
#
# Options:
#   --bump patch|minor|major   Version bump for sync-all mode  (default: patch)
#   --changelog <text>         Changelog for this release
#   --tags <t1,t2>             Comma-separated tags             (default: latest)
#   --dry-run                  Preview without uploading
#   --all                      Non-interactive, no prompts
#   -h, --help                 Show this help

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[clawhub]${NC} $*"; }
warn()  { echo -e "${YELLOW}[clawhub]${NC} $*"; }
err()   { echo -e "${RED}[clawhub] ERROR:${NC} $*" >&2; }
step()  { echo -e "${CYAN}[clawhub]${NC} $*"; }
die()   { err "$*"; exit 1; }

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <skill-folder> [options]   Publish a single skill
  $(basename "$0") [options]                  Publish all skills (sync)

Arguments:
  skill-folder   Path to the skill directory containing SKILL.md
                 Can be a name (e.g. extract-youtube-transcript) or full path

Options:
  --bump patch|minor|major   Version bump type for sync-all mode (default: patch)
  --changelog <text>         Changelog text for this release
  --tags <t1,t2>             Comma-separated tags (default: latest)
  --dry-run                  Preview what would be published, without uploading
  --all                      Publish all without interactive prompts
  -h, --help                 Show this help

Examples:
  ./publish_to_clawhub.sh extract-youtube-transcript
  ./publish_to_clawhub.sh perplexity-research --bump minor --changelog "new models"
  ./publish_to_clawhub.sh --dry-run
  ./publish_to_clawhub.sh --all --bump patch
EOF
}

# ── prerequisites ──────────────────────────────────────────────────────────────
check_clawhub() {
  if ! command -v clawhub &>/dev/null; then
    die "clawhub CLI not found. Install it with: npm install -g clawhub"
  fi
  local version
  version=$(clawhub --cli-version 2>/dev/null || clawhub -V 2>/dev/null || echo "unknown")
  info "clawhub CLI: $version"
}

check_auth() {
  if ! clawhub whoami &>/dev/null; then
    warn "Not authenticated."
    if [[ $NON_INTERACTIVE -eq 1 ]]; then
      die "Authentication required. Run 'clawhub login' first, or set CLAWHUB_TOKEN."
    fi
    echo -n "  → Would you like to login now? [y/N] "
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]] || die "Aborted – run 'clawhub login' and retry."
    clawhub login
  fi
  info "Logged in as: $(clawhub whoami 2>/dev/null)"
}

# ── resolve skill directory ────────────────────────────────────────────────────
resolve_skill_dir() {
  local input="$1"
  local resolved

  # Accept a bare name (e.g. "extract-youtube-transcript") or a path
  if [[ -d "$input" ]]; then
    resolved="$(cd "$input" && pwd)"
  elif [[ -d "$REPO_ROOT/$input" ]]; then
    resolved="$REPO_ROOT/$input"
  else
    die "Skill folder not found: '$input'\n  Looked at: $input and $REPO_ROOT/$input"
  fi

  [[ -f "$resolved/SKILL.md" ]] || die "No SKILL.md in '$resolved'. Is this a valid skill folder?"
  echo "$resolved"
}

# ── list all skill dirs in repo ────────────────────────────────────────────────
list_all_skills() {
  local skills=()
  while IFS= read -r skill_md; do
    skills+=("$(dirname "$skill_md")")
  done < <(find "$REPO_ROOT" -maxdepth 2 -name "SKILL.md" ! -path "*/.claude/*")

  if [[ ${#skills[@]} -eq 0 ]]; then
    die "No SKILL.md files found under $REPO_ROOT"
  fi

  info "Found ${#skills[@]} skill(s):"
  for s in "${skills[@]}"; do
    echo "    • $(basename "$s")  →  $s"
  done
}

# ── read version from SKILL.md frontmatter ────────────────────────────────────
read_skill_version() {
  local skill_dir="$1"
  local version
  version=$(awk '/^---/{f=!f; next} f && /^version:/{print $2; exit}' "$skill_dir/SKILL.md")
  if [[ -z "$version" ]]; then
    die "No 'version:' field found in $skill_dir/SKILL.md\n  Add a line like:  version: 1.0.0"
  fi
  echo "$version"
}

# ── publish one skill ──────────────────────────────────────────────────────────
publish_single() {
  local skill_dir="$1"
  local skill_name version
  skill_name="$(basename "$skill_dir")"
  version="$(read_skill_version "$skill_dir")"

  step "Publishing skill: $skill_name @ $version"
  step "  Path: $skill_dir"

  local args=("$skill_dir" --version "$version" --tags "$TAGS")
  [[ -n "$CHANGELOG" ]] && args+=(--changelog "$CHANGELOG")

  if [[ $DRY_RUN -eq 1 ]]; then
    warn "DRY RUN – would run: clawhub publish ${args[*]}"
    return
  fi

  clawhub publish "${args[@]}"
  info "Published: $skill_name@$version  →  https://clawhub.ai/skills/$skill_name"
}

# ── publish all skills via sync ────────────────────────────────────────────────
publish_all() {
  local args=(--workdir "$REPO_ROOT" --dir "." --bump "$BUMP" --tags "$TAGS")
  [[ -n "$CHANGELOG" ]]    && args+=(--changelog "$CHANGELOG")
  [[ $DRY_RUN -eq 1 ]]     && args+=(--dry-run)
  [[ $NON_INTERACTIVE -eq 1 ]] && args+=(--all)

  step "Running: clawhub sync ${args[*]}"
  echo ""
  clawhub sync "${args[@]}"
}

# ── argument parsing ───────────────────────────────────────────────────────────
SKILL_DIR=""
BUMP="patch"
CHANGELOG=""
TAGS="latest"
DRY_RUN=0
NON_INTERACTIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump)       BUMP="$2";       shift 2 ;;
    --changelog)  CHANGELOG="$2";  shift 2 ;;
    --tags)       TAGS="$2";       shift 2 ;;
    --dry-run)    DRY_RUN=1;       shift   ;;
    --all)        NON_INTERACTIVE=1; shift ;;
    --no-input)   NON_INTERACTIVE=1; shift ;;
    -h|--help)    usage; exit 0            ;;
    -*)           die "Unknown option: $1. Use --help for usage." ;;
    *)
      [[ -z "$SKILL_DIR" ]] || die "Unexpected argument: $1"
      SKILL_DIR="$1"
      shift ;;
  esac
done

# ── main ───────────────────────────────────────────────────────────────────────
main() {
  info "Repository: $REPO_ROOT"
  check_clawhub
  check_auth
  echo ""

  if [[ -n "$SKILL_DIR" ]]; then
    # Single-skill mode
    local resolved
    resolved="$(resolve_skill_dir "$SKILL_DIR")"
    [[ $DRY_RUN -eq 1 ]] && warn "DRY RUN – no changes will be uploaded"
    publish_single "$resolved"
  else
    # All-skills mode (sync)
    list_all_skills
    echo ""
    [[ $DRY_RUN -eq 1 ]] && warn "DRY RUN – no changes will be uploaded"
    publish_all
  fi

  echo ""
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry run complete. Remove --dry-run to publish for real."
  else
    info "Done. View your skills at: https://clawhub.ai"
  fi
}

main "$@"
