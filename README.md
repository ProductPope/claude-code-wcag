# wcag-for-claude-code

A lightweight [Claude Code](https://claude.ai/code) hook that enforces **WCAG 2.2** accessibility standards on every UI-related prompt — automatically, with zero config.

## How it works

A `UserPromptSubmit` hook intercepts each prompt and:

1. Detects UI context from prompt content and project files
2. Selects the relevant WCAG 2.2 rule subset
3. Injects it as `additionalContext` before Claude responds
4. Exits silently if no UI context is detected (no token cost)

### Detected contexts and injected rules

| Context | Detection signals | Rules injected |
|---|---|---|
| `react` | `.jsx`, `.tsx`, JSX syntax, `package.json` deps | Semantic elements, ARIA props, keyboard event parity, focus management |
| `html` | `.html`, `<!DOCTYPE`, `<html` | `lang` attr, heading hierarchy, landmarks, label association, alt text |
| `css` | `.css`, `.scss`, `.less`, `@media`, `color:` | Contrast ratios, `:focus-visible`, `prefers-reduced-motion`, target size |
| `js` | `.js`, `.ts`, `addEventListener`, `querySelector` | Keyboard traps, focus restoration, `aria-live`, `tabindex` |

WCAG 2.2-specific criteria (2.4.11, 2.5.7, 2.5.8, 3.3.7, 3.3.8) are appended whenever any UI context is detected.

## Requirements

- Claude Code CLI
- `jq` **or** `python3` (for install/uninstall only)
- bash 3.2+

## Installation

```bash
git clone https://github.com/ProductPope/claude-code-wcag.git
cd claude-code-wcag
bash install.sh
```

Restart Claude Code. The hook is now active for all projects.

## Disabling

**Per-project** — create a file in your project root:
```bash
touch .wcag-disabled
```

**Per-session** — set an environment variable before launching Claude Code:
```bash
export WCAG_DISABLED=1
```

## Uninstallation

```bash
bash uninstall.sh
```

## File structure

```
wcag-for-claude-code/
├── hooks/
│   └── wcag.sh       # Hook script (the only runtime dependency)
├── install.sh         # Registers hook in ~/.claude/settings.json
├── uninstall.sh       # Removes hook from ~/.claude/settings.json
└── README.md
```

## Token cost

~150–250 tokens per prompt when UI context is detected. Zero tokens otherwise.

---

## Why a hook, not an agent

This is a deliberate architectural choice. Understanding it matters if you care about accessibility done right.

### The agent model and its flaw

An accessibility agent operates in a review loop:

```
Claude generates code → agent audits output → agent suggests fixes → developer applies fixes
```

This is **remediation**. The code is born inaccessible and corrected afterward. In WCAG terms, it is the digital equivalent of building a staircase and then adding a ramp — technically compliant, but structurally compromised.

Remediation has a compounding cost: the later in the process an accessibility issue is found, the more expensive it is to fix. An agent that runs after code generation is still late.

### The hook model: constraint at the point of generation

A `UserPromptSubmit` hook injects accessibility requirements *before* the model sees your prompt. The model does not generate inaccessible code and then fix it. It generates accessible code because accessibility is part of the specification it is responding to.

```
Hook injects WCAG context → Claude generates code → output is accessible by construction
```

This is **prevention**. The shift is not cosmetic — it changes the generative prior. The model treats WCAG criteria as design constraints, not as a checklist to satisfy after the fact.

This mirrors how the best accessibility practitioners work: not as auditors who review finished products, but as contributors who shape decisions upstream — in design reviews, in component APIs, in the definition of done.

### Precision over noise

The hook injects only rules relevant to the detected technology stack. A prompt about a CSS animation receives contrast and motion rules. A prompt about a React modal receives focus management and ARIA rules. A prompt about a Python script receives nothing.

This matters for two reasons:

1. **Signal quality.** A model given 40 WCAG success criteria when writing a database migration will treat accessibility as background noise. A model given 4 targeted criteria when writing a dialog component will treat them as foreground constraints.

2. **Respect for the standard.** WCAG 2.2 is a precise, technology-aware specification. Applying it indiscriminately collapses that precision. Contextual injection preserves the intent of the standard.

### No second agent, no second API call

An accessibility agent requires an additional inference: the audit model reads the generated output and produces a review. This doubles latency and cost per interaction, and introduces a second model that may disagree with, misread, or simply rubber-stamp the first.

The hook has no runtime cost beyond the tokens it injects. There is no audit pass, no second model, no reconciliation step.

### Accessibility as a first-class constraint

The deeper point is philosophical. WCAG exists because accessibility is not a feature — it is a quality of the underlying design. A `button` that can only be activated with a mouse is not an accessible button with a missing feature. It is a broken button.

An agent that audits for accessibility treats it as a feature to be checked. A hook that constrains generation treats it as a property that must be true. The architecture encodes the correct model of what accessibility is.

This is what "shift left" means when applied rigorously: not moving the audit earlier in the pipeline, but eliminating the audit by making the constraint structural.

---

## License

MIT
