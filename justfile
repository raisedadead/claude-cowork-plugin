# dotplugins development tasks

set shell := ["bash", "-uc"]

# Default recipe - show help
default:
    @just --list

# Show current versions: just version
version:
    #!/usr/bin/env bash
    set -euo pipefail
    for plugin in sp cowork; do
        CURRENT=$(git tag -l "${plugin}-v*" --sort=-v:refname | head -1 | sed "s/${plugin}-v//")
        if [ -z "$CURRENT" ]; then
            echo "${plugin}: no tags (start with: just release ${plugin} 1.0.0)"
        else
            echo "${plugin}: v${CURRENT}"
        fi
    done

# Release a plugin: just release sp patch|minor|major|1.2.3
release plugin bump:
    #!/usr/bin/env bash
    set -euo pipefail
    PLUGIN="{{plugin}}"
    BUMP="{{bump}}"
    # Resolve current version from tags
    CURRENT=$(git tag -l "${PLUGIN}-v*" --sort=-v:refname | head -1 | sed "s/${PLUGIN}-v//")
    if [ -z "$CURRENT" ]; then CURRENT="0.0.0"; fi
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
    # Calculate next version
    case "$BUMP" in
        patch) VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
        minor) VERSION="${MAJOR}.$((MINOR + 1)).0" ;;
        major) VERSION="$((MAJOR + 1)).0.0" ;;
        *) VERSION="$BUMP" ;;  # explicit version
    esac
    TAG="${PLUGIN}-v${VERSION}"
    echo "${PLUGIN}: v${CURRENT} → v${VERSION}"
    # Find marketplace index for this plugin
    IDX=$(jq --arg name "$PLUGIN" '.plugins | to_entries[] | select(.value.name == $name) | .key' .claude-plugin/marketplace.json)
    # Bump plugin.json
    jq --arg v "$VERSION" '.version = $v' "plugins/${PLUGIN}/.claude-plugin/plugin.json" > tmp.$$.json && mv tmp.$$.json "plugins/${PLUGIN}/.claude-plugin/plugin.json"
    # Bump marketplace.json
    jq --arg v "$VERSION" --argjson i "$IDX" '.plugins[$i].version = $v' .claude-plugin/marketplace.json > tmp.$$.json && mv tmp.$$.json .claude-plugin/marketplace.json
    git add "plugins/${PLUGIN}/.claude-plugin/plugin.json" .claude-plugin/marketplace.json
    git commit -m "chore(${PLUGIN}): release ${VERSION}"
    git tag "$TAG"
    git push origin main "$TAG"
    echo "Pushed $TAG — GitHub Actions will create the release"
