// Home: how much do I have, will I make it to payday, how is this month going,
// where is my money going, and what needs my attention.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, attr, esc } = P;

  P.drillArg = (f) => JSON.stringify(f);
  P.acts.drill = (arg) => P.drill(JSON.parse(arg));
  P.drill = function (f, label) {
    st.filters = Object.assign({}, f, { label: f.label || label });
    st.txView = 'list'; st.limit = 40; st.select = null;
    P.go('tx', `drill${G.state.v}${JSON.stringify(f).length}`, { top: true });
  };

  P.metric = function (label, html, o) {
    const p = o || {};
    return `<div class="lg-metric"><span class="lg-metric__label">${label}${P.info(label)}</span><button type="button" class="p-clickable" ${p.drill ? act('drill', P.drillArg(p.drill)) : ''} aria-label="${esc(label)}, see the transactions"><span class="lg-metric__value" data-fit="${p.long ? 1 : 0}">${html}</span><span class="lg-metric__delta">${p.delta || ''}</span></button></div>`;
  };
  P.monthTiles = function (cur, prev, wrap) {
    const s = G.periodStats(cur); const b = G.periodStats(prev);
    const d = (x, y) => `${x >= y ? '+' : '−'}${L.fmt(Math.abs(x - y), 'EUR')} vs ${prev.short}`;
    const range = { start: cur.start, end: cur.end };
    const html = [
      P.metric('Income', P.eur(s.income, { sign: true, tone: 'positive' }), { delta: d(s.income, b.income), long: L.fmt(s.income, 'EUR').length > 10, drill: Object.assign({ income: true, label: `Income, ${cur.label}` }, range) }),
      P.metric('Spending', P.eur(-s.spending, { tone: 'negative' }), { delta: d(s.spending, b.spending), long: L.fmt(s.spending, 'EUR').length > 10, drill: Object.assign({ spending: true, label: `Spending, ${cur.label}` }, range) }),
      P.metric('Net', P.eur(s.net, { sign: true, tone: s.net >= 0 ? 'positive' : 'negative' }), { delta: d(s.net, b.net), long: L.fmt(s.net, 'EUR').length > 10, drill: Object.assign({ label: `All entries, ${cur.label}` }, range) }),
      P.metric('Savings rate', `<span class="money">${Math.round(s.rate * 100)}%</span>`, { delta: `${Math.round(b.rate * 100)}% in ${prev.short}`, drill: Object.assign({ label: `All entries, ${cur.label}` }, range) }),
    ].join('');
    return wrap === false ? html : `<div class="${P.isDesk() ? 'app__tiles' : 'lg-metrics'}">${html}</div>`;
  };

  function balanceCard() {
    const s = D.summary();
    const delta = s.total - s.lastMonth;
    const text = L.fmt(s.total, 'EUR');
    const rows = D.accounts().map((a) => `<button type="button" class="lg-balance__row p-balance-row" ${act('go', `account:${a.id}`)}><span>${esc(a.name)}</span>${L.money(a.balance, a.cur)}</button>`).join('');
    const line = (term, v) => `<div class="lg-balance__row lg-balance__row--strong"><span class="lg-inline" style="gap:0">${term}${P.info(term)}</span>${P.eur(v)}</div>`;
    return `<section class="lg-balance ${st.balanceOpen ? 'is-open' : ''}"><button type="button" class="lg-balance__toggle" aria-expanded="${st.balanceOpen}" ${act('toggleBalance')}><span class="lg-balance__label"><span>Total balance</span><span class="lg-balance__chev">${L.icon('chevronDown', 20)}</span></span><span class="lg-balance__value" data-fit="${text.length > 16 ? 2 : text.length > 13 ? 1 : 0}">${P.eur(s.total)}</span><span class="lg-balance__change">${L.icon(delta >= 0 ? 'up' : 'down', 16)}${P.eur(delta, { sign: true })} from last month</span></button><div class="lg-balance__list">${rows}<div style="margin-top:8px">${line('Balance', s.total).replace('Balance</span>', 'Balance</span>').replace('<span class="lg-inline" style="gap:0">Balance', '<span class="lg-inline" style="gap:0">Total balance')}${line('Earmarked for goals', s.earmarked)}${line('Free to use', s.free)}</div></div></section>`;
  }
  P.balanceCard = balanceCard;
  P.acts.toggleBalance = () => { st.balanceOpen = !st.balanceOpen; P.render(); };

  function forecastCard() {
    if (!G.nextPayday()) return '';
    const f = G.forecast();
    return `<button type="button" class="lg-card lg-card--action" ${act('openSheet', 'forecast')} aria-label="Lowest before payday, see the calculation"><span class="lg-between"><span class="label">Lowest before payday</span><span class="lg-badge">Estimate</span></span><span class="amount-large" style="display:block">${P.eur(f.lowest)}</span><span class="body-small lg-muted" style="display:block">Around ${G.shortDate(f.lowestDate)}, after ${L.fmt(f.billTotal, 'EUR')} of bills. Next salary ${G.shortDate(f.payday)}.</span></button>`;
  }
  P.forecastCard = forecastCard;
  P.acts.openSheet = (name) => P.sheet(name);
  P.sheets.forecast = function () {
    const f = G.forecast();
    const bills = f.bills.map((b) => P.kv(`${G.shortDate(b.date)} · ${esc(b.name)}`, `<span class="money">${L.fmt(-D.toEur(b.amount, b.cur), 'EUR')}</span>`)).join('');
    return `<h3>How this estimate works</h3><p>Estimate. Based on your balance, upcoming bills and normal daily spending.</p>
      <div class="lg-stack" style="gap:0">${P.kv('Balance today, without Savings', P.eur(f.liquid))}${P.kv(`Bills before ${G.shortDate(f.payday)}`, P.eur(-f.billTotal))}${P.kv(`Normal daily spending, ${L.fmt(f.perDay, 'EUR')} × ${f.days} days`, P.eur(-f.perDay * f.days))}${P.kv(`Lowest, around ${G.shortDate(f.lowestDate)}`, P.eur(f.lowest), 'p-kv--total')}</div>
      <div class="p-note" style="margin:12px 0 4px">Normal daily spending is the last 92 days without recurring entries.</div>
      <details style="margin-top:8px"><summary class="label" style="min-height:44px;display:flex;align-items:center;cursor:pointer">${f.bills.length} bills included</summary>${bills}</details>
      ${ui.button('Close', { block: true, kind: 'secondary', attr: act('closeSheet') })}`;
  };

  function topCategories(p) {
    const s = G.periodStats(p);
    const budgets = D.budgets().filter((b) => b.scope === 'Category');
    const rows = s.ranked.slice(0, 5).map((r) => {
      const b = budgets.find((x) => x.cat === r.cat);
      const drill = act('drill', P.drillArg({ cat: r.cat, start: p.start, end: p.end, spending: true, label: `${L.cat(r.cat).name}, ${p.label}` }));
      if (b) return `<button type="button" class="p-clickable p-top-row" ${drill}>${ui.budget(b, { flat: true })}</button>`;
      const c = L.cat(r.cat);
      return `<button type="button" class="p-clickable p-top-row" ${drill}><span class="lg-between"><span class="lg-inline" style="--chip-color:${P.catColor(c)}"><span class="lg-chip__icon">${L.icon(c.icon, 20)}</span><span class="label">${esc(c.name)}</span></span><span class="body-small">${P.eur(r.amount)}</span></span></button>`;
    }).join('');
    const notes = G.insights(p).slice(0, P.isWide() ? 2 : 1).map((n) => `<button type="button" class="p-clickable" style="padding:8px 12px" ${n.cat ? act('drill', P.drillArg({ cat: n.cat, start: p.start, end: p.end, spending: true, label: `${L.cat(n.cat).name}, ${p.label}` })) : act('drill', P.drillArg({ weekday: n.weekday, start: p.start, end: p.end, spending: true, label: `Spending by weekday, ${p.label}` }))}><span class="p-note" style="display:block">${esc(n.text)}</span></button>`).join('');
    return `<div class="lg-card lg-card--flush">${rows || `<div class="lg-state"><p>Nothing spent this month yet.</p></div>`}${notes ? `<div class="p-hairline" style="padding:4px 0">${notes}</div>` : ''}</div>`;
  }

  // Needs attention: at most three rows, in this order, each with its action in the row.
  P.attention = function () {
    const out = [];
    const ro = P.isDesk();
    D.RECURRING.filter((r) => r.state === 'due').forEach((r) => out.push({ key: r.id, title: esc(r.name), sub: `Due ${r.date === G.TODAY ? 'today' : `on ${G.shortDate(r.date)}`}, ${L.fmt(r.amount, r.cur)}`, label: ro ? 'View' : 'Confirm', name: ro ? 'tab' : 'confirmDue', arg: ro ? 'recurring' : r.id, icon: 'repeat' }));
    const rev = D.review().length;
    if (rev) out.push({ key: 'review', title: `${rev} ${rev === 1 ? 'entry' : 'entries'} to review`, sub: rev === 1 ? 'It needs a category' : 'They need a category', label: ro ? 'View' : 'Review', name: 'go', arg: 'review', icon: 'flag' });
    if (G.S.backup !== 'healthy') out.push({ key: 'backup', title: G.S.backup === 'failed' ? 'Backup failed' : 'Backup overdue', sub: G.S.backup === 'failed' ? 'Your data is safe on this phone.' : 'Last backup 12 days ago', label: 'View', name: 'go', arg: 'backup', icon: 'shield' });
    const stale = D.ACCOUNTS.map((a) => ({ a, age: G.diffDays(G.TODAY, G.checks[a.id]) })).filter((x) => (x.a.id === 'cash' ? x.age >= 14 : x.age >= 35)).sort((a, b) => b.age - a.age)[0];
    if (stale) out.push({ key: 'check', title: `Check your ${esc(stale.a.name)} balance`, sub: `Last checked ${stale.age} days ago`, label: ro ? 'View' : 'Check', name: ro ? 'go' : 'checkBalance', arg: ro ? `account:${stale.a.id}` : stale.a.id, icon: 'wallet' });
    const p = G.current();
    if (!G.S.closed[p.key] && G.diffDays(p.end, G.TODAY) <= 3 && !ro) out.push({ key: 'close', title: `${p.label} is ready to close`, sub: 'About two minutes', label: 'Start', name: 'go', arg: 'close', icon: 'check' });
    D.budgets().filter((b) => b.state !== 'normal' && b.scope === 'Category').sort((a, b) => b.ratio - a.ratio).slice(0, 1).forEach((b) => {
      const name = L.cat(b.cat).name;
      out.push({ key: `b${b.id}`, title: b.state === 'over' ? `${name} is ${L.fmt(-b.left, 'EUR')} over its limit` : `${name} is at ${Math.round(b.ratio * 100)}%`, sub: b.state === 'over' ? `${L.fmt(b.spent, 'EUR')} of ${L.fmt(b.limit, 'EUR')}` : `${L.fmt(b.left, 'EUR')} left for ${b.remaining} days`, label: 'View', name: 'go', arg: `budget:${b.id}`, icon: 'alert' });
    });
    return out.slice(0, 3);
  };
  const attentionRow = (a) => attr(ui.attention(a.title, a.sub, a.label, { icon: a.icon }).replace('data-attn', act(a.name, a.arg)), `data-key="${a.key}"`);
  P.acts.confirmDue = (id) => {
    const r = D.RECURRING.find((x) => x.id === id);
    P.withUndo(`${esc(r.name)} confirmed, ${L.fmt(r.amount, r.cur)}`, () => G.confirmRecurring(id));
  };

  P.backupLine = function () {
    const m = { healthy: `Backed up ${G.diffDays(G.TODAY, G.S.backupAt) === 0 ? 'today' : `${G.diffDays(G.TODAY, G.S.backupAt)} days ago`}`, overdue: 'Last backup 12 days ago', failed: 'Backup failed. Your data is safe on this phone.' }[G.S.backup];
    return `<button type="button" class="lg-link caption" style="justify-content:center;width:100%;color:var(--text-tertiary)" ${act('go', 'backup')}>${m}</button>`;
  };

  P.views.home = function () {
    const p = G.current(); const prev = G.prevPeriod(p);
    const attn = P.attention();
    const attnHtml = attn.length ? `${P.section('Needs attention')}<div class="lg-card lg-card--flush">${attn.map(attentionRow).join('')}</div>` : '';
    const recent = D.transactions.slice(0, P.isDesk() ? 7 : 3);
    const recentHtml = `${P.section('Recent', P.link('All', 'tab', 'tx'))}<div class="lg-card lg-card--flush">${recent.map((t) => P.txRow(t)).join('')}</div>`;
    const where = `${P.section('Where it went', P.link('All', 'tab', 'analytics'))}${topCategories(p)}`;
    if (P.isWide()) {
      return `<div class="app__scroll" data-scroll><div class="app__body app__wide">
        <div class="lg-between"><h2 class="lg-title">Home</h2><span class="body-small lg-muted">${p.label}</span></div>
        <div class="app__desk-col"><div class="app__col">${balanceCard()}${P.section('This month')}${P.monthTiles(p, prev)}${where}</div>
        <div class="app__col">${forecastCard()}${attnHtml}${recentHtml}${P.backupLine()}</div></div>
      </div></div>`;
    }
    return `<div class="app__scroll" data-scroll>
      <div class="lg-phone__head"><span class="lg-inline">${L.appIcon(32)}<span class="lg-wordmark">Ledgerly</span></span>${P.iconBtn(st.hidden ? 'eyeOff' : 'eye', st.hidden ? 'Show amounts' : 'Hide amounts', 'toggleHidden')}</div>
      <div class="app__body">${balanceCard()}${forecastCard()}${P.section('This month')}${P.monthTiles(p, prev)}${where}${attnHtml}${recentHtml}${P.backupLine()}</div></div>`;
  };
  P.acts.toggleHidden = () => { st.hidden = !st.hidden; P.render(); };
  P.acts.fileInfo = () => P.sheet('fileInfo');
  P.sheets.fileInfo = () => `<h3>Read-only copy</h3><p>${P.fileDate()}. This browser shows a copy of your Ledgerly data for analysis and reports. New entries are made on your phone or tablet, the main device.</p>
    <div class="lg-stack" style="gap:0">${P.kv('Transactions', `<b>${G.counts().transactions.toLocaleString('en-US')}</b>`)}${P.kv('Accounts', `<b>${G.counts().accounts}</b>`)}</div>
    <div style="margin:12px 0">${P.simulated('In this prototype the copy mirrors this session.')}</div>${P.btn('Close', 'closeSheet', null, { kind: 'secondary', block: true })}`;
  // A filter left by a chart should not follow you back through the tab bar.
  const openTab = P.acts.tab;
  P.acts.tab = (name) => { if (name === 'tx' && st.filters.label) st.filters = {}; openTab(name); };
})(window.Ledgerly);
