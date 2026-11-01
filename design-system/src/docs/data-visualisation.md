# Data visualisation

One chart style covers every view. Charts sit on `surface-1` inside a `Card`, and the title is the question the chart answers.

## Rules

- **Axes.** Bars start at zero. There is only one axis per chart. The baseline is `chart-axis`.
- **Gridlines.** Three at most, in `chart-grid`, so they recede.
- **Labels.** Label directly where there is room: line ends, weekday bars, the donut total. Use a key only for grouped bars.
- **Tooltips.** Selecting a mark shows its figures in a plain panel below the chart, so the text is never covered by a finger.
- **Selection.** Every bar, slice and point is a focusable button. A selected mark gets a `text-primary` outline, and the app then opens the transactions behind it.
- **Empty.** Keep the question as the title, then one sentence. Never draw fake data.
- **Screen readers.** Every chart has a text description that states the key figures. Keep it current with the data.
- **Avoid.** No 3D, truncated bar axes, dual axes, gradients, week-by-week square grids, or donuts with more than six slices.

## Colour

Charts use six rank slots plus a neutral Other, `chart-1` to `chart-6` and `chart-other`. Slot 1 is always the largest item. **Colour in a chart means rank, not category,** because any six of twelve category colours cannot be kept distinct for colour-blind users. The ranked list beside a donut shows each category's own icon and name, so identity carries over.

Income and spending bars are the exception: they use `positive-fill` and `negative-fill`, because those are semantic.

Colour is never the only cue. Lines also use dash patterns and direct labels, donut slices have gaps, and the list repeats each value.

## Heat scale

`heat-0` to `heat-5` is one sequential scale in both themes. It shades spending, so it stays in the coral family. `on-heat-low` is the text on steps 0 to 4, and `on-heat-high` is the text on step 5. Steps are fixed by daily EUR amount, so a shade means the same thing every month: under €20, under €50, under €100, under €300, and €300 or more.

## Calendar month

Every cell shows its date and a signed amount in euros, such as −€17 or +€2.0k. A day that ends with a net gain uses `positive-tint` instead of a heat step. Days from the months around it fill the grid, so it never starts with blank cells, and planned items appear on their future dates with a dashed outline. Month totals sit above the grid. At 560px and wider, each cell shows the full amount, the top category and the entry count.

A shade is never the only cue: every cell has a number, and markers show recurring items, income, days of €300 or more, and planned items.

## Year ledger

The year is twelve ledger lines, one per month, with days in columns from 1 to 31. Spending rises above the line and income hangs below it. Height follows the same five spending steps as the heat scale, and the tallest step also uses the darker `negative`. Because days share columns, rent on the 1st and salary on the 28th line up down the year, so a break in the rhythm stands out. Each line shows its month total, and selecting a line shows that month's figures and its busiest day.

Do not draw the year as a grid of squares by week. It says little about money and copies how code contribution charts look.

## Palette separation

Palette distance is measured in OKLab, multiplied by 100, as the smallest gap between any two colours in the set. Values of about 2 or under are hard to tell apart. The measured values are in the Contrast section.
