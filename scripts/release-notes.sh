#!/bin/bash
# Prints the markdown release notes for a tag.
#
#   scripts/release-notes.sh v1.2.3 > notes.md
#
# A hand-written note in docs/release-notes/<tag>.md wins, because a tag's
# commits say what changed but not why it matters to someone updating the app.
# Without one, the notes are grouped from the commits since the previous tag.
set -euo pipefail

TAG="${1:-}"
if [ -z "$TAG" ]; then
    echo "usage: $(basename "$0") <tag>" >&2
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NOTES_FILE="$REPO_ROOT/docs/release-notes/$TAG.md"

# Failing here beats publishing notes for a tag that does not exist.
if ! git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "error: no such tag: $TAG" >&2
    exit 1
fi

# The previous tag anchors the range; the first release has none.
PREVIOUS_TAG="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 "$TAG^" 2>/dev/null || true)"
if [ -n "$PREVIOUS_TAG" ]; then
    RANGE="$PREVIOUS_TAG..$TAG"
else
    RANGE="$TAG"
fi

REMOTE="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
REPO_URL=""
case "$REMOTE" in
    git@github.com:*) REPO_URL="https://github.com/${REMOTE#git@github.com:}" ;;
    https://github.com/*) REPO_URL="$REMOTE" ;;
esac
REPO_URL="${REPO_URL%.git}"

# The compare link is appended to either kind of notes, so a hand-written note
# does not have to carry a URL that goes stale as tags move.
compare_link() {
    if [ -n "$PREVIOUS_TAG" ] && [ -n "$REPO_URL" ]; then
        printf '\n**Full Changelog**: %s/compare/%s...%s\n' "$REPO_URL" "$PREVIOUS_TAG" "$TAG"
    fi
}

if [ -f "$NOTES_FILE" ]; then
    cat "$NOTES_FILE"
    if [ -n "$(tail -c 1 "$NOTES_FILE")" ]; then
        printf '\n'
    fi
    compare_link
    exit 0
fi

# %h and the subject, separated by a byte that cannot appear in either.
COMMITS="$(git -C "$REPO_ROOT" log --no-merges --pretty=format:'%h%x1f%s' "$RANGE" 2>/dev/null || true)"

if [ -z "$COMMITS" ]; then
    echo "No changes recorded for $TAG."
    exit 0
fi

# "feat(hud)!: drop the preview" → "feat"; a subject with no prefix → empty.
commit_type() {
    printf '%s' "$1" | sed -nE 's/^([a-z]+)(\(.*\))?!?:.*/\1/p'
}

# Bullets for the commits whose type matches the pattern (a case pattern, so
# "ci|build" matches either).
collect() {
    local pattern="$1" bullets="" sha subject type
    while IFS=$'\x1f' read -r sha subject; do
        [ -z "$sha" ] && continue
        type="$(commit_type "$subject")"
        [ -z "$type" ] && continue
        case "$type" in
            $pattern) bullets="${bullets}- ${subject} (\`${sha}\`)
" ;;
        esac
    done <<EOF
$COMMITS
EOF
    printf '%s' "$bullets"
}

# Everything the sections above did not claim: "bench:", "revert:", no prefix.
collect_unmatched() {
    local bullets="" sha subject type known
    while IFS=$'\x1f' read -r sha subject; do
        [ -z "$sha" ] && continue
        type="$(commit_type "$subject")"
        known=""
        case "$type" in
            feat|fix|perf|refactor|docs|test|ci|build|chore) known="yes" ;;
        esac
        [ -n "$known" ] && continue
        bullets="${bullets}- ${subject} (\`${sha}\`)
"
    done <<EOF
$COMMITS
EOF
    printf '%s' "$bullets"
}

# A heading and its bullets, or nothing when the section is empty.
section() {
    if [ -z "$2" ]; then
        return
    fi
    printf '### %s\n\n%s\n\n' "$1" "$2"
}

{
    printf "## What's changed\n\n"
    section "Features" "$(collect 'feat')"
    section "Fixes" "$(collect 'fix')"
    section "Performance" "$(collect 'perf')"
    section "Refactoring" "$(collect 'refactor')"
    section "Documentation" "$(collect 'docs')"
    section "Tests" "$(collect 'test')"
    section "Build and CI" "$(collect 'ci|build')"
    section "Chores" "$(collect 'chore')"
    section "Other changes" "$(collect_unmatched)"
} | sed -e '${/^$/d;}'

compare_link
