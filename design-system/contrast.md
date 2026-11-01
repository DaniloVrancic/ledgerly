# Contrast

Measured by the build with the WCAG 2 formula, and the build fails if any pair falls below its floor. Text needs 4.5:1. Large text and interface marks need 3:1. Text on `text-disabled` is excluded, because WCAG exempts inactive controls.

## What changed from the base colours

| Base colour | Now | Why |
|---|---|---|
| #D9685D coral | negative #B23F35 | Coral as text measures only about 3.2:1 on the off-white. The darker tone reaches 4.5:1 on every surface. The base stays as negative-fill for bars and marks, where 3:1 applies. |
| #D9A441 amber | warning #7A5710 | Amber as text measures about 2.1:1. The dark tone is for text and icons. |
| #D9A441 amber | warning-mark #9C6F12 | The base also fails the 3:1 floor for marks, so budget bars and markers use this tone. The base stays as warning-fill, always with charcoal text on it. |
| no positive colour given | positive #1F6B4F | The primary #163D32 is nearly as dark as the text, so it cannot read as a signal. Income needed its own visibly green tone at 4.5:1. |
| nothing changed | #163D32, #E8F2EC, #F7F8F5, #252C2A | All four base colours pass as given and are used unchanged. |

## Measured pairs

| Foreground | Background | Use | Floor | Light | Dark |
|---|---|---|---|---|---|
| `text-primary` | `background` | Text | 4.5:1 | 13.38:1 | 16.34:1 |
| `text-primary` | `surface-1` | Text | 4.5:1 | 14.26:1 | 15.07:1 |
| `text-primary` | `surface-2` | Text | 4.5:1 | 12.65:1 | 13.82:1 |
| `text-primary` | `surface-3` | Text | 4.5:1 | 11.63:1 | 12.20:1 |
| `text-primary` | `surface-tint` | Text | 4.5:1 | 12.46:1 | 12.69:1 |
| `text-secondary` | `background` | Text | 4.5:1 | 6.73:1 | 9.94:1 |
| `text-secondary` | `surface-1` | Text | 4.5:1 | 7.18:1 | 9.17:1 |
| `text-secondary` | `surface-2` | Text | 4.5:1 | 6.37:1 | 8.41:1 |
| `text-secondary` | `surface-3` | Text | 4.5:1 | 5.85:1 | 7.42:1 |
| `text-secondary` | `surface-tint` | Text | 4.5:1 | 6.27:1 | 7.72:1 |
| `text-tertiary` | `background` | Text | 4.5:1 | 5.27:1 | 7.21:1 |
| `text-tertiary` | `surface-1` | Text | 4.5:1 | 5.62:1 | 6.65:1 |
| `text-tertiary` | `surface-2` | Text | 4.5:1 | 4.99:1 | 6.10:1 |
| `text-tertiary` | `surface-3` | Text | 4.5:1 | 4.58:1 | 5.38:1 |
| `text-tertiary` | `surface-tint` | Text | 4.5:1 | 4.91:1 | 5.60:1 |
| `accent-forest` | `background` | Text | 4.5:1 | 11.27:1 | 11.14:1 |
| `accent-forest` | `surface-1` | Text | 4.5:1 | 12.02:1 | 10.28:1 |
| `accent-forest` | `surface-2` | Text | 4.5:1 | 10.66:1 | 9.42:1 |
| `accent-forest` | `surface-3` | Text | 4.5:1 | 9.80:1 | 8.32:1 |
| `accent-forest` | `surface-tint` | Text | 4.5:1 | 10.50:1 | 8.65:1 |
| `accent-lake` | `background` | Text | 4.5:1 | 8.13:1 | 10.37:1 |
| `accent-lake` | `surface-1` | Text | 4.5:1 | 8.66:1 | 9.57:1 |
| `accent-lake` | `surface-2` | Text | 4.5:1 | 7.68:1 | 8.78:1 |
| `accent-lake` | `surface-3` | Text | 4.5:1 | 7.07:1 | 7.74:1 |
| `accent-lake` | `surface-tint` | Text | 4.5:1 | 7.57:1 | 8.06:1 |
| `accent-plum` | `background` | Text | 4.5:1 | 8.66:1 | 10.02:1 |
| `accent-plum` | `surface-1` | Text | 4.5:1 | 9.23:1 | 9.24:1 |
| `accent-plum` | `surface-2` | Text | 4.5:1 | 8.19:1 | 8.48:1 |
| `accent-plum` | `surface-3` | Text | 4.5:1 | 7.53:1 | 7.48:1 |
| `accent-plum` | `surface-tint` | Text | 4.5:1 | 8.06:1 | 7.78:1 |
| `accent-slate` | `background` | Text | 4.5:1 | 8.59:1 | 10.91:1 |
| `accent-slate` | `surface-1` | Text | 4.5:1 | 9.16:1 | 10.06:1 |
| `accent-slate` | `surface-2` | Text | 4.5:1 | 8.12:1 | 9.23:1 |
| `accent-slate` | `surface-3` | Text | 4.5:1 | 7.47:1 | 8.14:1 |
| `accent-slate` | `surface-tint` | Text | 4.5:1 | 8.00:1 | 8.47:1 |
| `positive` | `background` | Text | 4.5:1 | 6.02:1 | 9.70:1 |
| `positive` | `surface-1` | Text | 4.5:1 | 6.41:1 | 8.95:1 |
| `positive` | `surface-2` | Text | 4.5:1 | 5.69:1 | 8.21:1 |
| `positive` | `surface-3` | Text | 4.5:1 | 5.23:1 | 7.24:1 |
| `positive` | `surface-tint` | Text | 4.5:1 | 5.60:1 | 7.53:1 |
| `negative` | `background` | Text | 4.5:1 | 5.39:1 | 9.09:1 |
| `negative` | `surface-1` | Text | 4.5:1 | 5.74:1 | 8.39:1 |
| `negative` | `surface-2` | Text | 4.5:1 | 5.10:1 | 7.69:1 |
| `negative` | `surface-3` | Text | 4.5:1 | 4.69:1 | 6.79:1 |
| `negative` | `surface-tint` | Text | 4.5:1 | 5.02:1 | 7.06:1 |
| `warning` | `background` | Text | 4.5:1 | 6.16:1 | 10.98:1 |
| `warning` | `surface-1` | Text | 4.5:1 | 6.57:1 | 10.13:1 |
| `warning` | `surface-2` | Text | 4.5:1 | 5.82:1 | 9.29:1 |
| `warning` | `surface-3` | Text | 4.5:1 | 5.36:1 | 8.20:1 |
| `warning` | `surface-tint` | Text | 4.5:1 | 5.74:1 | 8.53:1 |
| `neutral` | `background` | Text | 4.5:1 | 6.06:1 | 8.91:1 |
| `neutral` | `surface-1` | Text | 4.5:1 | 6.46:1 | 8.22:1 |
| `neutral` | `surface-2` | Text | 4.5:1 | 5.73:1 | 7.54:1 |
| `neutral` | `surface-3` | Text | 4.5:1 | 5.27:1 | 6.65:1 |
| `neutral` | `surface-tint` | Text | 4.5:1 | 5.64:1 | 6.92:1 |
| `positive` | `positive-tint` | Text | 4.5:1 | 5.51:1 | 7.33:1 |
| `negative` | `negative-tint` | Text | 4.5:1 | 4.97:1 | 7.44:1 |
| `warning` | `warning-tint` | Text | 4.5:1 | 5.84:1 | 8.36:1 |
| `neutral` | `neutral-tint` | Text | 4.5:1 | 5.53:1 | 6.87:1 |
| `on-primary` | `primary` | Text | 4.5:1 | 11.27:1 | 11.14:1 |
| `on-inverse` | `surface-inverse` | Text | 4.5:1 | 11.27:1 | 13.82:1 |
| `text-primary` | `surface-overlay` | Text | 4.5:1 | 14.26:1 | 12.20:1 |
| `text-secondary` | `surface-overlay` | Text | 4.5:1 | 7.18:1 | 7.42:1 |
| `text-tertiary` | `surface-overlay` | Text | 4.5:1 | 5.62:1 | 5.38:1 |
| `on-accent` | `accent-forest` | Text | 4.5:1 | 11.27:1 | 11.14:1 |
| `on-accent` | `accent-lake` | Text | 4.5:1 | 8.13:1 | 10.37:1 |
| `on-accent` | `accent-plum` | Text | 4.5:1 | 8.66:1 | 10.02:1 |
| `on-accent` | `accent-slate` | Text | 4.5:1 | 8.59:1 | 10.91:1 |
| `on-warning` | `warning-fill` | Text | 4.5:1 | 6.34:1 | 8.22:1 |
| `border-control` | `background` | Mark | 3:1 | 3.39:1 | 4.37:1 |
| `positive-fill` | `background` | Mark | 3:1 | 3.98:1 | 7.08:1 |
| `negative-fill` | `background` | Mark | 3:1 | 3.24:1 | 6.45:1 |
| `warning-mark` | `background` | Mark | 3:1 | 4.20:1 | 8.22:1 |
| `neutral-fill` | `background` | Mark | 3:1 | 3.49:1 | 5.38:1 |
| `border-control` | `surface-1` | Mark | 3:1 | 3.61:1 | 4.03:1 |
| `positive-fill` | `surface-1` | Mark | 3:1 | 4.24:1 | 6.53:1 |
| `negative-fill` | `surface-1` | Mark | 3:1 | 3.45:1 | 5.96:1 |
| `warning-mark` | `surface-1` | Mark | 3:1 | 4.47:1 | 7.58:1 |
| `neutral-fill` | `surface-1` | Mark | 3:1 | 3.72:1 | 4.96:1 |
| `border-control` | `surface-2` | Mark | 3:1 | 3.20:1 | 3.70:1 |
| `positive-fill` | `surface-2` | Mark | 3:1 | 3.76:1 | 5.99:1 |
| `negative-fill` | `surface-2` | Mark | 3:1 | 3.06:1 | 5.46:1 |
| `warning-mark` | `surface-2` | Mark | 3:1 | 3.97:1 | 6.95:1 |
| `neutral-fill` | `surface-2` | Mark | 3:1 | 3.30:1 | 4.55:1 |
| `accent-forest` | `surface-3` | Mark | 3:1 | 9.80:1 | 8.32:1 |
| `accent-lake` | `surface-3` | Mark | 3:1 | 7.07:1 | 7.74:1 |
| `accent-plum` | `surface-3` | Mark | 3:1 | 7.53:1 | 7.48:1 |
| `accent-slate` | `surface-3` | Mark | 3:1 | 7.47:1 | 8.14:1 |
| `cat-1` | `surface-1` | Mark | 3:1 | 7.91:1 | 5.30:1 |
| `cat-2` | `surface-1` | Mark | 3:1 | 5.11:1 | 10.55:1 |
| `cat-3` | `surface-1` | Mark | 3:1 | 4.39:1 | 7.71:1 |
| `cat-4` | `surface-1` | Mark | 3:1 | 5.56:1 | 8.00:1 |
| `cat-5` | `surface-1` | Mark | 3:1 | 6.42:1 | 9.03:1 |
| `cat-6` | `surface-1` | Mark | 3:1 | 4.40:1 | 4.18:1 |
| `cat-7` | `surface-1` | Mark | 3:1 | 5.64:1 | 8.84:1 |
| `cat-8` | `surface-1` | Mark | 3:1 | 5.53:1 | 11.50:1 |
| `cat-9` | `surface-1` | Mark | 3:1 | 4.16:1 | 4.54:1 |
| `cat-10` | `surface-1` | Mark | 3:1 | 6.39:1 | 11.20:1 |
| `cat-11` | `surface-1` | Mark | 3:1 | 8.65:1 | 4.23:1 |
| `cat-12` | `surface-1` | Mark | 3:1 | 10.16:1 | 6.29:1 |
| `chart-1` | `surface-1` | Mark | 3:1 | 4.96:1 | 6.19:1 |
| `chart-2` | `surface-1` | Mark | 3:1 | 5.64:1 | 6.07:1 |
| `chart-3` | `surface-1` | Mark | 3:1 | 10.57:1 | 10.79:1 |
| `chart-4` | `surface-1` | Mark | 3:1 | 5.35:1 | 9.99:1 |
| `chart-5` | `surface-1` | Mark | 3:1 | 5.47:1 | 4.39:1 |
| `chart-6` | `surface-1` | Mark | 3:1 | 9.83:1 | 9.48:1 |
| `chart-other` | `surface-1` | Mark | 3:1 | 3.72:1 | 4.96:1 |
| `brand-chart` | `brand-tile` | Mark | 3:1 | 8.05:1 | 8.05:1 |
| `brand-page` | `brand-tile` | Mark | 3:1 | 11.27:1 | 11.27:1 |
| `on-heat-low` | `heat-0` | Text | 4.5:1 | 14.26:1 | 15.07:1 |
| `on-heat-low` | `heat-1` | Text | 4.5:1 | 12.31:1 | 13.64:1 |
| `on-heat-low` | `heat-2` | Text | 4.5:1 | 10.55:1 | 11.10:1 |
| `on-heat-low` | `heat-3` | Text | 4.5:1 | 8.42:1 | 8.04:1 |
| `on-heat-low` | `heat-4` | Text | 4.5:1 | 5.83:1 | 5.15:1 |
| `on-heat-high` | `heat-5` | Text | 4.5:1 | 5.87:1 | 7.09:1 |

## Colour-blind separation

Smallest OKLab distance between any two colours in the set, times 100, simulated with Machado et al. 2009 at full severity.

| Palette | Theme | Normal | Protanopia | Deuteranopia | Tritanopia |
|---|---|---|---|---|---|
| Chart slots and Other | light | 13.1 | 5.9 | 4.8 | 4.7 |
| Category colours | light | 6.8 | 3.7 | 4.0 | 4.8 |
| Chart slots and Other | dark | 12.8 | 7.1 | 6.6 | 9.3 |
| Category colours | dark | 6.4 | 4.0 | 4.6 | 3.9 |

The nearest category colour to any semantic fill is 9.0 in light and 8.1 in dark. Twelve colours cannot all stay far apart, so a category always appears with its icon and name.
