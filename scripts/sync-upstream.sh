#!/usr/bin/env bash
# Sync this fork with homeassistant-ai/skills, for review before rolling in.
#
# Never merges to main. It parks upstream's changes on a branch and shows you
# what changed, because the whole point of the fork is a set of local patches
# that upstream doesn't have — see FORK.md.
#
#   scripts/sync-upstream.sh            # create/refresh the sync branch, show the diff
#   scripts/sync-upstream.sh --pr       # ...and open a PR against this fork's main
set -euo pipefail

UPSTREAM_URL="https://github.com/homeassistant-ai/skills.git"
BRANCH="sync/upstream"
OPEN_PR=false
[ "${1:-}" = "--pr" ] && OPEN_PR=true

cd "$(git rev-parse --show-toplevel)"

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch -q upstream main
git fetch -q origin main

behind=$(git rev-list --count HEAD..upstream/main)
if [ "$behind" -eq 0 ]; then
  echo "Already up to date with upstream/main — nothing to review."
  exit 0
fi

echo "== $behind new upstream commit(s) =="
git log --oneline --no-decorate HEAD..upstream/main
echo
echo "== files upstream touched =="
git diff --stat HEAD...upstream/main
echo

git checkout -q -B "$BRANCH" main
if git merge --no-edit -q upstream/main 2>/dev/null; then
  echo "Merged cleanly onto $BRANCH."
else
  echo
  echo "!! CONFLICTS — resolve on the $BRANCH branch, then commit:"
  git diff --name-only --diff-filter=U | sed 's/^/   /'
  echo
  echo "   Version fields (.claude-plugin/*.json, SKILL.md metadata.version) conflict by design:"
  echo "   upstream bumps the minor, this fork bumps the patch. Keep the higher of each,"
  echo "   then bump the patch again so /plugin update notices."
  exit 1
fi

echo
echo "== what this would change in YOUR tree =="
git diff --stat main.."$BRANCH"
echo
echo "Review the local patches survived:  git diff main..$BRANCH -- skills/"
echo "Roll in when happy:                 git checkout main && git merge $BRANCH"

if $OPEN_PR; then
  git push -q -u origin "$BRANCH"
  gh pr create --base main --head "$BRANCH" \
    --title "Sync with upstream ($behind commit(s))" \
    --body "$(printf 'Upstream commits:\n\n%s\n\nCheck the local patches in FORK.md survived the merge before merging.' "$(git log --oneline --no-decorate main..upstream/main)")" \
    || echo "PR already open."
fi
