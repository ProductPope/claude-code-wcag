#!/usr/bin/env bash
# install.sh — registers the WCAG 2.2 hook in ~/.claude/settings.json
#
# Requirements: jq OR python3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/hooks/wcag.sh"
SETTINGS_DIR="$HOME/.claude"
SETTINGS="$SETTINGS_DIR/settings.json"

# ── Validate hook script ───────────────────────────────────────────────────────
if [[ ! -f "$HOOK_SCRIPT" ]]; then
    echo "Error: hooks/wcag.sh not found. Run install.sh from the repo root." >&2
    exit 1
fi

chmod +x "$HOOK_SCRIPT"

# ── Ensure settings.json exists ───────────────────────────────────────────────
mkdir -p "$SETTINGS_DIR"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# ── Guard: already installed ───────────────────────────────────────────────────
if grep -q "wcag.sh" "$SETTINGS" 2>/dev/null; then
    echo "WCAG hook already installed in $SETTINGS"
    exit 0
fi

# ── Detect JSON tool ──────────────────────────────────────────────────────────
json_merge() {
    local file="$1" hook_cmd="$2"

    if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg cmd "$hook_cmd" '
            .hooks.UserPromptSubmit //= [] |
            .hooks.UserPromptSubmit += [{
                "matcher": "",
                "hooks": [{"type": "command", "command": $cmd}]
            }]
        ' "$file" > "$tmp" && mv "$tmp" "$file"
        return
    fi

    if command -v python3 &>/dev/null; then
        python3 - "$file" "$hook_cmd" <<'EOF'
import sys, json

settings_file, hook_cmd = sys.argv[1], sys.argv[2]

with open(settings_file) as f:
    cfg = json.load(f)

entry = {"matcher": "", "hooks": [{"type": "command", "command": hook_cmd}]}
cfg.setdefault("hooks", {}).setdefault("UserPromptSubmit", []).append(entry)

with open(settings_file, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
EOF
        return
    fi

    echo "Error: jq or python3 is required for installation." >&2
    exit 1
}

# ── Install ───────────────────────────────────────────────────────────────────
json_merge "$SETTINGS" "bash \"$HOOK_SCRIPT\""

echo "WCAG 2.2 hook installed."
echo ""
echo "Restart Claude Code to activate."
echo ""
echo "Disable per-project : touch .wcag-disabled"
echo "Disable per-session : export WCAG_DISABLED=1"
