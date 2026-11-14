# Design Manifest — Mobility

> Companion to **[DESIGN_MANIFEST.md](DESIGN_MANIFEST.md)**. It is a **delta, not a
> replacement**: everything in the parent manifest still holds unless a rule here
> explicitly overrides it. Sections are numbered `M{n}` against the parent's `{n}`, so
> `M9` overrides `§ 9`, `M14` overrides `§ 14`, and so on. If a concern is not mentioned
> here, the parent's rule applies verbatim.

## Scope

The primary target is **the platform's own web frontends viewed in a phone browser** —
Chrome on Android and Safari on iOS. Everything below 768 px (the parent's single
breakpoint, § 2.6) is governed by this document, and it is delivered by the shared design
system, not per application:

| Surface | Governed by | Where it is implemented |
|---|---|---|
| `.hm-*` frontends ≤ 768 px | M1–M24, in full | `frontend-shared/assets/styles/hm-base.css` + `components/ui/*` |
| Same frontends > 768 px | The parent manifest, unchanged | same |
| Native Flutter apps (`*/mobile`) | **Appendix D** | each app's `lib/core/theme` + `presentation/` |

**A phone gets a different layout of the same product — never a different product.** The
palette, the two typefaces, the grid overlay, the flat surfaces and the neon status accents
are unchanged. What changes is everything the desktop system inherited from a mouse, a
keyboard and 1440 px of width.

---

## Philosophy

| Desktop assumption | Phone reality |
|---|---|
| Hover reveals affordances | There is no hover. Every affordance is visible at rest. |
| 30 px controls are comfortable | A finger needs 48. |
| A table shows 9 columns at once | A phone shows one column. Tables become cards. |
| The header carries every route | The header carries the logo. A bottom bar carries the routes. |
| A modal floats in the middle | A sheet rises from the bottom, under the thumb. |
| The footer reports app status | The footer is hidden; its slots move into the nav sheet. |
| The body is bezelled by an 8 px frame | The phone is the bezel. |

Porting a dense desktop screen unchanged is the failure this document exists to prevent.
It produces a page that is legible only to the person who built it.

---

## M0. How it is delivered

Three mechanisms, in this order of preference:

1. **`@media (max-width: 768px)` in `hm-base.css`.** Anything that is purely geometry —
   heights, gutters, radii, stacking, hidden chrome — lands here and reaches every
   frontend at once. No application ships its own mobile CSS.
2. **A responsive branch inside a shared `components/ui/*` component.** Used where the
   markup itself must change (a table row cannot become a card in CSS). The branch is
   chosen by a client-side media query, so SSR renders the desktop tree and the client
   swaps after mount — never a hydration mismatch.
3. **A shared component the application mounts once** (`<UiMobileNav>`). Used only where
   the application owns the data (its own nav entries, its own sign-out handler).

Rules:

- **No application-local mobile CSS.** A `@media (max-width: 768px)` block in an app's
  `main.css` is a fork of the design system; the rule belongs in `hm-base.css`.
- **No JavaScript user-agent sniffing.** The breakpoint is width, never device class — a
  narrow desktop window gets the phone layout and that is correct.
- **The layer is consumed as a tagged version.** A change here reaches the frontends only
  after `frontend-shared` is tagged and every consumer's dependency is bumped.

---

## M1. Design Tokens

### M1.1 Unchanged

The **entire colour system is carried over byte-for-byte** — core palette (§ 1.1), status
colours (§ 1.2), the opacity scale (§ 1.3), the token rules (§ 1.4). A mobile view that
invents a colour is off the manifest exactly as a desktop view is.

The surface/bg rule matters *more* on a phone, where surfaces nest deeper: an element **on**
the page background uses `--hm-surface`; an element **inside** a card or sheet uses
`--hm-bg` so it recesses. A row card inside the table container is therefore `--hm-bg`.

### M1.2 Mobile-only tokens

Geometry only — the palette stays closed.

```css
@media (max-width: 768px) {
  :root {
    --hm-control-height: 48px;   /* overrides the desktop 36px */
    --hm-touch-min: 48px;        /* minimum hit area, both axes */
    --hm-tabbar-height: 56px;    /* bottom navigation bar */
    --hm-safe-bottom: env(safe-area-inset-bottom, 0px);
  }
}
```

`--hm-safe-bottom` is added to every fixed bottom surface: the tab bar, the sheet footer,
the snackbar stack. A primary button under the iPhone home indicator is unpressable.

### M1.3 The hover step becomes the pressed step

The parent's `+0.10 alpha` interaction step (§ 1.3) is preserved — it fires on a different
event.

| State | Desktop | Phone |
|---|---|---|
| Resting | `0.08`–`0.10` | identical |
| Hover | +0.10 alpha | **does not exist** |
| Pressed (`:active`) | — | +0.10 alpha, for the duration of the touch |

Rules:

- **Nothing may be discoverable only on hover.** A control that reveals its border, label
  or icon on hover must render that state permanently below 768 px.
- **Sticky hover is a bug.** Mobile browsers leave `:hover` applied after a tap until the
  next tap elsewhere; interaction feedback that must not stick is guarded with
  `@media (hover: hover)`.
- **`title` tooltips do not exist on touch.** An icon-only control needs `aria-label`, and
  the icon must be unambiguous without the tooltip.

### M1.4 Shadow

The no-shadow rule (§ 8.1) stands. The parent's popup/toast exception is joined by the
bottom sheet: a surface that rises over content gets `0 -8px 24px rgba(0, 0, 0, 0.4)`.
Cards, rows, header and tab bar stay flat.

---

## M2. Layout

### M2.1 The bezel is removed

**`body { border: 8px solid #000 }` (§ 5.3) drops to `0` below 768 px.** This is the
parent's most explicit "app-wide constant", and it is deliberately overridden:

- 16 px of a 360 px viewport is 4.4 % of the width spent on decoration.
- The phone's own frame already does the job the border was drawing.
- It cannot coexist with `env(safe-area-inset-*)` — a black border inside a notch cut-out
  reads as a rendering bug, not a frame.

Nothing replaces it. Do not substitute a subtle border or an inset shadow.

### M2.2 Shell

```
┌──────────────────────────────┐
│ Logo            [actions]    │  ← .hm-header, sticky, 56–60px
├──────────────────────────────┤
│                              │
│   .hm-canvas                 │  ← 16px gutters, scrolls
│                              │
├──────────────────────────────┤
│  Dash   Incid   Notif   More │  ← .hm-tabbar, fixed, 56px + safe area
└──────────────────────────────┘
```

- `.hm-grid-bg` is unchanged: `position: fixed`, `--hm-accent` @ `0.03`, **40 px cells**.
  The cell size stays 40 px even at a quarter of the viewport width — scaling it down would
  make the phone view look like a different product.
- `.hm-footer` is `display: none`; its slots move into the nav sheet (M6).
- `.hm-canvas` reserves the tab bar's height in its bottom padding, so the last row of
  content is never trapped under the bar.

### M2.3 Spacing

| Token | Desktop | Phone | Use |
|---|---|---|---|
| `page-x` | 40 | **16** | Side gutters, every surface, no exceptions |
| `page-y` | 32 | **12** | Header padding, first content gap |
| `page-bottom` | 60 | **24 + tab bar + safe area** | Below the last element |
| `gap-lg` | 28 | **16** | Between major sections |
| `gap-md` | 20 | **12** | Between cards |
| `gap-sm` | 16 | **12** | Form rows |
| `gap-xs` | 12 | **8** | Between list cards, inline groups |

**16 px gutters are constant.** Full-bleed is allowed for exactly one thing: a
horizontally scrolling strip (stat cards), which cancels the gutter with a negative margin
and restores it as padding, so its first item still aligns with the content above.

### M2.4 Layer order

The z-index scale of § 2.4 gains one layer:

| z-index | Layer |
|---|---|
| 0 | `.hm-grid-bg` |
| 1 | `.hm-canvas` |
| 10 | `.hm-header` (sticky on mobile) |
| 50 | Dropdowns, popovers |
| **90** | **`.hm-tabbar`** |
| 100 | Modal/sheet overlays, toasts |

The tab bar sits **below** overlays: a sheet covers navigation, navigation never covers a
sheet. Toasts sit **above** the tab bar and offset themselves by its height.

### M2.5 Overflow

`overflow-x: hidden` on `<body>` stays mandatory and is load-bearing here: at 360 px any
un-wrapped desktop row would otherwise scroll the document sideways. Wide content scrolls
**inside its own container**, and only where the container was designed to (stat strip,
code block). A page that scrolls horizontally on a phone is a bug, never a layout choice.

---

## M3. Typography

Families, weights and the Latin-only Syne fallback are unchanged (§ 3.1). The scale
(§ 3.2) is unchanged with two floors imposed by the medium:

- **9 px does not exist below 768 px.** At arm's length it is decoration, not text.
  Promote to 10 px (non-interactive, uppercase, tracked) or 11 px (anything tappable).
- **Form controls render at 16 px.** Below 16 px, iOS Safari zooms the viewport on focus
  and never zooms back — the single most common "the mobile site is broken" report. This
  applies to `input`, `textarea` and `select`; it does **not** change button or label type.

Everything else keeps its desktop size. The page title stays 22 px, table cell type stays
13 px, badges stay 10 px.

---

## M4. Navigation

Replaces § 4. The desktop header is a single row carrying logo, every route, page actions
and identity. None of that fits at 360 px, and none of it is reachable by a thumb.

### M4.1 Header

Below 768 px the header keeps **only** the logo and the `#header-actions` teleport target.
Every nav link, every `NavDropdown` and every divider is hidden — navigation moves to the
tab bar.

```css
@media (max-width: 768px) {
  .hm-header { position: sticky; top: 0; padding: 12px 16px; }
  .hm-header__logo { font-size: 18px; }
  .hm-header__nav > *:not(#header-actions) { display: none; }
}
```

The `:not(#header-actions)` selector is deliberate: the teleport target must stay in the
DOM even when empty, or a page teleporting a button into it throws.

Rules:

- **The header is sticky, not fixed.** It scrolls with the document's own scroll position
  and never auto-hides — a header that hides on scroll makes the page feel unanchored.
- **Page actions still land in `#header-actions`** (§ 4.5) and stay capped at two.
- **No hamburger button.** The routes are in the tab bar, not behind a glyph.

### M4.2 Tab bar (`.hm-tabbar`)

The primary navigation surface below 768 px, mounted once by the application's layout as
`<UiMobileNav>` and fed the same nav entries the desktop header uses.

| Element | Spec |
|---|---|
| Bar | `position: fixed; bottom: 0`, full width, `--hm-surface`, 1 px `--hm-border` top, height 56 + safe area, `z-index: 90` |
| Item | Equal-width column, ≥ 48 px tall, 11 px JetBrains 600, **sentence case**, single line with ellipsis |
| Inactive | `--hm-muted` |
| Active | `--hm-accent`, plus a 2 px `--hm-accent` bar along the item's top edge |
| Count | The **first three** flat routes become tabs; a fourth, **More**, opens the nav sheet |

Rules:

- **Three tabs plus More.** Four labels at 360 px leave 90 px each, which fits an 11 px
  mono label of ~13 characters. Five would not.
- **Labels are always visible**, and they are the affordance — an unlabelled icon is a
  guess. Icons are optional and only rendered when the application supplies one.
- **Sentence case is a deliberate break from § 4.3's uppercase nav.** `NOTIFICATIONS` at
  11 px does not fit a four-slot bar; the shape of the word is what is being recognised.
- **Active is signalled by colour *and* the top bar** — colour alone fails for the
  colour-blind.
- **The bar never hides on scroll.**

### M4.3 Nav sheet (More)

A bottom sheet (M14) holding everything the bar could not: the remaining flat routes, every
`NavDropdown` group rendered as a titled section, then identity, then status.

```
─────  ▁▁▁  ─────        ← drag handle
Menu
  AGENTS
  UPTIME REPORT
  ADMIN ──────────────   ← group, as .hm-section-title
    Settings
  ────────────────────
  My Profile             ← .hm-nav-link--active
  Sign Out               ← .hm-nav-link--signout
  ────────────────────
  App v1.4.2 · build a1b2c3
  [● online] [env: dev]  ← the footer's slots (M6)
```

Rules:

- **Identity anchors stay last, in order** (§ 4.6): *My Profile*, then *Sign Out*, with the
  same modifiers. Consistency across services is the point, on a phone as on a desktop.
- **The sheet closes on: route change, scrim tap, drag-down, `Escape`, and back.** All of
  them; a nav sheet that survives navigation is a trap.
- **Body scroll is locked while it is open.**

---

## M5. Screens

The `<body>` contract of § 5 holds with two changes: the bezel is gone (M2.1) and
`100dvh` on the framework root becomes load-bearing rather than defensive — it is what
keeps the layout correct while the browser's URL bar collapses.

---

## M6. Status Reporting

Replaces § 6. There is no room for a footer: the bottom 56 px belong to navigation.
`.hm-footer` is hidden below 768 px and its **required slots move into the nav sheet**,
unchanged in content and styling:

| Footer slot | Phone home |
|---|---|
| `App v{version} · build {sha}` | Nav sheet, bottom, 10 px muted |
| Online/offline pill (`.hm-pill` + `.hm-dot`) | Nav sheet, same markup |
| Environment pill (`.hm-pill--accent`) | Nav sheet, same markup |

Rules:

- **The environment pill is still always rendered, including in production** (§ 6.3). The
  "wait, why is this staging" cue is worth more on a phone, not less.
- **Still no actions.** The status block is read-only.
- **Nothing is dropped.** A slot that has no room is relocated, never deleted — a phone
  user must be able to tell you which build they are looking at.

---

## M7. Buttons

Variants and composition rules (§ 7.3, § 7.4) are unchanged: one `primary` per view,
destructive is always `red`, cancel is `neutral`. Geometry changes.

| Property | Desktop | Phone |
|---|---|---|
| `.hm-btn` height | 30 | **44** |
| `.hm-btn--sm` height | 24 | **36** |
| Label | 11 px | **12 px** |
| Padding | 0 14px | **0 16px** |
| Radius | 8 | 8 |

Rules:

- **`.hm-form-actions` and `.hm-modal__footer` stack**: `flex-direction: column-reverse`
  with full-width buttons, so the DOM order `[Cancel] [Primary]` renders as **primary on
  top, cancel below**. The thumb rests at the bottom edge; the reflex tap must not be the
  destructive one.
- **Full-width is the norm for form submits on a phone**, inverting § 7.7's "full-width is
  a form-submit convention only" into the default inside forms and sheets. Elsewhere
  buttons stay content-width.
- **`.hm-icon-btn--toolbar` grows from 30 to 44 px**, and `.action-btn` gets a 44 × 44
  minimum. Their icons keep their size — the target grows, not the glyph.
- **Loading still replaces the label and must not change the width** (§ 7.4). On a mobile
  connection this state is visible for seconds.

---

## M8. Cards

`.hm-card` keeps its 12 px radius, its `--hm-surface` background and its ban on shadows.
Two changes:

### M8.1 Stat cards scroll (`.hm-stat-cards`)

The desktop row is equal-flex (§ 8.4). Six cards at 360 px would be 44 px each, and
stacking them vertically costs a whole screen of scrolling before the user reaches the
data. Below 768 px the row becomes a **horizontally scrolling strip**:

```css
@media (max-width: 768px) {
  .hm-stat-cards {
    flex-wrap: nowrap;
    overflow-x: auto;
    gap: 8px;
    margin: 0 -16px;      /* cancel the canvas gutter … */
    padding: 0 16px;      /* … and restore it as padding, so item 1 stays aligned */
  }
  .hm-stat-card { flex: 0 0 auto; min-width: 128px; padding: 12px 16px; }
}
```

The accent stripe (§ 8.2) and the left status bar (§ 8.3) are unchanged, and remain
mutually exclusive.

### M8.2 Row card (`.hm-mcard`)

The mobile replacement for a table row (M9). It sits inside the table container, so it
steps **down** to `--hm-bg` per § 8.5. It is a global class of the base stylesheet, not a
private part of the data table: a simple `.hm-table` (§ 9.8) renders the same cards below
the breakpoint, from the same cells, and hides its `<table>`.

```
┌──────────────────────────────────────────┐
│ Primary identifier                       │  ← 13 px semibold, wraps
│ STATUS      ● OK                         │  ← label / value pairs
│ CHECKED     2026-06-15 14:30:05          │
└──────────────────────────────────────────┘
```

| Part | Spec |
|---|---|
| Card | `--hm-bg`, 1 px `--hm-border`, radius 8, padding 12/14, min-height 56, gap 8 |
| Title | The first visible column's cell, 13 px JetBrains 600, no label |
| Field | A row per remaining visible column: `--hm-muted` Syne 10 px uppercase label on the left, the cell's own rendered value right-aligned |
| Tap | The whole card is the link when the table supplies a row link |

Rules:

- **The fields render the table's own cell slots.** A mobile card is a re-layout of the
  same content, never a second rendering path the application has to maintain.
- **Hidden columns stay hidden**; the user's column preferences carry over.
- **No card renders more than the visible columns.** If that is too many fields, the table
  has too many columns for a phone and should hide some by default (`defaultHidden`).

---

## M9. Tables become cards

Replaces § 9 below the breakpoint. **There are no data tables on a phone.**

### M9.1 The mapping

| Desktop | Phone |
|---|---|
| `.grid-table` row of N columns | One `.hm-mcard` (M8.2) |
| Column headers | Gone — each field carries its own label |
| Sort by clicking a header | A **sort bar** above the list: a `.hm-select` of sortable columns + a direction toggle |
| Column resize / reorder / visibility menu | Gone — all three are mouse affordances |
| Sticky columns, row expansion chevron | Gone |
| Toolbar search (220 px) | Full-width search field, 48 px |
| Toolbar buttons | Same buttons, 44 px targets, wrapped to their own row |
| Pagination bar | **Compact pagination**: prev / current / next, 44 px targets |
| CSV download | Kept — it is a link to a file, and it works |

> **Compact pagination, not infinite scroll.** The frontends are server-paginated and the
> page number is part of their state; swapping in infinite scroll would change the data
> contract of every list in the platform. Infinite scroll remains the native-app rule
> (Appendix D), not a web one.

### M9.2 Loading, empty, error

Unchanged in substance (§ 9.6): the loading overlay wins over the empty state, errors are a
`<UiBanner>` above the table, never inside it. The overlay's spinner drops to 32 px.

### M9.3 What must not happen

| Pattern | Why |
|---|---|
| A horizontally scrolling data table | The porting failure this section exists to prevent |
| A card carrying every column of a 12-column table | Hide columns by default instead |
| Row actions as 4 px icon buttons | Below the touch floor; give them 44 px |
| Hover-only row affordances | There is no hover |

---

## M10. Forms

§ 10's structure is unchanged — vertical stack, uppercase top labels, red `*`, one-line
errors below the field. Geometry and keyboard behaviour change.

| Property | Desktop | Phone |
|---|---|---|
| `--hm-control-height` | 36 | **48** |
| Control type size | 12 | **16** (M3) |
| Control padding | 8 / 14 | **12 / 14** |
| Field gap | 16 | 12 |
| Action row | Right-aligned row | **Stacked, full width, primary on top** (M7) |

The one-control-family rule still binds: `.hm-input`, `.hm-select` and the form select's
trigger must remain pixel twins. On a phone they land on 48 px together or the form looks
broken.

Rules:

- **Every field declares its keyboard**: `type="email"`, `type="url"`, `inputmode="numeric"`,
  `autocomplete`. A phone user typing an email on an alphabetic keyboard is a lost signup.
- **Autocorrect and autocapitalise are off** for identifiers, hostnames, tokens and codes.
- **A failed submit scrolls to the first invalid field.**
- Field errors stay under the field; form-level failures stay a banner, never a toast that
  auto-dismisses over a form the user is still editing.

---

## M11. Search & Filters

The controls bar (§ 9.2) keeps its slot order but **wraps**: the search row first, the
actions row second, both full width.

| Element | Phone |
|---|---|
| `.hm-controls-search` | `width: 100%`, height 48 (the desktop's fixed 220 px is a toolbar constraint that no longer exists) |
| `.hm-controls-bar` | `flex-wrap: wrap`; `__left` and `__right` each take the full row |
| `.hm-controls-bar__right` | Right-aligned, 44 px targets, refresh still rightmost (§ 9.2) |
| Filter selects | Full width or 50 % in a two-up row; still `.hm-input` twins |
| `.hm-input--toolbar` | Height 48 — the 30 px toolbar height is a pointer affordance; on touch it rejoins the control height |

The placeholder stays `Search…` (§ 11.1) — on the web the surrounding page title still
provides the context that a native app's generic app bar does not.

---

## M12. Badges & Status

Unchanged (§ 12), with one floor: badge and pill text does not go below 10 px (M3). Status
is never colour alone — the badge's word, or a `.hm-dot` beside a label, carries it. Glow
stays exclusive to status dots.

---

## M13. Toggles, Checkboxes & Segmented Controls

- `.hm-toggle` keeps its 40 × 22 visual; the **row** (`.hm-toggle-row`) is the target and
  must be ≥ 48 px tall with the label clickable (§ 13.2).
- `.hm-check` keeps its 14 px box; the labelled row is the target and lands on the same
  48 px floor (§ 13.6). A bare `.hm-check__input` in a table selection column is covered
  by the row card (M9), which is the target there.
- `.hm-segmented` goes **full width** below 768 px, items share the width equally, height
  40. Above 4 options it must become a select — at 360 px five labels truncate.

---

## M14. Modals become sheets

Replaces § 14.1–14.2 below the breakpoint. A centred modal is a desktop shape; on a phone
it rises from the bottom edge, where the thumb already is.

```css
@media (max-width: 768px) {
  .hm-modal-overlay { align-items: flex-end; }
  .hm-modal,
  .hm-modal--sm {
    width: 100%;
    max-width: 100%;
    max-height: 92vh;
    border-radius: 16px 16px 0 0;
    border-bottom: none;
    padding: 20px 16px calc(20px + var(--hm-safe-bottom));
    box-shadow: 0 -8px 24px rgba(0, 0, 0, 0.4);
  }
}
```

| Element | Spec |
|---|---|
| Radius | 16 px, **top corners only** |
| Handle | A 36 × 4 `--hm-border` bar above the title — the affordance that says "drag me down" |
| Title | Unchanged (§ 14.3), still mandatory |
| Footer | Stacked, full width, primary on top (M7) |
| Scrim | Unchanged: `rgba(0,0,0,0.6)` + 4 px blur |

Behaviour (§ 14.5) is unchanged — scrim tap, `Escape`, focus trap, body scroll lock — plus
**drag-down to dismiss** where the sheet is dismissible. `dismissible: false` disables all
of them together.

A sheet that needs more than 92 vh is a page. On a phone that threshold arrives much
sooner than on a desktop, so promote earlier, not later.

---

## M15. Toasts

`.hm-toasts` moves from the bottom-right corner — which does not exist at 360 px — to the
bottom edge, full width inside the gutters, **offset above the tab bar and the safe area**:

```css
@media (max-width: 768px) {
  .hm-toasts {
    left: 16px;
    right: 16px;
    bottom: calc(var(--hm-tabbar-height) + var(--hm-safe-bottom) + 8px);
    max-width: none;
  }
}
```

Everything else is unchanged: newest on top, the 3 px left type stripe, success/info 4 s,
warning 6 s, **errors never auto-dismiss**, container `pointer-events: none`. Toasts stay
above sheets (§ 2.4), which is why they are offset from the tab bar rather than placed
under it.

---

## M16. Dropdowns

`.hm-dropdown` panels are capped to the viewport below 768 px: `max-width: calc(100vw - 32px)`,
`max-height: 60vh`, and a right-anchored panel may not overflow the gutter. The behaviour
contract of § 16.5 (outside click, `Escape`, arrows, `Enter`, `Tab`) is unchanged.

Panels that exist only to serve the mouse — the table's column-visibility menu — are not
rendered at all (M9.1).

---

## M17. Loaders

Unchanged (§ 17), except that the table's loading-overlay spinner drops from 48 px to
32 px, and the top-of-viewport navigation bar (`.hm-app-loader`) keeps its 2 px height —
it sits above the sticky header and is the only motion allowed there.

---

## M18–M20. Section titles, empty states, icons

- **Section titles** (§ 18) are unchanged — the trailing rule collapses naturally at any
  width.
- **Empty states** (§ 19.1) keep one line of copy and at most one CTA; padding drops to
  `32px 16px`.
- **Banners** (§ 19.2) are unchanged and become more important: an offline or stale-data
  banner is how a phone user learns the socket died.
- **Icons** (§ 20) keep their scale. The 12 px row is not used below 768 px; 16 px is the
  floor, and an icon inside a 44 px target keeps its own size.

---

## M21. Accessibility & touch

| Rule | Threshold |
|---|---|
| Minimum hit area | **48 × 48** (44 accepted where a control's visual box is the target, e.g. `.hm-btn`) |
| Spacing between adjacent targets | ≥ 8 px |
| Form control type | ≥ 16 px, or iOS zooms |
| State encoding | Colour + text. Never colour alone |
| Icon-only control | `aria-label` — there is no tooltip |
| Zoom | **Never disable it.** `user-scalable=no` / `maximum-scale=1` are banned |
| Motion | `prefers-reduced-motion` stops the status-dot pulse and sheet transitions |

**The thumb zone matters:** primary actions live at the bottom of a sheet; destructive
actions never sit at the very bottom edge where a reflex tap lands.

---

## M22. What the mobile view MUST NOT be

| Pattern | Why |
|---|---|
| A horizontally scrolling data table | The worst port; use `.hm-mcard` (M9) |
| Any control shorter than 44 px | Below the touch floor |
| Hover-dependent affordances | There is no hover |
| `title` as the only label | Touch has no tooltip |
| The 8 px black bezel | Fights the safe areas and eats 4 % of the width (M2.1) |
| A hamburger drawer | The routes belong in the tab bar |
| Corner-anchored toasts | Full width above the tab bar (M15) |
| Text below 10 px, form controls below 16 px | Illegible; the second one triggers iOS zoom |
| `user-scalable=no` | Accessibility violation, and Chrome ignores it anyway |
| A separate mobile route, template or app | One page, one markup, one breakpoint |
| App-local `@media` blocks | Forks the design system (M0) |

---

## Appendix A — Implementation map

| Manifest | File |
|---|---|
| M1.2, M2, M3, M7, M8.1, M10–M20 | `frontend-shared/assets/styles/hm-base.css` — the `@media (max-width: 768px)` block |
| M4.2, M4.3 | `frontend-shared/components/ui/MobileNav/MobileNav.vue` (`<UiMobileNav>`) |
| M8.2 | `frontend-shared/assets/styles/hm-base.css` — `.hm-mcard*`, global; rendered by the table's `isMobile` branch and by simple-table pages |
| M9 | `frontend-shared/components/ui/Table/Table.vue` — the `isMobile` branch |
| M7 (toolbar target) | `frontend-shared/components/ui/IconButton/IconButton.vue` |
| M13 (rows) | `frontend-shared/components/ui/Toggle/Toggle.vue`, `frontend-shared/components/ui/Checkbox/Checkbox.vue` |
| M9.1 (pagination) | `frontend-shared/components/ui/Table/Pagination/Pagination.vue` |
| M15 | `frontend-shared/components/ui/ToastsContainer/ToastsContainer.vue` |
| M4.1, M4.2 mounting | each app's `layouts/default.vue` |

Each application's `layouts/default.vue` mounts the tab bar with the nav entries it already
computes for the desktop header:

```vue
<UiMobileNav
  :entries="navEntries"
  :profile-url="authDisabled ? '' : `${authGatewayUrl}/profile`"
  :show-sign-out="!authDisabled"
  :meta="{ version: appVersion, buildSha: shortSha, env: appEnv, online }"
  @sign-out="signOut"
/>
```

---

## Appendix B — Review checklist

**Structure**
- [ ] No horizontal document scroll at 320 px
- [ ] 16 px gutters everywhere; nothing full-bleed except the stat strip
- [ ] Tab bar mounted; header nav hidden; `#header-actions` still present
- [ ] Footer hidden and its three slots present in the nav sheet

**Data**
- [ ] Every table renders cards below 768 px
- [ ] Sort reachable without column headers
- [ ] Pagination targets ≥ 44 px

**Touch & type**
- [ ] Every control ≥ 44 px, ≥ 8 px apart
- [ ] Form controls at 16 px; no iOS zoom on focus
- [ ] Nothing below 10 px; no hover-only affordance

**Surfaces**
- [ ] Modals render as bottom sheets with a handle
- [ ] Toasts full width above the tab bar; errors persist
- [ ] Sheets lock body scroll and close on route change

---

## Appendix C — Testing

- **Chrome DevTools device toolbar** at 360 × 800 (Android reference) and 390 × 844
  (iPhone reference) is the minimum; 320 px is the width that must not break.
- **`(hover: none)` emulation** matters: DevTools keeps a mouse, so sticky-hover bugs only
  reproduce with touch emulation on, or on a real device.
- **The safe-area insets are zero in DevTools.** A bottom-bar overlap can only be seen on a
  real iPhone or with an inset simulation.
- Validation for a frontend change is `pnpm lint` + `pnpm typecheck`; the unit-test
  environments in these repos do not boot, so visual verification is done in the browser.

---

## Appendix D — Native apps (Flutter)

The three Flutter apps in `*/mobile` are a **separate surface** with the same visual
language. They share the palette and typography (`HmColors`, `HmTypography` are lifted from
the parent manifest verbatim) and every principle of M1.3, M7, M10, M21 — but they are
built from platform widgets, not `.hm-*` classes, and a few rules differ because the
medium does:

| Concern | Web ≤ 768 px | Native |
|---|---|---|
| Navigation | `.hm-tabbar` (3 + More) | Platform bottom navigation bar, 3–5 tabs, icon + label |
| Lists | Card rendering of a paginated table | Grouped list, **pull-to-refresh + infinite scroll** |
| Modals | `.hm-modal` restyled as a sheet | Platform bottom sheet; confirms stay centred dialogs |
| Selects | `.hm-select` / dropdown panel | Picker sheet; never a native wheel |
| Toasts | `.hm-toasts` | Snackbar above the tab bar, errors persist |
| Theme | CSS tokens | `HmColors` only; every Material elevation zeroed |
| Status reporting | Nav sheet | Profile screen + a live connection dot in the app bar |
| Launch | — | Launch screen painted `#080C10`; a white flash is a bug |
| Alerts | — | Full-screen incident call over the lock screen, styled from the tokens |

Implementation map:

| Concern | File (relative to `<repo>/mobile/lib/`) |
|---|---|
| Tokens | `core/theme/colors.dart` |
| Type scale | `core/theme/typography.dart` |
| Material defaults | `core/theme/app_theme.dart` |
| Shell + grid overlay | `presentation/common/widgets/hm_scaffold.dart` |
| Tab bar | `presentation/router/app_router.dart` |
| Row card, stat strip, filters | `presentation/dashboard/widgets/*` |
| Status badge, empty state, loader | `presentation/common/widgets/*` |

Native-specific rules that have no web equivalent:

- **Fonts are bundled assets, never fetched at runtime** — a runtime-resolved font gives a
  first frame in the system typeface on every cold start.
- **Dark only.** The apps do not follow the system light/dark setting; there is no light
  palette in this design system.
- **Colours come from `HmColors` only.** A raw `Color(0x…)` or a Material palette constant
  in a widget is off the manifest.
- **Haptics are semantic and sparse**: selection on tab/chip changes, medium impact on a
  destructive confirm, nothing on validation or scroll.
