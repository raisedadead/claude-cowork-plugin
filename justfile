# dotplugins development tasks

set shell := ["bash", "-uc"]

# Default recipe - show help
default:
    @just --list

# === Info ===

# Show current plugin versions
version:
    #!/usr/bin/env bash
    set -euo pipefail
    for plugin in plugins/*/; do
        name=$(basename "$plugin")
        tag=$(git tag -l "${name}-v*" --sort=-v:refname | head -1)
        if [ -n "$tag" ]; then
            echo "${name}: ${tag#${name}-}"
        else
            echo "${name}: unreleased"
        fi
    done

# Show release status (tags vs plugin.json)
status:
    #!/usr/bin/env bash
    set -euo pipefail
    for plugin in plugins/*/; do
        name=$(basename "$plugin")
        tag=$(git tag -l "${name}-v*" --sort=-v:refname | head -1)
        tag_ver="${tag#${name}-v}"
        json_ver=$(jq -r '.version' "plugins/${name}/.claude-plugin/plugin.json" 2>/dev/null || echo "n/a")
        if [ "$tag_ver" = "$json_ver" ]; then
            echo "${name}: v${json_ver} (in sync)"
        else
            echo "${name}: tag=${tag_ver:-none} json=${json_ver} (MISMATCH)"
        fi
    done

# === Release ===

# Release a plugin: just release sp patch|minor|major|1.2.3
release plugin bump:
    #!/usr/bin/env bash
    set -euo pipefail
    PLUGIN="{{plugin}}"
    BUMP="{{bump}}"
    if [ ! -d "plugins/${PLUGIN}/.claude-plugin" ]; then
        echo "Error: unknown plugin '${PLUGIN}'" >&2; exit 1
    fi
    # Resolve current version from tags
    CURRENT=$(git tag -l "${PLUGIN}-v*" --sort=-v:refname | head -1 | sed "s/${PLUGIN}-v//")
    if [ -z "$CURRENT" ]; then CURRENT="0.0.0"; fi
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
    case "$BUMP" in
        patch) VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
        minor) VERSION="${MAJOR}.$((MINOR + 1)).0" ;;
        major) VERSION="$((MAJOR + 1)).0.0" ;;
        *) VERSION="$BUMP" ;;
    esac
    TAG="${PLUGIN}-v${VERSION}"
    echo "${PLUGIN}: v${CURRENT} → v${VERSION}"
    read -rp "Proceed? [y/N] " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
    # Bump plugin.json
    TMP=$(mktemp)
    jq --arg v "$VERSION" '.version = $v' "plugins/${PLUGIN}/.claude-plugin/plugin.json" > "$TMP" \
        && mv "$TMP" "plugins/${PLUGIN}/.claude-plugin/plugin.json"
    # Bump marketplace.json
    IDX=$(jq --arg name "$PLUGIN" '.plugins | to_entries[] | select(.value.name == $name) | .key' .claude-plugin/marketplace.json)
    TMP=$(mktemp)
    jq --arg v "$VERSION" --argjson i "$IDX" '.plugins[$i].version = $v' .claude-plugin/marketplace.json > "$TMP" \
        && mv "$TMP" .claude-plugin/marketplace.json
    git add "plugins/${PLUGIN}/.claude-plugin/plugin.json" .claude-plugin/marketplace.json
    git commit -m "chore(${PLUGIN}): release ${VERSION}"
    git tag "$TAG"
    git push origin main "$TAG"
    echo "Pushed $TAG — GitHub Actions will create the release"
