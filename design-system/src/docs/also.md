# Brand, print and privacy

## App icon and wordmark

**Temporary, because Ledgerly is a working name.** The mark is an open isometric ledger on deep forest. A three-column chart rises out of its pages, with a green euro coin for income and a coral dollar coin for expense. Below 36px the page rules drop out and the coins grow. The colours are the `brand-*` tokens, which are the same in both themes, because an app icon does not change with the theme. The wordmark is Inter semibold with slightly tight spacing.

The same ledger, as line art, is the empty-state style. The line icon set includes it as `ledger`, along with `dollar` and `euro`.

## Print

PDF reports use the `PrintStyle` specimen: white paper, black text, light only, whatever theme the app is in. A report must read in black and white, so bars use a hatched pattern, every value is a number, signs stay on money, and table rules separate rows. Keep cards from breaking across pages.

## Hidden amounts

Setting `data-amounts="hidden"` on the root replaces every `.money` value with five dots. The dot count is always the same, so the length of a number is not revealed. Layout does not move. Chart axis values hide too, while the shapes remain, because proportions alone give no amounts.

This CSS mask is for the visual style only. In the app, the Money component must not render the real value at all while hidden, and it should expose the label "Hidden amount" to screen readers.

## Accent colours

The user picks Forest, Lake, Plum or Slate. The accent changes only `accent` and `accent-text`: primary buttons, focus, selected controls and links. None of the options is a red, an amber or a bright green, so an accent cannot be mistaken for a semantic colour. Use `data-accent` on the root.

## Large text

Sizes are in rem. The specimens have a Large text control at 130% and 200%. Rows grow, labels wrap, and amounts stay on one line and stay complete. Calendar cells are the one fixed exception: their amount stays sized to the cell, and the day panel always shows the full figure.
