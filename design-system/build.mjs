// Generates every token file, the contrast table, the single-file page and the artifact tree.
// Plain Node, no dependencies: node design-system/build.mjs [artifact output folder]
import { mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
import * as T from './src/tokens.mjs';
import { contrast, over, separation, CVD_KINDS, distance } from './src/color.mjs';

const ROOT = dirname(fileURLToPath(import.meta.url));
const read = (p) => readFileSync(join(ROOT, p), 'utf8');
const write = (p, s) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, s); };

// ---- Tokens ----
const resolve = (name, theme) => {
  const v = T.color[name][theme];
  const alias = /^\{(.+)\}$/.exec(v);
  return alias ? resolve(alias[1], theme) : v;
};
const cssValue = (v) => { const a = /^\{(.+)\}$/.exec(v); return a ? `var(--${a[1]})` : v.toLowerCase(); };

function themeBlock(theme) {
  const lines = Object.entries(T.color).map(([n, c]) => `  --${n}: ${cssValue(c[theme])};`);
  T.shadow.forEach(([n, v]) => lines.push(`  --${n}: ${v[theme]};`));
  return lines.join('\n');
}
function typeClass(style) {
  const [name, size, lh, weight, tracking] = style;
  return `.${name} { font-family: var(--font-sans); font-size: ${size}; line-height: ${lh}; font-weight: ${weight}; letter-spacing: ${tracking}; }`;
}
const typeStyles = T.typeGroups.flatMap((g) => g.styles);
const flatFamilies = Object.values(T.families).flat();
const tokensCss = `/* Ledgerly Design System — generated from tokens.json */
:root, [data-theme="light"] {
${themeBlock('light')}
}
[data-theme="dark"] {
${themeBlock('dark')}
}
:root {
${[...T.spacing, ...T.radius, ...flatFamilies].map(([n, v]) => `  --${n}: ${v};`).join('\n')}
  --font-sans: ${T.typeFamily};
}
${typeStyles.map(typeClass).join('\n')}
`;

const tokensJson = {
  name: 'Ledgerly', version: 1,
  color: {
    themes: [{ id: 'light', name: 'Light' }, { id: 'dark', name: 'Dark' }],
    tokens: Object.entries(T.color).map(([name, c]) => ({ name, value: { light: c.light, dark: c.dark }, usage: c.usage })),
  },
  type: {
    fonts: [],
    families: { sans: T.typeFamily },
    groups: T.typeGroups.map((g) => ({
      name: g.name, family: 'sans',
      styles: g.styles.map(([name, fontSize, lineHeight, fontWeight, letterSpacing, usage, sample]) => ({ name, fontSize, lineHeight, fontWeight, letterSpacing, usage, sample })),
    })),
  },
  spacing: { tokens: T.spacing.map(([name, value, usage]) => ({ name, value, usage })) },
  radius: { tokens: T.radius.map(([name, value, usage]) => ({ name, value, usage })) },
  shadow: { tokens: T.shadow.map(([name, value, usage]) => ({ name, value, usage })) },
  ...Object.fromEntries(Object.entries(T.families).map(([k, list]) => [k, { tokens: list.map(([name, value, usage]) => ({ name, value, usage })) }])),
};

// ---- Contrast ----
const floorOf = { text: 4.5, mark: 3 };
const rows = T.pairs.map(([fg, bg, role]) => {
  const measure = (theme) => {
    const b = resolve(bg, theme);
    return contrast(over(resolve(fg, theme), b), b);
  };
  return { fg, bg, role, floor: floorOf[role], light: measure('light'), dark: measure('dark') };
});
const failures = rows.filter((r) => r.light < r.floor || r.dark < r.floor);
if (failures.length) {
  console.error(failures);
  throw new Error(`${failures.length} colour pairs miss their contrast floor`);
}
const palette = (prefix, n, extra, theme) => Array.from({ length: n }, (_, i) => resolve(`${prefix}-${i + 1}`, theme)).concat(extra ? [resolve(extra, theme)] : []);
const sepRows = ['light', 'dark'].flatMap((theme) => [
  ['Chart slots and Other', theme, separation(palette('chart', 6, 'chart-other', theme))],
  ['Category colours', theme, separation(palette('cat', 12, null, theme))],
]);
const semantic = ['positive-fill', 'negative-fill', 'warning-fill', 'neutral-fill'];
const nearest = ['light', 'dark'].map((theme) => [theme, Math.min(...semantic.flatMap((s) => palette('cat', 12, null, theme).map((c) => distance(c, resolve(s, theme)))))]);
const f = (n) => n.toFixed(2);
const contrastMd = `# Contrast

Measured by the build with the WCAG 2 formula, and the build fails if any pair falls below its floor. Text needs 4.5:1. Large text and interface marks need 3:1. Text on \`text-disabled\` is excluded, because WCAG exempts inactive controls.

## What changed from the base colours

| Base colour | Now | Why |
|---|---|---|
${T.changes.map((c) => `| ${c.was} | ${c.now} | ${c.why} |`).join('\n')}

## Measured pairs

| Foreground | Background | Use | Floor | Light | Dark |
|---|---|---|---|---|---|
${rows.map((r) => `| \`${r.fg}\` | \`${r.bg}\` | ${r.role === 'text' ? 'Text' : 'Mark'} | ${r.floor}:1 | ${f(r.light)}:1 | ${f(r.dark)}:1 |`).join('\n')}

## Colour-blind separation

Smallest OKLab distance between any two colours in the set, times 100, simulated with Machado et al. 2009 at full severity.

| Palette | Theme | Normal | Protanopia | Deuteranopia | Tritanopia |
|---|---|---|---|---|---|
${sepRows.map(([n, t, s]) => `| ${n} | ${t} | ${s.normal.toFixed(1)} | ${CVD_KINDS.map((k) => s[k].toFixed(1)).join(' | ')} |`).join('\n')}

The nearest category colour to any semantic fill is ${nearest[0][1].toFixed(1)} in light and ${nearest[1][1].toFixed(1)} in dark. Twelve colours cannot all stay far apart, so a category always appears with its icon and name.
`;

// ---- Docs ----
const usageMd = (catalog) => `# Usage rules

Short do and don't examples for every component.

| Component | Do | Don't |
|---|---|---|
${catalog.map((c) => `| ${c.name} | ${c.guide.do} | ${c.guide.dont} |`).join('\n')}
`;

// ---- Bundle ----
const parts = ['icons', 'brand', 'data', 'components', 'charts', 'screens', 'interact', 'catalog'].map((p) => read(`src/parts/${p}.js`));
const browserTokens = {
  color: Object.keys(T.color),
  type: typeStyles.map(([n, , , , , , sample]) => [n, sample]),
  categories: T.categories,
  accents: T.accents,
};
const bundleBody = `window.Ledgerly = window.Ledgerly || {};\nwindow.Ledgerly.tokens = ${JSON.stringify(browserTokens)};\n${parts.join('\n')}`;

const sandbox = { window: {}, Intl, Math, Date, String, Object };
vm.createContext(sandbox);
vm.runInContext(bundleBody, sandbox);
const L = sandbox.window.Ledgerly;
const catalog = L.catalog;
const names = catalog.map((c) => c.name);
const header = `/* @ds-bundle: ${JSON.stringify({ format: 4, namespace: 'Ledgerly', components: names.map((name) => ({ name })) })} */\n`;
const bundle = header + bundleBody;
if (/<\/script|<!--/i.test(bundle)) throw new Error('Bundle holds a literal that would break inlining');

const css = read('src/ledgerly.css');
const docs = {
  README: read('src/docs/README.md'),
  'data-visualisation': read('src/docs/data-visualisation.md'),
  categories: read('src/docs/categories.md'),
  writing: read('src/docs/writing.md'),
  also: read('src/docs/also.md'),
  contrast: contrastMd,
  usage: usageMd(catalog),
};

// ---- Repo outputs ----
write(join(ROOT, 'tokens/tokens.css'), tokensCss);
write(join(ROOT, 'tokens/tokens.json'), `${JSON.stringify(tokensJson, null, 2)}\n`);
write(join(ROOT, 'ledgerly.css'), css);
write(join(ROOT, 'ledgerly.js'), bundle);
write(join(ROOT, 'contrast.md'), contrastMd);
write(join(ROOT, 'usage-rules.md'), docs.usage);
const brandPalette = {};
for (const n of Object.keys(T.color).filter((k) => k.startsWith('brand-'))) {
  brandPalette[n.replace('brand-', '').replace(/-(\w)/, (_, a) => a.toUpperCase())] = T.color[n].light.toLowerCase();
}
const iconFull = L.markSvg(512, brandPalette);
const iconSmall = L.markSvg(32, brandPalette);
write(join(ROOT, 'brand/app-icon.svg'), `${iconFull}\n`);
write(join(ROOT, 'brand/app-icon-small.svg'), `${iconSmall}\n`);
const page = read('src/site.html')
  .replace('/*TOKENS*/', () => tokensCss)
  .replace('/*CSS*/', () => css)
  .replace('/*SITE*/', () => read('src/site.js'))
  .replace('/*BUNDLE*/', () => bundle)
  .replace('/*DOCS*/', () => `window.LEDGERLY_DOCS = ${JSON.stringify(docs).replace(/</g, '\\u003c')};\nwindow.LEDGERLY_TOKENS_JSON = ${JSON.stringify(JSON.stringify(tokensJson, null, 2)).replace(/</g, '\\u003c')};\nwindow.LEDGERLY_TOKENS_CSS = ${JSON.stringify(tokensCss).replace(/</g, '\\u003c')};`);
if (/https?:\/\/(?!www\.w3\.org)/.test(page)) throw new Error('The page must not reference a remote address');
write(join(ROOT, 'index.html'), page);

// ---- Artifact tree ----
const out = process.argv[2];
if (out) {
  rmSync(out, { recursive: true, force: true });
  const p = (x) => join(out, 'project', x);
  write(p('tokens.json'), JSON.stringify(tokensJson, null, 2));
  write(p('tokens.css'), tokensCss);
  write(p('README.md'), docs.README);
  write(p('colour-and-contrast.md'), contrastMd);
  write(p('data-visualisation.md'), docs['data-visualisation']);
  write(p('custom-categories.md'), docs.categories);
  write(p('writing.md'), docs.writing);
  write(p('assets/Logos/README.md'), 'The Ledgerly app icon, marked temporary because Ledgerly is a working name. `app-icon.svg` is for 40px and larger. `app-icon-small.svg` is for 36px and smaller. The colours are fixed, the same in both themes.\n');
  write(join(out, 'upload/app-icon.svg'), iconFull);
  write(join(out, 'upload/app-icon-small.svg'), iconSmall);
  write(p('brand-print-privacy.md'), docs.also);
  write(p('usage-rules.md'), docs.usage);
  write(p('components/bundle.js'), bundle);
  write(p('components/bundle.css'), css);
  write(p('components/index.d.ts'), `// Builders return HTML strings. Class names are the stable contract.\n${catalog.map((c) => `export interface ${c.name}Props { /** ${c.guide.provides.replace(/\*\//g, '')} */ }`).join('\n')}\n`);
  for (const c of catalog) {
    write(p(`components/${c.name}/README.md`), `${c.summary}\n\n**Provide:** ${c.guide.provides}\n\n**Do:** ${c.guide.do}\n\n**Don't:** ${c.guide.dont}\n`);
    const page2 = c.group === 'Proof' ? ' page' : '';
    write(p(`components/${c.name}/preview.html`), `<!-- @dsCard group="${c.group}" height=${c.height}${page2} -->\n<div id="root" style="padding:12px"></div>\n<script>Ledgerly.renderCard(${JSON.stringify(c.name)}, document.getElementById('root'));</script>\n`);
  }
  write(p('components/Cover/preview.html'), read('src/cover.html'));
  write(p('design-system.json'), JSON.stringify({
    v: 3, layout: 'files', createdOnFiles: { v: 1, at: new Date().toISOString() },
    title: 'Ledgerly Design System', namespace: 'Ledgerly', libraries: [], sections: {}, groups: [], assetGroups: {}, blobs: {},
    docs: { readme: 'project/README.md', sections: [] },
    lastChange: { by: 'DaniloVrancic', at: new Date().toISOString(), via: 'Claude Code', note: 'First complete design system' },
  }, null, 2));
  const files = {};
  for (const x of ['tokens.json', 'tokens.css', 'README.md', 'colour-and-contrast.md', 'data-visualisation.md', 'writing.md', 'brand-print-privacy.md', 'custom-categories.md', 'assets/Logos/README.md', 'usage-rules.md', 'components/bundle.js', 'components/bundle.css', 'components/index.d.ts', 'components/Cover/preview.html']) files[`project/${x}`] = `project/${x}`;
  for (const c of catalog) for (const f2 of ['README.md', 'preview.html']) files[`project/components/${c.name}/${f2}`] = `project/components/${c.name}/${f2}`;
  write(join(out, 'files.json'), JSON.stringify(files));
}

console.log(`${rows.length} contrast pairs passed, lowest text ${f(Math.min(...rows.filter((r) => r.role === 'text').flatMap((r) => [r.light, r.dark])))}:1, lowest mark ${f(Math.min(...rows.filter((r) => r.role === 'mark').flatMap((r) => [r.light, r.dark])))}:1`);
console.log(`${catalog.length} components, page ${(page.length / 1024).toFixed(0)} KB`);
