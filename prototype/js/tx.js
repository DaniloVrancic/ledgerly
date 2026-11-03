// Transactions: history, search and filters, multi-select, details and the desktop table.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, esc } = P;
  const byId = (id) => D.transactions.find((t) => t.id === Number(id));
  P.byId = byId;

  function activeChips() {
    const f = st.filters; const out = [];
    const chip = (label, key) => `<button type="button" class="lg-pill" aria-pressed="true" ${act('clearFilter', key)} aria-label="Remove filter ${esc(label)}"><span>${esc(label)}</span>${L.icon('x', 16)}</button>`;
    if (f.label) out.push(chip(f.label, '__drill'));
    if (f.type) out.push(chip({ expense: 'Expenses', income: 'Income', transfer: 'Transfers' }[f.type], 'type'));
    if (f.account) out.push(chip(D.acc(f.account).name, 'account'));
    if (f.cat && !f.label) out.push(chip(L.cat(f.cat).name, 'cat'));
    if (f.tag) out.push(chip(`#${f.tag}`, 'tag'));
    if (f.flag) out.push(chip({ receipt: 'Receipts', split: 'Split', shared: 'Shared', recurring: 'Recurring', refund: 'Refunds', review: 'Needs review' }[f.flag], 'flag'));
    if (f.span && !f.label) out.push(chip(f.span, 'span'));
    return out.join('');
  }
  const quick = () => [['Food', { cat: 'food' }], ['Transfers', { type: 'transfer' }], ['Receipts', { flag: 'receipt' }]].map(([l, x]) => P.pill(l, false, 'quickFilter', JSON.stringify(x))).join('');
  function filterBar() {
    const f = st.filters;
    const n = activeChips();
    return `<span class="lg-input lg-search">${L.icon('search', 20)}<input data-in="txSearch" data-search aria-label="Search transactions" value="${esc(f.q || '')}" placeholder="Search title, merchant or amount">${f.q ? `<button type="button" class="lg-icon-btn" style="min-width:32px;min-height:32px" aria-label="Clear search" ${act('clearFilter', 'q')}>${L.icon('x', 16)}</button>` : ''}</span>
      <div class="app__rowchips">${P.pill('Filters', st.sheet && st.sheet.name === 'filters', 'openSheet', 'filters', 'tag')}${n || quick()}</div>`;
  }
  P.acts.quickFilter = (json) => { Object.assign(st.filters, JSON.parse(json)); st.limit = 40; P.render(); };
  P.acts.clearFilter = (k) => {
    if (k === '__drill') st.filters = { q: st.filters.q }; else if (k === 'span') { delete st.filters.span; delete st.filters.start; delete st.filters.end; } else delete st.filters[k];
    P.render();
  };
  P.inputs.txSearch = (v) => { st.filters.q = v; st.limit = 40; P.render(); };

  function currentList() { return G.filterTx(st.filters); }
  const isFiltered = () => Object.keys(st.filters).some((k) => k !== 'q' ? st.filters[k] != null : !!st.filters.q);

  function groupsHtml(list) {
    const groups = new Map();
    list.slice(0, st.limit).forEach((t) => { if (!groups.has(t.date)) groups.set(t.date, []); groups.get(t.date).push(t); });
    const filtered = isFiltered();
    return [...groups.entries()].map(([date, rows]) => {
      const net = filtered ? D.dayNet(rows) : D.dayNet(D.transactions.filter((t) => t.date === date));
      return `<div data-key="day${date}">${ui.day(date, net)}<div class="lg-card lg-card--flush" style="margin:0 12px 8px">${rows.map((t) => {
        const sel = st.select && st.select.has(t.id);
        const row = P.txRow(t, { name: 'txTap', selected: sel });
        return P.isDesk() ? row : `<div class="p-swipe" data-swipe data-key="sw${t.id}"><div class="p-swipe__under" aria-hidden="true">${L.icon('x', 20)}Delete</div>${row}</div>`;
      }).join('')}</div></div>`;
    }).join('');
  }
  P.onScroll = function (e) {
    if (st.route.name !== 'tx' || st.txView !== 'list' || !e.target.matches || !e.target.matches('[data-scroll]')) return;
    const el = e.target;
    if (el.scrollHeight - el.scrollTop - el.clientHeight < 400 && st.limit < currentList().length) { st.limit += 40; P.queue(); }
  };
  function summaryLine(list) {
    if (!isFiltered()) return '';
    const spend = list.reduce((s, t) => s + G.countedFor(t, st.filters.cat), 0);
    const income = list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0), 0);
    return `<div class="lg-between" style="padding:4px 16px"><span class="body-small lg-muted">${list.length} ${list.length === 1 ? 'entry' : 'entries'}</span><span class="body-small">${spend ? `${P.eur(-spend, { tone: 'negative' })} ` : ''}${income ? P.eur(income, { sign: true, tone: 'positive' }) : ''}</span></div>`;
  }
  function emptyList() {
    if (isFiltered()) return P.state('search', 'No matches', 'Nothing matches these filters. Try a shorter search or remove a filter.', P.btn('Clear filters', 'clearAll', null, { kind: 'secondary' }));
    return P.state('plus', 'Nothing here yet', 'Transactions you add will appear here, grouped by day.', P.isDesk() ? '' : P.btn('Add a transaction', 'tab', 'add', { kind: 'primary', icon: 'plus' }));
  }
  P.acts.clearAll = () => { st.filters = {}; P.render(); };

  function bulkBar() {
    if (!st.select) return '';
    const n = st.select.size;
    return `<div class="p-bulk" role="toolbar" aria-label="Selected entries"><b>${n} selected</b>${P.btn('Category', 'bulkCat', null, { small: true, kind: 'secondary', state: n ? undefined : 'disabled' })}${P.btn('Tag', 'bulkTag', null, { small: true, kind: 'secondary', state: n ? undefined : 'disabled' })}${P.btn('Delete', 'bulkDelete', null, { small: true, kind: 'danger', state: n ? undefined : 'disabled' })}${P.iconBtn('x', 'Stop selecting', 'bulkStop')}</div>`;
  }
  P.startSelect = (id) => { st.select = new Set([id]); P.render(); };
  P.acts.txTap = (id) => {
    const n = Number(id);
    if (st.select) { if (st.select.has(n)) st.select.delete(n); else st.select.add(n); P.render(); return; }
    P.openTx(n);
  };
  P.acts.openTx = (id) => P.openTx(Number(id));
  P.openTx = function (id) {
    if (P.isWide() && (st.route.name === 'tx')) { st.panelTx = id; P.render(); return; }
    P.go('txd', id);
  };
  P.acts.bulkStop = () => { st.select = null; P.render(); };
  P.acts.bulkCat = () => P.sheet('pickCat', { bulk: true });
  P.acts.bulkTag = () => P.sheet('bulkTag');
  P.sheets.bulkTag = () => `<h3>Add a tag</h3><p>It is added to ${st.select.size} entries.</p>${P.input('bulkTagName', st.bulkTag || '', { placeholder: 'trip', label: 'Tag', focus: true })}<div style="height:12px"></div>${P.btn('Add tag', 'bulkTagSave', null, { kind: 'primary', block: true })}`;
  P.inputs.bulkTagName = (v) => { st.bulkTag = v; };
  P.acts.bulkTagSave = () => {
    const tag = (st.bulkTag || '').trim();
    if (!tag) return;
    const ids = [...st.select];
    P.withUndo(`Tag added to ${ids.length} entries`, () => ids.forEach((id) => { const t = byId(id); if (!t.tags.includes(tag)) t.tags.push(tag); G.bump(); }));
    st.select = null; st.sheet = null; st.bulkTag = ''; P.render();
  };
  P.acts.bulkDelete = () => {
    const ids = [...st.select];
    st.select = null;
    P.withUndo(`${ids.length} ${ids.length === 1 ? 'entry' : 'entries'} deleted`, () => G.remove(ids));
  };
  P.deleteTx = (id) => { P.withUndo('Transaction deleted', () => G.remove(id)); };

  // Category picker shared by details, Needs Review and bulk edit. History keeps every category.
  P.sheets.pickCat = function (o) {
    const q = G.fold(st.pickQ || '');
    const t = o.id ? byId(o.id) : null;
    const kind = t && t.type === 'income' ? 'income' : 'expense';
    const ids = G.allCats(kind).filter((id) => !q || G.fold(L.cat(id).name).includes(q));
    return `<h3>Choose a category</h3><span class="lg-input lg-search" style="margin-bottom:8px">${L.icon('search', 20)}<input data-in="pickQ" aria-label="Search categories" placeholder="Search categories" value="${esc(st.pickQ || '')}" data-autofocus></span>
      <div class="lg-card lg-card--flush">${ids.map((id) => { const c = L.cat(id); return `<button type="button" class="lg-row" data-key="p${id}" ${act('pickCat', id)}>${ui.catTile(c)}<span class="lg-row__body"><span class="lg-row__title">${esc(c.name)}</span>${c.parent ? `<span class="lg-row__sub">${esc(L.cat(c.parent).name)}</span>` : ''}</span></button>`; }).join('') || '<div class="lg-state"><p>No category with that name.</p></div>'}</div>`;
  };
  P.inputs.pickQ = (v) => { st.pickQ = v; P.render(); };
  P.acts.pickCat = (id) => {
    const o = st.sheet.arg;
    const parent = G.parentOf(id); const sub = parent === id ? null : id;
    st.pickQ = '';
    if (o.bulk) {
      const ids = [...st.select];
      st.sheet = null; st.select = null;
      P.withUndo(`${ids.length} entries moved to ${esc(L.cat(id).name)}`, () => ids.forEach((x) => { const t = byId(x); G.update(x, { cat: parent, subcat: sub, parts: undefined }); t.flags = t.flags.filter((f) => f !== 'split'); }));
      return;
    }
    if (o.field === 'recat') { st.sheet = null; P.withUndo(`Moved to ${esc(L.cat(id).name)}`, () => G.update(o.id, { cat: parent, subcat: sub })); return; }
    st.sheet = null;
    G.update(o.id, { cat: parent, subcat: sub });
    P.render();
  };

  P.sheets.filters = function () {
    const f = st.filters;
    const n = currentList().length;
    const types = [{ label: 'All', id: '' }, { label: 'Expense', id: 'expense', kind: 'expense' }, { label: 'Income', id: 'income', kind: 'income' }, { label: 'Transfer', id: 'transfer', kind: 'transfer' }];
    const cats = [['', 'All categories']].concat(G.allCats('expense').concat(G.catIds('income')).filter((x, i, a) => a.indexOf(x) === i).map((id) => [id, L.cat(id).parent ? `${L.cat(L.cat(id).parent).name} · ${L.cat(id).name}` : L.cat(id).name]));
    const flags = [['receipt', 'Receipts'], ['split', 'Split'], ['shared', 'Shared'], ['recurring', 'Recurring'], ['refund', 'Refunds'], ['review', 'Needs review']];
    const spans = ['This month', 'Last month', 'Last 3 months', 'This year'];
    return `<div class="lg-between"><h3 style="margin:0">Filters</h3>${P.iconBtn('x', 'Close', 'closeSheet')}</div><div class="lg-stack" style="gap:16px">
      ${P.field('Type', P.seg(types, f.type || '', 'fType', 'Type'))}
      ${P.field('Account', `<div class="lg-add__pills">${P.pill('All', !f.account, 'fAccount', '')}${D.ACCOUNTS.map((a) => P.pill(esc(a.name), f.account === a.id, 'fAccount', a.id)).join('')}</div>`)}
      ${P.field('Category', P.select('fCat', f.cat || '', cats, { label: 'Category' }))}
      ${P.field('Period', `<div class="lg-add__pills">${spans.map((s) => P.pill(s, f.span === s, 'fSpan', s)).join('')}</div><div class="p-grid2" style="margin-top:4px">${P.input('fStart', f.start || '', { type: 'date', label: 'From' })}${P.input('fEnd', f.end || '', { type: 'date', label: 'To' })}</div>`)}
      ${P.field('Marked with', `<div class="lg-add__pills">${flags.map(([id, l]) => P.pill(l, f.flag === id, 'fFlag', id)).join('')}</div>`)}
      ${P.field('Tag', `<div class="lg-add__pills">${G.tags().map((t) => P.pill(`#${esc(t)}`, f.tag === t, 'fTag', t)).join('') || '<span class="p-note">No tags yet.</span>'}</div>`)}
      ${P.btn(`Show ${n} ${n === 1 ? 'entry' : 'entries'}`, 'closeSheet', null, { kind: 'primary', block: true })}
    </div>`;
  };
  const setF = (k, v) => { if (v) st.filters[k] = v; else delete st.filters[k]; delete st.filters.label; st.limit = 40; P.render(); };
  P.acts.fType = (v) => setF('type', v);
  P.acts.fAccount = (v) => setF('account', v);
  P.inputs.fCat = (v) => setF('cat', v);
  P.acts.fFlag = (v) => setF('flag', st.filters.flag === v ? '' : v);
  P.acts.fTag = (v) => setF('tag', st.filters.tag === v ? '' : v);
  P.inputs.fStart = (v) => { delete st.filters.span; setF('start', v); };
  P.inputs.fEnd = (v) => { delete st.filters.span; setF('end', v); };
  P.acts.fSpan = (s) => {
    if (st.filters.span === s) { P.acts.clearFilter('span'); return; }
    const c = G.current();
    const r = s === 'This month' ? c : s === 'Last month' ? G.prevPeriod(c) : s === 'Last 3 months' ? { start: G.prevPeriod(G.prevPeriod(c)).start, end: c.end } : { start: '2026-01-01', end: '2026-12-31' };
    Object.assign(st.filters, { span: s, start: r.start, end: r.end });
    delete st.filters.label; st.limit = 40; P.render();
  };

  // ---- Desktop: a dense, sortable, read-only table with a details side panel ----
  const COLS = [['date', 'Date'], ['title', 'Title'], ['cat', 'Category'], ['account', 'Account'], ['base', 'Amount']];
  const sortValue = {
    date: (t) => `${t.date}${t.time}`, title: (t) => G.fold(G.titleOf(t)), cat: (t) => G.fold(t.cat ? L.cat(t.subcat || t.cat).name : ''), account: (t) => D.acc(t.account).name,
    base: (t) => (t.type === 'income' || t.type === 'refund' || t.type === 'repayment' ? t.base : -t.base),
  };
  P.acts.sort = (k) => { st.sort = { key: k, dir: st.sort.key === k ? -st.sort.dir : (k === 'date' || k === 'base' ? -1 : 1) }; P.render(); };
  function table(list) {
    const { key, dir } = st.sort;
    const rows = list.slice().sort((a, b) => { const x = sortValue[key](a); const y = sortValue[key](b); return (x < y ? -1 : x > y ? 1 : 0) * dir; }).slice(0, st.limit * 2);
    const head = COLS.map(([k, l]) => `<th ${k === 'base' ? 'data-end' : ''} aria-sort="${key === k ? (dir > 0 ? 'ascending' : 'descending') : 'none'}"><button type="button" ${act('sort', k)}>${l}${key === k ? L.icon(dir > 0 ? 'up' : 'down', 16) : ''}</button></th>`).join('');
    const body = rows.map((t) => {
      const c = t.cat ? L.cat(t.subcat || t.cat) : null;
      const label = t.type === 'transfer' ? 'Transfer' : t.type === 'adjustment' ? 'Untracked' : t.type === 'repayment' ? 'Repayment' : t.parts ? 'Split' : c ? c.name : 'Needs a category';
      const ic = t.type === 'transfer' ? 'transfer' : t.type === 'adjustment' ? 'flag' : t.type === 'repayment' ? 'people' : c ? c.icon : 'flag';
      return `<tr data-key="r${t.id}" class="${st.panelTx === t.id ? 'is-selected' : ''}" tabindex="0" ${act('openTx', t.id)}><td style="white-space:nowrap">${G.shortDate(t.date)} ${t.date.slice(0, 4)}</td><td>${esc(G.titleOf(t))}${t.merchant && t.merchant !== t.title ? ` <span class="lg-faint">${esc(t.merchant)}</span>` : ''}${ui.flags(t.flags.filter((f) => ['receipt', 'split', 'shared', 'recurring', 'refund', 'review'].includes(f)))}</td><td><span class="p-table__cat" style="--chip-color:${c ? P.catColor(c) : 'var(--neutral)'}"><span class="lg-chip__icon">${L.icon(ic, 16)}</span>${esc(label)}</span></td><td class="lg-muted">${t.type === 'transfer' ? `${D.acc(t.account).name} to ${D.acc(t.to).name}` : D.acc(t.account).name}</td><td data-end>${P.txMoney(t)}</td></tr>`;
    }).join('');
    return `<div class="lg-card lg-card--flush"><div class="p-scrollbox"><table class="p-table"><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table></div></div>`;
  }

  P.views.tx = function () {
    const desk = P.isDesk(); const wide = P.isWide();
    if (st.txView === 'calendar' && !wide) return P.views.calendar();
    const list = currentList();
    const seg = !wide ? P.seg(['List', 'Calendar'], st.txView === 'calendar' ? 'Calendar' : 'List', 'txSwitch', 'View') : '';
    const tools = desk ? '' : `${P.iconBtn('list', st.select ? 'Stop selecting' : 'Select entries', st.select ? 'bulkStop' : 'selectMode')}`;
    const back = st.stack.length && !wide ? P.iconBtn('chevron', 'Back', 'back').replace('<svg', '<svg style="transform:rotate(180deg)"') : '';
    const head = `<div class="app__head ${back ? '' : 'app__head--root'}">${back}<h2 class="lg-title">Transactions</h2>${tools}</div>`;
    const content = !list.length ? emptyList() : desk ? `<div class="app__body" style="padding-top:0">${table(list)}</div>` : `<div class="p-days">${groupsHtml(list)}</div>`;
    const sticky = `<div class="app__sticky">${seg}${filterBar()}</div>`;
    const scroll = `<div class="app__scroll" data-scroll>${head}${sticky}${summaryLine(list)}${content}</div>`;
    if (wide && st.panelTx && byId(st.panelTx)) return `<div class="app__split">${scroll}<aside class="app__panel" aria-label="Transaction details"><div class="app__panel-body">${P.txDetails(byId(st.panelTx), true)}</div></aside></div>`;
    return `${scroll}${bulkBar()}`;
  };
  P.acts.txSwitch = (v) => { st.txView = v === 'Calendar' ? 'calendar' : 'list'; P.render(); };
  P.acts.selectMode = () => { st.select = new Set(); P.render(); };
  P.acts.closePanel = () => { st.panelTx = null; P.render(); };

  // ---- Details: directly editable, saves itself ----
  const unlocked = new Set();
  P.acts.unlockTx = (id) => { unlocked.add(Number(id)); P.render(); };
  function receiptArt(t, i) {
    return `<svg class="p-receipt" viewBox="0 0 96 128" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" role="img" aria-label="Placeholder receipt ${i + 1} for ${esc(G.titleOf(t))}"><path d="M14 8h68v110l-8-5-9 5-8-5-9 5-8-5-9 5-8-5-9 5V8z"/><path d="M26 28h44M26 42h30M26 54h36M26 66h24M26 86h44"/></svg>`;
  }
  P.receiptArt = receiptArt;
  // Desktop is a read-only copy, so details are a plain summary, not disabled fields.
  function txSummary(t, panel) {
    const kinds = { expense: 'Expense', income: 'Income', transfer: 'Transfer', refund: 'Refund', adjustment: 'Untracked adjustment', repayment: 'Repayment' };
    const rows = [
      P.kv('Account', `<b>${t.type === 'transfer' ? `${esc(D.acc(t.account).name)} to ${esc(D.acc(t.to).name)}` : esc(D.acc(t.account).name)}</b>`),
      t.cat ? P.kv('Category', `<b>${esc(t.parts ? 'Split' : P.catName(t.subcat || t.cat))}</b>`) : '',
      P.kv('Date', `<b>${G.longDate(t.date)}, ${t.time}</b>`),
      t.tags && t.tags.length ? P.kv('Tags', `<b>${esc(t.tags.join(', '))}</b>`) : '',
      t.orig ? P.kv('Rate', `<b>1 ${t.orig.cur} = ${t.orig.rate} EUR</b>`) : '',
    ].join('');
    const parts = t.parts ? `<div class="lg-card lg-stack" style="gap:0"><div class="label">Split across ${t.parts.length} categories</div>${t.parts.map(([c, m, s]) => P.kv(esc(P.catName(s || c)), P.eur(m))).join('')}</div>` : '';
    const repaid = D.transactions.filter((r) => r.type === 'repayment' && r.of === t.id).reduce((s, r) => s + r.base, 0);
    const share = t.share != null ? `<div class="lg-card lg-stack" style="gap:0"><div class="label">My share</div>${P.kv('Paid', P.eur(t.base))}${P.kv('Counted as spending', P.eur(t.shareBase))}${P.kv(`Owed to me${t.owedFrom ? `, ${esc(t.owedFrom)}` : ''}`, P.eur(t.base - t.shareBase - repaid), 'p-kv--total')}</div>` : '';
    const n = t.flags.includes('receipt') ? (t.attachments || 1) : 0;
    return `<div class="lg-between"><span class="label">${kinds[t.type]}</span>${panel ? P.iconBtn('x', 'Close details', 'closePanel') : ''}</div>
      <div><div class="lg-row__title">${esc(G.titleOf(t))}</div>${t.merchant ? `<div class="body-small lg-muted">${esc(t.merchant)}</div>` : ''}<div class="amount-large">${P.txMoney(t)}</div></div>
      <div class="lg-stack" style="gap:0">${rows}</div>${parts}${share}
      ${t.note ? `<p class="p-note" style="white-space:pre-wrap">${esc(t.note)}</p>` : ''}
      ${n ? `<div class="lg-field"><span class="lg-field__label">Attachments</span><div class="p-attachments">${Array.from({ length: n }, (_, i) => receiptArt(t, i)).join('')}</div></div>` : ''}
      <p class="p-note">This copy is read-only. Edits are made on the phone or tablet.</p>`;
  }
  P.txDetails = function (t, panel) {
    const ro = P.isDesk();
    if (ro) return txSummary(t, panel);
    const locked = !ro && G.isReconciled(t) && !unlocked.has(t.id);
    const off = ro || locked;
    const dis = (html) => (off ? html.replace(/<(input|textarea|select)/g, '<$1 disabled').replace('class="lg-input"', 'class="lg-input is-disabled"') : html);
    const f = (label, html, hint) => P.field(label, dis(html), hint);
    const cur = t.cur;
    const kinds = { expense: 'Expense', income: 'Income', transfer: 'Transfer', refund: 'Refund', adjustment: 'Untracked adjustment', repayment: 'Repayment' };
    const canCat = t.type === 'expense' || t.type === 'income' || t.type === 'refund';
    const catRow = canCat ? P.field('Category', `<button type="button" class="lg-pill" style="justify-content:flex-start" ${off ? 'disabled' : act('openPickCat', t.id)}>${t.cat ? P.catIcon(t.subcat || t.cat, 16) : L.icon('flag', 16)}<span>${esc(t.parts ? 'Split, see below' : P.catName(t.subcat || t.cat))}</span></button>`) : '';
    const money = t.orig ? `<div class="p-note">${P.fmtAny(t.orig.amount, t.orig.cur)} at a rate you entered, ${t.orig.rate} EUR. ${L.fmt(t.base, 'EUR')} on this account.</div>` : cur !== 'EUR' ? `<div class="p-note">${L.fmt(t.base, 'EUR')} at the fixed rate.</div>` : '';
    const parts = t.parts ? `<div class="lg-card lg-stack" style="gap:0"><div class="label">Split across ${t.parts.length} categories</div>${t.parts.map(([c, m, s]) => P.kv(`${P.catIcon(s || c, 16).replace('class="lg-chip__icon"', 'class="lg-chip__icon" ')} ${esc(P.catName(s || c))}`, P.eur(m))).join('')}</div>` : '';
    const repaid = t.share != null ? D.transactions.filter((r) => r.type === 'repayment' && r.of === t.id).reduce((s, r) => s + r.base, 0) : 0;
    const owed = t.share != null ? t.base - t.shareBase - repaid : 0;
    const share = t.share != null ? `<div class="lg-card lg-stack" style="gap:0"><div class="label lg-inline" style="gap:4px">My share${P.info('Owed to me')}</div>${P.kv('Paid', P.eur(t.base))}${P.kv('My share, counted as spending', P.eur(t.shareBase))}${repaid ? P.kv('Repaid', P.eur(repaid)) : ''}${P.kv(`Owed to me${t.owedFrom ? `, ${esc(t.owedFrom)}` : ''}`, P.eur(owed), 'p-kv--total')}${owed > 0 && !ro ? `<div style="margin-top:8px">${P.btn(`Record ${L.fmt(owed, 'EUR')} repayment`, 'repay', t.id, { small: true, kind: 'secondary', block: true })}</div>` : ''}</div>` : '';
    const linked = t.of ? (() => { const o = byId(t.of); return o ? `<div class="p-note">${t.type === 'refund' ? 'Refund of' : 'Repayment for'}: ${P.link(esc(G.titleOf(o)), 'openTx', o.id)}</div>` : ''; })() : '';
    const refunds = D.transactions.filter((r) => r.type === 'refund' && r.of === t.id);
    const refundsHtml = refunds.length ? `<div class="p-note">Refunded: ${refunds.map((r) => P.link(L.fmt(r.amount, r.cur), 'openTx', r.id)).join(', ')}</div>` : '';
    const notes = G.NOTES.filter((n) => n.links.some((l) => l.type === 'transaction' && l.id === t.id));
    const nCount = t.flags.includes('receipt') ? (t.attachments || 1) : 0;
    const atts = `<div class="lg-field"><span class="lg-field__label">Attachments</span><div class="p-attachments">${Array.from({ length: nCount }, (_, i) => receiptArt(t, i)).join('')}</div>${nCount ? '<span class="lg-field__hint">Placeholder image in this prototype.</span>' : ''}${ro ? (nCount ? '' : '<span class="p-note">None.</span>') : `<div style="margin-top:4px">${P.btn('Attach receipt', 'attachReceipt', t.id, { small: true, kind: 'secondary', icon: 'receipt' })}</div>`}</div>`;
    const warn = locked ? `<div class="lg-card" style="background:var(--warning-tint);border-color:transparent"><div class="lg-inline" style="flex-wrap:nowrap;align-items:flex-start;color:var(--warning)">${L.icon('alert', 20)}<span class="body-small">This entry is before the last balance check of ${esc(D.acc(t.account).name)}, on ${G.shortDate(G.checks[t.account])}. Changing it changes a checked balance.</span></div><div style="margin-top:8px">${P.btn('Edit anyway', 'unlockTx', t.id, { small: true, kind: 'secondary' })}</div></div>` : '';
    const actions = ro ? `<p class="p-note">This copy is read-only. Edits are made on the phone or tablet.</p>` : `<div class="lg-stack" style="gap:8px">${P.btn('Duplicate', 'txDuplicate', t.id, { kind: 'secondary', block: true, icon: 'plus' })}${t.type === 'expense' ? P.btn('Record a refund', 'openRefund', t.id, { kind: 'secondary', block: true, icon: 'undo' }) : ''}${P.btn('Delete', 'txDelete', t.id, { kind: 'danger', block: true })}</div>`;
    const accountField = t.type === 'transfer'
      ? `<div class="p-grid2">${f('From', P.select('txAccount', t.account, D.ACCOUNTS.map((a) => [a.id, a.name]), { arg: t.id, label: 'From' }))}${f('To', P.select('txTo', t.to, D.ACCOUNTS.map((a) => [a.id, a.name]), { arg: t.id, label: 'To' }))}</div>`
      : f('Account', P.select('txAccount', t.account, D.ACCOUNTS.map((a) => [a.id, a.name]), { arg: t.id, label: 'Account' }));
    const header = panel ? `<div class="lg-between"><span class="label">${kinds[t.type]}</span>${P.iconBtn('x', 'Close details', 'closePanel')}</div>` : '';
    const transferNote = t.type === 'transfer' ? `<p class="p-note">Transfers never count as income or spending.</p>` : '';
    return `${header}${warn}
      ${f(`Amount, ${cur === 'EUR' ? 'EUR' : 'KM'}`, P.input('txAmount', (t.amount / 100).toFixed(2), { arg: t.id, mode: 'decimal', label: 'Amount' }))}${money}
      ${t.type === 'adjustment' ? '' : f('Title', P.input('txTitle', t.title || '', { arg: t.id, label: 'Title', placeholder: 'No title' }))}${t.type === 'adjustment' || t.type === 'transfer' ? '' : f('Merchant, optional', P.input('txMerchant', t.merchant || '', { arg: t.id, label: 'Merchant, optional', placeholder: 'None' }))}${P.repeatLine(t)}
      ${catRow}${transferNote}${parts}${share}${linked}${refundsHtml}${accountField}
      <div class="p-grid2">${f('Date', P.input('txDate', t.date, { arg: t.id, type: 'date', label: 'Date' }))}${P.field('Time', `<span class="lg-input is-disabled"><input disabled aria-label="Time" value="${t.time}"></span>`, 'Recorded automatically.')}</div>
      ${f('Tags', P.input('txTags', (t.tags || []).join(', '), { arg: t.id, label: 'Tags', placeholder: 'None' }))}
      ${f('Note', P.textarea('txNote', t.note || '', { arg: t.id, label: 'Note', placeholder: 'Anything to remember' }))}
      ${atts}
      ${notes.length ? `<div class="lg-field"><span class="lg-field__label">Linked notes</span>${notes.map((n) => P.link(esc(n.title), 'go', `note:${n.id}`)).join('')}</div>` : ''}
      ${ro ? '' : '<div class="caption lg-faint">Changes save themselves.</div>'}
      ${actions}`;
  };
  P.views.txd = function (id) {
    const t = byId(id);
    if (!t) return `<div class="app__scroll" data-scroll>${P.screenHead('Transaction')}${P.state('search', 'Entry deleted', 'This entry is no longer in Ledgerly.', P.btn('Go back', 'back', null, { kind: 'secondary' }))}</div>`;
    return `<div class="app__scroll" data-scroll>${P.screenHead(t.type === 'transfer' ? 'Transfer' : 'Transaction', G.longDate(t.date))}<div class="app__body app__narrow">${P.txDetails(t)}</div></div>`;
  };
  P.screenHead = function (title, sub, trail) {
    const back = P.iconBtn('chevron', 'Back', 'back').replace('<svg', '<svg style="transform:rotate(180deg)"');
    const canBack = st.stack.length > 0 || !['home', 'tx', 'analytics', 'more', 'calendar', 'budgets', 'goals', 'accounts', 'recurring', 'notebook', 'reports', 'settings'].includes(st.route.name);
    return `<div class="app__head ${canBack ? '' : 'app__head--root'}">${canBack ? back : ''}<div style="flex:1 1 auto;min-width:0"><h2 class="lg-title">${title}</h2>${sub ? `<div class="app__head-sub">${sub}</div>` : ''}</div>${trail || ''}</div>`;
  };
  P.inputs.txAmount = (v, id) => { const m = P.minorOf(v); if (m > 0) G.update(Number(id), { amount: m }); P.queue(); };
  P.inputs.txMerchant = (v, id) => { G.update(Number(id), { merchant: v || null }); };
  P.inputs.txTitle = (v, id) => { G.update(Number(id), { title: v || null }); P.queue(); };
  P.inputs.txAccount = (v, id) => { G.update(Number(id), { account: v }); P.render(); };
  P.inputs.txTo = (v, id) => { G.update(Number(id), { to: v }); P.render(); };
  P.inputs.txDate = (v, id) => { if (v) { G.update(Number(id), { date: v }); P.render(); } };
  P.inputs.txTags = (v, id) => { G.update(Number(id), { tags: v.split(',').map((s) => s.trim()).filter(Boolean) }); };
  P.inputs.txNote = (v, id) => { G.update(Number(id), { note: v }); };
  P.acts.openPickCat = (id) => P.sheet('pickCat', { id: Number(id) });
  P.acts.txDuplicate = (id) => {
    const copy = P.withUndo('Duplicated to today', () => G.duplicate(Number(id)));
    if (st.route.name === 'txd') st.route = { name: 'txd', arg: copy.id }; else st.panelTx = copy.id;
    P.render();
  };
  P.acts.txDelete = (id) => { const wasDetail = st.route.name === 'txd'; st.panelTx = null; if (wasDetail) P.back(); P.deleteTx(Number(id)); };
  P.acts.repay = (id) => { const t = byId(id); P.sheet('repay', t.id); };
  P.sheets.repay = function (id) {
    const t = byId(id);
    const left = G.owedList().find((o) => o.t.id === id);
    if (st.repayAmt == null && left) st.repayAmt = (left.left / 100).toFixed(2);
    return `<h3>Record a repayment</h3><p>Money coming back for ${esc(G.titleOf(t))}. It is not income.</p>
      ${P.field('Amount, EUR', P.input('repayAmt', st.repayAmt || '', { mode: 'decimal', label: 'Amount', focus: true }))}<div style="height:8px"></div>
      ${P.field('Received in', P.select('repayAccount', st.repayAccount || t.account, D.ACCOUNTS.map((a) => [a.id, a.name]), { label: 'Received in' }))}<div style="height:12px"></div>
      ${P.btn('Save repayment', 'repaySave', id, { kind: 'primary', block: true })}`;
  };
  P.inputs.repayAmt = (v) => { st.repayAmt = v; };
  P.inputs.repayAccount = (v) => { st.repayAccount = v; };
  P.acts.repaySave = (id) => {
    const eur = P.minorOf(st.repayAmt);
    if (!eur) return;
    const account = st.repayAccount || byId(id).account;
    const cur = D.acc(account).cur;
    const amount = cur === 'EUR' ? eur : Math.round(eur * G.PEG);
    st.sheet = null; st.repayAmt = null; st.repayAccount = null;
    P.withUndo(`Repayment saved, ${L.fmt(eur, 'EUR')}. Income did not change.`, () => G.repay(Number(id), amount, account));
  };
  P.acts.openRefund = (id) => { st.refundAmt = (byId(id).amount / 100).toFixed(2); P.sheet('refund', Number(id)); };
  P.sheets.refund = function (id) {
    const t = byId(id);
    return `<h3>Record a refund</h3><p>It is linked to ${esc(G.titleOf(t))}, reduces ${esc(P.catName(t.cat))} spending and is never income.</p>
      ${P.field(`Amount, ${t.cur === 'EUR' ? 'EUR' : 'KM'}`, P.input('refundAmt', st.refundAmt || '', { mode: 'decimal', label: 'Amount', focus: true }))}<div style="height:12px"></div>
      ${P.btn('Save refund', 'refundSave', id, { kind: 'primary', block: true })}`;
  };
  P.inputs.refundAmt = (v) => { st.refundAmt = v; };
  P.acts.refundSave = (id) => {
    const m = P.minorOf(st.refundAmt);
    if (!m) return;
    st.sheet = null;
    P.withUndo(`Refund saved, ${L.fmt(m, byId(id).cur)}`, () => G.refund(Number(id), m));
  };
})(window.Ledgerly);
