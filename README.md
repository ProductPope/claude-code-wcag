# wcag-for-claude-code

A Claude Code hook that makes accessibility structural — not remedial.

WCAG 2.2 rules are injected before Claude sees your prompt. The model generates accessible code because accessibility is part of the specification it responds to, not a checklist it reviews afterward.

Zero config. Zero runtime dependencies. Zero tokens when no UI context is detected.

---

## How it works

A `UserPromptSubmit` hook intercepts each prompt and:

1. Detects UI context from prompt content and project files
2. Selects the relevant WCAG 2.2 rule subset
3. Injects it as `additionalContext` before Claude responds
4. Exits silently if no UI context is detected

## Detected contexts

| Context | Detection signals | Rules injected |
|---|---|---|
| react | `.jsx`, `.tsx`, JSX syntax, `package.json` deps | Semantic elements, ARIA props, keyboard event parity, focus management |
| html | `.html`, `<!DOCTYPE`, `<html` | `lang` attr, heading hierarchy, landmarks, label association, alt text |
| css | `.css`, `.scss`, `.less`, `@media`, `color:` | Contrast ratios, `:focus-visible`, `prefers-reduced-motion`, target size |
| js | `.js`, `.ts`, `addEventListener`, `querySelector` | Keyboard traps, focus restoration, `aria-live`, `tabindex` |

WCAG 2.2-specific criteria (2.4.11, 2.5.7, 2.5.8, 3.3.7, 3.3.8) are appended whenever any UI context is detected.

Token cost: ~150–250 tokens per UI prompt. Zero otherwise.

---

## Requirements

- Claude Code CLI
- `jq` or `python3` (install/uninstall only)
- bash 3.2+

## Installation

```bash
git clone https://github.com/ProductPope/claude-code-wcag.git
cd claude-code-wcag
bash install.sh
```

Restart Claude Code. The hook is active for all projects.

## Disabling

Per-project:
```bash
touch .wcag-disabled
```

Per-session:
```bash
export WCAG_DISABLED=1
```

## Uninstallation

```bash
bash uninstall.sh
```

---

## Constitution

This repository includes a `CLAUDE.md` file that defines how Claude Code operates during development.
It covers component architecture, accessibility constraints, iteration protocol, and code quality defaults.

If you fork this repo, treat `CLAUDE.md` as a starting point — not a final answer.
Extend it as your project evolves.

---

## Why prevention beats remediation

The standard AI accessibility workflow looks like this:

> Claude generates code → agent audits output → agent suggests fixes → developer applies fixes

This is remediation. The code is born inaccessible. The agent is a ramp bolted onto a staircase.

This hook works differently:

> Hook injects WCAG context → Claude generates code → output is accessible by construction

Accessibility becomes a constraint at the point of generation, not a quality gate after it. The model doesn't produce inaccessible code and then fix it — it never produces inaccessible code in the first place.

This is what "shift left" actually means: not moving the audit earlier, but eliminating the audit by making the constraint structural.

## Why targeted injection matters

The hook doesn't dump all 78 WCAG 2.2 success criteria into every prompt. It injects only what's relevant to the detected stack.

A prompt about a CSS animation gets contrast and motion rules. A prompt about a React modal gets focus management and ARIA rules. A prompt about a Python script gets nothing.

This matters because signal quality degrades with noise. A model given 40 accessibility criteria for a database migration will treat them as background. A model given 4 targeted criteria for a dialog component will treat them as foreground constraints.

## Lessons learned: where AI cuts corners

These are patterns observed during development — moments where Claude Code tried to take shortcuts and the hook caught them.

**`div` as a button.** Claude will reach for `<div onClick={...}>` when generating quick interactive elements. The hook's semantic HTML rules surface this immediately. A `div` has no implicit role, no keyboard access, no focus management. It is not a button.

**ARIA overreach.** When asked to "make this accessible," Claude sometimes adds `aria-label` to elements that already have visible text labels, or applies `role="button"` to interactive elements instead of using `<button>`. The First Rule of ARIA exists for a reason: don't use ARIA if a native HTML element does the job.

**Missing focus restoration.** Claude generates modals that trap focus correctly on open but don't return focus to the trigger element on close. The hook's focus management rules flag this as a requirement, not an afterthought.

**Placeholder as label.** Form fields with `placeholder` as the only label text. The placeholder disappears when the user starts typing. It is not a label. The hook injects label association rules for every HTML context.

---

## File structure

```
wcag-for-claude-code/
├── hooks/
│   └── wcag.sh       # Hook script (only runtime file)
├── install.sh         # Registers hook in ~/.claude/settings.json
├── uninstall.sh       # Removes hook from ~/.claude/settings.json
└── README.md
```
