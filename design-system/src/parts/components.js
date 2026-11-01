// Component builders. Each returns an HTML string that uses only the classes in ledgerly.css.
// React components can wrap the same class names; these keep the system free of dependencies.
(function (L) {
  const icon = L.icon;
  const D = L.data;
  const CATS = {};
  (L.tokens ? L.tokens.categories : []).forEach(([id, name, slot, ic]) => { CATS[id] = { id, name, slot, icon: ic }; });
  L.cat = (id) => CATS[id] || D.CUSTOM.find((c) => c.id === id) || { id: 'other', name: 'Needs review', slot: 0, icon: 'flag' };
  const catColor = (c) => (c.slot ? `var(--cat-${c.slot})` : 'var(--neutral)');
  const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');

  // Grouping and the sign are written here so formatting cannot vary between screens.
  function number(minor) {
    return (Math.abs(minor) / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  L.fmt = function (minor, cur, sign) {
    const n = number(minor);
    const body = cur === 'EUR' ? `€${n}` : `${n} KM`;
    if (minor < 0) return `−${body}`;
    return sign ? `+${body}` : body;
  };
  // Compact form for chart labels and calendar cells only. Rows and cards show every digit.
  L.fmtShort = function (minor) {
    const v = Math.abs(minor) / 100;
    const s = v >= 1e6 ? `${(v / 1e6).toFixed(2)}M` : v >= 10000 ? `${Math.round(v / 1000)}k` : v >= 1000 ? `${(v / 1000).toFixed(1)}k` : `${Math.round(v)}`;
    return `${minor < 0 ? '−' : ''}${s}`;
  };
  // Signed and in whole currency, for calendar cells and ledger lines.
  L.fmtCell = function (minor) {
    const v = Math.abs(minor) / 100;
    const n = v >= 10000 ? `${Math.round(v / 1000)}k` : v >= 1000 ? `${(v / 1000).toFixed(1)}k` : `${Math.round(v)}`;
    if (Math.round(v) === 0) return '€0';
    return `${minor < 0 ? '\u2212' : '+'}€${n}`;
  };
  L.fmtWhole = function (minor) {
    const n = Math.round(Math.abs(minor) / 100).toLocaleString('en-US');
    return `${minor < 0 ? '\u2212' : ''}€${n}`;
  };
  L.money = function (minor, cur, o) {
    const opt = o || {};
    const cls = opt.tone ? ` money--${opt.tone}` : '';
    return `<span class="money${cls}">${L.fmt(minor, cur || 'EUR', opt.sign)}</span>`;
  };
  // The original amount sits first. The converted amount is smaller, below, and never coloured.
  L.moneyPair = function (minor, cur, base, o) {
    const main = L.money(minor, cur, o);
    if (cur === 'EUR') return `<span class="money-pair">${main}</span>`;
    return `<span class="money-pair">${main}<span class="money-pair__sub money">${L.fmt(Math.abs(base), 'EUR')}</span></span>`;
  };
  const fitLevel = (text, a, b) => (text.length > b ? 2 : text.length > a ? 1 : 0);

  const ui = {};
  ui.button = (label, o) => {
    const p = o || {};
    const cls = ['lg-btn', p.kind && `lg-btn--${p.kind}`, p.small && 'lg-btn--small', p.block && 'lg-btn--block', p.state && `is-${p.state}`].filter(Boolean).join(' ');
    const dis = p.state === 'disabled' ? ' disabled' : '';
    const inner = p.state === 'loading' ? `<span class="lg-spinner" aria-hidden="true"></span>${label}` : (p.icon ? icon(p.icon, 20) : '') + label;
    return `<button type="button" class="${cls}"${dis}${p.attr ? ` ${p.attr}` : ''}>${inner}</button>`;
  };
  ui.input = (o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    const icoR = p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : '';
    const hint = p.state === 'error' ? `<span class="lg-field__hint">${icon('alert', 16)}${p.error || 'Enter an amount above zero.'}</span>` : p.hint ? `<span class="lg-field__hint">${p.hint}</span>` : '';
    return `<label class="lg-field ${st}"><span class="lg-field__label">${p.label || 'Merchant'}</span><span class="lg-input ${st}"><input value="${esc(p.value || '')}" placeholder="${esc(p.placeholder || '')}"${p.state === 'disabled' ? ' disabled' : ''}>${icoR}</span>${hint}</label>`;
  };
  ui.search = (o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    const right = p.value ? `<span class="lg-faint">${icon('x', 16)}</span>` : p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : '';
    return `<span class="lg-input lg-search ${st}">${icon('search', 20)}<input aria-label="Search transactions" value="${esc(p.value || '')}" placeholder="Search merchant or amount"${p.state === 'disabled' ? ' disabled' : ''}>${right}</span>`;
  };
  ui.switch = (label, o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    return `<label class="lg-switch ${st}"><input type="checkbox" role="switch"${p.on || p.state === 'selected' ? ' checked' : ''}${p.state === 'disabled' ? ' disabled' : ''}><span class="lg-switch__track"></span><span>${label}</span></label>`;
  };
  ui.checkbox = (label, o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    return `<label class="lg-check ${st}"><input type="checkbox"${p.on || p.state === 'selected' ? ' checked' : ''}${p.state === 'disabled' ? ' disabled' : ''}><span class="lg-check__box">${icon('check', 16)}</span><span>${label}</span></label>`;
  };
  ui.segmented = (items, o) => {
    const p = o || {};
    return `<div class="lg-seg" role="group"${p.label ? ` aria-label="${p.label}"` : ''} data-seg>${items.map((it, i) => {
      const t = typeof it === 'string' ? { label: it } : it;
      const cls = p.states && p.states[i] ? `is-${p.states[i]}` : '';
      return `<button type="button" class="lg-seg__item ${cls}" aria-pressed="${i === (p.selected || 0)}"${t.kind ? ` data-kind="${t.kind}"` : ''}>${t.icon ? icon(t.icon, 16) : ''}${t.label}</button>`;
    }).join('')}</div>`;
  };
  ui.section = (title, action) => `<div class="lg-section"><h3 class="lg-section__title">${title}</h3>${action ? `<button type="button" class="lg-link">${action}</button>` : ''}</div>`;
  ui.row = (o) => {
    const p = o || {};
    return `<button type="button" class="lg-row ${p.state ? `is-${p.state}` : ''}"${p.state === 'disabled' ? ' disabled' : ''}><span class="lg-row__lead">${icon(p.icon || 'wallet', 20)}</span><span class="lg-row__body"><span class="lg-row__title">${p.title}</span>${p.sub ? `<span class="lg-row__sub">${p.sub}</span>` : ''}</span><span class="lg-row__trail">${p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : p.trail || icon('chevron', 20)}</span></button>`;
  };
  ui.tooltip = (term, def) => `<div class="lg-tip" role="tooltip"><b>${term}.</b> ${def}</div>`;
  ui.info = (term, def) => `<button type="button" class="lg-icon-btn" aria-label="${esc(`${term}: ${def}`)}" title="${esc(def)}" style="min-width:24px;min-height:24px">${icon('info', 16)}</button>`;
  ui.toast = (text, o) => {
    const p = o || {};
    return `<div class="lg-toast ${p.state ? `is-${p.state}` : ''}" role="status"><span class="lg-toast__text">${text}</span>${p.undo === false ? '' : ui.button('Undo', { small: true, attr: 'data-undo' })}${p.more ? ui.button(p.more, { small: true }) : ''}</div>`;
  };
  ui.nav = (active, o) => {
    const p = o || {};
    const items = [['Home', 'home'], ['Transactions', 'list'], null, ['Analytics', 'chart'], ['More', 'menu']];
    return `<nav class="lg-nav" aria-label="Main">${items.map((it, i) => {
      if (!it) return `<button type="button" class="lg-nav__add ${p.addState ? `is-${p.addState}` : ''}" aria-label="Add transaction">${icon('plus', 24)}</button>`;
      const on = i === active;
      return `<button type="button" class="lg-nav__item ${p.states && p.states[i] ? `is-${p.states[i]}` : ''}"${on ? ' aria-current="page"' : ''}>${icon(it[1], 24)}<span>${it[0] === 'Transactions' ? 'History' : it[0]}</span></button>`;
    }).join('')}</nav>`;
  };
  ui.rail = (active, st) => `<nav class="lg-rail" aria-label="Main">${['home', 'list', 'plus', 'chart', 'calendar', 'wallet', 'menu'].map((ic, i) => `<button type="button" class="lg-rail__item ${i === active ? 'is-selected' : ''} ${st && st[i] ? `is-${st[i]}` : ''}" aria-label="${['Home', 'Transactions', 'Add', 'Analytics', 'Calendar', 'Accounts', 'More'][i]}">${icon(ic, 24)}</button>`).join('')}</nav>`;
  ui.sidebar = (active, st) => {
    const items = [['Home', 'home'], ['Transactions', 'list'], ['Analytics', 'chart'], ['Calendar', 'calendar'], ['Budgets', 'pie'], ['Goals', 'target'], ['Accounts', 'wallet'], ['Reports', 'page'], ['Settings', 'gear']];
    return `<nav class="lg-side" aria-label="Main"><div class="lg-inline" style="padding:8px 12px 16px">${L.appIcon(28)}<span class="lg-wordmark">Ledgerly</span></div>${items.map(([n, ic], i) => `<button type="button" class="lg-side__item ${i === active ? 'is-selected' : ''} ${st && st[i] ? `is-${st[i]}` : ''}"${i === active ? ' aria-current="page"' : ''}>${icon(ic, 20)}${n}</button>`).join('')}<div style="flex:1;min-height:16px"></div>${ui.readOnly()}</nav>`;
  };
  ui.readOnly = () => `<div class="lg-readonly">${icon('eye', 16)}<span>Read-only copy<br>File from 29 Oct 2026, 08:14</span></div>`;
  ui.state = (kind) => {
    if (kind === 'loading') return `<div class="lg-stack" style="padding:16px" aria-busy="true" aria-label="Loading"><span class="lg-skel" style="width:40%"></span><span class="lg-skel" style="width:90%"></span><span class="lg-skel" style="width:72%"></span></div>`;
    if (kind === 'error') return `<div class="lg-state lg-state--error">${L.stateMark('alert')}<h3>This file could not be read</h3><p>It may be damaged. Nothing in Ledgerly was changed.</p>${ui.button('Choose another file', { kind: 'secondary' })}</div>`;
    return `<div class="lg-state">${L.stateMark('plus')}<h3>Nothing here yet</h3><p>Transactions you add will appear here, grouped by day.</p>${ui.button('Add a transaction', { kind: 'primary', icon: 'plus' })}</div>`;
  };
  ui.key = (label, st, attr) => `<button type="button" class="lg-key ${st ? `is-${st}` : ''}"${attr ? ` ${attr}` : ''}>${label}</button>`;
  ui.keypad = () => `<div class="lg-keypad" data-keypad>${['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'].map((k) => ui.key(k, '', `data-key="${k}"`)).join('')}${ui.key(icon('backspace', 24, 'Delete digit'), '', 'data-key="del"')}</div>`;
  ui.chip = (id, o) => {
    const p = o || {};
    const c = L.cat(id);
    const color = catColor(c);
    const st = p.state ? `is-${p.state}` : '';
    return `<button type="button" class="lg-chip ${st}" style="--chip-color:${color}"${p.state === 'disabled' || p.disabled ? ' disabled' : ''}${p.state === 'selected' ? ' aria-pressed="true"' : ''} data-chip="${c.name}"><span class="lg-chip__icon">${icon(c.icon, 20)}</span>${p.label || c.name}</button>`;
  };
  ui.chipAll = (o) => `<button type="button" class="lg-chip lg-chip--all ${o && o.state ? `is-${o.state}` : ''}"${o && o.disabled ? ' disabled' : ''}><span class="lg-chip__icon">${icon('search', 20)}</span>All</button>`;
  ui.chipLater = (o) => `<button type="button" class="lg-chip lg-chip--later ${o && o.state ? `is-${o.state}` : ''}"${o && o.disabled ? ' disabled' : ''} data-chip="Later"><span class="lg-chip__icon">${icon('clock', 20)}</span>Later</button>`;

  const FLAG = { receipt: ['receipt', 'Receipt'], split: ['split', 'Split'], shared: ['people', 'Shared cost'], recurring: ['repeat', 'Recurring'], refund: ['undo', 'Refund'], review: ['flag', 'Needs review'] };
  ui.flags = (flags) => (flags && flags.length ? `<span class="lg-tx__flags">${flags.map((f) => `<span class="${f === 'review' ? 'lg-tx__flag--review' : ''}">${icon(FLAG[f][0], 16, FLAG[f][1])}</span>`).join('')}</span>` : '');
  ui.tx = (t, o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    if (t.type === 'transfer') {
      const to = D.acc(t.to);
      return `<button type="button" class="lg-tx lg-tx--transfer ${st}"><span class="lg-tx__lead">${icon('transfer', 20, 'Transfer')}</span><span class="lg-tx__body"><span class="lg-tx__name">${t.merchant}</span><span class="lg-tx__meta">${D.acc(t.account).name} to ${to.name}</span></span><span class="lg-tx__amount">${L.moneyPair(t.amount, t.cur, t.base, { tone: 'neutral' })}</span></button>`;
    }
    const c = L.cat(t.cat);
    const color = c.slot ? `var(--cat-${c.slot})` : 'var(--warning)';
    const isIn = t.type === 'income' || t.type === 'refund';
    const money = L.moneyPair(isIn ? t.amount : -t.amount, t.cur, t.base, { sign: isIn, tone: isIn ? 'positive' : 'negative' });
    const meta = t.type === 'adjustment' ? 'Balance check, not counted' : t.sub || (t.cat ? `${c.name} · ${D.acc(t.account).name}` : `Needs a category · ${D.acc(t.account).name}`);
    const flags = t.flags.slice();
    return `<button type="button" class="lg-tx ${st}" style="--chip-color:${color}"><span class="lg-tx__lead">${p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : icon(c.icon, 20)}</span><span class="lg-tx__body"><span class="lg-tx__name">${t.merchant ? esc(t.merchant) : 'No merchant'}</span><span class="lg-tx__meta">${meta}${ui.flags(flags)}</span></span><span class="lg-tx__amount">${money}</span></button>`;
  };
  ui.day = (date, net) => `<div class="lg-day"><span>${D.dayLabel(date)}</span>${L.money(net, 'EUR', { sign: true, tone: net > 0 ? 'positive' : net < 0 ? 'negative' : 'neutral' })}</div>`;

  ui.balance = (o) => {
    const p = o || {};
    const s = D.summary();
    const total = p.value != null ? p.value : s.total;
    const text = L.fmt(total, 'EUR');
    const delta = s.total - s.lastMonth;
    const dir = delta >= 0;
    const body = p.state === 'loading'
      ? '<span class="lg-skel" style="height:2.25rem;width:70%;margin:8px 0"></span>'
      : `<span class="lg-balance__value" data-fit="${fitLevel(text, 13, 16)}">${L.money(total, 'EUR')}</span>`;
    const rows = D.accounts().map((a) => `<div class="lg-balance__row"><span>${a.name}</span>${L.money(a.balance, a.cur)}</div>`).join('');
    return `<section class="lg-balance ${p.open ? 'is-open' : ''} ${p.state ? `is-${p.state}` : ''}"><button type="button" class="lg-balance__toggle" aria-expanded="${!!p.open}" data-balance><span class="lg-balance__label"><span>Total balance</span><span class="lg-balance__chev">${icon('chevronDown', 20)}</span></span>${body}<span class="lg-balance__change">${icon(dir ? 'up' : 'down', 16)}${L.money(delta, 'EUR', { sign: true })} from last month</span></button><div class="lg-balance__list">${rows}<div class="lg-balance__row lg-balance__row--strong" style="margin-top:8px"><span>Earmarked for goals</span>${L.money(s.earmarked, 'EUR')}</div><div class="lg-balance__row lg-balance__row--strong"><span>Free to use</span>${L.money(s.free, 'EUR')}</div></div></section>`;
  };
  const DEFS = { Income: 'Income transactions only.', Spending: 'Expenses minus refunds.', Net: 'Income minus spending.', 'Savings rate': 'Net divided by income.' };
  ui.metric = (label, value, o) => {
    const p = o || {};
    const v = p.raw ? value : L.money(value, 'EUR', { sign: p.sign, tone: p.tone });
    const len = p.raw ? 4 : L.fmt(value, 'EUR', p.sign).length;
    return `<div class="lg-metric ${p.state ? `is-${p.state}` : ''}"><span class="lg-metric__label">${label}${ui.info(label, DEFS[label] || '')}</span><span class="lg-metric__value" data-fit="${len > 12 ? 1 : 0}">${p.state === 'loading' ? '<span class="lg-skel" style="height:1.5rem;width:70%;margin:4px 0"></span>' : v}</span><span class="lg-metric__delta">${p.delta || ''}</span></div>`;
  };
  ui.budget = (b, o) => {
    const p = o || {};
    const c = L.cat(b.cat);
    const pct = Math.round(b.ratio * 100);
    const label = { normal: `${pct}%, on track`, warning: `${pct}%, near the limit`, over: `${pct}%, over the limit` }[b.state];
    const ico = { normal: 'check', warning: 'alert', over: 'alert' }[b.state];
    const rem = b.left >= 0 ? `${L.money(b.left, 'EUR')} left` : `${L.money(-b.left, 'EUR')} over`;
    return `<div class="${p.flat ? '' : 'lg-card'}"><div class="lg-between"><span class="lg-inline" style="--chip-color:var(--cat-${c.slot})"><span class="lg-chip__icon">${icon(c.icon, 20)}</span><span class="label">${c.name}</span></span><span class="body-small">${L.money(b.spent, 'EUR')} <span class="lg-faint">of ${L.money(b.limit, 'EUR')}</span></span></div><div class="lg-bar lg-bar--${b.state === 'normal' ? 'ok' : b.state}" role="img" aria-label="${c.name} budget ${pct} percent used, expected pace ${Math.round(D.PACE * 100)} percent"><span class="lg-bar__fill" style="width:${Math.min(100, pct)}%"></span><span class="lg-bar__pace" style="left:${D.PACE * 100}%"></span></div><div class="lg-between"><span class="lg-budget__status lg-budget__status--${b.state}">${icon(ico, 16)}${label}</span><span class="caption lg-faint">${rem}</span></div></div>`;
  };
  ui.goal = (g) => {
    const pct = Math.round((g.saved / g.target) * 100);
    return `<div class="lg-card"><div class="lg-between"><span class="lg-inline">${icon(g.icon, 20)}<span class="label">${g.name}</span></span><span class="caption lg-muted">${pct}%</span></div><div class="lg-bar lg-bar--accent" role="img" aria-label="${pct} percent of goal"><span class="lg-bar__fill" style="width:${pct}%"></span></div><div class="body-small lg-muted">${L.money(g.saved, 'EUR')} of ${L.money(g.target, 'EUR')}</div></div>`;
  };
  ui.attention = (title, sub, action, o) => {
    const p = o || {};
    const ic = p.icon || 'alert';
    return `<div class="lg-attn ${p.state ? `is-${p.state}` : ''}"><span class="lg-attn__icon">${icon(ic, 20)}</span><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem;line-height:1.25rem">${title}</span><span class="lg-row__sub">${sub}</span></span>${ui.button(action, { kind: 'secondary', small: true, state: p.state === 'disabled' ? 'disabled' : p.state === 'loading' ? 'loading' : undefined, attr: 'data-attn' })}</div>`;
  };
  ui.recurring = (state) => {
    const m = { planned: ['Planned', 'clock', ''], due: ['Due', 'alert', 'lg-badge--due'], posted: ['Posted', 'check', 'lg-badge--posted'] }[state];
    return `<span class="lg-badge ${m[2]}">${icon(m[1], 16)}${m[0]}</span>`;
  };
  ui.dayCell = (o) => {
    const p = o || {};
    const h = p.heat || 0;
    const style = p.up ? '--cell-bg:var(--positive-tint);--cell-fg:var(--positive)' : `--cell-bg:var(--heat-${h});--cell-fg:var(--on-heat-${h === 5 ? 'high' : 'low'})`;
    const marks = (p.marks || []).map((m) => ({ recurring: icon('repeat', 12, 'Recurring'), income: icon('up', 12, 'Income'), high: icon('flag', 12, 'High spending'), planned: icon('clock', 12, 'Planned') }[m])).join('');
    const cls = ['lg-cell', p.state && `is-${p.state}`, p.today && 'is-today', p.outside && 'is-outside', p.planned && 'is-planned'].filter(Boolean).join(' ');
    const cat = p.cat ? `<span class="lg-cell__cat">${icon(L.cat(p.cat).icon, 16)}</span>` : '';
    return `<button type="button" class="${cls}" style="${style}"${p.date ? ` data-day="${p.date}"` : ''}${p.selected ? ' aria-pressed="true"' : ''}${p.label ? ` aria-label="${esc(p.label)}"` : ''}${p.tip ? ` data-tip="${esc(p.tip)}"` : ''}><span class="lg-cell__top"><span class="lg-cell__date">${p.day}</span>${cat}</span><span class="lg-cell__amount"><span class="is-short">${p.amount || ''}</span><span class="is-full">${p.full || p.amount || ''}</span></span><span class="lg-cell__foot"><span class="lg-cell__marks">${marks}</span>${p.count ? `<span class="lg-cell__count">${p.count}</span>` : ''}</span></button>`;
  };
  ui.backup = (state) => {
    const m = {
      healthy: ['shieldCheck', 'Backed up 2 days ago', 'Data, attachments and settings. Verified.', ''],
      overdue: ['clock', 'Last backup 12 days ago', 'Open Ledgerly with your backup folder available.', 'Back up now'],
      failed: ['alert', 'Backup failed', 'Ledgerly could not write to your backup folder. Your data is safe on this phone.', 'Choose folder'],
    }[state];
    return `<div class="lg-card lg-card--flush"><div class="lg-backup lg-backup--${state}"><span class="lg-backup__icon">${icon(m[0], 24)}</span><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem;line-height:1.25rem">${m[1]}</span><span class="lg-row__sub">${m[2]}</span>${m[3] ? `<span style="display:block;margin-top:8px">${ui.button(m[3], { kind: 'secondary', small: true })}</span>` : ''}</span></div></div>`;
  };
  ui.widget = (st) => `<div class="lg-widget ${st ? `is-${st}` : ''}"><span class="lg-widget__brand">${L.appIcon(28)}Add expense</span><button type="button" class="lg-widget__add ${st ? `is-${st}` : ''}" aria-label="Add a transaction">${icon('plus', 24)}</button></div>`;


  // ---- Categories ----
  ui.catTile = (c, size) => `<span class="lg-tile" style="--chip-color:${catColor(c)}">${c.img ? `<img src="${c.img}" alt="">` : icon(c.icon, size || 20)}</span>`;
  ui.categoryRow = (id, o) => {
    const p = o || {};
    const c = L.cat(id);
    const sub = p.state === 'error' ? 'Could not save this change' : p.state === 'disabled' ? 'Archived, kept in history' : D.accountsLabel(id);
    return `<button type="button" class="lg-row ${p.state ? `is-${p.state}` : ''}"${p.state === 'disabled' ? ' disabled' : ''}>${ui.catTile(c)}<span class="lg-row__body"><span class="lg-row__title">${esc(c.name)}</span><span class="lg-row__sub">${c.custom ? `<span class="lg-badge">Yours</span>` : ''}${sub}</span></span><span class="lg-row__trail lg-faint">${p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : icon('chevron', 20)}</span></button>`;
  };
  ui.categoryList = (kind, account) => D.categories(kind, account).map((id) => ui.categoryRow(id)).join('');
  ui.addChips = (account, kind, disabled) => `${D.categories(kind, account).slice(0, 6).map((id) => ui.chip(id, { disabled })).join('')}${ui.chipAll({ disabled })}${ui.chipLater({ disabled })}`;
  ui.iconPicker = (selected, o) => {
    const p = o || {};
    const names = p.names || L.pickIcons;
    return `<div class="lg-iconpick" role="group" aria-label="Icon">${names.map((n, i) => `<button type="button" class="lg-iconpick__item ${p.states && p.states[i] ? `is-${p.states[i]}` : ''}" aria-pressed="${n === selected}" aria-label="${n}" data-pick-icon="${n}"${p.states && p.states[i] === 'disabled' ? ' disabled' : ''}>${icon(n, 24)}</button>`).join('')}</div>`;
  };
  const SWATCHES = ['Indigo', 'Leaf', 'Sky', 'Orchid', 'Pine', 'Violet', 'Lavender', 'Periwinkle', 'Olive', 'Rose', 'Berry', 'Deep purple'];
  ui.colourPicker = (selected, o) => {
    const p = o || {};
    return `<div class="lg-colourpick" role="group" aria-label="Colour">${SWATCHES.map((n, i) => `<button type="button" class="lg-colourpick__item ${p.states && p.states[i] ? `is-${p.states[i]}` : ''}" style="--chip-color:var(--cat-${i + 1})" aria-pressed="${i + 1 === selected}" aria-label="${n}" data-pick-colour="${i + 1}"${p.states && p.states[i] === 'disabled' ? ' disabled' : ''}><span>${icon('check', 16)}</span></button>`).join('')}</div>`;
  };
  ui.accountPicker = (selected, o) => {
    const p = o || {};
    const all = !selected || !selected.length;
    return `<div class="lg-stack" data-pick-accounts style="gap:4px">${ui.switch('All accounts', { on: all }).replace('<input', '<input data-pick-all')}<div class="lg-accountpick" role="group" aria-label="Accounts">${D.ACCOUNTS.map((a, i) => {
      const on = !all && selected.includes(a.id);
      const st = p.states && p.states[i];
      return `<button type="button" class="lg-accountpick__item ${st ? `is-${st}` : ''}" aria-pressed="${on}" data-pick-account="${a.id}"${all || st === 'disabled' ? ' disabled' : ''}><span class="lg-accountpick__check">${icon('check', 16)}</span>${a.name}<span class="lg-faint caption">${a.cur === 'EUR' ? 'EUR' : 'KM'}</span></button>`;
    }).join('')}</div></div>`;
  };
  let editors = 0;
  ui.categoryEditor = (o) => {
    const p = o || {};
    editors += 1;
    const seed = { name: p.name || '', icon: p.icon || 'paw', slot: p.slot || 9 };
    const preview = { name: seed.name || 'New category', icon: seed.icon, slot: seed.slot };
    return `<div class="lg-cated" data-cat-editor data-kind="expense" data-icon="${seed.icon}" data-slot="${seed.slot}">
      <div class="lg-between"><h3 style="margin:0">New category</h3>${p.close ? `<button type="button" class="lg-icon-btn" aria-label="Close" data-cat-close>${icon('x', 20)}</button>` : ''}</div>
      <div class="lg-cated__preview" data-cat-preview>${ui.catTile(preview, 24)}<span class="lg-row__body"><span class="lg-row__title">${esc(preview.name)}</span><span class="lg-row__sub">${(p.accounts || []).map((a) => D.acc(a).name).join(', ') || 'All accounts'}</span></span></div>
      <div class="lg-field" data-cat-name><label class="lg-field__label" for="cat-name-${editors}">Name</label><span class="lg-input"><input id="cat-name-${editors}" value="${esc(seed.name)}" placeholder="For example Čišćenje" maxlength="32"></span><span class="lg-field__hint" data-cat-hint>Shown on chips and in reports.</span></div>
      <div class="lg-field"><span class="lg-field__label">Type</span>${ui.segmented([{ label: 'Expense', kind: 'expense', icon: 'down' }, { label: 'Income', kind: 'income', icon: 'up' }], { label: 'Type' })}</div>
      <div class="lg-field"><span class="lg-field__label">Icon</span>${ui.iconPicker(seed.icon)}<label class="lg-btn lg-btn--secondary lg-btn--small lg-btn--block lg-cated__upload">${icon('image', 20)}<span data-cat-upload-label>Use my own image</span><input type="file" accept="image/*" data-pick-image></label></div>
      <div class="lg-field"><span class="lg-field__label">Colour</span>${ui.colourPicker(seed.slot)}</div>
      <div class="lg-field"><span class="lg-field__label">Accounts</span>${ui.accountPicker(p.accounts)}<span class="lg-field__hint">It appears on the Add sheet for these accounts. History and reports always keep it.</span></div>
      ${ui.button('Save category', { kind: 'primary', block: true, attr: 'data-cat-save' })}
    </div>`;
  };

  // Forced-state grid used by the component specimens.
  ui.states = (cells) => `<div class="ds-states">${cells.map(([name, html]) => `<div class="ds-state"><div class="ds-state__name">${name}</div>${html}</div>`).join('')}</div>`;
  L.ui = ui;
})(window.Ledgerly = window.Ledgerly || {});
