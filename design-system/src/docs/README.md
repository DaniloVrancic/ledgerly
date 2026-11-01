Ledgerly is a quiet everyday tool, opened 10 to 20 times a day to record money or check a balance. Build every screen from these tokens and components. If something is missing, add it here first.

Each token has a usage note. A consuming screen loads `tokens.css`, then `ledgerly.css`, and sets `data-theme` on its root.

## Content fundamentals

Write plainly, calmly and precisely, with no guilt and no hype. Say what happened, then what can be done. Use sentence case and "you" only where a sentence needs it. Never use exclamation marks or emoji. Full wording examples are in the Writing section.

- Use the defined terms exactly: Balance, Income, Spending, Net, Savings rate, Earmarked for goals, Free to use.
- Offline is normal, so never mention sync, online or loading from a server. Say "Backed up 2 days ago".

## Visual foundations

**Colour.** Use semantic tokens, never raw values. `positive` is income, `negative` is expense, `warning` is attention, and `neutral` is transfers and supporting information. These meanings never change. `accent` is for interactive elements only and the user chooses it. Always pair colour with a sign, an icon or a label.

**Type.** Set everything in Inter. Set money with tabular numerals through `.money`. `balance` is the largest element on any screen. Body text is `body` or `body-small`, and nothing is smaller than `caption`, which is 12px. Sizes are in rem so they follow Android's text setting: let rows grow, let long names wrap, and never truncate an amount.

**Money.** Write €1,234.56 and 1,234.56 KM. A negative amount uses a real minus, as in −€20.00. The original amount sits first and the converted amount sits below it in `amount-small`. Very large values step down one or two sizes on cards and stay complete. Only chart labels and calendar cells use a compact form.

**Spacing and shape.** Spacing is an 8-point scale with a 4px half step. `space-4` is the phone gutter and card padding. Radii run from `radius-sm` at 8px to `radius-lg` at 16px. `radius-full` is only for circles and pills.

**Depth.** In light, use `elevation-1` for the Add button and toasts, and `elevation-2` for sheets and dialogs. In dark, shadows are off: step up the surface tokens and use `border-subtle`.

**Focus.** The focus ring is a solid 2px `accent` line, offset 2px, and holds 3:1 on every surface in all four accent options.

**Touch.** Touch targets are at least `touch-min`, 44px. Primary controls stay in the lower half of the phone.

**Motion.** Motion is short: `duration-fast` for press, `duration-base` for toggles, `duration-slow` for sheets, with `ease-standard`. With reduced motion turned on, everything happens at once. Nothing bounces or celebrates.

## Iconography

Use the one line set in `Ledgerly.icon(name, size)`: a 24px grid, a 1.75 stroke, round caps, no fills, drawn for this system. Sizes are 16, 20 and 24. A standalone icon needs a label. Do not use emoji or a second icon set.

The brand motif is the isometric ledger. It appears in colour only as the app icon, and as line art in empty, error and first-run states through `Ledgerly.stateMark(icon)`. The bundled files are in `brand/`.

## Using the files

- `tokens.css` and `tokens.json` hold the same tokens, generated from one source.
- `ledgerly.css` holds every component style.
- `brand/` holds the app icon as SVG, in full and small sizes.
- `ledgerly.js` exposes `Ledgerly.ui`, which returns HTML for every component, plus `Ledgerly.charts` and `Ledgerly.money`.
- Inter is not included: the app bundles it, and this system falls back to the system sans until then.
