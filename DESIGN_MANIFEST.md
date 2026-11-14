# Design Manifest — Dark Monitoring Dashboard

> Portable design specification. Copy this file into a new project's root and reference it from `CLAUDE.md` to reproduce the exact visual style. The manifest is technology-agnostic — it describes the visual system in CSS classes and behavioral rules, with no dependency on a specific framework, component library, or backend.
>
> Project-specific adoption details (component file paths, env var names, library choices, currently-disabled features) live in the companion document `DESIGN_SPECIFICATION.md`. **Rule:** if a fact would change when copied into a sibling project, it goes in the specification, not here.

## Philosophy

Dark-first, data-dense monitoring UI. Inspired by terminal aesthetics and sci-fi control panels. Every surface is low-contrast dark, accents are neon-bright, and a fixed grid overlay creates depth. The viewport itself is bezelled by a solid black frame around the body so the app reads as a self-contained "screen" rather than a browser document.

No rounded "app" feel — this is a **command center**.

### One shared component library

UI primitives are **not** re-implemented per project. Every frontend consumes the
**same canonical component library** — a single shared source for the primitives in this
manifest (buttons, inputs, selects, tables, modals, popups, toasts, badges, loaders, …).
Copying, forking, or re-authoring a primitive inside an individual project is off the
manifest: when a component needs to change, extend the shared component (add a prop or
variant) so **every** consumer gets the change at once. There is no per-project copy of a
shared primitive living next to the library version.

A component that is too coupled to one project's domain to be reused — it depends on that
project's stores, services, or domain types — stays local to that project instead of
polluting the shared library. Everything generic belongs to the library.

> Where the library lives, how its components are imported, and which components are
> **deliberately kept local** are project-specific facts — see `DESIGN_SPECIFICATION.md`.

---

## 1. Design Tokens

All colors and the opacity scale live as CSS custom properties on `:root`. They are the single source of truth for every component — no hex literal should appear in component CSS unless it is intentionally outside the token system (see § 1.4).

Tokens are declared inside `@layer base` so Tailwind utilities can override them when needed without specificity wars.

### 1.1 Core Palette

```css
:root {
  --hm-bg:      #080c10;   /* Deepest background — body, page, deepest form fields */
  --hm-surface: #0d1117;   /* Cards, modals, table wrappers, sidebars */
  --hm-border:  #1c2333;   /* All borders, dividers, subtle separators */
  --hm-accent:  #00d4ff;   /* Primary cyan — focus, active nav, primary CTA */
  --hm-text:    #e6edf3;   /* Primary text */
  --hm-muted:   #8b949e;   /* Secondary text, labels, placeholders */
}
```

| Token           | Value     | Role                                                                      |
| --------------- | --------- | ------------------------------------------------------------------------- |
| `--hm-bg`       | `#080c10` | Deepest dark. Body canvas. Form inputs (to contrast against surface).     |
| `--hm-surface`  | `#0d1117` | One step lighter. Cards, modals, table wrappers, dropdown menus.          |
| `--hm-border`   | `#1c2333` | All borders, dividers, separators. Never use a custom hex for a border.   |
| `--hm-accent`   | `#00d4ff` | Cyan accent. Focus rings, active nav, primary CTA, grid lines.            |
| `--hm-text`     | `#e6edf3` | Primary text on dark surfaces.                                            |
| `--hm-muted`    | `#8b949e` | Secondary text — labels, placeholders, timestamps, helper copy.           |

> **Surface vs. bg, the rule of thumb:** if an element sits *on* the page background, it uses `--hm-surface`. If an element sits *inside* a card/modal, it uses `--hm-bg` so it visibly recesses into the surface. This is why filter inputs in a toolbar use `--hm-surface` but form inputs inside a modal use `--hm-bg`.

### 1.2 Status Colors

Semantic colors for state. Each one has both a token (for solid use) and a documented rgba pattern (for tinted backgrounds — see § 1.3).

```css
:root {
  --hm-ok:       #10b981;   /* Healthy, active, success */
  --hm-error:    #ef4444;   /* Unhealthy, failed, danger, sign-out */
  --hm-active:   #3b82f6;   /* Active resource count, info */
  --hm-paused:   #6b7280;   /* Paused, inactive, disabled */
  --hm-warning:  #f59e0b;   /* Caution, admin, gradient endpoints */
  --hm-purple:   #7c3aed;   /* Secondary CTA, gradient endpoint */
  --hm-purple-l: #a78bfa;   /* Purple button text (lighter for contrast) */
}
```

| Token           | Value     | Use case                                            | Glow shadow            |
| --------------- | --------- | --------------------------------------------------- | ---------------------- |
| `--hm-ok`       | `#10b981` | Healthy, success, "OK" status dots                  | `0 0 8px #10b981`      |
| `--hm-error`    | `#ef4444` | Unhealthy, failed, destructive actions, sign-out    | `0 0 8px #ef4444`      |
| `--hm-active`   | `#3b82f6` | Active counts, info badges                          | —                      |
| `--hm-paused`   | `#6b7280` | Paused, inactive, disabled                          | —                      |
| `--hm-warning`  | `#f59e0b` | Warnings, admin nav, caution badges                 | —                      |
| `--hm-purple`   | `#7c3aed` | Secondary CTA, gradient endpoints                   | —                      |
| `--hm-purple-l` | `#a78bfa` | Text color *on* purple ghost buttons (contrast fix) | —                      |

Glow (`box-shadow`) is reserved for **status dots only** (`.hm-dot--ok`, `.hm-dot--error`). Do not put glow on text, borders, or buttons — it muddies the dense data layout.

### 1.3 Opacity / rgba Scale

Tokens define the base color; transparency is layered on per interaction state. CSS custom properties can't be interpolated inside `rgba()` directly, so the rgb triple is used inline. Always pick from this scale — no ad-hoc alpha values.

| State              | Background alpha          | Border alpha              | Example                                    |
| ------------------ | ------------------------- | ------------------------- | ------------------------------------------ |
| Subtle tint        | `0.03`                    | —                         | Grid lines, row hover backgrounds          |
| Resting (ghost)    | `0.08`–`0.10`             | `0.20`–`0.30`             | Ghost buttons, active nav, badges          |
| Hover (ghost)      | `0.15`–`0.20`             | (unchanged)               | Hover on ghost buttons / nav links         |
| Error background   | `0.06`–`0.08`             | `0.30`                    | `.hm-banner--error`, error row backgrounds |
| Modal overlay      | `rgba(0, 0, 0, 0.6)` + `backdrop-filter: blur(4px)` | — | `.hm-modal-overlay`            |

The hover step is **always +0.10 alpha** over resting. Don't deviate — the consistent step is what makes the whole UI feel like one system.

### 1.4 Token Rules

- **Never inline a hex** that has a token equivalent. `color: #00d4ff` → `color: var(--hm-accent)`.
- **Never invent a new shade.** If a status needs a new color, add a token first, then use it. No one-off hex in component CSS.
- **The viewport bezel (`#000000` on `<body>`) is the one documented exception.** It is intentionally outside the token system because it represents "the world outside the app," not a surface within it.
- **rgba() uses the literal rgb triple**, not the token. Document the source token in a comment if it isn't obvious: `background: rgba(0, 212, 255, 0.08); /* --hm-accent @ 8% */`.
- **New tokens go in `:root` inside `@layer base`** in `main.css`. Don't scatter custom properties across component files.

---

## 2. Layout

The page shell that lives inside `<body>`. It owns three things: the dark canvas above the body's bezel, the cyan grid overlay that gives depth, and the vertical stack of header → main → footer.

### 2.1 Page Shell (`.hm-page`)

```css
.hm-page {
  min-height: 100vh;
  background: var(--hm-bg);
  position: relative;
  display: flex;
  flex-direction: column;
}
```

Rules:

- `position: relative` is the positioning context for the absolutely-positioned grid background and any decorative `position: absolute` children.
- `display: flex; flex-direction: column` so the footer settles to the bottom of the viewport when content is short (see § 6.2).
- **Do not** add a `border` or `box-shadow` to `.hm-page`. The bezel is on `<body>` (§ 5.3); the grid provides the cyan inner edge. Layering more frames muddies both.

### 2.2 Grid Background (`.hm-grid-bg`)

```css
.hm-grid-bg {
  position: fixed;
  inset: 0;
  background-image:
    linear-gradient(rgba(0, 212, 255, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0, 212, 255, 0.03) 1px, transparent 1px);
  background-size: 40px 40px;
  pointer-events: none;
  z-index: 0;
}
```

Rules:

- **Always `position: fixed`**, never `absolute`. The grid must stay anchored to the viewport while content scrolls — that's what makes it read as depth, not as a wallpaper.
- `pointer-events: none` is mandatory. The overlay covers the entire viewport and would intercept clicks otherwise.
- The 40 px cell size is a global constant. Spacing tokens (§ 2.5) align to it implicitly: 8 / 16 / 24 / 40 all snap to grid intersections at common widths.

### 2.3 Canvas (`.hm-canvas`)

The main content container — every page renders into it via `<slot />`.

```css
.hm-canvas {
  position: relative;
  z-index: 1;
  flex: 1;                          /* push footer down when content is short */
  padding: 32px 40px 60px;
  display: flex;
  flex-direction: column;
  gap: 28px;
}
```

Rules:

- `z-index: 1` so canvas content sits above the grid (`z-index: 0`).
- `flex: 1` makes the canvas absorb all leftover vertical space inside `.hm-page`, which pins the footer to the bottom of the viewport on short pages.
- Pages **do not** add their own outer `padding`. Use `gap` and inner sections instead — the canvas already handles gutters.

### 2.4 Z-Index Stack

Definitive list. Every value used in the app must come from this scale; no inline magic numbers.

| z-index | Layer                     | Examples                                              |
| ------- | ------------------------- | ----------------------------------------------------- |
| `0`     | Grid background           | `.hm-grid-bg`                                         |
| `1`     | Canvas / page content     | `.hm-canvas`, all rendered pages                      |
| `auto`  | Footer                    | `.hm-footer` (must not create a stacking context, so dropdowns rendered inside the canvas can overlay it via fixed positioning) |
| `10`    | Sticky header             | `.hm-header`                                          |
| `50`    | Dropdown menus, popovers  | `.hm-nav-dropdown__menu`, autocomplete dropdowns      |
| `100`   | Modal overlays, toasts    | `.hm-modal-overlay`, `<ToastsContainer>`              |

If a new layer is needed, insert it into this table first — don't pick an arbitrary value at the call site.

Modal overlays and toasts share layer `100`, so **DOM order decides which of the two wins**: the toasts container must be rendered *after* the popup/modal container in the app root file. Rendered before it, toasts land underneath the overlay and get swallowed by its `backdrop-filter: blur()` — the errors that matter most (they're the ones that never auto-dismiss) become unreadable exactly when a modal is open.

### 2.5 Spacing Constants

| Token         | Value | Use case                                                             |
| ------------- | ----- | -------------------------------------------------------------------- |
| `page-x`      | 40 px | Horizontal page padding (`.hm-canvas`, `.hm-header`, `.hm-footer`)   |
| `page-y`      | 32 px | Top padding on canvas/header                                         |
| `page-bottom` | 60 px | Bottom padding on canvas (above footer)                              |
| `gap-lg`      | 28 px | Between major sections inside the canvas                             |
| `gap-md`      | 20 px | Between cards                                                        |
| `gap-sm`      | 16 px | Form rows, grid gaps                                                 |
| `gap-xs`      | 12 px | Filter row, small inline groups                                      |
| `gap-xxs`     | 8 px  | Divider margins, tiny inline gaps                                    |

These are not yet CSS custom properties — they live as literal values in component CSS. When adding a new component, **pick the closest value from this table** rather than inventing a new one.

### 2.6 Responsive

Single breakpoint at 768 px (mobile / tablet boundary). Below it:

```css
@media (max-width: 768px) {
  .hm-canvas { padding: 16px 16px 40px; gap: 16px; }
  .hm-header { padding: 16px 16px 12px; }
  .hm-footer { padding: 12px 16px; }
}
```

The manifest **does not** support a separate desktop-XL breakpoint. The data-dense layout is designed for ≥ 1280 px with no upper bound — extra width becomes extra column space, not a redesign.

---

## 3. Typography

Two self-hosted fonts, no external CDN. Display font for headings/values, monospace for everything else — the monospace bias reinforces the terminal/control-panel aesthetic.

### 3.1 Font Stack

| Role                | Family                         | Weights       |
| ------------------- | ------------------------------ | ------------- |
| Body, code, UI text | `'JetBrains Mono', monospace`  | 400, 600, 700 |
| Display, headings   | `'Syne', sans-serif`           | 400, 700, 800 |

Both are self-hosted and loaded from `/fonts/` via `@font-face` declarations at the top of the base stylesheet (before `@tailwind base`). `font-display: swap` is mandatory — the data-dense layout must not block on font load.

```css
@font-face {
  font-family: 'JetBrains Mono';
  font-weight: 100 800;          /* variable axis range */
  font-style: normal;
  font-display: swap;
  src: url('/fonts/jetbrains-mono-latin.woff2') format('woff2');
  unicode-range: U+0000-00FF, /* …Latin extended ranges… */;
}

@font-face {
  font-family: 'JetBrains Mono';
  font-weight: 100 800;
  font-style: normal;
  font-display: swap;
  src: url('/fonts/jetbrains-mono-cyrillic.woff2') format('woff2');
  unicode-range: U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116;
}

@font-face {
  font-family: 'Syne';
  font-weight: 100 900;
  font-style: normal;
  font-display: swap;
  src: url('/fonts/syne-latin.woff2') format('woff2');
  unicode-range: U+0000-00FF, /* …Latin only — no Cyrillic Syne… */;
}
```

Rules:

- **Always split by `unicode-range`** (Latin / Cyrillic). The browser only downloads the subset it needs.
- **Syne is Latin-only.** Cyrillic display text falls back to JetBrains Mono. This is intentional — the project doesn't ship a Cyrillic Syne file.
- **No `<link rel="preload">` for fonts.** The dark canvas already prevents FOUC; preloading every weight is wasted bytes.

### 3.2 Type Scale

| px | Role                              | Family    | Weight  | Extras                                  |
| -- | --------------------------------- | --------- | ------- | --------------------------------------- |
| 22 | Page title, header logo           | Syne      | 800     | `letter-spacing: -0.5px`                |
| 20 | Stat card value                   | Syne      | 800     |                                         |
| 18 | Dialog heading                    | JetBrains | 700     |                                         |
| 15 | Modal title                       | Syne      | 700     |                                         |
| 14 | Form input value                  | JetBrains | 400     |                                         |
| 13 | Body text, table cell             | JetBrains | 400–600 |                                         |
| 12 | Filter input, form label, button  | JetBrains | 400–600 | `letter-spacing: 0.5px`                 |
| 11 | Section title, nav link, badge    | Syne / JB | 600–700 | `uppercase`, `letter-spacing: 1–1.5px`  |
| 10 | Table header, stat label, footer  | Syne      | 700     | `uppercase`, `letter-spacing: 1px`      |
| 9  | Smallest badge text               | JetBrains | 600     |                                         |

Pick a row, don't interpolate. If a use case doesn't fit the scale, the design is wrong, not the scale.

### 3.3 Text Rules

- **Page title** (`.hm-page-title`): the one `<h1>` per page — 22 px Syne 800, `letter-spacing: -0.5px`, `line-height: 1.2`, no margin of its own (the head layout owns the spacing). It sets no colour: `--hm-text` is inherited from the body, and a page that colours its title by state (a health verdict) keeps its `text-*` utility. Never rebuild it from font utilities (`font-display text-[22px]`) — that is a fork of the scale.
- **Section titles** (`.hm-section-title`): `uppercase`, `letter-spacing: 1.5px`, `color: var(--hm-muted)`, with an `::after` divider that fills remaining row width (`flex: 1; height: 1px; background: var(--hm-border)`).
- **Labels**: `uppercase`, `letter-spacing: 0.5–1px`, `color: var(--hm-muted)`. Always use `<label for="…">` — never wrap the input.
- **No `text-shadow`.** Glow is reserved for status dots only (§ 1.2).
- **Numerals are tabular by default** — JetBrains Mono is monospace, so columns of numbers align in tables without `font-variant-numeric: tabular-nums`. Don't fight it.

---

## 4. Header (`.hm-header`)

The top bar of every page. Single-row, sticky-feeling (lives at the top of `.hm-page` with `z-index: 10`), and contains only the app logo and navigation. No page title, no breadcrumbs — the URL and the active nav link are the breadcrumb.

### 4.1 Structure

```
┌────────────────────────────────────────────────────────┐
│ Logo              [page actions] [Profile] [Sign Out]  │
└────────────────────────────────────────────────────────┘
```

```html
<header class="hm-header">
  <div class="hm-header__left">
    <RouterLink to="/" class="hm-header__logo">App Name</RouterLink>
  </div>

  <nav class="hm-header__nav">
    <!-- Top-level links + NavDropdown groups, with __nav-divider between sections -->
    <RouterLink class="hm-nav-link" to="/" />
    <NavDropdown :label="…" :items="…" />
    <span class="hm-header__nav-divider" />

    <!-- Teleport target for page-specific actions (optional) -->
    <div id="header-actions" />

    <!-- Identity anchors — always present, always last two (see § 4.6) -->
    <a class="hm-nav-link hm-nav-link--active" href="…/profile">My Profile</a>
    <button class="hm-nav-link hm-nav-link--signout" @click="signOut">Sign Out</button>
  </nav>
</header>
```

### 4.2 Spec

```css
.hm-header {
  position: relative;
  z-index: 10;
  padding: 32px 40px 20px;
  border-bottom: 1px solid var(--hm-border);
  background: linear-gradient(180deg, rgba(0, 212, 255, 0.04) 0%, transparent 100%);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.hm-header__logo {
  font-family: 'Syne', sans-serif;
  font-size: 22px;
  font-weight: 800;
  letter-spacing: -0.5px;
  color: var(--hm-text);
  text-decoration: none;
}

.hm-header__nav {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hm-header__nav-divider {
  width: 1px;
  height: 18px;
  background: var(--hm-border);
  margin: 0 4px;
}
```

The cyan gradient at the top is what visually separates the header from the canvas without needing a heavy border. The `border-bottom` is a single hairline — keep it.

### 4.3 Nav Links (`.hm-nav-link`)

Defined **globally** in `main.css`, not scoped to any component. Reason: pages inject buttons via `<Teleport to="#header-actions">`, so the receiving DOM is outside any page component's scope.

```css
.hm-nav-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  text-decoration: none;
  color: var(--hm-muted);
  background: transparent;
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 0.15s;
}

.hm-nav-link:hover {
  background: rgba(0, 212, 255, 0.08);
  color: var(--hm-accent);
}
```

| Modifier      | Background                | Border                    | Color           | Use case                  |
| ------------- | ------------------------- | ------------------------- | --------------- | ------------------------- |
| (base)        | transparent               | transparent               | `--hm-muted`    | Inactive nav link         |
| `--active`    | `rgba(0,212,255,0.08)`    | `rgba(0,212,255,0.30)`    | `--hm-accent`   | Current route, My Profile |
| `--admin`     | `rgba(245,158,11,0.08)`   | `rgba(245,158,11,0.30)`   | `#f59e0b`       | Admin-only entries        |
| `--signout`   | `rgba(239,68,68,0.08)`    | `rgba(239,68,68,0.30)`    | `#ef4444`       | Sign Out only             |

Hover step is the standard +0.10 alpha (§ 1.3).

### 4.4 Nav Grouping (`NavDropdown`)

Top-level routes that share a domain are collapsed into a `NavDropdown` (e.g. *Build & Deliver*, *Infrastructure*, *Security*, *Admin*). The trigger is a `.hm-nav-link` with a chevron; the menu is a `position: absolute` panel anchored `top: calc(100% + 8px); right: 0`, with `z-index: 50` (per § 2.4).

Rules:

- **Use a dropdown when a domain has 2+ items.** A single-item domain stays as a flat link.
- **Dropdowns close on outside click and `Escape`.** Both are non-negotiable accessibility behaviors.
- **Active state propagates upward**: if any child route is active, the trigger renders as `--active`.

### 4.5 Page-Specific Actions (`#header-actions`)

Pages inject buttons into the header via `<Teleport to="#header-actions">`. Rules:

- **Position is fixed by the layout**: between the last nav-divider and the My Profile button. Pages do not control where their button lands.
- **Use `.hm-nav-link` (or `.hm-btn`) classes**, not custom styles. The header is a single visual system.
- **Maximum 2 page-action buttons.** If you need more, the page needs a toolbar of its own inside the canvas.

### 4.6 Identity Anchors (My Profile + Sign Out)

When a product family shares an authentication surface, the rightmost two nav items are reserved for the user's identity actions: a link to their profile and a sign-out trigger. Render them in this exact order, with these exact modifiers, so users recognize "this app belongs to the same family".

| Button         | Element    | Class                              | Behavior                                                       |
| -------------- | ---------- | ---------------------------------- | -------------------------------------------------------------- |
| **My Profile** | `<a>`      | `hm-nav-link hm-nav-link--active`  | External nav to the auth surface's profile page                |
| **Sign Out**   | `<button>` | `hm-nav-link hm-nav-link--signout` | Clears local auth, redirects to the auth surface root          |

When auth is disabled (e.g. local dev), both buttons are hidden — but **never** restyled or relabeled. Consistency is the point.

### 4.7 What the Header MUST NOT Contain

| Element                      | Where it belongs                                  |
| ---------------------------- | ------------------------------------------------- |
| Page title                   | First `<h1>` in `.hm-canvas` (`.hm-page-title`)   |
| Breadcrumbs                  | The URL is the breadcrumb. Don't add them.       |
| Global search bar            | Page-level search lives in the table toolbar      |
| User avatar / name display   | Auth gateway profile page                         |
| Settings cog                 | A nav link to `/settings`, not an icon button     |

A notifications counter (e.g. unread Events badge) is allowed as an inline `.hm-nav-link` with a number pill — see the Events bell in `layouts/default.vue` for the canonical pattern.

---

## 5. Body Container

The `<body>` is the outermost surface controlled by the design system. Everything else (the framework root, pages, modals, toasts) lives inside it. Its job is threefold:

1. Establish the **dark canvas** (`--hm-bg`) so there is never a flash of white during navigation, suspense boundaries, or font swaps.
2. Render the **viewport bezel** — an 8 px solid black frame that visually separates the app from the OS chrome.
3. Lock down **horizontal overflow** so wide tables, code blocks, or absolutely-positioned glow effects cannot produce a horizontal scrollbar at the document level.

### 5.1 Spec

```css
body {
  margin: 0;
  background-color: var(--hm-bg);   /* #080c10 */
  color: var(--hm-text);            /* #e6edf3 */
  border: 8px solid #000000;        /* viewport bezel — see § 5.3 */
  overflow-x: hidden;               /* never allow horizontal scroll on the document */
}
```

The `:root` block must declare `color-scheme: dark` and the default font stack so native UI (scrollbars, form controls, autofill) inherits the dark palette before any component CSS loads:

```css
:root {
  font-family: 'JetBrains Mono', monospace;
  color-scheme: dark;
}
```

### 5.2 Framework Root (`#app`)

The framework root sits directly inside `<body>` and stretches it to the full viewport height. It is **not** a styling layer — it only guarantees that the page fills the screen even when content is shorter than the viewport, so the dark canvas never gives way to a white gap. The selector here is `#app` (Vue convention) — adapt to your framework's mount-node selector if different.

```css
#app {
  min-height: 100dvh;               /* dynamic vh — accounts for mobile URL bar */
  display: flex;
  flex-direction: column;
  background-color: var(--hm-bg);
  color: var(--hm-text);
}
```

Use `100dvh` (not `100vh`) so the layout collapses correctly when mobile browsers hide their URL bar.

### 5.3 Viewport Bezel

The `border: 8px solid #000000` on `<body>` is a deliberate visual element, not a debug outline. It reads as the bezel of a hardware monitor and frames the cyan grid background inside.

Rules:

- **Color is pure black (`#000000`)**, not `var(--hm-bg)`. The bezel must be darker than the canvas to read as a frame.
- **Width is 8 px on all four sides.** Do not change it per-page or per-breakpoint — it is a global, app-wide constant.
- **Do not add `box-shadow` or a second border** to `.hm-page`, `#__nuxt`, or any layout wrapper. The bezel is the only frame; layering more borders muddies it.
- **Do not remove the bezel for embedded views** (modals inside iframes, OAuth callback pages, etc.) unless the embedding host already provides chrome. Consistency across services is the point.

### 5.4 Overflow Rules

- `overflow-x: hidden` on `<body>` is **mandatory**. Wide content (data tables, log viewers, terminal output) must scroll inside its own container, never inside the document.
- Do **not** set `overflow-y: hidden` on `<body>`. Vertical scrolling belongs to the document so the browser's native scroll-restoration on back/forward navigation keeps working.
- If a page needs a fixed full-screen layer (e.g. a full-bleed modal or a fullscreen terminal), layer it via `position: fixed` and `z-index` (see the Z-Index Stack section, forthcoming) — never by toggling `body { overflow: hidden }` from JS.

### 5.5 Things That Must NOT Live on `<body>`

To keep the body container portable across projects, the following concerns belong elsewhere:

| Concern                          | Where it belongs                                  |
| -------------------------------- | ------------------------------------------------- |
| Grid background overlay          | `.hm-grid-bg` inside `.hm-page` (see § Layout)    |
| Page padding / gutters           | `.hm-canvas`                                      |
| Sticky header                    | `.hm-header` inside `.hm-page`                    |
| Modal overlays / toasts / popups | Sibling nodes of the layout root inside the app root file, toasts last (§ 2.4) |
| Font `@font-face` declarations   | Top of `main.css`, before `@tailwind base`        |
| CSS custom properties            | `:root` inside `@layer base`                      |

Keeping `<body>` minimal means the same selector block can be lifted into any new project verbatim, without dragging project-specific layout assumptions along with it.

---

## 6. Footer (`.hm-footer`)

The bottom edge of every page. Functions as a **status bar**, not a navigation surface — its job is to surface app-level state at a glance (environment, version, connection) without competing with content.

### 6.1 Structure

```
┌────────────────────────────────────────────────────────┐
│ App vX.Y.Z · build sha    [● online] [env: prod]    ⓘ │
└────────────────────────────────────────────────────────┘
```

```html
<footer class="hm-footer">
  <div class="hm-footer__left">
    <span class="hm-footer__meta">App v{{ version }}</span>
    <span class="hm-footer__sep">·</span>
    <span class="hm-footer__meta">build {{ buildSha.slice(0, 7) }}</span>
  </div>

  <div class="hm-footer__center">
    <span class="hm-footer__pill">
      <span class="hm-dot" :class="online ? 'hm-dot--ok' : 'hm-dot--error'" />
      {{ online ? 'online' : 'offline' }}
    </span>
    <span class="hm-footer__pill hm-footer__pill--env">
      env: {{ environment }}
    </span>
  </div>

  <div class="hm-footer__right">
    <!-- Optional: docs/support links — use .hm-nav-link styling. -->
  </div>
</footer>
```

### 6.2 Spec

```css
.hm-footer {
  position: relative;                /* no z-index — see § 2.4. Must not form a stacking context, otherwise popovers/dropdowns rendered inside the canvas can't overlay the footer. */
  padding: 14px 40px;
  border-top: 1px solid var(--hm-border);
  background: linear-gradient(0deg, rgba(0, 212, 255, 0.04) 0%, transparent 100%);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: var(--hm-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.hm-footer__left,
.hm-footer__center,
.hm-footer__right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hm-footer__sep  { opacity: 0.4; }
.hm-footer__meta { color: var(--hm-muted); }

.hm-footer__pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--hm-border);
}

.hm-footer__pill--env {
  background: rgba(0, 212, 255, 0.08);
  border-color: rgba(0, 212, 255, 0.30);
  color: var(--hm-accent);
}
```

The cyan gradient at the top of the footer mirrors the gradient at the bottom of the header — together they make the canvas feel framed, top and bottom, by a faint cyan glow.

The footer settles to the bottom of the viewport on short pages because `.hm-page` is a flex column and `.hm-canvas` has `flex: 1` (§ 2.1, § 2.3). **No `position: sticky` or `fixed`** — the footer is in normal flow; if content is long, it sits below the content as expected.

### 6.3 Required Slots

The footer renders at minimum:

| Slot   | Content                                                     | Required |
| ------ | ----------------------------------------------------------- | -------- |
| Left   | `App v{version}` and a 7-char build SHA                     | ✅       |
| Center | Online/offline pill (live connection status)                | ✅       |
| Center | Environment pill (`dev` / `staging` / `prod`)               | ✅       |
| Right  | Optional links (docs, support, status page)                 | —        |

Rules:

- **The environment pill is always shown, including in production.** Hiding it in prod removes the visual cue that catches "wait, why is this staging" mistakes.
- **Version and build SHA come from build-time identifiers.** Never hardcode.
- **No actions in the footer.** No buttons that mutate state, no dropdowns, no popovers. It is a read-only status surface.

### 6.4 What the Footer MUST NOT Contain

| Element                | Why                                                         |
| ---------------------- | ----------------------------------------------------------- |
| Navigation links       | Nav lives in the header. Putting it in both is duplication. |
| Copyright / legal text | Belongs on the auth gateway / marketing site, not the app.  |
| Newsletter signup      | This is a control center, not a content site.               |
| Social media icons     | Same as above.                                              |

---

## 7. Buttons

There is **one** Button component in the entire app: `<UiButton>`. It wraps the `.hm-btn` class system from `main.css`. Pages, modals, toolbars, and headers all consume it — there is no second button library, no per-page button CSS, and no Tailwind-color buttons.

> **Single-component rule.** If you find yourself writing `<button class="bg-…">` or importing a different `Button` from a UI kit, you are off the manifest. Add the missing variant to `<UiButton>` instead of forking.

### 7.1 Anatomy

```html
<UiButton variant="primary" size="md" :icon="icon" :loading="isPending" @click="…">
  Save
</UiButton>
```

| Prop       | Type                                                              | Default     | Notes                                                         |
| ---------- | ----------------------------------------------------------------- | ----------- | ------------------------------------------------------------- |
| `variant`  | `'primary' \| 'cyan' \| 'green' \| 'purple' \| 'red' \| 'neutral'` | `'cyan'`    | Maps 1:1 to `.hm-btn--{variant}`                              |
| `size`     | `'sm' \| 'md'`                                                    | `'md'`      | `md` = 30 px height (canonical). `sm` = 24 px (toolbar inline)|
| `type`     | `'button' \| 'submit' \| 'reset'`                                 | `'button'`  | Pass through to `<button>`. Ignored when `to` is set.         |
| `to`       | `RouteLocationRaw \| undefined`                                   | —           | If set, renders a `<RouterLink>` instead of `<button>` (link styled as a button). Same `.hm-btn` styling. |
| `icon`     | `string \| undefined`                                             | —           | Icon name (see § 20). Renders before label.                   |
| `trailing` | `boolean`                                                         | `false`     | Render the icon **after** the label                           |
| `loading`  | `boolean`                                                         | `false`     | Replaces label with a spinner; auto-disables                  |
| `disabled` | `boolean`                                                         | `false`     | Applies `:disabled` styles. Ignored when `to` is set.         |

Slot: default slot is the button label.

### 7.2 Spec (`.hm-btn`)

```css
.hm-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 30px;
  padding: 0 14px;
  border-radius: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  cursor: pointer;
  transition: all 0.15s;
  border: 1px solid transparent;
}

.hm-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

Height (30 px), font size (11 px), and radius (8 px) are **fixed**. Do not override them per call site — pick a different `size` if you need a smaller button. Spawning `<UiButton style="height: 36px">` is forbidden.

### 7.3 Variants

| Variant     | Background                | Border                    | Text         | Use case                                                  |
| ----------- | ------------------------- | ------------------------- | ------------ | --------------------------------------------------------- |
| `primary`   | `--hm-accent` (solid)     | none                      | `#0a0e17`    | The single primary CTA per view (Save, Submit, Connect)   |
| `cyan`      | `rgba(0,212,255,0.10)`    | `rgba(0,212,255,0.30)`    | `--hm-accent`| Default action button — most common variant               |
| `green`     | `rgba(16,185,129,0.10)`   | `rgba(16,185,129,0.30)`   | `#10b981`    | Confirm-positive (Approve, Mark healthy)                  |
| `purple`    | `rgba(124,58,237,0.10)`   | `rgba(124,58,237,0.30)`   | `#a78bfa`    | Secondary CTA — text uses `--hm-purple-l` for contrast    |
| `red`       | `rgba(239,68,68,0.10)`    | `rgba(239,68,68,0.30)`    | `#ef4444`    | Destructive (Delete, Remove, Disable)                     |
| `neutral`   | transparent               | `--hm-border`             | `--hm-muted` | Cancel, Close, dismissive secondary                       |

Hover step is the standard **+0.10 alpha** on the background (§ 1.3). `primary` is the exception — it uses `opacity: 0.9` because its background is solid.

### 7.4 Composition Rules

- **One `primary` per view.** Multiple primary buttons cancel each other's emphasis. Everything else is `cyan` (default action) or a status variant.
- **Destructive actions are always `red`.** Never style a Delete button as `neutral` "to be subtle" — destructive intent must be visually loud.
- **Cancel is `neutral`.** Always paired left-of the primary in a button row. Order: `[Cancel]  [Primary]`, with a 12 px gap, right-aligned in modal footers.
- **Loading state replaces the label**, not the icon. The button width should not jump — use `min-width` if the label is short.
- **Don't put an icon-only button inside a button row.** Icon-only is a separate pattern (see § 7.6).

### 7.5 Header / Toolbar Variant

Buttons rendered into the header (`#header-actions` teleport, see § 4.5) or into a table toolbar use the same `<UiButton>`. They do **not** get their own classes. The visual continuity between "a header button" and "a body button" is the point.

The only exception is the small icon-only toolbar button (refresh, CSV download), which has its own spec — see § 9.

### 7.6 Row Action Buttons (`.action-btn`)

Inline action buttons inside table rows use a denser variant: smaller padding, 10 px font, no fixed height (sized to icon).

```css
.action-btn {
  padding: 4px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
}
.action-btn:disabled { opacity: 0.5; cursor: not-allowed; }
```

| Modifier         | Border                      | Color         | Use case                  |
| ---------------- | --------------------------- | ------------- | ------------------------- |
| `.action-edit`   | `rgba(0,212,255,0.30)`      | `--hm-accent` | Edit, Configure           |
| `.action-success`| `rgba(16,185,129,0.30)`     | `--hm-ok`     | Approve, Activate         |
| `.action-warning`| `rgba(245,158,11,0.30)`     | `#f59e0b`     | Pause, Caution actions    |
| `.action-delete` | `rgba(239,68,68,0.30)`      | `#ef4444`     | Delete, Remove            |
| `.action-neutral`| `rgba(255,255,255,0.15)`    | `--hm-muted`  | Inert / informational     |

Hover step is +0.10 alpha. These are consumed by <UiTableActions> — call sites should not style row buttons by hand.

### 7.7 What Buttons MUST NOT Be

| Pattern                                          | Why it's banned                                                         |
| ------------------------------------------------ | ----------------------------------------------------------------------- |
| `<button class="bg-blue-500 …">` (Tailwind)      | Bypasses the variant system; visual drift across pages                  |
| Per-page `.my-feature-btn` CSS                   | Same — forks the system                                                 |
| Custom hover effects (scale, shadow, glow)       | Glow is reserved for status dots (§ 1.2); buttons get the alpha step    |
| Icon-only button without an `aria-label`         | Accessibility: screen readers have nothing to announce                  |
| `width: 100%` on a button outside a form footer  | Full-width buttons are a form-submit convention only                    |
| Mixing variants in a button group                | A `[Cancel] [Save]` pair is `neutral + primary`, not `red + green`      |

---

## 8. Cards

Cards are the primary container for grouped content inside `.hm-canvas`. Every card sits on `--hm-bg` and uses `--hm-surface` as its own background — that one-step lift is what makes the canvas feel layered.

### 8.1 Base Card (`.hm-card`)

```css
.hm-card {
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  overflow: hidden;
}
```

Rules:

- **Padding is set by the consumer**, not the card. A card with a table inside has zero padding (the table fills it); a card with a paragraph has 20 px. Don't bake padding into `.hm-card`.
- **`overflow: hidden` is mandatory.** Without it, the accent stripe (§ 8.2) bleeds past the rounded corners.
- **Radius is 12 px.** Tables use 10 px (§ 9), modals 14 px (§ 14). The scale is intentional — cards sit between tables and modals visually.
- **No `box-shadow`.** Depth comes from the surface/bg contrast, not from elevation shadows. Adding shadow flattens the dark hierarchy.

### 8.2 Accent Stripe (`.hm-card-accent`)

Optional 2 px gradient strip at the top of a card. Renders as the **first child** inside `.hm-card`.

```css
.hm-card-accent { height: 2px; }

.hm-card-accent--ok       { background: linear-gradient(90deg, #10b981, #00d4ff); }
.hm-card-accent--error    { background: linear-gradient(90deg, #ef4444, #f59e0b); }
.hm-card-accent--total    { background: linear-gradient(90deg, #00d4ff, #7c3aed); }
.hm-card-accent--active   { background: linear-gradient(90deg, #3b82f6, #00d4ff); }
.hm-card-accent--paused   { background: linear-gradient(90deg, #6b7280, #9ca3af); }
.hm-card-accent--uptime   { background: linear-gradient(90deg, #7c3aed, #00d4ff); }
```

Rules:

- **Use the accent when the card communicates a category at a glance** — health (`--ok` / `--error`), workload type (`--active` / `--paused`), aggregate (`--total`), uptime metric. A card showing a generic form has **no accent**.
- **Pick from the table.** Don't invent a new gradient. If a new category genuinely needs a distinct color, add a `--{name}` modifier to the table first.
- **One accent per card.** Stacking accents is not allowed.

### 8.3 Left Status Bar (`.hm-card-status-bar`)

Vertical 2 px-wide bar pinned to the left edge of a `.hm-card`. Used when a card represents a single live resource whose health/state should be color-coded at a glance (server, node, deployment target). Mutually exclusive with `.hm-card-accent` (top stripe) — pick one channel, not both.

```css
.hm-card-status-bar {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 2px;
}

.hm-card-status-bar--ok      { background: var(--hm-ok); }
.hm-card-status-bar--error   { background: var(--hm-error); }
.hm-card-status-bar--paused  { background: var(--hm-paused); }
.hm-card-status-bar--warning { background: var(--hm-warning); }
```

Rules:

- The host `.hm-card` must be `position: relative` for the bar to anchor (`.hm-card` doesn't enforce this — set it where the bar is used).
- Card content needs `padding-left ≥ 12 px` so the bar never crowds the title. A typical pl is `pl-5` / `20 px` to leave breathing room.
- **Color must come from a status token (§ 1.2).** No ad-hoc hex, no Tailwind palette colors (`bg-green-500`, `bg-red-500`).
- **Pick the right channel:** use the **top stripe** (§ 8.2) when the card represents an aggregate or category (KPI, summary). Use the **left bar** when the card represents a single live resource whose status changes over time.

### 8.4 Stat Cards (`.hm-stat-card`)

KPI-style card with a label and a single large value. Used for dashboards and at-a-glance summaries.

```css
.hm-stat-cards {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}

.hm-stat-card {
  min-width: 10vw;
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 12px;
  padding: 16px 20px;
  overflow: hidden;
  flex: 1;
}

.hm-stat-card__label {
  font-family: 'Syne', sans-serif;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--hm-muted);
  margin-bottom: 8px;
}

.hm-stat-card__value {
  font-family: 'Syne', sans-serif;
  font-size: 20px;
  font-weight: 800;
  color: var(--hm-text);
}
```

Rules:

- **Label always above the value.** Never side-by-side. The vertical order is what makes the row scannable.
- **Value is a single number/token.** Not a sentence, not a description. Use a separate card or section for explanatory text.
- **Cards in a row are equal-flex.** `.hm-stat-cards` uses `flex: 1` per card so widths balance automatically. Don't set fixed widths.
- **Accent stripe is optional but encouraged** — it color-codes the metric without taking value-area space.

### 8.5 Composition

Cards can be composed: a `.hm-card` may contain a `.hm-section-title` (§ 18), a `.hm-table` (§ 9), a form (§ 10), or another card. The rule is that contained surfaces step **down** the contrast: a sub-card inside a card uses `--hm-bg`, not another `--hm-surface` (otherwise the levels merge).

| Layer            | Background                      |
| ---------------- | ------------------------------- |
| Page             | `--hm-bg`                       |
| Card             | `--hm-surface`                  |
| Sub-card / Input | `--hm-bg` (recessed into card)  |

### 8.6 What Cards MUST NOT Be

| Pattern                                                       | Why                                                                  |
| ------------------------------------------------------------- | -------------------------------------------------------------------- |
| Card with `box-shadow`                                        | Breaks the flat dark hierarchy                                       |
| Card with a colored background (not `--hm-surface`)           | Use the accent stripe to color-code, not the body                    |
| Card with `border-radius` ≠ 12 px                             | Use the documented radius — 10 (table) / 12 (card) / 14 (modal)     |
| Nested cards on the same surface level                        | Step the inner one down to `--hm-bg`                                 |
| `.hm-stat-card` with a multi-line value                       | Stat cards are single-token. Use a regular card for prose.           |
| `.hm-card-status-bar` and `.hm-card-accent` on the same card  | Pick one channel — stacking them double-codes the same axis          |

---

## 9. Tables

The data table is the densest surface in the app. There are **two variants**, picked by use case:

| Variant                                | When to use                                                                  | Component                                    |
| -------------------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------- |
| **Grid Table** (canonical)             | Server-driven data: pagination, sort, filter, refresh, CSV export            | `<UiTable>` |
| **Simple Table** (`.hm-table`)         | Static/few-row tables embedded in cards or modals — no controls, no paging   | Plain `<table>` with `.hm-table` classes     |

The Grid Table is what 99% of pages render. The Simple Table is for read-only summaries (e.g. environment info inside a modal).

### 9.1 Grid Table — Container

Outermost wrapper. Replaces the older `.hm-table-wrap`/`.hm-table` pair.

```css
.hm-table-container {
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 10px;
  padding: 20px;
  min-height: 100%;
}
```

The container owns its padding (20 px). Don't wrap it in another card — the container **is** the card.

### 9.2 Controls Bar

The toolbar above the table. Three slot zones, fixed left-to-right order.

```
┌──────────────────────────────────────────────────────────────────┐
│ [Search] [filters…]                  [actions…] [⟳] [csv?]       │
└──────────────────────────────────────────────────────────────────┘
```

```css
.hm-controls-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  gap: 12px;
}
.hm-controls-bar__left,
.hm-controls-bar__right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.hm-controls-search {
  width: 220px;
  height: 30px;
}
```

Slot order is **enforced** by `<UiTable>`:

| Slot                | Position                          | What goes here                                  |
| ------------------- | --------------------------------- | ----------------------------------------------- |
| (built-in search)   | Leftmost in `__left`              | Global search input — always present            |
| `controls-left`     | After search                      | Filter checkboxes (`<UiCheckbox>`, § 13.6.4), dropdowns, multi-select filters (`<UiMultiSelect>`, § 11.6), date pickers |
| `controls-prepend`  | Leftmost in `__right`             | Page-level actions (e.g. "Mark all read")       |
| (built-in refresh)  | After `controls-prepend`          | Auto-rendered when `tableDataKey` is set        |
| `controls-append`   | After refresh, before CSV         | Rare — items that must sit between refresh/CSV  |
| (built-in CSV)      | Rightmost                         | Auto-rendered when `isCsvDownload` is true      |

> **The refresh button is always to the right of page actions.** Never place a custom button to the right of refresh or CSV. This is non-negotiable cross-page consistency.

### 9.3 Toolbar Icon Button (`.hm-toolbar-btn`)

The 30×30 square icon button used by refresh and CSV download. Reusable for any toolbar-level icon action.

```css
.hm-toolbar-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border-radius: 6px;
  border: 1px solid var(--hm-border);
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
  color: var(--hm-muted);
}
.hm-toolbar-btn:hover {
  background: rgba(0, 212, 255, 0.08);
  border-color: rgba(0, 212, 255, 0.30);
}
```

Rules:

- **Always 30×30.** Matches the height of the search input and `<UiButton size="md">` so the toolbar reads as one row.
- **Always has a `title` attribute.** Tooltip is the only label (no visible text).
- **Icon size is 14 px** (`w-[14px] h-[14px]`), centered, `color: var(--hm-muted)`.

### 9.4 Grid Table — Layout

The table itself is **CSS Grid**, not `<table>`. This lets columns share a single `grid-template-columns` and align across header/body without the constraints of HTML table layout.

```css
.grid-table { display: flex; flex-direction: column; width: 100%; }
.grid-row   { display: grid; width: 100%; }

.grid-row--header { border-bottom: 1px solid var(--hm-border); }
.grid-row--body   {
  border-bottom: 1px solid rgba(28, 35, 51, 0.5);
  transition: background 0.15s;
}
.grid-row--body:last-child { border-bottom: none; }
.grid-row--body:hover      { background: rgba(0, 212, 255, 0.03); }

.grid-cell        { display: flex; align-items: center; }
.grid-cell--header { padding: 10px 16px; }
.grid-cell--body  {
  padding: 10px 16px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 13px;
  color: var(--hm-text);
  min-height: 52px;
}

.grid-cell--sticky { background: var(--hm-surface); }   /* sticky-left or sticky-right */

.hm-th-label {
  font-family: 'Syne', sans-serif;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--hm-muted);
}
```

Rules:

- **Row min-height is 52 px.** Don't shrink it for "denser" tables — density is achieved with column count, not row height.
- **Hover background is the subtle tint** (`rgba(0,212,255,0.03)`, alpha 0.03 from § 1.3). Same value applies whether the row is sticky or not.
- **Sticky cells** (left or right pinned) use `--hm-surface` as their cell background so they hide rows scrolling underneath. On hover, mix in 3% accent so the sticky cell doesn't visually detach from the hovered row.
- **Cell horizontal padding is 16 px**, vertical is 10 px. Same on header and body.

### 9.5 Column Spec (`TableColumn<T>`)

```ts
type TableColumn<T> = {
  key: keyof T | string;
  label?: string;
  sortBy?: string;          // server-side sort key
  filterBy?: string;        // server-side filter key
  filterType?: 'text' | 'select' | 'date';
  options?: unknown[];      // for filterType: 'select'
  width?: number | string;  // 'auto' or px
  minWidth?: number;        // px
  maxWidth?: number;        // px
  textWrap?: boolean;       // wrap vs truncate (default: truncate)
  expandable?: boolean;     // chevron toggles row expansion
  sticky?: 'left' | 'right';
  csvField?: string;        // CSV export column name
  hidable?: boolean;        // default true; set false to lock the column visible
  defaultHidden?: boolean;  // start hidden on first render — user can opt in via column toggle
};
```

`gridTemplateColumns` is computed from `width`/`minWidth`/`maxWidth`:

| Inputs                       | Resulting track                  |
| ---------------------------- | -------------------------------- |
| `width: 'auto'` + `maxWidth` | `{maxWidth}px`                   |
| `width: 'auto'` + `minWidth` | `{minWidth}px`                   |
| `minWidth` + `maxWidth`      | `minmax({min}px, {max}px)`       |
| `minWidth` only              | `minmax({min}px, 1fr)`           |
| (none)                       | `minmax(auto, 1fr)`              |

Rules:

- **Use `minWidth` for every column** unless the column is fixed-width. Without a min, narrow viewports collapse columns into illegible slivers.
- **Sort indicators are dual-arrows** (up + down icon stack), with the active direction at full opacity and the inactive at 0.4. Don't substitute a single chevron — the dual-arrow is a recognized "this column is sortable" affordance.
- **Filter inputs are rendered into the column header** when `filterBy` is set. The header becomes a two-line: label on top, filter input below.

### 9.6 Loading & Empty States

| State        | Render                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------- |
| `loading`    | Absolute overlay over the table area: `bg-hm-bg/80`, `backdrop-blur-sm`, centered spinner |
| Empty        | Centered `.hm-empty-state` div at 60% vertical, default copy `"Nothing found"`           |
| Error        | Use `<UiBanner variant="error">` (§ 19.2) **above** the table, not inside the table area |

Loading and empty are mutually exclusive — never show both. The `loading` flag wins.

### 9.7 Pagination Bar

```css
.hm-pagination-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0 4px;
  border-top: 1px solid var(--hm-border);
  margin-top: 4px;
}
.hm-pagination-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  color: var(--hm-muted);
}
```

Layout: `[Rows per page: <select>]  Showing X to Y (Z total)` on the left, page buttons on the right.

```css
.hm-pagination-btn {
  padding: 6px 12px;
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 6px;
  font-size: 12px;
  color: var(--hm-text);
  cursor: pointer;
  transition: all 0.15s;
  font-family: 'JetBrains Mono', monospace;
}
.hm-pagination-btn--active {
  background: var(--hm-accent);
  color: #0a0e17;
  border-color: var(--hm-accent);
}
.hm-pagination-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}
```

Rules:

- **Pagination is hidden when `itemsCount ≤ rowsPerPage`.** Don't render a single disabled "1" button.
- **Page-size options are fixed: `[10, 20, 50, 100]`.** Don't add custom sizes.
- **Active page uses the solid `--hm-accent` background** (same treatment as `<UiButton variant="primary">`).

### 9.8 Simple Table (`.hm-table`)

For static tables embedded in cards/modals where you don't need pagination, sort, or filters.

```css
.hm-table-wrap {
  border: 1px solid var(--hm-border);
  border-radius: 10px;
  background: var(--hm-surface);
  overflow: hidden;
}
.hm-table { width: 100%; border-collapse: collapse; }
.hm-table th {
  padding: 10px 16px;
  font-family: 'Syne', sans-serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--hm-muted);
  border-bottom: 1px solid var(--hm-border);
  text-align: left;
  font-weight: 700;
}
.hm-table td {
  padding: 10px 16px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 13px;
  border-bottom: 1px solid rgba(28, 35, 51, 0.5);
  color: var(--hm-text);
}
.hm-table tbody tr:hover           { background: rgba(0, 212, 255, 0.03); }
.hm-table tbody tr:last-child td   { border-bottom: none; }

.hm-table-row--ok    { border-left: 3px solid #10b981; }
.hm-table-row--error { border-left: 3px solid #ef4444; }
```

Same row paddings, same hover, same border colors as the Grid Table — so the two variants visually match.

The `--ok` / `--error` row stripes are a 3 px left border. Use them when a row carries a hard health signal — e.g. the row for an unhealthy server. Do not use them for "warning" or "info" — only the two binary states are documented.

### 9.9 Inline Cell Edit (`<UiTableInput>`)

Editing inside a cell uses <UiTableInput> — a borderless input that becomes bordered on focus. The input replaces the cell content **in place** (no modal, no drawer). On blur or Enter, the change is emitted; on Escape, it reverts.

Cells that are editable get no special visual chrome at rest — discoverability is via hover affordance, not persistent borders. This keeps the table dense.

### 9.10 What Tables MUST NOT Be

| Pattern                                                     | Why                                                                  |
| ----------------------------------------------------------- | -------------------------------------------------------------------- |
| Per-page custom table CSS                                   | Use `<UiTable>` slots, not a forked layout                           |
| Action button to the right of the refresh button            | Refresh/CSV are always rightmost — non-negotiable                    |
| Striped (zebra) rows                                        | Hover background carries the row affordance — stripes add noise      |
| Row height < 52 px                                          | Drops the touch target below comfort and breaks the visual rhythm    |
| Custom sort icons                                           | Use the dual-arrow pattern; one direction at 1.0, other at 0.4       |
| Filter UI in a separate panel above the table               | Filters live in column headers (when `filterBy` is set)              |
| Table without `minWidth` columns on a horizontal-scroll page | Columns collapse into illegible slivers                              |

---

## 10. Forms

A form is a vertical stack of labeled fields, an optional helper/error per field, and a button row at the bottom. There are no multi-column forms in this manifest — density comes from concise labels and inline status, not from cramming two columns.

> **Form primitives may be wrapped over a third-party library** (form group, input, textarea, select) — that's a project choice. The manifest specifies the **visual contract**: classes, sizing, label placement, error treatment. As long as the wrapper renders to that contract, the choice of underlying library is internal.

### 10.1 Anatomy

```html
<UiForm @submit="onSubmit">
  <UiFormField label="Name" name="name">
    <UiFormInput v-model="name" placeholder="Service name" />
  </UiFormField>
  <UiFormField label="Region" name="region">
    <UiFormSelect v-model="region" :options="regions" />
  </UiFormField>
  <UiFormField label="Notes" name="notes">
    <UiFormTextarea v-model="notes" />
  </UiFormField>

  <div class="hm-form-actions">
    <UiButton variant="neutral" type="button" @click="onCancel">Cancel</UiButton>
    <UiButton variant="primary" type="submit" :loading="isPending">Save</UiButton>
  </div>
</UiForm>
```

`<UiFormField>` is the field wrapper — it owns the label, helper text, and error slot. The input components live inside it.

### 10.2 Form Container

```css
.hm-form {
  display: flex;
  flex-direction: column;
  gap: 16px;             /* gap-sm — between fields */
}

.hm-form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;             /* gap-xs — Cancel / Submit */
  margin-top: 8px;
}
```

Rules:

- **Field gap is `gap-sm` (16 px).** Not 12, not 20. The whole app is built on this rhythm.
- **Action row is always right-aligned.** Cancel left, primary right.
- **Don't separate fields with `<hr>`.** Use `.hm-section-title` (§ 18) between logical groups.

### 10.3 Label Spec

```css
.hm-form-label {
  display: block;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  color: var(--hm-muted);
  margin-bottom: 6px;
}
.hm-form-label__required::after {
  content: ' *';
  color: var(--hm-error);
}
```

Rules:

- **Always associate the label with the input** (`<label for="…">` or via the field wrapper) — never wrap the input.
- **Required marker is a red `*` after the label** — never a separate "(required)" word.
- **Optional fields are not labeled "(optional)".** Required-ness is the marked exception, not the rule.

### 10.4 Form Input (`<UiFormInput>`)

A text input rendered inside `<UiFormField>`. Its visual contract is the same as `.hm-input` (§ 10.7.1) — same colors, same border, same focus treatment — but the wrapper handles the field-level concerns (label, error).

Variants documented by name:

| Variant   | Use case                                                  |
| --------- | --------------------------------------------------------- |
| `default` | Standard sized field inside a form                        |
| `dense`   | Denser fields (filter inputs in column headers)           |
| `table`   | Inline cell editing (matches table cell padding/height)   |

Don't pass per-call `class="..."` overrides for color/border. If a new shape is needed, add a variant.

### 10.5 Form Textarea (`<UiFormTextarea>`)

Same visual contract as the input plus `resize: vertical`. Min height 80 px. No horizontal resize.

### 10.6 Form Select (`<UiFormSelect>`)

Combobox-style select with a popover menu. Use this for **most** select use cases — it gives keyboard navigation, search, and proper z-index handling.

**Inside a form the trigger is a pixel-twin of `.hm-input`** (§ 10.7.1): same 12 px mono type, same 8 px radius, same 8/14 px padding, the same `--hm-bg` surface on a 1 px `--hm-border` ring that turns `--hm-accent` on focus. A select and the text field next to it are one control family — if they differ in height, type size, radius or grey, that is a bug. The popover's options carry the same 12 px type as the trigger. There is exactly **one form control height**: every size preset of the underlying library must land on it. A size is not a way to get a taller field, and the library's own dark palette has to be beaten as thoroughly as in § 11.2 — a "close enough" grey is the bug.

When the select is used as a **toolbar filter** (in a table controls bar, alongside the search input), the trigger must read as part of that one-row toolbar — same height as the search input and the buttons next to it. The trigger keeps its own internal padding from the size preset, so a wrapper height alone won't shrink it; the component exposes a dedicated **filter** affordance that renders the *trigger itself* as a pixel-twin of `.hm-input` — 30 px height, mono font, 8 px radius, **and the `--hm-bg` / `--hm-border` colours** (the library's default greys must be overridden, not left as "close enough"). See § 11.2 for the toolbar contract. Never force a select to toolbar height by constraining its wrapper — that leaves the inner trigger overflowing.

### 10.7 Bare Input Primitives (no form wrapper)

For surfaces where a plain styled `<input>` is needed without the field-wrapper machinery, the manifest provides three bare classes. Use them sparingly — only when the form wrapper can't be made to fit (custom popover, table inline-edit, search field with a clear button).

#### 10.7.1 `.hm-input`

```css
.hm-input {
  background: var(--hm-bg);
  border: 1px solid var(--hm-border);
  border-radius: 8px;
  padding: 8px 14px;
  color: var(--hm-text);
  font-size: 12px;
  font-family: 'JetBrains Mono', monospace;
  outline: none;
  transition: border-color 0.15s;
}
.hm-input:focus       { border-color: var(--hm-accent); }
.hm-input::placeholder { color: var(--hm-muted); }
.hm-input:disabled    { opacity: 0.5; cursor: not-allowed; }
.hm-input--error      { border-color: var(--hm-error); }
```

Background is `--hm-bg`, not `--hm-surface`. The input **recesses** into the card around it (surface/bg rule from § 1.1).

Used by table inline-edit, the toolbar search built into the data table, and as the base for `<UiSearchInput>` (§ 11.1).

#### 10.7.2 `.hm-select`

Native `<select>` styled with a baked-in chevron SVG. For selects rendered **inside modals** where a popover-based select would clip:

```css
.hm-select {
  width: 100%;
  padding: 8px 14px;
  padding-right: 32px;          /* room for the chevron */
  background: var(--hm-bg);
  border: 1px solid var(--hm-border);
  border-radius: 8px;
  font-size: 12px;              /* same type as .hm-input — one control family */
  /* …chevron via inline SVG background-image… */
  appearance: none;
  cursor: pointer;
}
```

The bare select is a **pixel-twin of `.hm-input`**, exactly like the form select of § 10.6 — same 12 px mono type, 8 px radius, 8/14 px padding. Type size is not cosmetic here: a select and an input with the same padding but different font sizes render **different heights**, and a field grid that mixes them (status / priority selects beside a numeric input) visibly breaks.

#### 10.7.3 Custom select panel (`<UiSelectMenu>`)

A custom-rendered select with a search input inside the dropdown panel — for long option lists. Use it where the form-select's popover would clash with surrounding chrome. Z-index is 50 per § 2.4.

#### 10.7.4 One control height (`--hm-control-height`)

Every single-line form control lands on one height, published as a token:

```css
:root { --hm-control-height: 36px; }

input.hm-input:not(.hm-controls-search):not(.hm-input--toolbar),
.hm-select {
  min-height: var(--hm-control-height);
}
```

The token is the floor, not the mechanism — controls reach it from their own type and padding; the `min-height` only guarantees that a font swap or a lighter control never drops below the family height. Toolbar controls (§ 11) are the one exception: they share their own 30 px height and are excluded. A select reaches the same height as its neighbour whichever implementation renders it — the popover select, the custom panel and the native one each land on the token, and so does every size preset of a wrapped library control.

### 10.8 Bulk Env Input (`<UiEnvBulkInput>`)

Specialized textarea for `KEY=VALUE` pairs. One pair per line. Empty lines and lines starting with `#` are ignored. Validation is inline — invalid lines get a red dot in the gutter, and the count of valid pairs renders below.

Use **instead of** an array of input rows when the user is pasting from a `.env` file or maintaining > 5 pairs. For ≤ 5 pairs, stick with individual `<UiFormInput>` rows so each pair is independently labelable.

### 10.9 Validation & Error Display

The field wrapper renders the error message under the field via its `error` prop / slot.

| State                   | Visual                                                                  |
| ----------------------- | ----------------------------------------------------------------------- |
| Pristine (untouched)    | Default border `--hm-border`                                            |
| Focused                 | Border `--hm-accent`                                                    |
| Error                   | Border `--hm-error`. Helper line below: 11 px, color `--hm-error`       |
| Success (rare)          | Don't render a "success" tick on text inputs. Only on toggle/checkbox.  |
| Disabled                | Opacity 0.5, cursor not-allowed                                         |

Rules:

- **Error text is one line.** If validation needs more, the field is wrong, not the message.
- **Errors render below the input** — never inline-right (which collides with input width on narrow viewports).
- **Don't shake or animate inputs on error.** A border-color change is enough.

### 10.10 What Forms MUST NOT Be

| Pattern                                              | Why                                                                  |
| ---------------------------------------------------- | -------------------------------------------------------------------- |
| Multi-column field layout                            | Vertical stack is the manifest. Use multiple cards for grouping.     |
| Inline labels (label left of input)                  | Top labels with uppercase styling are the rhythm of this UI          |
| `<input>` outside a field wrapper, in a real form    | Lose the label/helper/error story; only acceptable for bare primitives |
| Submit button on the left                            | Primary is always rightmost in a button row                          |
| Custom-styled select that doesn't match the manifest spec | Fork of the system — extend the variant set instead             |
| Hand-rolled `<input>` mimicking `<UiFormInput>`      | Use the wrapper — don't reinvent it per call site                    |

---

## 11. Search & Filter Inputs

Search and filter inputs are visually `.hm-input` (§ 10.4) with toolbar-tuned dimensions. They live in two places: the table controls bar (§ 9.2) — the global search plus any filter controls in the `controls-left` slot — and the column headers (when `filterBy` is set on a column).

**Every control in the toolbar shares one height: 30 px.** Search input, text filters, *and* select dropdowns all line up to that height so the controls bar reads as a single row. A toolbar filter that renders taller than its neighbours (the typical failure: a select left at its default form height) is a bug, not a style choice.

### 11.1 Toolbar Search (`.hm-controls-search`)

```css
.hm-controls-search {
  /* Inherits .hm-input — only overrides geometry */
  width: 220px;
  height: 30px;
}
```

Rules:

- **Width is fixed at 220 px.** Don't stretch it to fill the toolbar — a long search input visually competes with the table itself.
- **Height matches `<UiButton size="md">` and `.hm-toolbar-btn` (30 px)** so the toolbar is one clean row.
- **Placeholder is always "Search…"** Don't customize per page ("Search servers…") — the table title above already provides context.

#### 11.1.1 Toolbar Fields Outside a Table (`.hm-input--toolbar`)

A toolbar is not only a table controls bar. A row that puts a text field beside buttons — an editor's name bar, a page-level context picker with its action — is a toolbar too, and the same one-height rule holds: the field takes the 30 px of the buttons next to it, never the 36 px form height.

```css
.hm-input--toolbar {
  height: 30px;
  padding: 0 14px;
}
```

A select in such a row uses the filter affordance of § 11.2. A field with a label above it, in a vertical form, is a form field and keeps the form height — the modifier is for a single row of controls only.

### 11.2 Toolbar Filter Selects

Dropdown filters in the `controls-left` slot use `<UiFormSelect>` (§ 10.6) with its **filter** affordance enabled. This makes the *trigger button* — not just the wrapper — render as a pixel-twin of `.hm-input`: 30 px control height, mono font (12 px), 8 px radius, `--hm-bg` background, a 1 px `--hm-border` ring that turns `--hm-accent` on focus. Result: it is indistinguishable from the search input and text filters beside it.

```css
/* Global (NOT component-scoped) + !important on purpose — see the delivery rule
   below. The trigger keeps its own padding AND the library's default colours, so
   both geometry and colour are forced on the trigger itself, not the wrapper. */
.<select>--filter [trigger] {
  height: 30px !important;
  min-height: 30px !important;
  padding: 0 14px !important;
  border-radius: 8px !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-size: 12px !important;
  background: var(--hm-bg) !important;
  box-shadow: inset 0 0 0 1px var(--hm-border) !important;   /* 1px border via ring — no layout shift */
}
.<select>--filter [trigger]:focus {
  box-shadow: inset 0 0 0 1px var(--hm-accent) !important;
  outline: none !important;
}
```

Rules:

- **Enable the filter affordance for every toolbar select.** Don't reach for an intermediate `size` and hope it lands at 30 px — the size presets don't, and they vary per option count.
- **Never set `height` on the select *wrapper* to fake it.** The wrapper shrinks but the inner trigger keeps its padding and overflows — the exact "tall, mismatched, bright-bordered" box this rule exists to prevent.
- **Force the tokens past the library defaults.** A wrapped UI-kit select ships its own dark palette (a lighter grey background, a brighter grey ring) whose selectors out-specify plain token utilities — so the trigger reads visibly lighter/bluer than the `.hm-input` next to it until `--hm-bg` / `--hm-border` are applied with enough weight to win. Match the neighbour exactly; a "close enough" grey is the bug.
- **Deliver the trigger override as a *global* rule with `!important`, never a component-scoped one.** The trigger is a button the component library renders deep inside its own markup. A component-scoped style compiles to a selector keyed on the wrapper's scope id — which the library's root element doesn't reliably carry, so the rule silently never matches (the symptom: the open menu, themed through the component's config, looks right while the *closed trigger* stays grey and tall). Target the filter class globally and use `!important`, because the library's dark-mode colour selectors out-specify a plain class selector. The class is only ever on filter selects, so a global rule can't leak. Config-driven theming does reach the menu — but only the menu; the closed trigger's chrome needs the CSS escape hatch.
- **The open panel matches too — every state, not just the trigger.** The dropdown menu uses `--hm-surface` background, a 1 px `--hm-border` ring, `--hm-text` options, and the standard accent tint (`rgba(0,212,255,0.08)` background + `--hm-accent` text) for the active/hovered and selected rows. A wrapped UI-kit's menu ships its own grey panel (lighter background, brighter ring, white option text) whose colour classes carry a dark-mode variant the bare token classes don't — so when the kit *merges* your overrides with its defaults the defaults survive and win. Theme the menu through the component's config in **replace/override** mode (swap the slot's class string outright) rather than the default *merge* mode, so the tokens land cleanly. The closed trigger and the open panel are one component; both must read as `.hm-input`-family surfaces.
- **Layout width (e.g. `min-width: 160px`) stays a page concern.** The filter affordance only standardizes height, colour, font, and radius — never the width.

### 11.3 Filter Inputs (column header)

When a column declares `filterBy`, its header becomes a two-line: the label on top, a filter input below. The input type is picked from `filterType`:

| `filterType` | Renders                              | Notes                                    |
| ------------ | ------------------------------------ | ---------------------------------------- |
| `'text'`     | `.hm-input` at column-cell width     | Debounced 300 ms before emitting         |
| `'select'`   | Native `<select>` styled as `.hm-select` | Consumes `column.options`             |
| `'date'`     | Date input or `<UiDateRangeFilter>`  | See § 11.4                               |

Filter inputs are visually flatter than toolbar inputs (no border by default) so the header doesn't look like a second toolbar. They get a border on focus, like all `.hm-input`s.

### 11.4 Date Range Filter (`<UiDateRangeFilter>`)

<UiDateRangeFilter> — paired start/end date inputs with shortcut chips ("Today", "Last 7d", "Last 30d", "Custom"). Used both in the toolbar and in column-header filter slots.

Rules:

- **Shortcut chips set both dates atomically** — no in-between state where only one bound is set.
- **Custom mode reveals two date inputs side by side**, gap 8 px.
- **Empty range = no filter applied** — don't default to "last 7 days" silently. The user must opt in.
- **Days are the account's days.** A picked day runs from its first to its last instant in the account's timezone, and "Today" / "Last 7 days" are counted there — never in the browser's zone, which may differ. The filter's value is that pair of UTC instants.
- **One height with its row.** The trigger is a 30 px toolbar control; below 768 px it takes the touch height and 16 px type like the search beside it. A date field in a form is the form control height (§ 10.7.4).
- **Preset names are translated** like every other UI word.

### 11.5 Reset Filters

A "Reset filters" affordance — a neutral button at the toolbar height, rendered by the table itself after the filters — appears in `controls-left`, **only when at least one filter is active**. Clicking it emits `reset-filters` and clears everything in one step (including the global search input). **It keeps the rows-per-page choice**: the page size is the visitor's preference, not a filter.

### 11.6 Multi-Select Filter (`<UiMultiSelect>`)

A toolbar filter that takes **several values of one field** — kinds, statuses, owners. One per field, in `controls-left`. A single-value filter stays a § 11.2 select; a boolean stays a `<UiCheckbox>` (§ 13.6.4).

```vue
<UiMultiSelect
  v-model="filterProxies.status"
  :label="t('filters.status')"
  :options="statusOptions"   /* { label, value, count?, tone?, disabled? }[] */
/>
```

**Trigger** — a 30 px pixel-twin of the toolbar search (§ 11.1): 12 px mono, 8 px radius, `--hm-bg` on a 1 px `--hm-border` ring that goes `--hm-accent` @ 30 % on hover and `--hm-accent` when open or focused. What it shows:

| Chosen   | Trigger reads                                   |
| -------- | ----------------------------------------------- |
| nothing  | `Kind` (muted) — the filter's name              |
| one      | `Kind:` (muted) `Pod`                           |
| several  | `Kind` + a count chip (`--hm-accent` @ 10 % / 30 %, 10 px 600) |

While anything is chosen a 16 px `×` sits before the chevron and clears **this** filter without opening the panel. Width is the page's concern (min 150 px).

**Panel** — a § 16.1 dropdown (`--hm-surface`, 8 px radius, 4 px padding, the dropdown shadow), at least 248 px and at most 320 px wide, body-teleported so it layers above a modal. Top to bottom:

1. **A search field, always** — 30 px, magnifier inside, focused the moment the panel opens. Typing narrows the list (case-insensitive substring of the label) and draws the match in `--hm-accent` 700. This is the one deliberate deviation from § 16.4: a multi-select has no 8-option threshold — the field is the panel's entry point, not a fallback for long lists.
2. **A meta line** — 10 px Syne uppercase muted: `2 selected`, or `5 of 7 · 2 selected` while searching; on the right `All` (picks every *visible* option) and `Clear`, accent on hover. A divider below it.
3. **Options** — one row per value: a § 13.6 `.hm-check__input`, an optional still status dot (`tone`: ok / error / warning / active / paused — no pulse), the label, an optional right-aligned muted `count`. The highlighted row takes the `--hm-accent` @ 8 % tint; selection is shown by the box alone — a tinted row per chosen value would turn the list into stripes.
4. **`No matches`** — centered muted text when the search leaves nothing.

**Behaviour** — § 16.5 with one difference: **picking an option keeps the panel open** (several values are usually picked in a row). Click outside, `Escape` (focus back to the trigger) and `Tab` close it; `ArrowUp`/`ArrowDown` move the highlight; `Enter` toggles the highlighted option — after typing, the first match is highlighted, so type-and-Enter picks it. The value is emitted in the options' order, whatever the click order, so a URL or saved table state built from it is stable; a chosen value that is no longer among the options is kept, not silently dropped.

**Phone** (Mobility M11/M13/M16): the trigger and the search field take `--hm-control-height` and 16 px type, every option row is a 48 px target, the panel stays inside the 16 px gutter.

**As a form field** (`size="form"`) the same component picks several values inside a form — the engines a server runs, the scopes of a client. The trigger becomes a `.hm-input` twin at `--hm-control-height` (§ 10.7.4) spanning the field; `label` is the muted placeholder while nothing is chosen, and the chosen labels are listed comma-separated (a form is about *what* is chosen, so no count chip). The panel is the same.

| Don't                                                        | Why                                                         |
| ------------------------------------------------------------ | ----------------------------------------------------------- |
| A row of `<UiCheckbox>` for one field's values               | Grows with the data and pushes the toolbar onto two lines   |
| A page-local checkbox dropdown                               | Second implementation of the same role                      |
| Closing the panel on every pick                              | Forces one reopen per value                                 |
| Hiding the search below some option count                    | The field is where the panel is entered, at any length      |

---

## 12. Badges & Status Indicators

Three small affordances for surfacing state at a glance: badges (text), dots (icon-sized state), and pills (boxed label-value).

### 12.1 Badges (`.hm-badge`)

Text-only label, used for status in tables and inline next to titles.

```css
.hm-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.5px;
}
.hm-badge--ok      { background: rgba(16, 185, 129, 0.15); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.30); }
.hm-badge--error   { background: rgba(239, 68, 68, 0.15);  color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.30);  }
.hm-badge--default { background: rgba(107, 114, 128, 0.15); color: #6b7280; }
```

Rules:

- **Badge alpha is 0.15** — one notch above the standard ghost-button alpha because badges are smaller and need more presence.
- **`--default` has no border** by design — it's the "neutral / inactive" state and shouldn't compete with the active variants.
- **Don't add new color variants** without first promoting the underlying semantic to a status token (§ 1.2).

### 12.2 Status Dots (`.hm-dot`)

8×8 circle. Used inline next to labels (footer status, server health, connection state). The **only place glow is allowed** in the manifest.

```css
.hm-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}
.hm-dot--ok    { background: #10b981; box-shadow: 0 0 8px #10b981; animation: hm-pulse 2s   infinite; }
.hm-dot--error { background: #ef4444; box-shadow: 0 0 8px #ef4444; animation: hm-pulse 1.5s infinite; }
```

Rules:

- **Pulse is faster for error** (1.5 s vs 2 s) — error states should visually demand attention.
- **`flex-shrink: 0`** is mandatory. The dot must never compress in flex layouts.
- **No "warning" or "paused" dot variants.** Status dots are binary (live/dead). Use a badge for tri-state semantics.

### 12.3 Monitor Badge (`.hm-monitor-badge`)

A boxed counter/label combination, used for "monitoring active" type indicators in nav and header.

```css
.hm-monitor-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: linear-gradient(135deg, rgba(0, 212, 255, 0.10), rgba(124, 58, 237, 0.10));
  border: 1px solid rgba(0, 212, 255, 0.30);
  border-radius: 8px;
  padding: 6px 14px;
  font-size: 11px;
  color: var(--hm-text);
  font-family: 'JetBrains Mono', monospace;
}
```

The cyan→purple gradient is the only place that gradient pair appears in the manifest — it's the visual signature of "monitoring is on". Don't reuse it elsewhere.

### 12.4 Pills (footer & elsewhere)

Pill-style label (`label: value` format with a colored border). Defined for the footer (§ 6.2) but reusable.

```css
.hm-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--hm-border);
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--hm-muted);
}
.hm-pill--accent  { background: rgba(0, 212, 255, 0.08); border-color: rgba(0, 212, 255, 0.30); color: var(--hm-accent); }
.hm-pill--warning { background: rgba(245, 158, 11, 0.08); border-color: rgba(245, 158, 11, 0.30); color: #f59e0b; }
.hm-pill--ok      { background: rgba(16, 185, 129, 0.08); border-color: rgba(16, 185, 129, 0.30); color: #10b981; }
.hm-pill--error   { background: rgba(239, 68, 68, 0.08);  border-color: rgba(239, 68, 68, 0.30);  color: #ef4444; }
```

> **Today the footer pill lives under `.hm-footer__pill` / `.hm-footer__pill--env`.** The unification target is to promote it to a generic `.hm-pill` class, with the footer-specific positioning kept under the footer namespace.

### 12.5 Choosing Between Badge / Dot / Pill

| Need                                             | Use            |
| ------------------------------------------------ | -------------- |
| Single word state in a table cell                | `.hm-badge`    |
| Just live/dead next to a label                   | `.hm-dot`      |
| `key: value` chip (env, version, region)         | `.hm-pill`     |
| Counter ("3 monitors active")                    | `.hm-monitor-badge` (cyan/purple gradient is reserved for this) |

---

## 13. Toggles

A two-state on/off switch. Used for boolean settings where the on/off decision is independently meaningful (not part of a multi-option choice — that's a radio/select). The component is `<UiToggle>`; the form-side counterpart, committed on submit rather than applied at once, is `<UiCheckbox>` (§ 13.6).

### 13.1 Spec (`.hm-toggle`, `<UiToggle>`)

```vue
<UiToggle
  v-model="showRequestToasts"
  :label="t('generalSettings.showRequestToasts')"
  :hint="t('generalSettings.showRequestToastsDesc')"
/>
```

| Prop       | Type      | Default | Notes                                                      |
| ---------- | --------- | ------- | ---------------------------------------------------------- |
| `label`    | `string`  | —       | Required. A toggle without a label is forbidden (§ 13.4).   |
| `hint`     | `string`  | —       | Optional muted line under the label                        |
| `disabled` | `boolean` | `false` | Dims the row to 50 % and blocks the click                  |

`v-model` is the boolean. The row is a `<label>`, so clicking the text flips the switch; the real control is a visually hidden `<input type="checkbox" role="switch">`, which is what gives keyboard focus, Space to flip and a screen-reader name for free. The `.hm-toggle` span is only the visual.

```css
.hm-toggle {
  position: relative;
  width: 40px;
  height: 22px;
  border-radius: 11px;
  background: var(--hm-border);
  cursor: pointer;
  transition: background 0.2s;
}
.hm-toggle--active { background: var(--hm-accent); }

.hm-toggle__thumb {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #fff;
  position: absolute;
  top: 2px;
  left: 2px;
  transition: transform 0.2s;
}
.hm-toggle--active .hm-toggle__thumb { transform: translateX(18px); }
```

### 13.2 Composition

Toggles are always paired with a label — the label is **clickable** and toggles the state. This is the markup `<UiToggle>` renders:

```html
<label class="hm-toggle-row">
  <span class="hm-toggle-row__text">
    <span class="hm-toggle-row__label">Notifications</span>
    <span class="hm-toggle-row__hint">Show a toast for every request the page makes.</span>
  </span>
  <input type="checkbox" role="switch" class="hm-toggle__input" />
  <span class="hm-toggle" :class="{ 'hm-toggle--active': enabled }" aria-hidden="true">
    <span class="hm-toggle__thumb" />
  </span>
</label>
```

```css
.hm-toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  cursor: pointer;
}
.hm-toggle-row__label { font: 600 12px 'JetBrains Mono'; letter-spacing: 0.5px; color: var(--hm-text); }
.hm-toggle-row__hint  { font-size: 11px; line-height: 1.5; color: var(--hm-muted); }

.hm-toggle__input { /* visually hidden, never display:none — it must stay focusable */ }
.hm-toggle__input:focus-visible + .hm-toggle { box-shadow: 0 0 0 2px rgba(0, 212, 255, 0.3); }
.hm-toggle-row:has(.hm-toggle__input:disabled) .hm-toggle,
.hm-toggle-row:has(.hm-toggle__input:disabled) .hm-toggle-row__text { opacity: 0.5; }
```

Layout: label on the left, toggle on the right, justified across the row. This is the inverse of the form-label rule (§ 10.3, top-label) — toggles are dense, settings-style controls and inline label reads better. The input must precede the `.hm-toggle` span: the focus ring is drawn through the `+` sibling selector.

### 13.3 Toggle vs. Checkbox

| Use a toggle when…                                            | Use a checkbox when…                                     |
| ------------------------------------------------------------- | -------------------------------------------------------- |
| The change takes effect immediately (settings)                | The change is committed on form submit                   |
| The value is a standalone boolean                             | One option from a multi-select group                     |
| The control is in a settings/preferences surface              | The control is in a form alongside text inputs           |

### 13.4 What Toggles MUST NOT Be

| Pattern                                | Why                                                                  |
| -------------------------------------- | -------------------------------------------------------------------- |
| Toggle without an adjacent label       | "What does this toggle do?" is unanswerable from the toggle alone    |
| Three-state toggle (on / off / partial)| Use a select. Toggles are binary by definition.                      |
| Custom-colored thumb                   | Thumb is always white (`#fff`) — it's the contrast against the track |
| Toggle inside a button row             | Toggles are not "actions" — they're persistent state                 |
| A `<button>` styled as `.hm-toggle`    | It has no `checked` state for assistive tech and no label binding — use `<UiToggle>` |

### 13.5 Segmented Control (`<UiSegmentedControl>`)

Pick **one** value out of N short options, with all options visible. Use it for tab-style view switching (Ports vs Domains, Settings/Builds/Logs/etc) where the option set is small (2–8) and stable. For larger sets, fall back to `<UiHmSelect>` (§ 10.7.3).

> **Use a SegmentedControl, not a row of toggle-style buttons.** A row of `<UiButton :variant="active ? 'cyan' : 'neutral'">` with mutually exclusive state is exactly what this primitive replaces.

#### 13.5.1 Anatomy

```vue
<UiSegmentedControl
  v-model="activeTab"
  aria-label="Ingress view"
  :options="[
    { label: 'Ports', value: 'ports' },
    { label: 'Domains', value: 'domains' },
  ]"
/>
```

| Prop        | Type                                | Default | Notes                                   |
| ----------- | ----------------------------------- | ------- | --------------------------------------- |
| `options`   | `Array<{label, value, disabled?}>`  | —       | Required. Generic over `string \| number` |
| `size`      | `'sm' \| 'md'`                      | `'md'`  | `md` = 30 px height; `sm` = 26 px       |
| `ariaLabel` | `string`                            | —       | Strongly recommended for accessibility  |

`v-model` binds to the active value; clicking an option updates it (disabled options are inert).

#### 13.5.2 Spec (`.hm-segmented`)

```css
.hm-segmented {
  display: inline-flex;
  align-items: center;
  background: var(--hm-bg);
  border: 1px solid var(--hm-border);
  border-radius: 8px;
  padding: 2px;
  gap: 2px;
}

.hm-segmented__item {
  background: transparent;
  border: none;
  border-radius: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  color: var(--hm-muted);
  cursor: pointer;
}

.hm-segmented__item--active {
  background: rgba(0, 212, 255, 0.12);
  color: var(--hm-accent);
}
```

Heights are the control's **outer box**: `--md` = 30 px, `--sm` = 26 px — the items are 24 px / 20 px inside the 2 px padding and the 1 px frame. `md` is the toolbar height on purpose: a segmented control sits in a table controls bar (§ 11) or above a panel as its tabs, next to 30 px buttons, and must read as part of that one row. Size the items from the outer height, never the other way round. Border radius is 8 px on the wrapper, 6 px on items (one notch smaller — softer pill inside the frame).

The wrapper background is `--hm-bg` (recessed into surrounding card per § 1.1). The active item highlights with `--hm-accent` at 12 % alpha — slightly stronger than ghost-button alpha because items are smaller.

#### 13.5.3 When to use what

| Need                                                | Use                                  |
| --------------------------------------------------- | ------------------------------------ |
| Pick one of 2–8 short labels (mutually exclusive)   | `<UiSegmentedControl>`               |
| Pick one of many options (>8) or long labels        | `<UiHmSelect>` (§ 10.7.3)            |
| Toggle independent panels (multiple can be on)      | `<UiButton :variant="active ? 'cyan' : 'neutral'">` per panel |
| Boolean on/off, applied immediately (settings)      | `<UiToggle>` (§ 13.1)                |
| Boolean on/off, committed with the form             | `<UiCheckbox>` (§ 13.6)              |

#### 13.5.4 What SegmentedControl MUST NOT Be

| Pattern                                       | Why                                                              |
| --------------------------------------------- | ---------------------------------------------------------------- |
| Long-text labels (more than ~12 chars)        | Becomes too wide; use `<UiHmSelect>`                             |
| > 8 options                                   | Overflow risk; use `<UiHmSelect>`                                |
| No active option (all inactive)               | One value must always be selected — model is required, not optional |
| Multi-select (multiple active at once)        | That's a chip group, not a segmented control                     |
| Without `aria-label`                          | Accessibility: screen readers need the group's purpose           |

### 13.6 Checkbox (`<UiCheckbox>`, `.hm-check`)

The boolean control of a **form**: its value is committed on submit together with the text inputs around it (§ 13.3). Every checkbox on the platform is one of exactly two things — a `<UiCheckbox>` row, or a bare `.hm-check__input` in a table's selection column. A native `<input type="checkbox">` in a form, a `<UCheckbox>`, a `<button>` drawn as a box, or a per-page `.hm-checkbox` class are all forbidden.

#### 13.6.1 Anatomy

```vue
<div class="hm-check-group">
  <UiCheckbox
    v-model="form.isActive"
    :label="t('form.isActive')"
    :hint="t('form.isActiveHint')"
  />
  <UiCheckbox
    v-model="form.isMaintenance"
    variant="warning"
    :label="t('form.isMaintenance')"
    :hint="t('form.isMaintenanceHint')"
  />
</div>
```

| Prop       | Type                     | Default     | Notes                                                                 |
| ---------- | ------------------------ | ----------- | --------------------------------------------------------------------- |
| `label`    | `string`                 | —           | Required. The row is the `<label>`, so the text is the click target   |
| `hint`     | `string`                 | —           | Muted 11 px line under the label, aligned with it, not with the box   |
| `variant`  | `'default' \| 'warning'` | `'default'` | `warning` for a flag that puts the entity into a holding or degraded state (maintenance, mute) |
| `disabled` | `boolean`                | `false`     | Box and text dim to 50 %                                              |

`v-model` is the boolean. Consecutive checkboxes sit in a `.hm-check-group` (14 px gap); a single one sits in an ordinary form field spanning the full row.

Write the hint as **what happens when the box is on**, in one sentence, so the row explains itself the way a toggle row does: "When off, the monitor is not checked at all — no status updates, no incidents, no notifications."

#### 13.6.2 Spec

```css
.hm-check-group { display: flex; flex-direction: column; gap: 14px; }

.hm-check {
  display: grid;
  grid-template-columns: 14px 1fr;   /* box | label, hint spans column 2 */
  align-items: center;
  column-gap: 10px;
  row-gap: 4px;
  cursor: pointer;
}

.hm-check__input {
  appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 3px;
  background: var(--hm-bg);
  border: 1px solid var(--hm-border);
  transition: all 0.15s;
}
.hm-check__input:hover         { border-color: var(--hm-muted); }
.hm-check__input:focus-visible { border-color: var(--hm-accent); box-shadow: 0 0 0 2px rgba(0, 212, 255, 0.3); }
.hm-check__input:checked       { background: rgba(0, 212, 255, 0.1); border-color: var(--hm-accent); }
.hm-check__input:checked::after { /* 4 × 7 px tick, 2 px accent stroke, rotated 45° */ }
.hm-check__input:disabled      { opacity: 0.5; cursor: not-allowed; }

.hm-check__label { font: 600 12px 'JetBrains Mono'; letter-spacing: 0.5px; color: var(--hm-text); }
.hm-check__hint  { grid-column: 2; font-size: 11px; line-height: 1.5; color: var(--hm-muted); }

.hm-check--warning .hm-check__label            { color: var(--hm-warning); }
.hm-check--warning .hm-check__input:checked    { background: rgba(245, 158, 11, 0.1); border-color: var(--hm-warning); }
```

The box is drawn, not native: `appearance: none` on the input itself, so it stays a real checkbox for the keyboard and for assistive tech while taking the design system's 14 px box and 3 px radius. The tick is the accent, never white-on-accent — a filled cyan square is a button, not a checkbox.

#### 13.6.3 Table selection

A selection column in a table (§ 11) uses the bare input with an `aria-label`, because the row already is the label:

```html
<input type="checkbox" class="hm-check__input" :aria-label="`Select ${row.name}`" />
```

When the rows carry a status, a checked box may take that status colour through a tone modifier on the input — `hm-check__input--ok`, `--error`, `--warning`, `--muted` — so a multi-select over mixed rows still reads the status at a glance. Tone modifiers are for table selection only; a form checkbox is always the accent (or `variant="warning"`).

#### 13.6.4 Filters

A boolean filter in the controls bar (§ 9.2, `controls-left`) is a `<UiCheckbox>` too — "Unread only", "Mine". It is not a bordered pill with a check icon: that shape is a button, and § 9.2 already has one.

#### 13.6.5 What Checkboxes MUST NOT Be

| Pattern                                          | Why                                                                          |
| ------------------------------------------------ | ---------------------------------------------------------------------------- |
| Native `<input type="checkbox">` in a form       | Browser-drawn, 13 px, wrong radius, no hint slot — use `<UiCheckbox>`         |
| `<UCheckbox>` (Nuxt UI)                          | Second implementation of the same role — 20 px box, different focus ring     |
| `<button>` or `<span>` drawn as a box            | No `checked` state, no label binding, no keyboard                            |
| A page-local `.hm-checkbox` / `.rf-checkbox`     | The primitive is `.hm-check` in the shared base; a copy drifts               |
| Label without a `hint` for a non-obvious flag    | "Skip consent" or "Internal" means nothing without the one-line consequence  |
| `accent-color` on a native input                 | Recolours the browser's box; it is still the browser's box                   |
| A checkbox that acts immediately                 | That is a toggle (§ 13.3)                                                    |

---

## 14. Modals

A modal is a focused, blocking surface for a single decision or short workflow. If a modal grows past one screen of content, it's the wrong container — promote it to a dedicated page.

### 14.1 Overlay (`.hm-modal-overlay`)

```css
.hm-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
}
```

Rules:

- **`z-index: 100`** per the stack (§ 2.4). Modals beat dropdowns (50) and the sticky header (10).
- **Always `position: fixed; inset: 0`.** Never `absolute` — the overlay must cover the viewport regardless of scroll.
- **Backdrop blur is 4 px.** Don't increase it — heavier blur reads as "frosted glass," which fights the terminal aesthetic.
- **Overlay is centered both axes.** No top-anchored modals.

### 14.2 Modal Container (`.hm-modal`)

```css
.hm-modal {
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 14px;
  padding: 24px;
  width: 520px;
  max-width: 90vw;
  max-height: 90vh;
  overflow-y: auto;
}

.hm-modal--sm  { width: 380px; }
.hm-modal--md  { width: 520px; }   /* default — same as base */
.hm-modal--lg  { width: 720px; }
.hm-modal--xl  { width: 960px; }
```

Rules:

- **Radius is 14 px** — one notch above cards (12) and tables (10) so modals read as "the topmost surface."
- **Padding is 24 px** on all sides. Don't reduce it — the modal is a focus surface, it should breathe.
- **Width snaps to one of the four sizes.** Don't pass arbitrary widths. If your form needs `--xl`, ask whether it should be a page instead.
- **`max-width: 90vw` and `max-height: 90vh`** are mandatory — modals that touch the viewport edges feel broken.
- **Vertical scroll is on the modal**, not on the body. Body scroll-lock is the consumer's job (`<UiModal>` handles it).

### 14.3 Title (`.hm-modal__title`)

```css
.hm-modal__title {
  font-family: 'Syne', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: var(--hm-text);
  margin-bottom: 20px;
}
```

The title is **always present** — even a confirmation modal has one ("Delete server?"). A modal without a title is disorienting.

### 14.4 Footer / Action Row

Action buttons sit at the bottom of the modal, right-aligned, in the same `.hm-form-actions` row as forms (§ 10.2):

```html
<div class="hm-modal__footer">
  <UiButton variant="neutral" type="button" @click="close">Cancel</UiButton>
  <UiButton variant="primary" type="submit" :loading="isPending">Confirm</UiButton>
</div>
```

```css
.hm-modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid var(--hm-border);
}
```

Rules:

- **Cancel left, primary right.** Same as form actions (§ 10.2).
- **Destructive confirms use `red` for the primary**, not `primary`. "Delete" is `<UiButton variant="red">`.
- **One primary action per modal.** If you need two, the modal is doing two things — split it.
- **Top divider is mandatory.** It separates content from actions and frames the click target.

### 14.5 Behavior

| Trigger              | Behavior                                                 |
| -------------------- | -------------------------------------------------------- |
| Click on overlay     | Close modal — unless modal has `:dismissible="false"`    |
| Press `Escape`       | Close modal (always, even if `:dismissible="false"`?)   |
| Open                 | Focus the first focusable element; trap focus inside    |
| Close                | Restore focus to the element that opened the modal      |
| Body scroll          | Locked while open                                        |

> **`:dismissible` resolves the Escape question.** If `false`, `Escape` is also ignored — the user must click an explicit button. Use this only for irreversible mid-flow steps (in-progress 2FA, payment confirmation) where accidental dismiss has real cost.

### 14.6 Specialized Modals

The manifest does not enumerate every modal type — modals are composed from the base spec (§ 14.2) plus form/button primitives. Common patterns:

- **2FA / OTP entry** — `--sm` width, single tightly-scoped input, `:dismissible="false"` (irreversible mid-flow).
- **Confirm-delete** — `--sm` width, single `<p>` body, `[Cancel] [Delete (red)]` footer.
- **Form modal** — `--md` width, vertical field stack, `[Cancel] [Save (primary)]` footer.

Build new modals from `<UiModal>` by composing the base; don't fork the modal CSS.

### 14.7 What Modals MUST NOT Be

| Pattern                                                         | Why                                                                  |
| --------------------------------------------------------------- | -------------------------------------------------------------------- |
| Modal opening another modal (modal stacking)                    | Cognitive overload. Replace step 1's content in place.               |
| Modal without a title                                           | Disorienting — the title is the modal's purpose                      |
| Modal wider than `--xl` (960 px)                                | At that point it's a page, not a modal                               |
| Modal that scrolls horizontally                                 | Horizontal scroll inside a focus surface is a usability bug          |
| Side-by-side button groups (Cancel/Save) inside the body        | Action buttons live in the footer, not in body content               |
| Tabs across a modal                                             | A modal has one purpose. If it needs tabs, it's a page.              |

---

## 15. Popups & Toasts

Two transient surfaces: **popups** are anchored to a trigger (positioned floating panels — confirms, contextual menus), and **toasts** are stacked viewport-edge notifications.

### 15.1 Popup Container (`<UiPopupContainer>`)

`<UiPopupContainer>` is the render slot for all popups. Mounted once at the app root (sibling of the layout root), it owns the absolute-positioning context and the close-on-outside-click behavior.

Rules:

- **One container per app.** Never mount a second `<UiPopupContainer>` inside a page — popups stack inside the global one.
- **Z-index range: 50** (per § 2.4). Popups sit above tables and the header but below modals and toasts.
- **Outside click closes all open popups.** Escape closes the topmost popup.

### 15.2 Popup Box (`<UiPopupBox>`)

<UiPopupBox> — the visual container of a single popup. Anchored to a trigger element via `anchor` prop.

```css
.hm-popup {
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 8px;
  padding: 12px 16px;
  min-width: 200px;
  max-width: 320px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  font-size: 12px;
  color: var(--hm-text);
}
```

> **Box-shadow on popups is the one exception** to the no-shadow rule (§ 8.1). Popups float over varied content; without the shadow, they visually merge with whatever is underneath.

| Anchor placement     | Default offset      | Use case                                |
| -------------------- | ------------------- | --------------------------------------- |
| `bottom-start`       | 8 px                | Default — menu-style popups             |
| `bottom-end`         | 8 px                | Right-anchored row actions              |
| `top-start`          | 8 px                | When trigger is near the viewport bottom |
| `right-start`        | 8 px                | Sidebar contextual popups               |

Rules:

- **Use a popup, not a modal**, for confirms that don't need full attention ("Remove this tag?").
- **Popups don't lock body scroll.** Scrolling the page closes them (or repositions, if `:reposition-on-scroll="true"`).
- **Don't put forms in popups.** Anything that needs > 2 inputs goes in a modal.

### 15.3 Toasts (`<UiToast>` / `<UiToastsContainer>`)

<UiToast> + <UiToastsContainer> — stacked notifications anchored to the bottom-right of the viewport.

```css
.hm-toasts {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 100;
  display: flex;
  flex-direction: column-reverse;   /* newest on top */
  gap: 8px;
  pointer-events: none;             /* container is click-through */
}

.hm-toast {
  pointer-events: auto;             /* individual toasts ARE clickable */
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 8px;
  padding: 12px 16px;
  min-width: 280px;
  max-width: 420px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  color: var(--hm-text);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.hm-toast--success { border-left: 3px solid var(--hm-ok);    }
.hm-toast--error   { border-left: 3px solid var(--hm-error); }
.hm-toast--info    { border-left: 3px solid var(--hm-accent); }
.hm-toast--warning { border-left: 3px solid var(--hm-warning); }
```

Rules:

- **Anchored bottom-right.** Don't move toasts to top-right or center — bottom-right is the canonical position.
- **Newest on top.** `flex-direction: column-reverse` so the latest toast appears at the top of the stack.
- **Auto-dismiss timing**: success/info = 4 s, warning = 6 s, error = **never** (user must dismiss). Errors are too important to vanish.
- **Type stripe is a 3 px left border**, mirroring `.hm-table-row--ok/--error`. Same vocabulary across the app.
- **Z-index: 100** — same layer as modals; toasts must surface even over open modals. Because the layer is shared, the container must also come **after** the modal/popup container in the app root's DOM order (see § 2.4) — otherwise the modal's `backdrop-filter` blurs the toasts away.
- **Container is `pointer-events: none`** so clicks pass through the toast gutter to the page underneath; individual toasts opt back in.

### 15.4 Toast Composition

```
┌────────────────────────────────────┐
│ ⓘ  Title                       ✕ │
│    Optional one-line description.  │
└────────────────────────────────────┘
```

- **Icon (left)** — semantic, matches the type (✓ / ✗ / ⓘ / ⚠)
- **Title (one line)** — primary message
- **Description (optional one line)** — context, never wrap to 3+ lines
- **Close button (top-right)** — always present, always works

If a notification needs more than two lines, it doesn't belong in a toast — link to the page or open a modal from the toast.

### 15.5 What Popups & Toasts MUST NOT Be

| Pattern                              | Why                                                                |
| ------------------------------------ | ------------------------------------------------------------------ |
| Toast that auto-dismisses errors     | Errors must persist until acknowledged                             |
| Popup containing a multi-input form  | Use a modal — popups are for short, anchored interactions          |
| Stacked popups (popup over popup)    | Close the first before opening the second                          |
| Toast at top of viewport             | Bottom-right is the cross-service standard                         |
| Toast wider than 420 px              | Above 420 px it's a card or banner, not a transient notification   |

---

## 16. Dropdowns & Menus

A dropdown is a positioned panel anchored to a trigger, containing a vertical list of items. Three concrete uses in the manifest: `NavDropdown` in the header (§ 4.4), the row-action menu in `<UiTableActions>`, and the option panel of `<UiHmSelect>` (§ 10.7). All three share one base spec.

### 16.1 Panel (`.hm-dropdown`)

```css
.hm-dropdown {
  position: absolute;
  top: calc(100% + 8px);    /* 8 px below the trigger by default */
  min-width: 180px;
  max-width: 320px;
  max-height: 60vh;
  overflow-y: auto;
  background: var(--hm-surface);
  border: 1px solid var(--hm-border);
  border-radius: 8px;
  padding: 4px;             /* gives items breathing room from the panel edge */
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 50;
}

.hm-dropdown--right { right: 0; left: auto; }
.hm-dropdown--up    { top: auto; bottom: calc(100% + 8px); }
```

Rules:

- **Panel border-radius is 8 px** — same as buttons and inputs, smaller than cards. Panels are interactive surfaces, not content surfaces.
- **Box-shadow is allowed** (same exception as popups, § 15.2).
- **Always `max-height: 60vh` + `overflow-y: auto`.** A dropdown that takes the full viewport height is a select picker, not a menu.
- **Z-index: 50.** Dropdowns sit above the table/header but below modals and toasts.
- **Default anchor is `bottom-start`** (top-left aligned with trigger). Use `--right` for trigger-right alignment, `--up` when the trigger is near the bottom of the viewport.

### 16.2 Item (`.hm-dropdown__item`)

```css
.hm-dropdown__item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 6px;          /* sub-radius — softer than the panel */
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  color: var(--hm-text);
  cursor: pointer;
  transition: background 0.15s;
}
.hm-dropdown__item:hover           { background: rgba(0, 212, 255, 0.08); }
.hm-dropdown__item--active         { background: rgba(0, 212, 255, 0.10); color: var(--hm-accent); }
.hm-dropdown__item--danger         { color: var(--hm-error); }
.hm-dropdown__item--danger:hover   { background: rgba(239, 68, 68, 0.10); }
.hm-dropdown__item:disabled,
.hm-dropdown__item[aria-disabled]  { opacity: 0.5; cursor: not-allowed; }
```

| Modifier   | Use case                                                  |
| ---------- | --------------------------------------------------------- |
| (base)     | Standard menu item                                        |
| `--active` | Currently selected (in `<UiHmSelect>`) or current route   |
| `--danger` | Destructive action (Delete, Remove)                       |

### 16.3 Section Headers & Dividers

For grouping items inside a long dropdown:

```css
.hm-dropdown__heading {
  padding: 8px 12px 4px;
  font-family: 'Syne', sans-serif;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--hm-muted);
}
.hm-dropdown__divider {
  height: 1px;
  background: var(--hm-border);
  margin: 4px 0;
}
```

Use a heading when the dropdown has 8+ items split into clear groups. Use a divider when the bottom group is qualitatively different (e.g. destructive actions separated from navigation items).

### 16.4 Search-in-Dropdown

`<UiHmSelect>` and any future "long-list" picker put a `.hm-input` at the **top** of the panel (`<UiMultiSelect>`, § 11.6, always has one):

```html
<div class="hm-dropdown">
  <input class="hm-input hm-dropdown__search" placeholder="Search…" />
  <div class="hm-dropdown__list">…</div>
</div>
```

Rules:

- **Search shows up only when `options.length >= 8`.** Below that threshold, scanning is faster than typing. The multi-select filter is the exception — its search is always there (§ 11.6).
- **Search input is sticky** at the top of the panel as the list scrolls.
- **Empty result state**: a `.hm-empty-state`-style centered "No matches" message inside the panel (§ 19).

### 16.5 Behavior

| Trigger              | Behavior                                                       |
| -------------------- | -------------------------------------------------------------- |
| Click outside panel  | Close                                                          |
| Press `Escape`       | Close, return focus to the trigger                             |
| `ArrowUp`/`ArrowDown`| Move focus between items                                       |
| `Enter`              | Activate focused item                                          |
| `Tab`                | Close panel, move focus to next page element                   |
| Item click           | Activate the item, close the panel (a multi-select toggles and stays open, § 11.6) |

These are non-negotiable accessibility behaviors. If a new dropdown is built, it must implement all six.

### 16.6 NavDropdown vs. Generic Dropdown

The `NavDropdown` in the header (§ 4.4) is a **specialization** of `.hm-dropdown` — its trigger is `.hm-nav-link` and its items use the same nav-link styling for visual continuity with the header. Apart from the trigger and item styling, the panel itself uses the generic `.hm-dropdown` spec.

### 16.7 What Dropdowns MUST NOT Be

| Pattern                                           | Why                                                              |
| ------------------------------------------------- | ---------------------------------------------------------------- |
| Dropdown without a click-outside / Escape handler | Accessibility violation                                          |
| Dropdown wider than 320 px                        | Above that, use a popover or modal                               |
| Two dropdowns open at once                        | Opening one closes the other                                     |
| Dropdown with a form inside                       | Use a modal — dropdowns are for selection / single actions       |
| Custom indent / hierarchical tree                 | Tree views are a separate component; don't shoehorn into menus   |

---

## 17. Loaders & Progress

Three loading affordances: an inline circular spinner, a top-of-page progress bar for navigation, and a static linear progress bar for known-percent operations.

### 17.1 Circular Loader (`<UiCircularLoader>`)

The single spinner primitive. Inherits `currentColor` so it adopts the surrounding text color.

```css
.hm-spinner {
  display: inline-block;
  width: 1em;          /* sized by font-size of the parent */
  height: 1em;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: hm-spin 0.8s linear infinite;
}
@keyframes hm-spin {
  to { transform: rotate(360deg); }
}
```

Rules:

- **Sized in `em`**, never px. The loader scales to whatever it sits in (a 12 px button, a 20 px stat card, a 48 px overlay).
- **Color is `currentColor`.** Don't pass a color prop — the consumer sets it via `color: var(--hm-accent)` on a wrapper.
- **Used inside `<UiButton>` when `loading` is true** (replaces the label, see § 7.1).
- **Used as the table loading overlay** (§ 9.6) at 48 px size, centered, color `--hm-accent`.
- **Never center the spinner with `transform`.** The `hm-spin` animation owns `transform`
  (it animates `rotate()`), so a `transform: translate(-50%, -50%)` on the same element is
  overridden the moment the animation runs — the spinner snaps off-center and appears to
  drift instead of rotating in place. When absolutely positioning the spinner (button
  loader, overlay), center it with negative margins (`top/left: 50%` + `margin: -0.5em`,
  since the loader is `1em²`) or a non-transformed wrapper — leave `transform` free for the
  animation.

### 17.2 App Loading Indicator (`<UiAppLoadingIndicator>`)

A top-of-viewport progress bar that shows during route navigation and global suspense boundaries.

```css
.hm-app-loader {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: transparent;
  z-index: 100;
  pointer-events: none;
}
.hm-app-loader__bar {
  height: 100%;
  background: linear-gradient(90deg, var(--hm-accent), var(--hm-purple));
  transition: width 0.2s ease-out, opacity 0.3s;
  box-shadow: 0 0 8px rgba(0, 212, 255, 0.5);
}
```

Rules:

- **2 px tall, top of viewport, full width.** Don't change the geometry per route.
- **Cyan→purple gradient** — the same pair that signals "monitoring active" in `.hm-monitor-badge` (§ 12.3). Reusing it here ties "the app is doing something" to the same visual language.
- **Glow shadow is allowed here** (and only here) on a non-status surface. The exception is justified because the bar is a transient, viewport-edge ribbon — it doesn't compete with content.
- **Auto-managed** by the framework's navigation/loading hooks. Page-level code never starts/stops the bar manually.

### 17.3 Linear Progress (`.hm-progress`)

For known-percent operations — file uploads, deployment progress, batch ops.

```css
.hm-progress {
  height: 3px;
  border-radius: 2px;
  background: var(--hm-border);
  overflow: hidden;
}
.hm-progress__bar {
  height: 100%;
  border-radius: 2px;
  animation: hm-fill-in 1.2s ease forwards;
}

.hm-progress__bar--ok       { background: var(--hm-ok); }
.hm-progress__bar--accent   { background: var(--hm-accent); }
.hm-progress__bar--error    { background: var(--hm-error); }
.hm-progress__bar--warning  { background: var(--hm-warning); }

@keyframes hm-fill-in {
  from { width: 0; }
}
```

Rules:

- **3 px tall.** Same height across all uses — taller bars distract from the value they're paired with.
- **Track is `--hm-border`**, not `--hm-bg`. The 1-step-darker contrast is what makes the progress visible.
- **`hm-fill-in` is fire-and-forget** — it animates from 0 to the target width on mount. For continuous updates, set `width` directly via `:style` and don't rely on the animation.
- **Bar color carries semantics**: `--ok` for healthy progress, `--error` for failed/error step, `--warning` for paused/throttled.

### 17.4 Skeletons

The manifest does **not** ship skeletons. The reasoning: data-dense tables look strange when rendered as gray rectangles, and the table loading overlay (§ 9.6) handles the same use case more honestly ("we're fetching, here's a spinner"). If a skeleton pattern becomes necessary later, it must be added to this section first.

### 17.5 What Loaders MUST NOT Be

| Pattern                                       | Why                                                                  |
| --------------------------------------------- | -------------------------------------------------------------------- |
| Spinner sized in px                           | Doesn't scale with surrounding text; breaks at different font sizes  |
| Multiple spinners on one page                 | One global spinner (table overlay or button loader) at a time        |
| Linear progress without a known percent       | Use a spinner — fake progress bars are dishonest UX                  |
| Custom-color spinner (not `currentColor`)     | Color is set by the parent's `color`, not by the spinner             |
| Top-bar loader during data fetches            | The top bar is for navigation/suspense only; data uses table overlay |

---

## 18. Section Titles & Dividers

Section titles structure long pages and modal bodies into scannable chunks. The manifest has one canonical title style — a small uppercase label followed by a horizontal rule that fills the remaining row.

### 18.1 Section Title (`.hm-section-title`)

```css
.hm-section-title {
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: 'Syne', sans-serif;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--hm-muted);
}
.hm-section-title::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--hm-border);
}
```

Render:

```
NETWORK ─────────────────────────────────────────────────────
```

Rules:

- **The trailing rule is part of the title**, not a separate `<hr>`. The `::after` pseudo-element fills whatever row width remains.
- **Always uppercase, always `letter-spacing: 1.5px`.** The wide tracking is what makes it read as a label, not a heading.
- **Color is `--hm-muted`** — section titles are wayfinding, not content. They should not pull focus.
- **Use Syne (display)**, not JetBrains Mono. The contrast between Syne titles and JetBrains body text is part of the visual rhythm.

### 18.2 Dividers

For separating items inside a row (footer meta, breadcrumbs, inline groups), use one of these:

| Pattern                                   | When to use                                              |
| ----------------------------------------- | -------------------------------------------------------- |
| `·` text separator (opacity 0.4)          | Inline between meta items (e.g. footer "v1.0 · build a1b2c3") |
| `.hm-header__nav-divider` (1×18 vertical) | Between groups of nav links in the header                |
| Horizontal `<hr>` styled `border-color: var(--hm-border)` | Avoid — use `.hm-section-title` instead |

> **Plain `<hr>` is discouraged.** The bare horizontal rule reads as a content break, but the manifest separates content via cards (§ 8) and section titles (§ 18.1). If you reach for `<hr>`, the structure is probably wrong.

### 18.3 Heading Hierarchy

The page has exactly one `<h1>` — the page title at the top of `.hm-canvas`. Beyond that:

| Tag    | Visual                          | Use case                              |
| ------ | ------------------------------- | ------------------------------------- |
| `<h1>` | `.hm-page-title` (22 px Syne 800) | Page title (one per page)           |
| `<h2>` | `.hm-section-title`             | Section within a page                 |
| `<h3>` | `.hm-modal__title` (15 px Syne) | Modal title, card heading              |
| `<h4>` | `.hm-stat-card__label` style    | Sub-label inside a card               |
| `<h5>`/`<h6>` | (don't use)              | If you need this depth, restructure   |

Semantic tags carry the hierarchy; class names carry the visual style. Don't conflate them.

---

## 19. Empty States & Banners

Surfaces for "nothing here yet" and "something went wrong." Both are designed to be quiet — the dark theme is loud enough.

### 19.1 Empty State (`.hm-empty-state`)

```css
.hm-empty-state {
  text-align: center;
  padding: 40px;
  color: var(--hm-muted);
  font-size: 13px;
}
```

Used as:

- The empty placeholder inside `<UiTable>` (§ 9.6)
- The "No matches" state inside `<UiHmSelect>` dropdown search (§ 16.4)
- The default "Nothing here" surface on a page with zero data

Rules:

- **One line of copy** — "No servers configured", "Nothing found", "No active alerts". Not a paragraph, not a full marketing-style empty state.
- **Optional icon above the text** — 32 px, color `--hm-muted`. Usually an inbox / search / alert icon matching the context.
- **Optional CTA below** — a single `<UiButton variant="cyan" size="md">` to guide the next action ("Create server"). Never two CTAs.
- **No illustrations.** This is a control center, not an onboarding flow.

### 19.2 Banner (`<UiBanner>` / `.hm-banner`)

For inline messages that are **page-level**, not field-level. Field errors stay under the input (§ 10.9).

```css
.hm-banner {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 12px 16px;
  border-radius: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
}
.hm-banner--error   { background: rgba(239, 68, 68, 0.08);  border: 1px solid rgba(239, 68, 68, 0.30);  color: #ef4444; }
.hm-banner--warning { background: rgba(245, 158, 11, 0.08); border: 1px solid rgba(245, 158, 11, 0.30); color: #f59e0b; }
.hm-banner--info    { background: rgba(0, 212, 255, 0.08);  border: 1px solid rgba(0, 212, 255, 0.30);  color: var(--hm-accent); }
.hm-banner--ok      { background: rgba(16, 185, 129, 0.08); border: 1px solid rgba(16, 185, 129, 0.30); color: #10b981; }
```

| Variant   | Use case                                                          |
| --------- | ----------------------------------------------------------------- |
| `error`   | API call failed; permission denied; destructive prerequisite      |
| `warning` | Stale data; about-to-expire; degraded mode                        |
| `info`    | Neutral notice; informational state                                |
| `ok`      | Success notice (rare — toasts handle most success acknowledgments) |

Composition:

```html
<UiBanner variant="error" icon="exclamation-triangle">
  Failed to load servers. <a href="…" class="underline">Try again</a>
</UiBanner>
```

### 19.3 What Empty States & Banners MUST NOT Be

| Pattern                                         | Why                                                              |
| ----------------------------------------------- | ---------------------------------------------------------------- |
| Empty state with multiple CTAs                  | Decision paralysis on an empty surface; pick one primary action  |
| Empty state with an illustration                | Not the manifest's aesthetic; this is a control center           |
| Banner with a dismiss button on a critical error | Don't let users dismiss errors that block their next action     |
| Stacked banners (3+ at once)                    | Consolidate into a list inside one banner                        |
| Banner used for a field error                   | Field errors live under the input (§ 10.9)                       |

---

## 20. Icons

Icons are sourced from a single component, sized from a small fixed scale, and colored via `currentColor`. There is no per-page icon library.

### 20.1 Icon Component (`<UiAppIcon>`)

<UiAppIcon> is the single icon-rendering component. It accepts:

| Prop          | Type                              | Notes                                        |
| ------------- | --------------------------------- | -------------------------------------------- |
| `name`        | `string`                          | Icon identifier (sprite key)                 |
| `paint`       | `'fill' \| 'stroke' \| 'auto'`    | Default `'auto'` (lets the SVG decide)       |
| `color`       | `string`                          | Override fill/stroke color (rare — see § 20.3) |
| `class`       | `string`                          | Tailwind size utilities (`w-4 h-4`)          |

The component renders an inline SVG (sprite reference) so icons inherit `color` and `font-size` from the parent. CSS rule from `main.css`:

```css
.nuxt-icon svg { fill: currentColor; }
```

### 20.2 Size Scale

Pick from this table — don't pass arbitrary sizes.

| Size  | Tailwind    | Use case                                                                 |
| ----- | ----------- | ------------------------------------------------------------------------ |
| 12 px | `w-3 h-3`   | Inline with 11–12 px text (button label icon, badge icon)                |
| 14 px | `w-[14px] h-[14px]` | Toolbar icon button (`.hm-toolbar-btn`), small inline indicators |
| 16 px | `w-4 h-4`   | Default icon — paired with 13 px body text                               |
| 18 px | `w-[18px] h-[18px]` | Row-expand chevron, dropdown item icons                          |
| 20 px | `w-5 h-5`   | Stat card label icon, header nav icons                                   |
| 24 px | `w-6 h-6`   | Modal title icon                                                          |
| 32 px | `w-8 h-8`   | Empty-state icon (above the text)                                        |
| 48 px | `w-12 h-12` | Table loading-overlay spinner                                            |

### 20.3 Color Rules

- **Default: `currentColor`.** Icons inherit the parent text color. Don't pass `color="white"` on a button — the button's `color` already cascades.
- **Use `color="var(--hm-accent)"` etc.** when you need a different tone than the parent (e.g. a muted icon next to bright text). Always use a token, never a hex.
- **Glow / shadow on icons is forbidden** — see § 1.2. The only glowing things are status dots.

### 20.4 Stroke vs. Fill

- **`paint="stroke"`** for outlined / hairline icons (Heroicons-outline style). Stroke width is baked into the SVG; don't override with CSS.
- **`paint="fill"`** for solid icons (Heroicons-solid style).
- **`paint="auto"`** (default) — the SVG decides. Most icons fall through to `currentColor` regardless.

The manifest doesn't enforce stroke vs. fill globally — pick the variant that matches the icon's role (outline for decorative/inline, solid for emphasis).

### 20.5 What Icons MUST NOT Be

| Pattern                                   | Why                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------- |
| Hard-coded color (`color="#fff"`)         | Use `currentColor` or a token                                        |
| Size outside the documented scale         | Pick the closest documented size                                     |
| Icon-only button without `aria-label`     | No screen reader text, no tooltip, no label = no accessibility       |
| Two icon libraries in one app             | One sprite source, accessed via `<UiAppIcon>`                        |
| Icon with `box-shadow` glow               | Glow is reserved for status dots                                     |

---

## 21. Transactional Email

Email is the one surface where none of the machinery above is available: no stylesheet, no
custom properties, no external assets, no flexbox worth trusting. The visual language is
therefore restated as a single **card on a dark canvas**, built from inline-styled tables,
and every message a product sends — confirmation code, welcome, sign-in alert, incident
alert, test notification — is assembled from the same fixed set of blocks. One layout, one
palette, one block vocabulary: a recipient should recognise the product from the shape of
the message before reading a word of it.

### 21.1 Email Palette

Email cannot read tokens, so the values are literal — and lifted one step from the in-app
scale, because clients that strip borders must still show the card separating from the
canvas. Status tints are **pre-blended against the card colour**; `rgba()` backgrounds are
dropped by some clients.

| Role              | Value     | Used for                                        |
| ----------------- | --------- | ----------------------------------------------- |
| Canvas            | `#0e1117` | Page background, inset detail boxes             |
| Card              | `#161b22` | The single content card                         |
| Border            | `#232a34` | Card border, detail-box border                  |
| Text              | `#e6edf3` | Product header, codes, field values             |
| Muted             | `#8a94a6` | Body copy, labels                               |
| Fine print        | `#5a6473` | Closing note, unsubscribe line                  |
| Accent            | `#2f81f7` | The one CTA button, links                       |
| Ok / Error / Warn | `#10b981` / `#ef4444` / `#f59e0b` | Status pill text and tints  |

### 21.2 Card Anatomy

Fixed 440px wide (`width:100%` + `max-width` so it collapses on phones), 12px radius, 32px
padding, on a canvas with 24px of breathing room. Content is a vertical stack in one order:

1. **Product header** — 18px/600 in Text. The product name, nothing else. No logo image.
2. **Intro** — one muted 14px/20px line saying why this message exists.
3. **Blocks** — 20px apart, from § 21.3.
4. **Fine print** — 12px/18px in Fine print: expiry, "you can ignore this", unsubscribe.

### 21.3 Block Vocabulary

| Block             | Shape                                                          |
| ----------------- | -------------------------------------------------------------- |
| **Paragraph**     | Muted 14px/20px body copy                                      |
| **Code**          | Muted label above 32px/700 digits, 8px letter-spacing          |
| **Button**        | Accent pill, white 14px/600 label, 8px radius — one per message |
| **Link**          | Muted note above the raw, wrapping URL — the button's fallback |
| **Fields**        | Label/value rows; muted 13px labels, Text values, `—` if empty |
| **Status change** | Two uppercase tone-tinted pills joined by `→`                  |
| **Details**       | Monospace 12px box on Canvas with a Border — errors, payloads  |

### 21.4 Hard Rules

- **Every message carries a plain-text alternative** rendered from the same blocks, and is
  delivered as `multipart/alternative`. HTML-only mail is not shippable.
- **Inline styles only.** No `<style>` block, no classes, no web fonts — the system font
  stack, and tables for layout.
- **No remote assets.** No tracking pixel, no hosted logo, no icon font; images are blocked
  by default and the message must be whole without them.
- **Escape every interpolated value.** A resource name, a user agent and an error body are
  all untrusted strings inside an HTML document.
- **One CTA.** A second button is a second decision; the copy-paste link is a fallback, not
  a competing action.
- **The unsubscribe line lives inside the card**, in Fine print — never appended after the
  document.

### 21.5 What Email MUST NOT Be

| Pattern                                    | Why                                                            |
| ------------------------------------------ | -------------------------------------------------------------- |
| A light-themed message                     | Same product, same surface language as the app                  |
| A per-message bespoke layout               | The card is the product's signature; blocks carry the variation |
| A raw hex outside § 21.1                   | The email palette is closed; blend a tint if you need one       |
| Copy shipped only as HTML                  | Text clients and previews get an empty message                  |
| A code the recipient must hunt for         | Codes are the largest element on the card, or they aren't codes |
| Dashboard chrome (headers, nav, cards grid)| Email is one card; the dashboard lives behind the button        |

---

## Appendix A — Animations

The manifest ships exactly three keyframe animations. New animations must be added to this list and justified.

```css
@keyframes hm-pulse {
  0%, 100% { opacity: 1;   }
  50%      { opacity: 0.4; }
}

@keyframes hm-fill-in {
  from { width: 0; }
}

@keyframes hm-spin {
  to { transform: rotate(360deg); }
}
```

| Animation     | Used by                              | Duration       |
| ------------- | ------------------------------------ | -------------- |
| `hm-pulse`    | `.hm-dot--ok` (2 s), `.hm-dot--error` (1.5 s) | Status dots only |
| `hm-fill-in`  | `.hm-progress__bar`                  | 1.2 s ease     |
| `hm-spin`     | `.hm-spinner` (CircularLoader)       | 0.8 s linear   |

Rules:

- **No bounce, no elastic, no spring.** Easing is `linear` or `ease` — the terminal aesthetic excludes playful motion.
- **Hover transitions are `0.15s` all** (buttons, inputs, links, dropdown items). Stick to it.
- **Toggle thumb transition is `0.2s transform`.** Slightly slower than hover so the throw reads as deliberate.

---

## Appendix B — Scrollbars

Custom scrollbars override the OS chrome to fit the dark theme. Applied globally to all scrollable surfaces.

```css
::-webkit-scrollbar              { width: 4px; height: 4px; }
::-webkit-scrollbar-thumb        { background: var(--hm-border); border-radius: 2px; }
::-webkit-scrollbar-thumb:hover  { background: var(--hm-muted); }
::-webkit-scrollbar-track        { background: transparent; }
```

Rules:

- **Width is 4 px** (both horizontal and vertical). Thin enough to be ignorable, wide enough to grab.
- **Thumb is `--hm-border` resting, `--hm-muted` on hover.** Don't tint it cyan — scrollbars are utility, not accent.
- **Track is transparent.** The scrollbar floats over the surface.
- **Firefox uses `scrollbar-width: thin; scrollbar-color: var(--hm-border) transparent;`** as the equivalent — not yet in `main.css` but should be added during portability work.

---

## Appendix C — Selection

Text selection uses an accent-tinted background so highlighted text is unmistakably "yours" — and stays visible against the dark canvas.

```css
::selection      { background: rgba(0, 212, 255, 0.30) !important; color: var(--hm-text) !important; }
::-moz-selection { background: rgba(0, 212, 255, 0.30) !important; color: var(--hm-text) !important; }
```

`!important` is intentional — third-party rich-text editors sometimes override selection styles, and the manifest reasserts.

---

## Appendix D — Native Input Chrome Resets

Browser-native chrome on `<input type="range">` and `<input type="number">` doesn't follow `color-scheme: dark` cleanly across engines. The manifest resets the visible parts so the dark theme stays consistent.

```css
/* Range input — hide the native thumb; visual thumb is drawn by the component */
input[type='range']::-webkit-slider-thumb,
input[type='range']::-moz-range-thumb {
  appearance: none;
  background: transparent;
  border: none;
  width: 0;
  height: 0;
}

/* Number input — hide the native spin buttons */
input[type='number']::-webkit-inner-spin-button,
input[type='number']::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
input[type='number'] {
  -moz-appearance: textfield;
}
```

These are global rules — applied even when the project doesn't ship a custom slider or number stepper, because they prevent native chrome from leaking through anywhere `<input type="range">` or `<input type="number">` is rendered (third-party libraries, native form controls, etc.).

