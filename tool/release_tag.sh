#!/usr/bin/env bash
# Prints the tag a CI build publishes under, or nothing when it publishes none.
# A beta is one patch ahead of pubspec.yaml once that version is out, so it sorts above it.
# main publishes the stable release once a chore(release) commit lands there, since cloud sessions cannot push tags.
set -euo pipefail

ref="${GITHUB_REF:?}"
beta_branch="${BETA_BRANCH:-beta}"

case "$ref" in
  refs/tags/v*)
    echo "${ref#refs/tags/}"
    ;;
  refs/heads/main)
    version="$(sed -n 's/^version: *\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' pubspec.yaml)"
    if [[ -n "$version" ]] && grep -qF "\"tag\": \"v$version\"" changelog.json &&
      ! git ls-remote --exit-code --tags origin "refs/tags/v$version" >/dev/null; then
      echo "v$version"
    fi
    ;;
  "refs/heads/$beta_branch")
    version="$(sed -n 's/^version: *\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' pubspec.yaml)"
    if [[ -z "$version" ]]; then
      echo 'No version in pubspec.yaml' >&2
      exit 1
    fi
    if git ls-remote --exit-code --tags origin "refs/tags/v$version" >/dev/null; then
      IFS='.' read -r major minor patch <<<"$version"
      version="$major.$minor.$((patch + 1))"
    fi
    echo "v$version-beta.${GITHUB_RUN_NUMBER:?}"
    ;;
esac
