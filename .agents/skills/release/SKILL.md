---
name: release
description: Release InputSwitch to GitHub by pushing a vX.Y.Z tag, which triggers the CI DMG build (.github/workflows/release.yml). Use when the user asks to release, publish, or 打包/发布 to GitHub.
argument-hint: "[version, e.g. 0.0.3]"
---

Releasing = pushing a `vX.Y.Z` tag to `origin`. CI ([.github/workflows/release.yml](../../../.github/workflows/release.yml)) builds the universal DMG with `MARKETING_VERSION` taken from the tag and publishes the GitHub Release, using `scripts/release-notes.sh` for the body. No local build is needed.

Requested version: $ARGUMENTS

## 1. Check the tree

- `git status --porcelain` must be empty. Uncommitted work is not part of the tag, so if it is dirty, show the user what is uncommitted and ask whether to commit it first or release HEAD as-is.
- `git fetch origin --tags`. If the current branch is ahead of its upstream, `git push` it so the tagged commit is on GitHub's branch too.

Done when: the tree is clean (or the user chose to release HEAD as-is) and HEAD is on `origin`.

## 2. Pick the tag

- Normalise the requested version to `vX.Y.Z` (add the `v`; reject anything else).
- No version requested → take the highest existing tag (`git tag -l 'v*' --sort=-v:refname | head -1`) and bump the patch. State the chosen tag in your reply.
- Check whether it exists: `git ls-remote --tags origin "refs/tags/$TAG"` and `gh release view "$TAG"`.
- Exists → ask with AskUserQuestion, naming both the existing tag and the next free patch version:
  - **Bump** (recommended): increment the patch until neither tag nor release exists.
  - **Overwrite**: replace the old release with HEAD (step 4).

Done when: `$TAG` is chosen, and either it is free or the user chose Overwrite.

## 3. Write the release notes

CI publishes whatever `scripts/release-notes.sh <tag>` prints: `docs/release-notes/<tag>.md` when it exists, otherwise a changelog assembled from the commits since the previous tag. That fallback reads like a commit dump, so write the file.

- See what changed: `git log --no-merges --pretty='%h %s' <previous-tag>..HEAD`, and open the diff when a subject does not say what a user would notice.
- Write `docs/release-notes/<tag>.md` for people updating the app, not for people reading the diff. Lead with what they can now do or what stopped breaking; leave out refactors, tests, bench runs and CI noise. Group under `## New`, `## Fixed`, `## Changed` once there is more than a couple of entries.
- `./scripts/release-notes.sh <tag>` must print that file, not the fallback.
- Commit it. The file has to be inside the tagged commit: CI checks out the tag, so notes committed afterwards are invisible to it.

Done when `docs/release-notes/<tag>.md` is committed on the commit that will be tagged, and the script prints it.

## 4. Overwrite only: remove the old version

```bash
gh release delete "$TAG" --yes --cleanup-tag 2>/dev/null || git push origin ":refs/tags/$TAG"
git tag -d "$TAG" 2>/dev/null || true
```

Done when: `git ls-remote --tags origin "refs/tags/$TAG"` prints nothing.

## 5. Tag and push

```bash
git tag -a "$TAG" -m "InputSwitch $TAG"
git push origin "$TAG"
```

The annotated message is not the release body — it never reaches the Release page. Only `docs/release-notes/<tag>.md` does.

## 6. Follow CI

- Find the run: `gh run list --workflow release.yml --limit 1 --json databaseId,headBranch,status` (its `headBranch` is the tag; it can take a few seconds to appear).
- `gh run watch <id> --exit-status` in the background, then report the result.
- Success → print `gh release view "$TAG" --json url -q .url` and check the body is the written note rather than the fallback (`gh release view "$TAG" --json body -q .body`).
- Failure → show `gh run view <id> --log-failed | tail -50` and diagnose. After a fix is committed, re-release the same tag via the Overwrite path; it replaces the body as well as the assets.
