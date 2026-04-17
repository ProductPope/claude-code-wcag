# CLAUDE.md — Constitution for AI-Assisted Development

This file defines how Claude Code operates in this repository.
It is not a style guide. It is a set of constraints that shape every decision made during code generation.

When in doubt: do less, verify more, ask once.

---

## 1. Design System & Component Architecture

This is the foundation. Everything else builds on it.

**Before creating anything, check what exists.**
- Reuse before you build. Extend before you rewrite.
- If a component exists that is 80% of what you need, extend it. Do not create a parallel version.
- If a pattern exists in the codebase, follow it. Do not introduce a second pattern that does the same thing.

**Atomic design is the default mental model.**
- Atoms: single-purpose, no dependencies on other components
- Molecules: composed of atoms, still reusable in multiple contexts
- Organisms: composed of molecules, tied to a specific context
- When unsure which level a component belongs to, default to smaller

**Tokens and variables first. Hardcoded values never.**
- Colors, spacing, typography, shadows — always via design tokens or CSS variables
- A hardcoded `#1a73e8` or `padding: 12px` is a bug, not a shortcut
- If a token doesn't exist for what you need, flag it before proceeding

**Component API discipline.**
- Props should be explicit and minimal
- Avoid prop drilling beyond two levels — lift state or use context
- A component that does three unrelated things is three components

---

## 2. Accessibility (WCAG 2.2)

Accessibility is a property of the design, not a feature added afterward.
A button that only works with a mouse is not an accessible button with a missing feature. It is a broken button.

**Semantic HTML is non-negotiable.**
- Use the element that matches the meaning: `<button>` for actions, `<a>` for navigation, `<input>` for input
- Never use `<div>` or `<span>` for interactive elements
- The First Rule of ARIA: do not use ARIA if a native HTML element does the job

**Every interactive element must be keyboard accessible.**
- Focusable via Tab
- Activatable via Enter or Space
- Visible focus state via `:focus-visible` (never `outline: none` without a replacement)

**Focus management is part of the component, not an afterthought.**
- Modals trap focus on open, restore focus to trigger on close
- Dynamic content updates are announced via `aria-live` where appropriate
- `tabindex` values above 0 are forbidden

**Forms.**
- Every input has a `<label>` — not a placeholder, not an `aria-label` on a visible field
- Error messages are associated with their field via `aria-describedby`
- Required fields are marked with `aria-required`

**WCAG 2.2 criteria always applied.**
- 2.4.11: Focus not obscured
- 2.5.7: Dragging movements have a single-pointer alternative
- 2.5.8: Target size minimum 24x24px
- 3.3.7: Redundant entry is avoided
- 3.3.8: Accessible authentication

---

## 3. Iteration Protocol

**Define done before you start.**
Before writing any code, state explicitly:
- What this change does
- What it does not do
- How you will verify it is complete

**One problem per prompt.**
- Do not combine a refactor with a feature addition
- Do not combine a bug fix with a style change
- If a prompt contains "and also" — split it

**Checkpoint before every significant change.**
Significant means: touches more than one file, changes a shared component, modifies configuration, or cannot be easily undone.
State what you are about to do and wait for confirmation before proceeding.

**Small, verifiable steps over large, confident ones.**
A change that can be reviewed in 30 seconds is better than a change that requires 5 minutes of reading. Prefer multiple small commits over one large one.

---

## 4. Hallucination Minimization

**Verify before implementing, not after.**
- If you are unsure whether a library supports a feature, say so before writing code that depends on it
- If you are unsure about an API signature, check before using it
- "I think this works" is not acceptable — state uncertainty explicitly

**Do not invent.**
- Do not reference libraries that are not in `package.json`
- Do not reference APIs that have not been confirmed in documentation or existing code
- Do not assume configuration options exist — verify against actual config files in the repo

**Explicit uncertainty is required.**
When you do not know something, say: "I'm not certain about X — verify against [specific source] before using this."
This is not a weakness. Undisclosed uncertainty is.

**Scope creep is a hallucination risk.**
If a task requires touching something outside its defined scope, stop and flag it. Do not silently expand the scope of a change.

---

## 5. Token Efficiency

**Be concise by default.**
- Do not re-explain context that is already in the codebase
- Do not summarize what you just did unless asked
- Do not add commentary to straightforward code

**Match response length to task complexity.**
- Simple change: show the diff, nothing else
- Complex change: brief explanation of the approach, then the code
- Never pad a response to appear more thorough

**Context is expensive. Use it deliberately.**
- Reference existing files rather than reproducing their content
- If you need to show a large block of existing code to make a point, quote only the relevant lines

---

## 6. Code Quality Defaults

**Naming is documentation.**
- Variables, functions, and components should be named for what they do, not how they do it
- Avoid abbreviations unless they are universally understood in the domain
- Boolean variables start with `is`, `has`, or `can`

**Comments explain why, not what.**
- If the code is clear, no comment is needed
- If the code requires explanation, the comment should explain the decision, not describe the syntax
- TODO comments include a reason and an owner: `// TODO(owner): reason`

**File structure follows responsibility.**
- One primary export per file
- Files that change together should live together
- If a file is growing beyond ~200 lines, consider splitting by responsibility

**Do not leave the codebase worse than you found it.**
- If you touch a file that has an obvious issue unrelated to your task, flag it — do not silently fix it, do not silently ignore it
- Fixing unrelated issues in the same commit obscures history

---

## 7. [Reserved]

This section is reserved for future constraints.
