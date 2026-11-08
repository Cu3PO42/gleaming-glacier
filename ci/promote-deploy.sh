#!/usr/bin/env bash
set -euo pipefail

# Refresh refs even when an old successful run is being retried.
git fetch --no-tags origin '+refs/heads/*:refs/remotes/origin/*'
git merge-base --is-ancestor "$GITHUB_SHA" refs/remotes/origin/master

if git show-ref --verify --quiet refs/remotes/origin/deploy; then
  if git merge-base --is-ancestor "$GITHUB_SHA" refs/remotes/origin/deploy; then
    echo 'deploy already contains this commit; leaving it unchanged.'
    exit 0
  fi
  # Fail on divergent history instead of moving the deployment branch sideways.
  git merge-base --is-ancestor refs/remotes/origin/deploy "$GITHUB_SHA"
fi

# A normal push creates the branch or fast-forwards it to the exact tested SHA.
# It also rejects a conflicting update made after the fetch above.
git push origin "$GITHUB_SHA:refs/heads/deploy"
