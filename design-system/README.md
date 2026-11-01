# Ledgerly design system

Design stage. Tokens and component styles are real; everything under Proof is a prototype.

Open [index.html](index.html) in a browser. It is one self-contained file with no network access.

| File | What |
|---|---|
| `index.html` | The interactive page, generated |
| `tokens/tokens.css`, `tokens/tokens.json` | The same tokens in two formats, generated |
| `ledgerly.css` | Component styles, copied from `src/` |
| `ledgerly.js` | Component builders, charts, sample ledger and proof screens, generated |
| `brand/` | The app icon as SVG, generated |
| `contrast.md`, `usage-rules.md` | The measured contrast table and the do and don't list, generated |
| `src/` | The sources. Edit these, never the generated files |

Rebuild after any change:

```bash
node design-system/build.mjs
```

The build fails if a colour pair misses its contrast floor or the page references a remote address. All sample data is fictional.
