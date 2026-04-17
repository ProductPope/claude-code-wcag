#!/usr/bin/env bash
# WCAG 2.2 context-aware hook for Claude Code (UserPromptSubmit)
#
# Detects UI context from the incoming prompt and injects targeted
# WCAG 2.2 accessibility rules. Exits silently for non-UI prompts.
#
# Disable per-session:  export WCAG_DISABLED=1
# Disable per-project:  touch .wcag-disabled

set -euo pipefail

# ── Disable guards ─────────────────────────────────────────────────────────────
[[ "${WCAG_DISABLED:-0}" == "1" ]] && exit 0
[[ -f ".wcag-disabled" ]]          && exit 0

# ── Read prompt payload ────────────────────────────────────────────────────────
readonly PROMPT=$(cat)

# ── Helpers ───────────────────────────────────────────────────────────────────
prompt_has() { printf '%s' "$PROMPT" | grep -qiE "$1"; }

# ── Context detection ──────────────────────────────────────────────────────────
ctx_react=0; ctx_html=0; ctx_css=0; ctx_js=0

# From prompt content
prompt_has '\.(jsx|tsx)|<[A-Z][a-zA-Z]+[\s/>]|\breact\b'                && ctx_react=1
prompt_has '\.(html?)|<!doctype\s+html|<html[\s>]'                      && ctx_html=1
prompt_has '\.(s?css|less|sass)|@media|color\s*:|background(-color)?\s*:' && ctx_css=1
prompt_has '\.(m?[jt]sx?)|addEventListener|querySelector|document\.'    && ctx_js=1

# From project files (fast, targeted checks only)
if [[ -f package.json ]]; then
    grep -qiE '"(react|next|gatsby|remix)"' package.json 2>/dev/null && ctx_react=1
fi

# ── Bail out when no UI context detected ───────────────────────────────────────
(( ctx_react + ctx_html + ctx_css + ctx_js == 0 )) && exit 0

# ── Rule sets ─────────────────────────────────────────────────────────────────
# Each rule set is a compact, actionable summary of WCAG 2.2 criteria
# relevant to the detected technology.

RULE_REACT="React: semantic elements over div/span, ARIA props (aria-label/aria-describedby), onKeyDown parity with onClick, useRef for focus management, never aria-hidden on focusable elements."
RULE_HTML="HTML: lang attribute on <html>, single h1, landmark regions (main/nav/aside/footer), explicit label-input association, alt text on images (empty alt for decorative), skip-nav link."
RULE_CSS="CSS: contrast >=4.5:1 normal text / >=3:1 large text, :focus-visible never removed, prefers-reduced-motion respected, target size >=24x24px (WCAG 2.2 SC 2.5.8), never convey meaning by color alone."
RULE_JS="JS: no keyboard traps, restore focus after modal/overlay close, aria-live regions for dynamic content updates, no tabindex > 0."
RULE_WCAG22="WCAG 2.2 new criteria: focus not obscured (2.4.11/12), dragging movement alternatives (2.5.7), no cognitive test in authentication (3.3.7/3.3.8)."

# ── Build output ───────────────────────────────────────────────────────────────
labels=""; rules=""

append_ctx() {
    local label="$1" rule="$2"
    labels="${labels:+$labels,}${label}"
    rules="${rules} ${rule}"
}

(( ctx_react )) && append_ctx "react" "$RULE_REACT"
(( ctx_html ))  && append_ctx "html"  "$RULE_HTML"
(( ctx_css ))   && append_ctx "css"   "$RULE_CSS"
(( ctx_js ))    && append_ctx "js"    "$RULE_JS"

rules="${rules} ${RULE_WCAG22}"
rules="${rules# }"

printf '{"additionalContext":"[WCAG 2.2|%s] %s"}\n' "$labels" "$rules"
