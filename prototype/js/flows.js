// Needs Review, Monthly close, First launch, the widget, the state gallery and the sitemap.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, esc } = P;
  const ro = () => P.isDesk();

  // ---- Needs Review: one tap finishes an entry ----
  function reviewRow(t) {
    const chips = G.chips(t.account, t.type === 'income' ? 'income' : 'expense').slice(0, 4).map((id) => P.chip(id, { attrs: act('reviewChip', `${t.id}|${id}`) })).join('');
    const all = P.attr(ui.chipAll(), act('reviewAll', t.id));
    return `<div class="lg-card lg-stack" data-key="rv${t.id}" style="gap:8px"><div class="lg-between" style="flex-wrap:nowrap;align-items:flex-start"><button type="button" class="p-clickable" style="flex:1 1 auto;min-width:0" ${act('openTxFull', t.id)}><span class="lg-row__title" style="display:block">${esc(G.titleOf(t))}</span><span class="lg-row__sub">${D.dayLabel(t.date)} · ${esc(D.acc(t.account).name)}</span></button><span class="lg-tx__amount">${P.txMoney(t)}</span></div>${ro() ? '' : `<div class="lg-chips">${chips}${all}</div>`}</div>`;
  }
  P.reviewList = function () {
    const list = D.review();
    if (!list.length) return P.state('check', 'All reviewed', 'Every entry has a category. New amount-only entries will wait here.', '');
    return list.map(reviewRow).join('');
  };
  P.views.review = function () {
    const n = D.review().length;
    return P.scroll(P.screenHead('Needs Review', n ? `${n} ${n === 1 ? 'entry' : 'entries'}` : ''), P.reviewList(), 'app__narrow');
  };
  P.acts.openTxFull = (id) => P.go('txd', Number(id));
  P.acts.reviewChip = (arg) => {
    const [id, cat] = arg.split('|');
    const parent = G.parentOf(cat);
    P.withUndo(`Moved to ${esc(L.cat(cat).name)}`, () => G.update(Number(id), { cat: parent, subcat: parent === cat ? null : cat }));
  };
  P.acts.reviewAll = (id) => P.sheet('pickCat', { id: Number(id), field: 'recat' });

  // ---- Monthly close: about two minutes, five short steps ----
  const STEPS = ['Check account balances', 'Clear Needs Review', 'Mark due items paid', 'Read the summary', 'Add a note'];
  P.views.close = function () {
    const c = (st.closeRun = st.closeRun || { step: 0, checked: {}, note: '' });
    const p = G.current(); const prev = G.prevPeriod(p);
    if (ro()) return P.scroll(P.screenHead('Monthly close', p.label), `${P.monthTiles(p, prev)}<p class="p-note">The monthly close runs on the phone or tablet, where entries are made. This copy is read-only.</p>`, 'app__wrap');
    if (G.S.closed[p.key] && c.step < 5) c.step = 5;
    const head = P.screenHead('Monthly close', c.step < 5 ? `${p.label}, step ${c.step + 1} of 5` : p.label);
    const bar = `<div class="p-steps" aria-hidden="true">${STEPS.map((_, i) => `<i class="${i <= c.step ? 'is-on' : ''}"></i>`).join('')}</div>`;
    let body = '';
    if (c.step === 0) {
      body = `<p class="p-note">Compare each balance with your bank app and wallet.</p><div class="lg-card lg-card--flush">${D.accounts().map((a) => {
        const done = c.checked[a.id];
        return `<div class="p-row-action" data-key="c${a.id}" style="flex-wrap:nowrap"><span class="lg-row__body" style="flex:1 1 auto"><span class="lg-row__title">${esc(a.name)}</span><span class="lg-row__sub p-amount-sm">${L.money(a.balance, a.cur)}</span><span class="lg-row__sub">${done ? 'Checked' : `Last checked ${G.shortDate(G.checks[a.id])}`}</span></span>${done ? `<span style="color:var(--positive);padding-right:8px">${L.icon('check', 20, 'Checked')}</span>` : `${P.btn('Matches', 'closeMatch', a.id, { small: true, kind: 'secondary' })}${P.btn('Differs', 'checkBalance', a.id, { small: true })}`}</div>`;
      }).join('')}</div>`;
    } else if (c.step === 1) {
      body = `<p class="p-note">Give every entry a category so the summary is complete.</p>${P.reviewList()}`;
    } else if (c.step === 2) {
      const due = D.RECURRING.filter((r) => r.state === 'due');
      body = due.length ? `<p class="p-note">Mark what you have paid. Nothing posts by itself.</p><div class="lg-card lg-card--flush">${due.map((r) => `<div class="p-row-action" data-key="${r.id}"><span class="lg-row__body"><span class="lg-row__title">${esc(r.name)}</span><span class="lg-row__sub">${ui.recurring('due')}${G.shortDate(r.date)}</span></span><span class="p-amount-sm">${L.money(-r.amount, r.cur, { tone: 'negative' })}</span>${P.btn('Mark paid', 'confirmDue', r.id, { small: true, kind: 'secondary' })}</div>`).join('')}</div>` : P.state('check', 'No bills waiting', 'Every due bill for this month is confirmed.', '');
    } else if (c.step === 3) {
      const s = G.periodStats(p);
      const over = D.budgets().filter((b) => b.state === 'over' && b.every === 'Monthly');
      body = `${P.monthTiles(p, prev)}<div class="lg-card lg-stack" style="gap:4px"><div class="label">In short</div>${G.insights(p).map((n) => `<div class="p-note">${esc(n.text)}</div>`).join('')}${s.ranked[0] ? `<div class="p-note">${esc(L.cat(s.ranked[0].cat).name)} was the largest category at ${L.fmt(s.ranked[0].amount, 'EUR')}.</div>` : ''}${over.length ? `<div class="p-note">Over the limit: ${over.map((b) => `${esc(L.cat(b.cat).name)} by ${L.fmt(-b.left, 'EUR')}`).join(', ')}.</div>` : '<div class="p-note">No budget went over its limit.</div>'}</div>`;
    } else if (c.step === 4) {
      body = `${P.field('A note for this month, optional', P.textarea('closeNote', c.note, { label: 'A note for this month', placeholder: 'What stood out?' }), 'Saved in Notebook.')}`;
    } else {
      body = P.state('check', `${p.label} is closed`, 'Balances are checked and the month is saved. You can still edit entries, with a warning first.', P.btn('Go to Home', 'tab', 'home', { kind: 'primary' }));
    }
    const nav = c.step < 5 ? `<div class="lg-stack" style="gap:8px">${P.btn(c.step === 4 ? 'Close the month' : 'Continue', 'closeNext', null, { kind: 'primary', block: true })}${c.step ? P.btn('Back', 'closePrev', null, { block: true }) : ''}</div>` : '';
    return P.scroll(head, `${bar}${c.step < 5 ? `<h3 class="lg-section__title">${STEPS[c.step]}</h3>` : ''}${body}${nav}`, 'app__narrow');
  };
  P.acts.closeMatch = (id) => { G.checks[id] = G.TODAY; st.closeRun.checked[id] = true; G.bump(); P.render(); };
  P.acts.closePrev = () => { st.closeRun.step -= 1; P.render(); };
  P.inputs.closeNote = (v) => { st.closeRun.note = v; };
  P.acts.closeNext = () => {
    const c = st.closeRun;
    if (c.step === 4) {
      const p = G.current();
      G.S.closed[p.key] = true;
      if (c.note.trim()) G.NOTES.unshift({ id: `n${Date.now()}`, title: `${p.label} close`, date: G.TODAY, tags: ['monthly'], body: c.note.trim(), links: [] });
      G.bump();
    }
    c.step += 1;
    P.render();
  };

  // ---- First launch ----
  P.acts.firstRun = () => { st.sheet = null; st.first = { step: 'choose', name: 'Main Bank', cur: 'BAM', open: '' }; st.full = { name: 'first' }; P.render(); };
  P.views.first = function () {
    const f = st.first;
    if (f.step === 'account') {
      return `<div class="p-first"><div>${L.appIcon(48)}</div><h2 class="lg-title">Your first account</h2><p class="p-note">Add the account you use most. You can add the others later.</p>
        ${P.field('Name', P.input('frName', f.name, { label: 'Name', focus: true }))}${P.field('Currency', P.seg([{ label: 'EUR', id: 'EUR' }, { label: 'BAM', id: 'BAM' }], f.cur, 'frCur', 'Currency'))}
        ${P.field(`Balance today, ${f.cur === 'EUR' ? 'EUR' : 'KM'}`, P.input('frOpen', f.open, { mode: 'decimal', placeholder: '0.00', label: 'Balance today' }))}
        ${P.btn('Start using Ledgerly', 'frStart', null, { kind: 'primary', block: true, state: f.name.trim() ? undefined : 'disabled' })}${P.btn('Back', 'frBack', null, { block: true })}</div>`;
    }
    const opt = (title, sub, icon, name, arg) => P.row({ title, sub, icon, name, arg });
    return `<div class="p-first"><div>${L.appIcon(64)}</div><div><h2 class="lg-title">Welcome to Ledgerly</h2><p class="p-note">Your money, on this device. Recording takes seconds and every number can be traced to its entries.</p></div>
      <div class="lg-card lg-card--flush">${opt('Start empty', 'Create your first account', 'plus', 'frEmpty')}${opt('Explore demo data', '14 months of sample entries', 'ledger', 'frDemo')}${opt('Import a data file', 'Move from another device', 'upload', 'startImport', 'first')}</div>
      <p class="p-note">Everything stays on this device. Nothing needs a network connection.</p></div>`;
  };
  P.acts.frEmpty = () => { st.first.step = 'account'; P.render(); };
  P.acts.frBack = () => { st.first.step = 'choose'; P.render(); };
  P.acts.frDemo = () => { st.full = null; P.go('home', null, { tab: true }); };
  P.inputs.frName = (v) => { st.first.name = v; P.render(); };
  P.inputs.frOpen = (v) => { st.first.open = v; };
  P.acts.frCur = (c) => { st.first.cur = c; P.render(); };
  P.acts.frStart = () => {
    const f = st.first;
    G.startEmpty({ name: f.name.trim(), cur: f.cur, open: P.minorOf(f.open) });
    st.full = null; st.first = null; st.filters = {};
    P.go('home', null, { tab: true });
  };

  // ---- Widget: opens the Add sheet directly and shows no balances ----
  P.views.widget = function () {
    return `${P.screenHead('Home-screen widget', 'Android home screen')}<div class="p-home-screen"><div class="p-home-icons" aria-hidden="true">${'<span></span>'.repeat(8)}</div>${P.attr(ui.widget(), '').replace('class="lg-widget__add ', `${act('tab', 'add')} class="lg-widget__add `)}<div class="p-home-icons" aria-hidden="true">${'<span></span>'.repeat(4)}</div></div><div class="app__body"><div>${P.simulated('A real widget needs Android.')}</div><p class="p-note">It opens the Add sheet with the amount focused. It never shows a balance.</p></div>`;
  };

  // ---- States gallery: one place to review them ----
  P.views.states = function () {
    const card = (title, html) => `<div class="lg-stack" style="gap:4px"><div class="label">${title}</div><div class="lg-card lg-card--flush">${html}</div></div>`;
    const ask = (name, label) => P.btn(label, name, null, { kind: 'secondary', small: true });
    return P.scroll(P.screenHead('States', 'Empty, loading, error, dialogs, permissions'), `
      ${card('Empty', ui.state().replace('<button type="button" class="lg-btn lg-btn--primary"', `<button type="button" class="lg-btn lg-btn--primary" ${act('tab', 'add')}`))}
      ${card('Cleared', P.state('check', 'All reviewed', 'Every entry has a category. New amount-only entries will wait here.', ''))}
      ${card('Empty chart', `<div style="padding:16px">${L.charts.empty('Where did my money go?')}</div>`)}
      ${card('Loading from this device', ui.state('loading'))}
      ${card('Error', ui.state('error').replace('<button type="button" class="lg-btn lg-btn--secondary"', `<button type="button" class="lg-btn lg-btn--secondary" ${act('stateFile')}`))}
      <div class="label">Backup status</div>${ui.backup('healthy')}${ui.backup('overdue')}${ui.backup('failed')}
      <div class="label">Dialogs and permission prompts</div>
      <div class="lg-inline">${ask('demoRestore', 'Restore')}${ask('demoReset', 'Reset')}${ask('demoCategory', 'Delete a category')}${ask('demoCamera', 'Camera')}${ask('demoPhotos', 'Photos')}</div>`, 'app__narrow');
  };
  P.acts.stateFile = () => P.acts.startImport('settings');
  P.acts.demoRestore = () => P.dialog({ title: 'Restore this backup?', text: 'It replaces all current data with the backup from 27 Oct 2026. Ledgerly takes a safety copy first.', ok: 'Restore', danger: true, confirm: () => P.toast('Restore simulated. Nothing changed.', {}) });
  P.acts.demoReset = () => P.dialog({ title: 'Reset Ledgerly?', text: 'It deletes all data on this device. Export a copy first if you want to keep it.', ok: 'Reset all data', danger: true, confirm: () => P.toast('Reset simulated. Nothing changed.', {}) });
  P.acts.demoCategory = () => { P.catEdit = { kind: 'expense' }; P.acts.catDelete('entertainment'); };
  P.acts.demoCamera = () => P.dialog({ title: 'Allow Ledgerly to use the camera?', text: 'Simulated Android prompt. Photos of receipts stay on this device, inside Ledgerly.', ok: 'Allow', cancel: 'Not now', confirm: () => { G.S.permissions.camera = true; P.toast('Camera allowed. Simulated.', {}); } });
  P.acts.demoPhotos = () => P.dialog({ title: 'Allow Ledgerly to read your photos?', text: 'Simulated Android prompt. Only the photos you pick are copied into Ledgerly.', ok: 'Allow', cancel: 'Not now', confirm: () => { G.S.permissions.photos = true; P.toast('Photos allowed. Simulated.', {}); } });

  // ---- Sitemap: every screen, one tap away ----
  const MAP = [
    ['Home', [['Home dashboard', 'home'], ['Balance by account', 'home|balance'], ['Forecast calculation', 'home|forecast']]],
    ['Add', [['Add transaction', 'add|expense'], ['Add income', 'add|income'], ['Add transfer', 'add|transfer']]],
    ['Transactions', [['History list', 'tx'], ['Calendar month', 'tx|calendar'], ['Calendar year', 'tx|year'], ['Needs Review', 'review'], ['Search and filters', 'tx|filters']]],
    ['Analytics', [['Overview', 'analytics|overview'], ['Categories', 'analytics|categories'], ['Patterns', 'analytics|patterns'], ['Progress', 'analytics|progress'], ['Category analytics', 'catan:food']]],
    ['More', [['Budgets', 'budgets'], ['Budget details', 'budget:b1'], ['Goals', 'goals'], ['Goal details', 'goal:g1'], ['Accounts', 'accounts'], ['Account details', 'account:cash'], ['Recurring', 'recurring'], ['Notebook', 'notebook'], ['Note details', 'note:n2'], ['Reports', 'reports'], ['Monthly close', 'close']]],
    ['Settings', [['Settings', 'settings'], ['Appearance', 'appearance'], ['Regional', 'regional'], ['Security', 'security'], ['Backup and data', 'backup'], ['Bank statement CSV', 'csv'], ['Categories', 'categories']]],
    ['Other', [['First launch', 'first'], ['Home-screen widget', 'widget'], ['Empty, error and permission states', 'states']]],
  ];
  P.views.sitemap = function () {
    return `<div class="app__head">${P.iconBtn('x', 'Close sitemap', 'sitemap')}<div style="flex:1 1 auto"><h2 class="lg-title">Sitemap</h2><div class="app__head-sub">Prototype only</div></div></div><div class="app__scroll" data-scroll><div class="app__body"><div class="app__triple">${MAP.map(([group, items]) => `<div class="app__col"><div class="p-menu-group">${group}</div><div class="lg-card lg-card--flush">${items.map(([label, to]) => `<button type="button" class="lg-row" style="min-height:44px" ${act('mapGo', to)}><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem">${label}</span></span></button>`).join('')}</div></div>`).join('')}</div></div></div>`;
  };
  P.acts.mapGo = (to) => {
    st.full = null; st.sheet = null; st.dialog = null; st.add = null;
    const [where, sub] = to.split('|');
    if (where === 'add') { if (P.isDesk()) { st.device = 'phone'; st.fixedLayout = 'phone'; P.layout(); } P.openAdd({ kind: sub }); return; }
    if (where === 'first') { P.acts.firstRun(); return; }
    const [name, arg] = where.split(':');
    const tabs = ['home', 'tx', 'analytics', 'more'];
    if (name === 'tx') {
      st.filters = {};
      st.txView = sub === 'calendar' || sub === 'year' ? 'calendar' : 'list';
      if (sub === 'year') st.cal.mode = 'year'; else if (sub === 'calendar') st.cal.mode = 'month';
    }
    if (name === 'analytics' && sub) st.an.section = sub;
    if (name === 'home' && sub === 'balance') st.balanceOpen = true;
    if (tabs.includes(name)) P.go(name, null, { tab: true }); else { st.stack = []; st.tab = 'more'; P.go(name, arg); }
    if (name === 'tx' && sub === 'filters') P.sheet('filters');
    if (name === 'home' && sub === 'forecast') P.sheet('forecast');
  };
})(window.Ledgerly);
