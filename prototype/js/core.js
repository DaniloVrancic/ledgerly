// Prototype shell: state, navigation, rendering and the small helpers every screen shares.
// Screens are functions that return HTML built from Ledgerly.ui. State lasts for the session.
(function (L) {
  'use strict';
  const D = L.data;
  const G = window.Ledger;
  const ui = L.ui;
  const P = (window.LP = { views: {}, acts: {}, inputs: {}, sheets: {} });

  const st = (P.st = {
    route: { name: 'home', arg: null }, stack: [], tab: 'home',
    layout: 'phone', device: 'phone', theme: 'light', themePref: 'light', accent: 'forest', hidden: false, textSize: 'Default',
    balanceOpen: false, txView: 'list', filters: {}, filterOpen: false, select: null, limit: 40, sort: { key: 'date', dir: -1 }, panelTx: null,
    cal: { ym: D.CURRENT, mode: 'month', day: null, showPanel: false },
    an: { range: 'month', offset: 0, section: 'overview', tip: {}, trend: ['food', 'shopping', 'transport'], selected: null },
    sheet: null, dialog: null, toast: null, add: null, full: null, chrome: true, sitemap: false, fixedLayout: null,
    backupDemo: 'healthy', firstRun: null, stateDemo: null,
  });

  const esc = (P.esc = (s) => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;'));
  const attr = (P.attr = (html, a) => html.replace(/^(\s*)<(\w+)/, `$1<$2 ${a}`));
  const act = (P.act = (name, arg) => `data-act="${name}"${arg != null ? ` data-arg="${esc(arg)}"` : ''}`);
  P.btn = (label, name, arg, o) => ui.button(label, Object.assign({}, o, { attr: `${act(name, arg)}${o && o.attr ? ` ${o.attr}` : ''}` }));
  P.iconBtn = (icon, label, name, arg) => `<button type="button" class="lg-icon-btn" aria-label="${esc(label)}" ${act(name, arg)}>${L.icon(icon, 20)}</button>`;
  P.link = (label, name, arg) => `<button type="button" class="lg-link" ${act(name, arg)}>${label}</button>`;
  P.section = (title, action) => `<div class="lg-section"><h3 class="lg-section__title">${title}</h3>${action || ''}</div>`;
  P.row = (o) => attr(ui.row(o), o.name ? act(o.name, o.arg) : '');
  P.pill = (label, on, name, arg, icon) => `<button type="button" class="lg-pill" aria-pressed="${!!on}" ${act(name, arg)}>${icon ? L.icon(icon, 16) : ''}<span>${label}</span></button>`;
  P.seg = (items, selected, name, label) => `<div class="lg-seg" role="group" aria-label="${esc(label || '')}">${items.map((it) => {
    const t = typeof it === 'string' ? { label: it, id: it } : it;
    const id = t.id == null ? t.label : t.id;
    return `<button type="button" class="lg-seg__item" aria-pressed="${id === selected}" ${t.kind ? `data-kind="${t.kind}"` : ''} ${act(name, id)}>${t.icon ? L.icon(t.icon, 16) : ''}${t.label}</button>`;
  }).join('')}</div>`;
  P.field = (label, inner, hint) => `<div class="lg-field"><span class="lg-field__label">${label}</span>${inner}${hint ? `<span class="lg-field__hint">${hint}</span>` : ''}</div>`;
  P.input = (name, value, o) => {
    const p = o || {};
    return `<span class="lg-input${p.error ? ' is-error' : ''}"><input data-in="${name}" ${p.arg != null ? `data-arg="${esc(p.arg)}"` : ''} value="${esc(value)}" aria-label="${esc(p.label || p.placeholder || name)}" placeholder="${esc(p.placeholder || '')}" ${p.type ? `type="${p.type}"` : ''} ${p.mode ? `inputmode="${p.mode}"` : ''} ${p.focus ? 'data-autofocus' : ''}>${p.trail || ''}</span>`;
  };
  P.select = (name, value, options, o) => `<span class="lg-input"><select class="p-select" data-in="${name}" aria-label="${esc((o && o.label) || name)}" ${o && o.arg != null ? `data-arg="${esc(o.arg)}"` : ''}>${options.map(([v, l]) => `<option value="${esc(v)}" ${String(v) === String(value) ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select></span>`;
  P.textarea = (name, value, o) => `<textarea class="p-textarea" data-in="${name}" ${o && o.arg != null ? `data-arg="${esc(o.arg)}"` : ''} aria-label="${esc((o && o.label) || name)}" placeholder="${esc((o && o.placeholder) || '')}">${esc(value)}</textarea>`;
  P.switch = (label, on, name, arg) => attr(ui.switch(label, { on }), '').replace('<input', `<input data-in="${name}" ${arg != null ? `data-arg="${esc(arg)}"` : ''}`);
  P.check = (label, on, name, arg) => ui.checkbox(label, { on }).replace('<input', `<input data-in="${name}" ${arg != null ? `data-arg="${esc(arg)}"` : ''}`);
  P.card = (html, flush) => `<div class="lg-card${flush ? ' lg-card--flush' : ''}">${html}</div>`;
  P.kv = (k, v, cls) => `<div class="p-kv ${cls || ''}"><span>${k}</span><span>${v}</span></div>`;
  P.state = (icon, title, text, action) => `<div class="lg-state">${L.stateMark(icon)}<h3>${title}</h3><p>${text}</p>${action || ''}</div>`;
  P.defs = {
    Balance: 'Sum of all account balances. Credit cards count as negative. Converted at the current rate.',
    Income: 'Income transactions only.', Spending: 'Expenses minus refunds.', Net: 'Income minus spending.', 'Savings rate': 'Net divided by income.',
    'Earmarked for goals': 'Money set aside inside an account. It is not moved or spent.', 'Free to use': 'Total balance minus what is earmarked for goals.',
    Transfers: 'Money moved between your accounts. Never income or spending.', 'Owed to me': 'The part of a payment that is not your share, until it is repaid. A repayment is not income.',
    Untracked: 'The difference found by a balance check. Excluded from income and spending.',
  };
  P.info = (term) => attr(ui.info(term, P.defs[term] || ''), act('showDef', term));
  P.eur = (v, o) => L.money(v, 'EUR', o);
  P.toneOf = (v) => (v > 0 ? 'positive' : v < 0 ? 'negative' : 'neutral');
  P.catName = (id) => (id ? L.cat(id).name : 'Needs a category');
  const catColor = (c) => (c.slot ? `var(--cat-${c.slot})` : 'var(--neutral)');
  P.catColor = catColor;
  P.catIcon = (id, size) => { const c = L.cat(id); return `<span style="--chip-color:${catColor(c)}" class="lg-chip__icon">${L.icon(c.icon, size || 20)}</span>`; };
  P.chip = (id, o) => attr(ui.chip(id, o), (o && o.attrs) || '');
  P.isWide = () => st.layout !== 'phone';
  P.isDesk = () => st.layout === 'desktop';
  P.simulated = (text) => `<span class="lg-badge lg-badge--proto">Simulated</span>${text ? ` <span class="caption lg-faint">${text}</span>` : ''}`;

  const CUR = { EUR: '€', USD: '$', GBP: '£', CHF: 'CHF ' };
  P.fmtAny = (minor, cur) => (cur === 'EUR' || cur === 'BAM' ? L.fmt(minor, cur) : `${minor < 0 ? '−' : ''}${CUR[cur] || `${cur} `}${(Math.abs(minor) / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
  P.currencies = ['EUR', 'BAM', 'USD', 'GBP', 'CHF'];

  // One row for every kind of entry, so the rules are written once.
  function txMoney(t) {
    if (t.type === 'transfer') return L.moneyPair(t.amount, t.cur, t.base, { tone: 'neutral' });
    if (t.type === 'adjustment') return L.moneyPair(-t.amount, t.cur, t.base, { tone: 'neutral', sign: true });
    if (t.type === 'repayment') return L.moneyPair(t.amount, t.cur, t.base, { tone: 'neutral', sign: true });
    const isIn = t.type === 'income' || t.type === 'refund';
    if (t.orig) return `<span class="money-pair"><span class="money money--negative">−${P.fmtAny(t.orig.amount, t.orig.cur)}</span><span class="money-pair__sub money">${L.fmt(t.base, 'EUR')}</span></span>`;
    return L.moneyPair(isIn ? t.amount : -t.amount, t.cur, t.base, { sign: isIn, tone: isIn ? 'positive' : 'negative' });
  }
  P.txMoney = txMoney;
  function txMeta(t) {
    const acc = D.acc(t.account).name;
    if (t.type === 'transfer') return `${acc} to ${D.acc(t.to).name}`;
    if (t.type === 'adjustment') return 'Balance check, not counted';
    if (t.type === 'repayment') return `Repayment, not income · ${acc}`;
    if (t.flags.includes('review')) return `Needs a category · ${acc}`;
    if (t.parts) return `Split across ${t.parts.length} categories`;
    if (t.share != null) { const left = t.base - t.shareBase; return `My share ${L.fmt(t.shareBase, 'EUR')}, ${L.fmt(left, 'EUR')} owed to me`; }
    if (t.type === 'refund') return `Refund · ${P.catName(t.subcat || t.cat)}`;
    return `${P.catName(t.subcat || t.cat)} · ${acc}`;
  }
  P.txMeta = txMeta;
  const KNOWN = ['receipt', 'split', 'shared', 'recurring', 'refund', 'review'];
  P.txRow = function (t, o) {
    const p = o || {};
    const a = `data-key="t${t.id}" ${act(p.name || 'openTx', t.id)} ${p.extra || ''}`;
    const sel = p.selected ? 'is-selected' : '';
    if (t.type === 'transfer') return `<button type="button" class="lg-tx lg-tx--transfer ${sel}" ${a}><span class="lg-tx__lead">${L.icon('transfer', 20, 'Transfer')}</span><span class="lg-tx__body"><span class="lg-tx__name">${esc(t.merchant)}</span><span class="lg-tx__meta">${txMeta(t)}</span></span><span class="lg-tx__amount">${txMoney(t)}</span></button>`;
    const neutral = t.type === 'adjustment' || t.type === 'repayment';
    const c = t.cat ? L.cat(t.subcat || t.cat) : null;
    const color = c ? catColor(c) : neutral ? 'var(--neutral)' : 'var(--warning)';
    const ic = neutral ? (t.type === 'repayment' ? 'people' : 'flag') : c ? c.icon : 'flag';
    return `<button type="button" class="lg-tx ${sel}" style="--chip-color:${color}" ${a}><span class="lg-tx__lead">${L.icon(ic, 20)}</span><span class="lg-tx__body"><span class="lg-tx__name">${t.merchant ? esc(t.merchant) : 'No merchant'}</span><span class="lg-tx__meta">${txMeta(t)}${ui.flags(t.flags.filter((f) => KNOWN.includes(f)))}</span></span><span class="lg-tx__amount">${txMoney(t)}</span></button>`;
  };

  // ---- Navigation. Going back keeps scroll position and filters ----
  const keyOf = (r) => `${r.name}:${r.arg == null ? '' : r.arg}`;
  const scrolls = {};
  P.go = function (name, arg, o) {
    saveScroll();
    if (o && o.tab) { st.stack = []; st.tab = name; } else st.stack.push(st.route);
    st.route = { name, arg: arg == null ? null : arg };
    st.sheet = null;
    if (o && o.top) delete scrolls[keyOf(st.route)];
    P.render();
  };
  P.back = function () {
    saveScroll();
    delete scrolls[keyOf(st.route)];
    st.route = st.stack.pop() || { name: st.tab, arg: null };
    P.render();
  };
  function scroller() { return P.root && P.root.querySelector('[data-scroll]'); }
  function saveScroll() { const s = scroller(); if (s) scrolls[keyOf(st.route)] = s.scrollTop; }
  P.sheet = (name, arg) => { st.sheet = { name, arg }; P.render(); };
  P.closeSheet = () => { st.sheet = null; P.render(); };
  P.dialog = (d) => { st.dialog = d; P.render(); };
  P.closeDialog = () => { st.dialog = null; P.render(); };

  // Undo holds for five seconds, matching the Add confirmation.
  let toastTimer;
  P.toast = function (text, o) {
    clearTimeout(toastTimer);
    st.toast = Object.assign({ text }, o);
    toastTimer = setTimeout(() => { st.toast = null; P.render(); }, (o && o.ms) || 5000);
    P.render();
  };
  P.withUndo = function (text, fn, o) {
    const restore = G.checkpoint();
    const result = fn();
    P.toast(text, Object.assign({ undo: restore }, o));
    return result;
  };
  P.acts.undo = () => { const t = st.toast; if (t && t.undo) t.undo(); st.toast = null; clearTimeout(toastTimer); st.panelTx = st.panelTx && D.transactions.some((x) => x.id === st.panelTx) ? st.panelTx : null; P.render(); };
  P.acts.toastMore = () => { const t = st.toast; st.toast = null; clearTimeout(toastTimer); if (t && t.more) t.more(); P.render(); };
  P.acts.back = () => P.back();
  P.acts.go = (arg) => { const [name, a] = arg.split(':'); P.go(name, a); };
  P.acts.tab = (name) => { if (name === 'add') P.openAdd(); else P.go(name, null, { tab: true }); };
  P.acts.closeSheet = () => P.closeSheet();
  P.acts.closeDialog = () => P.closeDialog();
  P.acts.dialogConfirm = () => { const d = st.dialog; st.dialog = null; if (d && d.confirm) d.confirm(); P.render(); };
  // Definitions sit in a small tooltip beside the term, inside the app's own frame.
  P.acts.showDef = (term, el) => {
    const box = P.root.querySelector('.app').getBoundingClientRect();
    const r = el.getBoundingClientRect();
    st.tip = { term, x: Math.max(8, Math.min(r.left - box.left - 110, box.width - 248)), y: r.bottom - box.top + 4 > box.height - 120 ? r.top - box.top - 88 : r.bottom - box.top + 4 };
    P.render();
  };
  P.acts.stop = () => {};

  // ---- Shells ----
  const NAV = [['Home', 'home', 'home'], ['History', 'list', 'tx'], null, ['Analytics', 'chart', 'analytics'], ['More', 'menu', 'more']];
  function phoneNav() {
    const tab = st.tab;
    return `<nav class="lg-nav" aria-label="Main">${NAV.map((it) => {
      if (!it) return `<button type="button" class="lg-nav__add" aria-label="Add transaction" ${act('tab', 'add')}>${L.icon('plus', 24)}</button>`;
      return `<button type="button" class="lg-nav__item" ${it[2] === tab ? 'aria-current="page"' : ''} ${act('tab', it[2])}>${L.icon(it[1], 24)}<span>${it[0]}</span></button>`;
    }).join('')}</nav>`;
  }
  const RAIL = [['Home', 'home', 'home'], ['Transactions', 'list', 'tx'], ['Add', 'plus', 'add'], ['Analytics', 'chart', 'analytics'], ['Calendar', 'calendar', 'calendar'], ['Accounts', 'wallet', 'accounts'], ['More', 'menu', 'more']];
  function rail() {
    return `<nav class="lg-rail" aria-label="Main">${RAIL.map(([n, ic, id]) => `<button type="button" class="lg-rail__item ${id === st.tab ? 'is-selected' : ''}" aria-label="${n}" title="${n}" ${act('tab', id)}>${L.icon(ic, 24)}</button>`).join('')}</nav>`;
  }
  const SIDE = [['Home', 'home', 'home'], ['Transactions', 'list', 'tx'], ['Analytics', 'chart', 'analytics'], ['Calendar', 'calendar', 'calendar'], ['Budgets', 'pie', 'budgets'], ['Goals', 'target', 'goals'], ['Accounts', 'wallet', 'accounts'], ['Recurring', 'repeat', 'recurring'], ['Notebook', 'note', 'notebook'], ['Reports', 'page', 'reports'], ['Settings', 'gear', 'settings']];
  P.fileDate = () => 'File from 29 Oct 2026, 08:14';
  function sidebar() {
    return `<nav class="lg-side" aria-label="Main"><div class="lg-inline" style="padding:8px 12px 16px">${L.appIcon(32)}<span class="lg-wordmark">Ledgerly</span></div>${SIDE.map(([n, ic, id]) => `<button type="button" class="lg-side__item ${id === st.tab ? 'is-selected' : ''}" ${id === st.tab ? 'aria-current="page"' : ''} ${act('tab', id)}>${L.icon(ic, 20)}${n}</button>`).join('')}<div style="flex:1;min-height:16px"></div><button type="button" class="p-clickable" ${act('fileInfo')} aria-label="About this read-only copy"><span class="lg-readonly">${L.icon('eye', 16)}<span>Read-only copy<br>${P.fileDate()}</span></span></button></nav>`;
  }

  function overlays() {
    let out = '';
    if (st.sheet) {
      const body = (P.sheets[st.sheet.name] || (() => ''))(st.sheet.arg);
      out += `<div class="lg-phone__overlay" data-key="sheet:${st.sheet.name}" ${act('scrim')}><div class="lg-sheet" ${act('stop')} role="dialog" aria-modal="true"><div class="lg-sheet__grip"></div>${body}</div></div>`;
    }
    if (st.add) out += `<div class="lg-phone__overlay" data-key="add" ${act('scrim')}><div class="lg-sheet" ${act('stop')} role="dialog" aria-modal="true" aria-label="Add transaction"><div class="lg-sheet__grip"></div>${P.addSheet()}</div></div>`;
    if (st.full) out += `<div class="app__full" data-key="full">${(P.views[st.full.name] || (() => ''))(st.full.arg)}</div>`;
    if (st.dialog) {
      const d = st.dialog;
      out += `<div class="app__center" data-key="dialog" role="presentation"><div class="lg-dialog" role="alertdialog" aria-modal="true"><h3>${d.title}</h3><p>${d.text}</p>${d.body || ''}<div class="lg-dialog__actions" style="margin-top:16px">${d.cancel === false || !d.confirm ? '' : P.btn(d.cancel || 'Cancel', 'closeDialog')}${d.confirm ? P.btn(d.ok, 'dialogConfirm', null, { kind: d.danger ? 'danger' : 'primary', state: d.disabled ? 'disabled' : undefined }) : P.btn(d.ok || 'Close', 'closeDialog', null, { kind: 'primary' })}</div></div></div>`;
    }
    if (st.tip) out += `<div class="app__tip" data-key="tip" style="left:${st.tip.x}px;top:${st.tip.y}px">${ui.tooltip(st.tip.term === 'Balance' ? 'Total balance' : st.tip.term, P.defs[st.tip.term])}</div>`;
    if (st.toast) {
      const t = st.toast;
      out += `<div class="app__toasts" data-key="toast"><div class="lg-toast ${t.error ? 'is-error' : ''}" role="status"><span class="lg-toast__text">${t.text}</span>${t.undo ? P.btn('Undo', 'undo', null, { small: true }) : ''}${t.moreLabel ? P.btn(t.moreLabel, 'toastMore', null, { small: true }) : ''}</div></div>`;
    }
    return out;
  }
  P.acts.scrim = (a, el, e) => { if (e.target !== el) return; if (st.add) P.closeAdd(); else P.closeSheet(); };

  function screen() {
    const v = P.views[st.route.name] || P.views.home;
    return v(st.route.arg);
  }

  function appHtml() {
    const l = st.layout;
    const cls = l === 'phone' ? 'app--phone' : l === 'tablet' ? 'app--rail app--wide' : 'app--desk app--wide';
    const nav = l === 'desktop' ? sidebar() : l === 'tablet' ? rail() : '';
    const main = `<main class="app__main">${screen()}</main>`;
    return `<div class="app ${cls}" tabindex="-1" ${st.hidden ? 'data-amounts="hidden"' : ''}>${nav}${main}${l === 'phone' ? phoneNav() : ''}${overlays()}</div>`;
  }

  // One screen as a still, for the screen walls. It uses the same views as the live app.
  P.snapshot = function (cfg) {
    const keep = Object.assign({}, st);
    Object.assign(st, { layout: cfg.layout, device: cfg.layout, route: { name: cfg.route, arg: cfg.arg == null ? null : cfg.arg }, tab: cfg.tab || cfg.route, stack: [], sheet: null, add: null, full: null, dialog: null, toast: null, tip: null, select: null, panelTx: null, filters: {}, txView: 'list', balanceOpen: false, cal: Object.assign({}, st.cal), an: Object.assign({}, st.an) }, cfg.state);
    if (cfg.setup) cfg.setup(st, P);
    D.PACE = Math.min(1, (G.diffDays(G.TODAY, G.current().start) + 1) / G.current().days);
    const html = appHtml();
    Object.assign(st, keep);
    return html;
  };

  // Small DOM patcher: keeps scroll, focus and CSS transitions across a render.
  function morph(a, b) {
    if (a.nodeType !== b.nodeType || a.nodeName !== b.nodeName) { a.replaceWith(b); return; }
    if (a.nodeType === 3 || a.nodeType === 8) { if (a.nodeValue !== b.nodeValue) a.nodeValue = b.nodeValue; return; }
    if (a.nodeType !== 1) return;
    [...a.attributes].forEach((x) => { if (!b.hasAttribute(x.name)) a.removeAttribute(x.name); });
    [...b.attributes].forEach((x) => { if (a.getAttribute(x.name) !== x.value) a.setAttribute(x.name, x.value); });
    if (a.nodeName === 'TEXTAREA') { if (document.activeElement !== a) a.value = b.textContent; return; }
    const kid = (n) => (n.nodeType === 1 ? n.getAttribute('data-key') : null);
    const keyed = new Map();
    [...a.childNodes].forEach((n) => { const k = kid(n); if (k) keyed.set(k, n); });
    let cur = a.firstChild;
    [...b.childNodes].forEach((nb) => {
      const k = kid(nb);
      let match = null;
      if (k && keyed.has(k)) {
        match = keyed.get(k); keyed.delete(k);
        if (match === cur) cur = cur.nextSibling; else a.insertBefore(match, cur);
      } else if (cur && !k && !kid(cur) && cur.nodeType === nb.nodeType && cur.nodeName === nb.nodeName) {
        match = cur; cur = cur.nextSibling;
      }
      if (match) morph(match, nb); else a.insertBefore(nb, cur);
    });
    while (cur) { const n = cur.nextSibling; a.removeChild(cur); cur = n; }
    if (a.nodeName === 'INPUT' && document.activeElement !== a) {
      if (a.type === 'checkbox') a.checked = b.hasAttribute('checked');
      else a.value = b.getAttribute('value') || '';
    }
    if (a.nodeName === 'SELECT') { const opt = [...b.options].find((o) => o.hasAttribute('selected')); if (opt) a.value = opt.value; }
  }

  function chromeHtml() {
    if (!st.chrome) return '';
    return `<header class="pv__bar" aria-label="Prototype controls"><span class="lg-badge lg-badge--proto">Prototype</span><span class="label">Ledgerly</span><span class="pv__spacer"></span>
      ${P.seg([{ label: 'Phone', id: 'phone' }, { label: 'Tablet', id: 'tablet' }, { label: 'Desktop', id: 'desktop' }, { label: 'Fit', id: 'fit' }], st.device, 'device', 'Layout')}
      ${P.seg([{ label: 'Light', id: 'light' }, { label: 'Dark', id: 'dark' }], st.theme, 'themeNow', 'Theme')}
      ${P.btn('Sitemap', 'sitemap', null, { small: true, kind: 'secondary', icon: 'list' })}
      ${P.btn('Reset', 'resetProto', null, { small: true })}
    </header>`;
  }
  P.acts.device = (d) => { st.device = d; st.fixedLayout = d; P.layout(); P.render(); };
  P.acts.themeNow = (t) => { st.themePref = t; P.applyTheme(); P.render(); };
  P.acts.sitemap = () => { st.full = st.full && st.full.name === 'sitemap' ? null : { name: 'sitemap' }; P.render(); };
  P.acts.resetProto = () => { window.location.reload(); };
  P.applyTheme = function () {
    const sys = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    st.theme = st.themePref === 'system' ? sys : st.themePref;
  };

  function pvHtml() {
    const bare = !st.chrome;
    const device = bare ? st.layout : st.device;
    return `<div class="pv ${bare ? 'pv--bare' : ''}" data-theme="${st.theme}" data-accent="${st.accent}" style="font-size:${st.textSize === 'Large' ? '1.125rem' : '1rem'}">${chromeHtml()}<div class="pv__stage"><div class="pv__device pv__device--${device}" data-device>${appHtml()}</div></div></div>`;
  }

  let queued = false;
  let lastKey = null;
  P.render = function () {
    if (!P.root) return;
    P.layout();
    D.PACE = Math.min(1, (G.diffDays(G.TODAY, G.current().start) + 1) / G.current().days);
    const tpl = document.createElement('template');
    tpl.innerHTML = pvHtml();
    const next = tpl.content.firstElementChild;
    if (P.root.firstElementChild) morph(P.root.firstElementChild, next); else P.root.appendChild(next);
    const key = keyOf(st.route);
    const s = scroller();
    if (s && key !== lastKey) s.scrollTop = scrolls[key] || 0;
    lastKey = key;
    const f = P.root.querySelector('[data-autofocus]');
    if (f && f !== document.activeElement && !f.dataset.done) { f.focus(); f.dataset.done = '1'; }
  };
  P.queue = () => { if (queued) return; queued = true; requestAnimationFrame(() => { queued = false; P.render(); }); };

  // Layout is chosen from the space the app really has, so resizing works in any host.
  P.layout = function () {
    const w = P.root ? P.root.clientWidth : 1200;
    if (st.chrome && !st.fixedLayout && w < 600) st.chrome = false;
    const byWidth = w < 680 ? 'phone' : w < 1100 ? 'tablet' : 'desktop';
    if (!st.chrome && !st.lockedLayout) { st.layout = byWidth; st.device = st.layout; return; }
    if (st.device === 'fit') { st.layout = byWidth; return; }
    st.layout = st.device;
    if (st.device === 'tablet' && w < 680) st.layout = 'phone';
  };

  // ---- Events ----
  function onClick(e) {
    if (P.suppressClick) { P.suppressClick = false; e.preventDefault(); return; }
    let el = e.target.closest('[data-act]');
    if (st.tip) { st.tip = null; if (!el || el.getAttribute('data-act') !== 'showDef') { P.render(); if (!el) return; } }
    while (el) {
      const name = el.getAttribute('data-act');
      if (name === 'stop') { if (e.target.closest('[data-act]') === el) return; return; }
      if (P.acts[name]) { P.acts[name](el.getAttribute('data-arg'), el, e); return; }
      el = el.parentElement && el.parentElement.closest('[data-act]');
    }
  }
  function onInput(e) {
    const el = e.target.closest('[data-in]');
    if (!el) return;
    const name = el.getAttribute('data-in');
    const v = el.type === 'checkbox' ? el.checked : el.value;
    if (P.inputs[name]) P.inputs[name](v, el.getAttribute('data-arg'), el);
  }
  function onKey(e) {
    const typing = /INPUT|TEXTAREA|SELECT/.test(e.target.nodeName);
    if ((e.key === 'Enter' || e.key === ' ') && e.target.matches('[data-act][tabindex], [data-act][role="button"]')) {
      e.preventDefault();
      e.target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return;
    }
    if (e.key === 'Escape') {
      if (st.dialog) P.closeDialog(); else if (st.add) P.closeAdd(); else if (st.sheet) P.closeSheet(); else if (st.full) { st.full = null; P.render(); }
      return;
    }
    if (st.add && !typing && P.addKey && P.addKey(e)) { e.preventDefault(); return; }
    if (P.isDesk() && !typing) {
      if (e.key === '/') { e.preventDefault(); P.focusSearch(); }
      if (e.key === '?') { e.preventDefault(); P.dialog({ title: 'Keyboard shortcuts', text: 'This copy is read-only, so shortcuts only find and move.', body: `<div class="lg-stack" style="gap:4px">${P.kv('Search transactions', '<b>/</b>')}${P.kv('Show these shortcuts', '<b>?</b>')}${P.kv('Close a panel or dialog', '<b>Esc</b>')}</div>` }); }
    }
  }
  P.focusSearch = function () {
    if (st.route.name !== 'tx') P.go('tx', null, { tab: true });
    const i = P.root.querySelector('[data-search]');
    if (i) i.focus();
  };

  // Swipe to delete and long-press to select, on phone rows only.
  let press = null;
  function onDown(e) {
    // Keeps keyboard shortcuts alive after a click on a plain part of the page.
    setTimeout(() => { const app = P.root.querySelector('.app'); if (app && document.activeElement === document.body) app.focus({ preventScroll: true }); });
    const row = e.target.closest('[data-swipe] .lg-tx');
    if (!row || e.button) return;
    press = { row, id: Number(row.getAttribute('data-arg')), x: e.clientX, y: e.clientY, dx: 0, moved: false };
    press.timer = setTimeout(() => { if (press && !press.moved) { P.suppressClick = true; const id = press.id; press = null; P.startSelect(id); } }, 480);
  }
  function onMove(e) {
    if (!press) return;
    const dx = e.clientX - press.x; const dy = e.clientY - press.y;
    if (!press.moved && Math.abs(dy) > 10) { clearTimeout(press.timer); press = null; return; }
    if (!press.moved && Math.abs(dx) > 8) { press.moved = true; clearTimeout(press.timer); }
    if (press.moved) { press.dx = Math.min(0, dx); press.row.style.transform = `translateX(${press.dx}px)`; }
  }
  function onUp() {
    if (!press) return;
    clearTimeout(press.timer);
    const { row, dx, moved, id } = press;
    press = null;
    if (!moved) return;
    P.suppressClick = true;
    setTimeout(() => { P.suppressClick = false; }, 60);
    row.style.transform = '';
    if (dx < -row.clientWidth * 0.35) P.deleteTx(id);
  }

  P.mount = function (root, opts) {
    const o = opts || {};
    P.root = root;
    st.chrome = o.chrome !== false;
    if (o.layout) { st.device = o.layout; st.layout = o.layout; st.fixedLayout = o.layout; st.lockedLayout = !!o.locked; }
    else if (root.clientWidth >= 600) { st.device = 'phone'; st.fixedLayout = 'phone'; }
    if (o.theme) { st.themePref = o.theme; st.theme = o.theme; }
    if (o.route) { st.route = { name: o.route, arg: o.arg == null ? null : o.arg }; st.tab = o.tab || o.route; }
    if (o.setup) o.setup(st, P);
    root.addEventListener('click', onClick);
    root.addEventListener('input', onInput);
    root.addEventListener('keydown', onKey);
    root.addEventListener('pointerdown', onDown);
    root.addEventListener('pointermove', onMove);
    root.addEventListener('pointerup', onUp);
    root.addEventListener('pointercancel', onUp);
    root.addEventListener('scroll', (e) => { if (P.onScroll) P.onScroll(e); }, true);
    if (window.ResizeObserver) new ResizeObserver(() => P.queue()).observe(root);
    if (window.matchMedia) window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => { if (st.themePref === 'system') { P.applyTheme(); P.render(); } });
    P.render();
    const app = root.querySelector('.app');
    if (app) app.focus({ preventScroll: true });
    return P;
  };
})(window.Ledgerly);
