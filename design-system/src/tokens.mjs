// The single source of every design value. build.mjs generates tokens.css, tokens.json and
// the contrast table from this file, so the CSS and the JSON cannot drift apart.

const c = (light, dark, usage) => ({ light, dark, usage });

export const color = {
  // Grounds
  background: c('#F7F8F5', '#0D1412', 'Page ground. The warm off-white is the brief\'s base; dark is a green-tinted near-black.'),
  'surface-1': c('#FFFFFF', '#141D1A', 'Cards, list groups, the keypad body.'),
  'surface-2': c('#F0F2ED', '#1A2521', 'Inset wells: input fills, chips at rest, table headers, keypad keys in dark.'),
  'surface-3': c('#E6E9E3', '#222F2A', 'Pressed fills and the top layer. In dark, sheets and dialogs.'),
  'surface-overlay': c('#FFFFFF', '#222F2A', 'Sheets and dialogs. In dark, a layer up instead of a shadow.'),
  'surface-inverse': c('#163D32', '#1A2521', 'The balance card and toasts. Deep forest in light.'),
  'on-inverse': c('#F7F8F5', '#EDF1EC', 'Text and icons on surface-inverse.'),
  'border-inverse': c('#163D32', '#26332E', 'Edge of surface-inverse. Only visible in dark.'),
  'surface-tint': c('#E8F2EC', '#1B2D26', 'Soft mint. Selected rows and quiet highlights.'),

  // Text
  'text-primary': c('#252C2A', '#EDF1EC', 'Body copy and money on every background and surface token.'),
  'text-secondary': c('#4F5A55', '#B4C0BA', 'Supporting copy on every background and surface token.'),
  'text-tertiary': c('#5F6A65', '#97A49D', 'Metadata and axis labels. Passes 4.5:1 on every surface token.'),
  'text-disabled': c('#8A938E', '#6B7871', 'Disabled labels only. WCAG exempts inactive controls; never use for readable content.'),

  // Borders
  'border-subtle': c('#E2E5DF', '#26332E', 'Dividers and card edges. Decorative, so it carries no meaning on its own.'),
  'border-control': c('#7F8984', '#6F7E76', 'Input, checkbox and switch outlines. 3:1 on every surface.'),

  // Primary is structure and brand. It does not change with the accent.
  primary: c('#163D32', '#9CD4BA', 'Brand structure: wordmark, app icon, the balance card fill in light.'),
  'on-primary': c('#F7F8F5', '#0D1412', 'Text and icons on primary.'),
  'primary-tint': c('#E8F2EC', '#1F352D', 'Primary at low emphasis.'),

  // Semantic meaning. Fixed in both themes, never changed by the accent.
  positive: c('#1F6B4F', '#7CCBA2', 'Income and positive money: text and marks.'),
  'positive-fill': c('#2F8A66', '#5FAF87', 'Bars and chart marks for income.'),
  'positive-tint': c('#E3F1E9', '#16302A', 'Quiet income ground.'),
  negative: c('#B23F35', '#F0A195', 'Text-safe coral: expense and negative money as text and icons.'),
  'negative-fill': c('#D9685D', '#D9806F', 'The base coral. Bars and chart marks, 3:1 or better.'),
  'negative-tint': c('#FBEBE8', '#35201D', 'Quiet expense ground.'),
  warning: c('#7A5710', '#E6C27A', 'Text-safe amber: warning text and icons.'),
  'warning-fill': c('#D9A441', '#D0A650', 'The base amber as a fill, always with on-warning text. Fails 3:1 as a bare mark in light.'),
  'warning-mark': c('#9C6F12', '#D0A650', 'Amber bars, outlines and markers that must hold 3:1 on their own.'),
  'on-warning': c('#252C2A', '#0D1412', 'Text on warning-fill.'),
  'warning-tint': c('#FAF1DC', '#322A16', 'Quiet warning ground.'),
  neutral: c('#55615C', '#AAB6B0', 'Transfers and supporting information: text and icons.'),
  'neutral-fill': c('#7C8782', '#7F8D86', 'Transfer bars and the chart Other slice.'),
  'neutral-tint': c('#ECEEEA', '#222C28', 'Quiet transfer ground.'),

  // Accent. Interactive elements only.
  accent: c('{accent-forest}', '{accent-forest}', 'Interactive elements: primary buttons, focus, selected controls, links. The user chooses it.'),
  'on-accent': c('#F7F8F5', '#0D1412', 'Text and icons on accent, in every accent option.'),
  'accent-text': c('{accent-forest}', '{accent-forest}', 'Links and selected labels on every surface.'),
  'accent-forest': c('#163D32', '#9CD4BA', 'Accent option: Forest, the default.'),
  'accent-lake': c('#1F4E79', '#9CC6EA', 'Accent option: Lake.'),
  'accent-plum': c('#5B3A6E', '#CFB4E2', 'Accent option: Plum.'),
  'accent-slate': c('#3B4A54', '#BAC8D2', 'Accent option: Slate.'),
  'scrim': c('#14201C8C', '#000000A6', 'Behind sheets and dialogs.'),

  // The mark. Fixed values, the same in both themes, because an app icon does not change with the theme.
  'brand-tile': c('#163D32', '#163D32', 'App icon ground.'),
  'brand-page': c('#F7F8F5', '#F7F8F5', 'App icon: lit ledger page.'),
  'brand-page-shade': c('#DCE9E1', '#DCE9E1', 'App icon: shaded ledger page.'),
  'brand-edge': c('#B5D0C2', '#B5D0C2', 'App icon: page block, right face.'),
  'brand-edge-dark': c('#8DB3A0', '#8DB3A0', 'App icon: page block, left face, spine and page rules.'),
  'brand-cover': c('#2F8A66', '#2F8A66', 'App icon: ledger cover.'),
  'brand-cover-dark': c('#22694E', '#22694E', 'App icon: ledger cover, left face.'),
  'brand-shadow': c('#0F2C24', '#0F2C24', 'App icon: the shadow under the ledger.'),
  'brand-chart': c('#7CE8B5', '#7CE8B5', 'App icon: the line chart and the ribbon.'),
  'brand-chart-side': c('#1F7A58', '#1F7A58', 'App icon: the depth of the line chart.'),

  // Category identity. Twelve curated colours, each a mark at 3:1 on surfaces.
  'cat-1': c('#4A4A8D', '#8689CC', 'Housing. Indigo.'),
  'cat-2': c('#487B00', '#ADD78C', 'Food. Leaf.'),
  'cat-3': c('#007FBF', '#63B5F1', 'Transportation, Salary. Sky.'),
  'cat-4': c('#A1497F', '#DC9FC0', 'Shopping, Freelance. Orchid.'),
  'cat-5': c('#106D3B', '#97C7A4', 'Health, Investments. Pine.'),
  'cat-6': c('#9365B5', '#926FAE', 'Entertainment, Business. Violet.'),
  'cat-7': c('#665FA2', '#B7B6E1', 'Bills, Rental Income. Lavender.'),
  'cat-8': c('#575CCB', '#C9D1FE', 'Travel. Periwinkle.'),
  'cat-9': c('#7A8228', '#818847', 'Education. Olive.'),
  'cat-10': c('#A43952', '#FBC2CA', 'Personal Care. Rose.'),
  'cat-11': c('#822A5A', '#A86C88', 'Gifts. Berry.'),
  'cat-12': c('#59248E', '#A695C0', 'Subscriptions. Deep purple.'),

  // Charts. Six rank slots plus a neutral Other. Hues were searched for the widest separation under protanopia, deuteranopia and tritanopia, with one hue per slot across themes.
  'chart-1': c('#3770BF', '#6C9DE2', 'Chart slot 1, blue.'),
  'chart-2': c('#905C0E', '#C88E46', 'Chart slot 2, ochre.'),
  'chart-3': c('#651A7B', '#E4C1EF', 'Chart slot 3, deep violet.'),
  'chart-4': c('#247A3C', '#9DD2A5', 'Chart slot 4, green.'),
  'chart-5': c('#9949A3', '#A76BAE', 'Chart slot 5, orchid.'),
  'chart-6': c('#683705', '#FBB075', 'Chart slot 6, brown.'),
  'chart-other': c('#7C8782', '#7F8D86', 'Chart Other. Always the last slot.'),
  'chart-grid': c('#E2E5DF', '#26332E', 'Gridlines. Decorative, one step above the surface.'),
  'chart-axis': c('#7F8984', '#6F7E76', 'The zero baseline and axis ticks.'),

  // Sequential heat, low to high, each step with its own text colour.
  'heat-0': c('#FFFFFF', '#141D1A', 'Heat step 0: no spending.'),
  'heat-1': c('#FBEBE6', '#2A2220', 'Heat step 1.'),
  'heat-2': c('#F6D7CF', '#472C27', 'Heat step 2.'),
  'heat-3': c('#EFBBAF', '#6C3A32', 'Heat step 3.'),
  'heat-4': c('#E2917F', '#9A4F43', 'Heat step 4.'),
  'heat-5': c('#A9443A', '#D98A7B', 'Heat step 5: highest.'),
  'on-heat-low': c('#252C2A', '#EDF1EC', 'Text on heat steps 0 to 4.'),
  'on-heat-high': c('#FFFFFF', '#14100F', 'Text on heat step 5.'),
};

export const accents = [
  { id: 'forest', name: 'Forest' },
  { id: 'lake', name: 'Lake' },
  { id: 'plum', name: 'Plum' },
  { id: 'slate', name: 'Slate' },
];

// [foreground, background, role]. Role sets the floor: text 4.5, large or mark 3.
const grounds = ['background', 'surface-1', 'surface-2', 'surface-3', 'surface-tint'];
const pairsOn = (fg, role) => grounds.map((g) => [fg, g, role]);
export const pairs = [
  ...pairsOn('text-primary', 'text'),
  ...pairsOn('text-secondary', 'text'),
  ...pairsOn('text-tertiary', 'text'),
  ...pairsOn('accent-forest', 'text'),
  ...pairsOn('accent-lake', 'text'),
  ...pairsOn('accent-plum', 'text'),
  ...pairsOn('accent-slate', 'text'),
  ...pairsOn('positive', 'text'),
  ...pairsOn('negative', 'text'),
  ...pairsOn('warning', 'text'),
  ...pairsOn('neutral', 'text'),
  ['positive', 'positive-tint', 'text'],
  ['negative', 'negative-tint', 'text'],
  ['warning', 'warning-tint', 'text'],
  ['neutral', 'neutral-tint', 'text'],
  ['on-primary', 'primary', 'text'],
  ['on-inverse', 'surface-inverse', 'text'],
  ['text-primary', 'surface-overlay', 'text'],
  ['text-secondary', 'surface-overlay', 'text'],
  ['text-tertiary', 'surface-overlay', 'text'],
  ['on-accent', 'accent-forest', 'text'],
  ['on-accent', 'accent-lake', 'text'],
  ['on-accent', 'accent-plum', 'text'],
  ['on-accent', 'accent-slate', 'text'],
  ['on-warning', 'warning-fill', 'text'],
  ...['background', 'surface-1', 'surface-2'].flatMap((g) => [
    ['border-control', g, 'mark'],
    ['positive-fill', g, 'mark'],
    ['negative-fill', g, 'mark'],
    ['warning-mark', g, 'mark'],
    ['neutral-fill', g, 'mark'],
  ]),
  ...['accent-forest', 'accent-lake', 'accent-plum', 'accent-slate'].map((a) => [a, 'surface-3', 'mark']),
  ...Array.from({ length: 12 }, (_, i) => [`cat-${i + 1}`, 'surface-1', 'mark']),
  ...Array.from({ length: 6 }, (_, i) => [`chart-${i + 1}`, 'surface-1', 'mark']),
  ['chart-other', 'surface-1', 'mark'],
  ['brand-chart', 'brand-tile', 'mark'],
  ['brand-page', 'brand-tile', 'mark'],
  ['on-heat-low', 'heat-0', 'text'],
  ['on-heat-low', 'heat-1', 'text'],
  ['on-heat-low', 'heat-2', 'text'],
  ['on-heat-low', 'heat-3', 'text'],
  ['on-heat-low', 'heat-4', 'text'],
  ['on-heat-high', 'heat-5', 'text'],
];

export const changes = [
  { was: '#D9685D coral', now: 'negative #B23F35', why: 'Coral as text measures only about 3.2:1 on the off-white. The darker tone reaches 4.5:1 on every surface. The base stays as negative-fill for bars and marks, where 3:1 applies.' },
  { was: '#D9A441 amber', now: 'warning #7A5710', why: 'Amber as text measures about 2.1:1. The dark tone is for text and icons.' },
  { was: '#D9A441 amber', now: 'warning-mark #9C6F12', why: 'The base also fails the 3:1 floor for marks, so budget bars and markers use this tone. The base stays as warning-fill, always with charcoal text on it.' },
  { was: 'no positive colour given', now: 'positive #1F6B4F', why: 'The primary #163D32 is nearly as dark as the text, so it cannot read as a signal. Income needed its own visibly green tone at 4.5:1.' },
  { was: 'nothing changed', now: '#163D32, #E8F2EC, #F7F8F5, #252C2A', why: 'All four base colours pass as given and are used unchanged.' },
];

export const typeFamily = 'Inter, "Segoe UI", Roboto, system-ui, sans-serif';

// All sizes are rem so they follow Android's text scale.
export const typeGroups = [
  {
    name: 'Money',
    styles: [
      ['balance', '2.25rem', '2.75rem', 700, '-0.02em', 'Account balance. The largest element on any screen.', '€12,483.36'],
      ['amount-large', '1.5rem', '2rem', 600, '-0.01em', 'Metric tiles and the amount on the Add sheet.', '−€1,482.50'],
      ['amount', '1rem', '1.5rem', 600, '0', 'Transaction rows and day totals.', '39.12 KM'],
      ['amount-small', '0.8125rem', '1.125rem', 500, '0', 'The converted amount under a primary amount.', '€20.00'],
    ],
  },
  {
    name: 'Text',
    styles: [
      ['title-large', '1.5rem', '2rem', 600, '-0.01em', 'Screen titles. Never larger than the balance on the same screen.', 'Transactions'],
      ['title', '1.125rem', '1.5rem', 600, '0', 'Card and sheet titles.', 'This month'],
      ['subtitle', '1rem', '1.5rem', 500, '0', 'Row titles and merchants.', 'Konzum Čengić Vila'],
      ['body', '1rem', '1.5rem', 400, '0', 'Reading text.', 'Backed up 2 days ago.'],
      ['body-small', '0.875rem', '1.25rem', 400, '0', 'The smallest body size.', 'Expected lowest balance before payday.'],
      ['label', '0.875rem', '1.25rem', 500, '0', 'Buttons, chips, tabs.', 'Confirm'],
      ['caption', '0.75rem', '1rem', 500, '0.01em', 'The smallest text. Axis labels, badges, metadata.', 'Estimate'],
    ],
  },
];

export const spacing = [
  ['space-0', '0px', 'Flush elements.'],
  ['space-1', '4px', 'Half step. Icon to label inside a chip.'],
  ['space-2', '8px', 'Tight gaps within a row.'],
  ['space-3', '12px', 'Gap between related controls.'],
  ['space-4', '16px', 'Card padding and the phone side gutter.'],
  ['space-5', '24px', 'Between cards.'],
  ['space-6', '32px', 'Between sections.'],
  ['space-7', '40px', 'Large section gap.'],
  ['space-8', '48px', 'Tablet and desktop gutters.'],
  ['space-9', '64px', 'Page-level separation on desktop.'],
];

export const radius = [
  ['radius-sm', '8px', 'Chips, inputs, keys, tooltips.'],
  ['radius-md', '12px', 'Cards, buttons, toasts, list groups.'],
  ['radius-lg', '16px', 'Sheets, dialogs, the balance card. The largest radius.'],
  ['radius-full', '999px', 'Only circles and pills: switch, Add button, status dots.'],
];

export const shadow = [
  ['elevation-0', { light: 'none', dark: 'none' }, 'Flat. Cards use a border.'],
  ['elevation-1', { light: '0 1px 2px #14201c14', dark: 'none' }, 'Raised Add button and toasts. Dark uses a border instead.'],
  ['elevation-2', { light: '0 8px 24px #14201c1f', dark: 'none' }, 'Sheets and dialogs. Dark uses surface-3 and a border.'],
];

export const families = {
  border: [
    ['border-width-hairline', '1px', 'Card edges and dividers.'],
    ['border-width-control', '1.5px', 'Inputs and checkboxes.'],
    ['border-width-focus', '2px', 'Focus ring, offset by 2px.'],
  ],
  size: [
    ['touch-min', '44px', 'Smallest touch target.'],
    ['control-height', '48px', 'Buttons and inputs on phones.'],
    ['nav-height', '64px', 'Bottom navigation.'],
    ['nav-raise', '24px', 'How far the Add button rises above the bar. Content above the bar keeps this much clear space.'],
    ['icon-sm', '16px', 'Row indicators.'],
    ['icon-md', '20px', 'Standard icons.'],
    ['icon-lg', '24px', 'Navigation icons.'],
  ],
  motion: [
    ['duration-fast', '100ms', 'Press feedback and hovers.'],
    ['duration-base', '180ms', 'Toggles, chips, expanding rows.'],
    ['duration-slow', '260ms', 'Sheets and dialogs.'],
    ['ease-standard', 'cubic-bezier(0.2, 0, 0, 1)', 'Everything by default.'],
    ['ease-exit', 'cubic-bezier(0.4, 0, 1, 1)', 'Elements leaving the screen.'],
  ],
};

export const categories = [
  ['housing', 'Housing', 1, 'home'], ['food', 'Food', 2, 'basket'], ['transport', 'Transportation', 3, 'bus'],
  ['shopping', 'Shopping', 4, 'bag'], ['health', 'Health', 5, 'pulse'], ['entertainment', 'Entertainment', 6, 'ticket'],
  ['bills', 'Bills', 7, 'receipt'], ['travel', 'Travel', 8, 'plane'], ['education', 'Education', 9, 'book'],
  ['personal', 'Personal Care', 10, 'sparkle'], ['gifts', 'Gifts', 11, 'gift'], ['subscriptions', 'Subscriptions', 12, 'repeat'],
  ['salary', 'Salary', 3, 'briefcase'], ['freelance', 'Freelance', 4, 'pen'], ['business', 'Business', 6, 'store'],
  ['investments', 'Investments', 5, 'trend'], ['rental', 'Rental Income', 7, 'key'], ['other', 'Other', 0, 'dots'],
];
