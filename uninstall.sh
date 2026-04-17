#!/usr/bin/env bash
# uninstall.sh — removes the WCAG 2.2 hook from ~/.claude/settings.json
#
# Requirements: jq OR python3

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"

# ── Guard: nothing to remove ──────────────────────────────────────────────────
if [[ ! -f "$SETTINGS" ]] || ! grep -q "wcag.sh" "$SETTINGS" 2>/dev/null; then
    echo "WCAG hook not found in $SETTINGS. Nothing to uninstall."
    exit 0
fi

# ── Remove hook entry ─────────────────────────────────────────────────────────
if command -v jq &>/dev/null; then
    tmp=$(mktemp)
    jq '
        .hooks.UserPromptSubmit //= [] |
        .hooks.UserPromptSubmit |= map(
            select(.hooks | map(.command) | any(test("wcag\\.sh")) | not)
        )
    ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

elif command -v python3 &>/dev/null; then
    python3 - "$SETTINGS" <<'EOF'
import sys, json

settings_file = sys.argv[1]

with open(settings_file) as f:
    cfg = json.load(f)

hooks = cfg.get("hooks", {}).get("UserPromptSubmit", [])
cfg["hooks"]["UserPromptSubmit"] = [
    h for h in hooks
    if not any("wcag.sh" in c.get("command", "") for c in h.get("hooks", []))
]

with open(settings_file, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
EOF

else
    echo "Error: jq or python3 is required for uninstallation." >&2
    exit 1
fi

echo "WCAG hook removed. Restart Claude Code to deactivate."
