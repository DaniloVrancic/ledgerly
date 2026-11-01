// More menu, Budgets, Goals, Accounts with balance checks, and Recurring.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, esc } = P;
  const ro = () => P.isDesk();
  const scroll = (head, body, cls) => `<div class="app__scroll" data-scroll>${head}<div class="app__body ${cls || 'app__wrap'}">${body}</div></div>`;
  P.scroll = scroll;

  P.views.more = function () {
    const review = D.review().length;
    const rows = [['Budgets', 'pie', 'budgets'], ['Goals', 'target', 'goals'], ['Accounts', 'wallet', 'accounts'], ['Recurring', 'repeat', 'recurring'], ['Notebook', 'note', 'notebook'], ['Reports', 'page', 'reports'], ['Settings', 'gear', 'settings']];
    const list = rows.map(([title, icon, to]) => P.row({ title, icon, name: 'go', arg: to })).join('');
    const extra = [P.row({ title: 'Needs Review', icon: 'flag', sub: review ? `${review} ${review === 1 ? 'entry' : 'entries'} waiting` : 'All reviewed', name: 'go', arg: 'review' }), P.row({ title: 'Monthly close', icon: 'check', sub: G.S.closed[G.current().key] ? `${G.current().label} is closed` : `${G.current().label} is ready`, name: 'go', arg: 'close' })].join('');
    return scroll(`<div class="app__head app__head--root"><h2 class="lg-title">More</h2></div>`, `<div class="lg-card lg-card--flush">${list}</div>${P.section('Routines')}<div class="lg-card lg-card--flush">${extra}</div>${P.backupLine()}`);
  };

  // ---- Budgets ----
  const budgetCard = (v) => {
    D.PACE = v.pace;
    const html = ui.budget(v, {});
    return `<button type="button" class="lg-card lg-card--action" ${act('go', `budget:${v.id}`)}>${html.replace(/^<div class="lg-card">/, '').replace(/<\/div>$/, '')}<span class="caption lg-faint" style="display:block;margin-top:4px">${v.left > 0 ? `Safe to spend ${L.fmt(v.safe, 'EUR')} a day for ${v.remaining} ${v.remaining === 1 ? 'day' : 'days'}` : 'No safe daily amount left'}</span></button>`;
  };
  P.views.budgets = function () {
    const all = D.budgets();
    const p = G.current();
    const group = (title, list) => (list.length ? `${P.section(title)}<div class="lg-grid-2">${list.map(budgetCard).join('')}</div>` : '');
    const overall = all.find((b) => b.scope === 'Overall');
    const over = all.filter((b) => b.state === 'over').length;
    const line = over ? `${over} ${over === 1 ? 'budget is' : 'budgets are'} over the limit.` : 'All budgets are within their limits.';
    const head = P.screenHead('Budgets', p.label, ro() ? '' : P.iconBtn('plus', 'New budget', 'newBudget'));
    return scroll(head, `<p class="p-note">${line} Months follow your month start, the ${G.S.monthStart === 1 ? '1st' : `${G.S.monthStart}th`}.</p>
      ${overall ? budgetCard(overall) : ''}${group('Categories', all.filter((b) => b.scope === 'Category'))}${group('Subcategories', all.filter((b) => b.scope === 'Subcategory' && b.every === 'Monthly'))}${group('Weekly', all.filter((b) => b.every === 'Weekly'))}
      ${ro() ? '' : P.btn('New budget', 'newBudget', null, { block: true, kind: 'primary', icon: 'plus' })}`);
  };
  P.views.budget = function (id) {
    const b = G.BUDGETS.find((x) => x.id === id);
    if (!b) return scroll(P.screenHead('Budget'), P.state('pie', 'Budget removed', 'This budget is no longer in Ledgerly.', P.btn('Go back', 'back', null, { kind: 'secondary' })));
    const v = G.budgetView(b);
    const name = L.cat(b.cat).name;
    const pct = Math.round(v.ratio * 100);
    const say = v.state === 'over' ? `${name} is ${L.fmt(-v.left, 'EUR')} over its limit.` : `${name} is at ${pct}%, with ${L.fmt(v.left, 'EUR')} left for ${v.remaining} ${v.remaining === 1 ? 'day' : 'days'}.`;
    const hist = G.budgetHistory(b, 6).map((h) => ({ label: h.label, value: h.spent, limit: b.limit, pick: { id: `bh${b.id}${h.range.key}`, title: `${name}, ${h.range.label}`, sub: `${L.fmt(h.spent, 'EUR')} of ${L.fmt(b.limit, 'EUR')}, ${Math.round(h.ratio * 100)}%`, filter: Object.assign({ spending: true, start: h.range.start, end: h.range.end }, b.cat === 'overall' ? {} : { cat: b.cat }) } }));
    const filter = Object.assign({ spending: true, start: v.range.start, end: v.range.end }, b.cat === 'overall' ? {} : { cat: b.cat });
    const list = G.filterTx(filter).slice(0, 8);
    D.PACE = v.pace;
    const tile = (label, html) => `<div class="lg-metric"><span class="lg-metric__label">${label}</span><span class="lg-metric__value">${html}</span></div>`;
    return scroll(P.screenHead(esc(name), `${b.every} budget, ${v.range.label}`), `
      ${ui.budget(v, {})}<p class="p-note">${say} The mark on the bar is today's expected pace, ${Math.round(v.pace * 100)}%.</p>
      <div class="lg-metrics">${tile('Limit', P.eur(v.limit))}${tile('Spent', P.eur(v.spent))}${tile(v.left >= 0 ? 'Remaining' : 'Over', P.eur(Math.abs(v.left)))}${tile('Safe a day', P.eur(v.safe))}</div>
      ${ro() ? '' : P.field('Limit, EUR', P.input('budgetLimit', (b.limit / 100).toFixed(2), { arg: b.id, mode: 'decimal', label: 'Limit' }), 'Changes save themselves.')}
      <div class="lg-card">${P.ch.bars(hist, 'Has this stayed within its limit?')}<div class="lg-key-list"><span><i style="background:transparent;border-top:2px dashed var(--text-primary);border-radius:0;height:0"></i>Limit</span></div></div>
      ${P.section('In this budget', P.link('All', 'drill', P.drillArg(Object.assign({ label: `${name}, ${v.range.label}` }, filter))))}
      <div class="lg-card lg-card--flush">${list.map((t) => P.txRow(t)).join('') || '<div class="lg-state"><p>Nothing spent here yet.</p></div>'}</div>
      ${ro() ? '' : P.btn('Delete budget', 'budgetDelete', b.id, { kind: 'danger', block: true })}`);
  };
  P.inputs.budgetLimit = (v, id) => { const m = P.minorOf(v); if (m > 0) { G.BUDGETS.find((b) => b.id === id).limit = m; G.bump(); P.queue(); } };
  P.acts.budgetDelete = (id) => { P.back(); P.withUndo('Budget deleted', () => { G.BUDGETS.splice(G.BUDGETS.findIndex((b) => b.id === id), 1); G.bump(); }); };
  P.acts.newBudget = () => { st.nb = { scope: 'Category', cat: 'health', limit: '', every: 'Monthly' }; P.sheet('newBudget'); };
  P.sheets.newBudget = function () {
    const n = st.nb;
    const parents = G.catIds('expense').filter((id) => id !== 'other').map((id) => [id, L.cat(id).name]);
    const subs = G.allCats('expense').filter((id) => L.cat(id).parent).map((id) => [id, `${L.cat(L.cat(id).parent).name} · ${L.cat(id).name}`]);
    const hasOverall = G.BUDGETS.some((b) => b.scope === 'Overall');
    const opts = n.scope === 'Subcategory' ? subs : parents;
    const left = !!P.minorOf(n.limit);
    return `<h3>New budget</h3><div class="lg-stack" style="gap:12px">
      ${P.field('Covers', P.seg(hasOverall ? ['Category', 'Subcategory'] : ['Overall', 'Category', 'Subcategory'], n.scope, 'nbScope', 'Covers'))}
      ${n.scope === 'Overall' ? '' : P.field(n.scope, P.select('nbCat', n.cat, opts, { label: n.scope }))}
      ${P.field('Limit, EUR', P.input('nbLimit', n.limit, { mode: 'decimal', placeholder: '100.00', label: 'Limit', focus: true }))}
      ${P.field('Repeats', P.seg(['Monthly', 'Weekly'], n.every, 'nbEvery', 'Repeats'), 'Monthly budgets follow your month start.')}
      ${P.btn('Save budget', 'nbSave', null, { kind: 'primary', block: true, state: left ? undefined : 'disabled' })}</div>`;
  };
  P.acts.nbScope = (v) => { st.nb.scope = v; st.nb.cat = v === 'Subcategory' ? 'fuel' : 'health'; P.render(); };
  P.acts.nbEvery = (v) => { st.nb.every = v; P.render(); };
  P.inputs.nbCat = (v) => { st.nb.cat = v; };
  P.inputs.nbLimit = (v) => { st.nb.limit = v; P.render(); };
  P.acts.nbSave = () => {
    const n = st.nb;
    const m = P.minorOf(n.limit);
    if (!m) return;
    st.sheet = null;
    const id = `b${Date.now()}`;
    P.withUndo(`Budget saved, ${L.fmt(m, 'EUR')}`, () => { G.BUDGETS.push({ id, cat: n.scope === 'Overall' ? 'overall' : n.cat, scope: n.scope, limit: m, every: n.every }); G.bump(); });
  };

  // ---- Goals. Money in a goal is earmarked inside an account, not moved or spent ----
  function threeFigures() {
    const s = D.summary();
    return `<div class="lg-card lg-stack" style="gap:0">${P.kv(`<span class="lg-inline" style="gap:0">Total balance${P.info('Balance')}</span>`, P.eur(s.total))}${P.kv(`<span class="lg-inline" style="gap:0">Earmarked for goals${P.info('Earmarked for goals')}</span>`, P.eur(s.earmarked))}${P.kv(`<span class="lg-inline" style="gap:0">Free to use${P.info('Free to use')}</span>`, P.eur(s.free), 'p-kv--total')}</div>`;
  }
  P.threeFigures = threeFigures;
  const goalCard = (g) => `<button type="button" class="lg-card lg-card--action" ${act('go', `goal:${g.id}`)}>${ui.goal(g).replace(/^<div class="lg-card">/, '').replace(/<\/div>$/, '')}<span class="caption lg-faint" style="display:block;margin-top:4px">Earmarked in ${esc(D.acc(g.account).name)}${g.by ? `, by ${G.shortDate(g.by)} ${g.by.slice(0, 4)}` : ''}</span></button>`;
  P.views.goals = function () {
    return scroll(P.screenHead('Goals', '', ro() ? '' : P.iconBtn('plus', 'New goal', 'newGoal')), `${threeFigures()}<p class="p-note">Money in a goal stays in its account. It is earmarked, not moved or spent.</p>
      <div class="lg-grid-2">${D.GOALS.map(goalCard).join('')}</div>${ro() ? '' : P.btn('New goal', 'newGoal', null, { block: true, kind: 'primary', icon: 'plus' })}`);
  };
  P.views.goal = function (id) {
    const g = D.GOALS.find((x) => x.id === id);
    if (!g) return scroll(P.screenHead('Goal'), P.state('target', 'Goal removed', 'This goal is no longer in Ledgerly.'));
    const left = g.target - g.saved;
    const months = g.by ? Math.max(1, Math.round(G.diffDays(g.by, G.TODAY) / 30)) : null;
    const notes = G.NOTES.filter((n) => n.links.some((l) => l.type === 'goal' && l.id === id));
    return scroll(P.screenHead(esc(g.name), `Earmarked in ${esc(D.acc(g.account).name)}`), `${ui.goal(g)}
      <div class="lg-card lg-stack" style="gap:0">${P.kv('Earmarked', P.eur(g.saved))}${P.kv('Still to earmark', P.eur(Math.max(0, left)))}${months ? P.kv(`About ${L.fmt(Math.round(left / months), 'EUR')} a month for ${months} months`, '') : ''}</div>
      ${ro() ? '' : `<div class="p-grid2">${P.btn('Earmark more', 'goalMove', `${id}|1`, { kind: 'primary' })}${P.btn('Release', 'goalMove', `${id}|-1`, { kind: 'secondary' })}</div>
      ${P.field('Target, EUR', P.input('goalTarget', (g.target / 100).toFixed(2), { arg: id, mode: 'decimal', label: 'Target' }), 'Changes save themselves.')}`}
      ${notes.length ? `<div class="lg-field"><span class="lg-field__label">Linked notes</span>${notes.map((n) => P.link(esc(n.title), 'go', `note:${n.id}`)).join('')}</div>` : ''}
      ${ro() ? '' : P.btn('Delete goal', 'goalDelete', id, { kind: 'danger', block: true })}`);
  };
  P.inputs.goalTarget = (v, id) => { const m = P.minorOf(v); if (m > 0) { D.GOALS.find((g) => g.id === id).target = m; G.bump(); P.queue(); } };
  P.acts.goalDelete = (id) => { P.back(); P.withUndo('Goal deleted. Its money stays in the account.', () => { D.GOALS.splice(D.GOALS.findIndex((g) => g.id === id), 1); G.bump(); }); };
  P.acts.goalMove = (arg) => { const [id, dir] = arg.split('|'); st.gm = { id, dir: Number(dir), amount: '' }; P.sheet('goalMove'); };
  P.sheets.goalMove = function () {
    const m = st.gm; const g = D.GOALS.find((x) => x.id === m.id);
    const free = D.summary().free;
    const amount = P.minorOf(m.amount);
    const bad = m.dir > 0 ? amount > free : amount > g.saved;
    return `<h3>${m.dir > 0 ? 'Earmark more' : 'Release from goal'}</h3><p>${m.dir > 0 ? `${L.fmt(free, 'EUR')} is free to use.` : `${L.fmt(g.saved, 'EUR')} is earmarked here.`} The money stays in ${esc(D.acc(g.account).name)}.</p>
      ${P.field('Amount, EUR', P.input('gmAmount', m.amount, { mode: 'decimal', placeholder: '50.00', label: 'Amount', focus: true, error: bad }), bad ? 'That is more than is available.' : '')}<div style="height:12px"></div>
      ${P.btn('Save', 'gmSave', null, { kind: 'primary', block: true, state: amount && !bad ? undefined : 'disabled' })}`;
  };
  P.inputs.gmAmount = (v) => { st.gm.amount = v; P.render(); };
  P.acts.gmSave = () => {
    const m = st.gm; const v = P.minorOf(m.amount) * m.dir;
    st.sheet = null;
    P.withUndo(`${m.dir > 0 ? 'Earmarked' : 'Released'} ${L.fmt(Math.abs(v), 'EUR')}. No money moved.`, () => { D.GOALS.find((g) => g.id === m.id).saved += v; G.bump(); });
  };
  P.acts.newGoal = () => { st.ng = { name: '', target: '', account: 'savings', icon: 'target' }; P.sheet('newGoal'); };
  P.sheets.newGoal = function () {
    const n = st.ng;
    return `<h3>New goal</h3><div class="lg-stack" style="gap:12px">${P.field('Name', P.input('ngName', n.name, { placeholder: 'For example Novi bicikl', label: 'Name', focus: true }))}${P.field('Target, EUR', P.input('ngTarget', n.target, { mode: 'decimal', placeholder: '500.00', label: 'Target' }))}${P.field('Earmarked inside', P.select('ngAccount', n.account, D.ACCOUNTS.filter((a) => a.id !== 'card').map((a) => [a.id, a.name]), { label: 'Account' }))}${P.btn('Save goal', 'ngSave', null, { kind: 'primary', block: true, state: n.name && P.minorOf(n.target) ? undefined : 'disabled' })}</div>`;
  };
  P.inputs.ngName = (v) => { st.ng.name = v; P.render(); };
  P.inputs.ngTarget = (v) => { st.ng.target = v; P.render(); };
  P.inputs.ngAccount = (v) => { st.ng.account = v; };
  P.acts.ngSave = () => {
    const n = st.ng;
    st.sheet = null;
    P.withUndo(`${esc(n.name)} added`, () => { D.GOALS.push({ id: `g${Date.now()}`, name: n.name, target: P.minorOf(n.target), saved: 0, icon: n.icon, account: n.account, by: '' }); G.bump(); });
  };

  // ---- Accounts. Balance checks prompt regularly, especially for Cash ----
  const agoLabel = (id) => { const n = G.diffDays(G.TODAY, G.checks[id]); return n === 0 ? 'Checked today' : `Checked ${n} ${n === 1 ? 'day' : 'days'} ago`; };
  P.views.accounts = function () {
    const owed = G.owedList();
    const list = D.accounts().map((a) => `<button type="button" class="lg-row" data-key="a${a.id}" ${act('go', `account:${a.id}`)}><span class="lg-row__lead">${L.icon(a.icon, 20)}</span><span class="lg-row__body"><span class="lg-row__title">${esc(a.name)}</span><span class="lg-row__sub">${a.kind} · ${agoLabel(a.id)}</span></span><span class="lg-row__trail">${L.moneyPair(a.balance, a.cur, a.base, a.balance < 0 ? { tone: 'negative' } : undefined)}</span></button>`).join('');
    const stale = G.diffDays(G.TODAY, G.checks.cash) >= 14;
    const prompt = stale ? `<div class="lg-card lg-card--flush"><div class="lg-attn"><span class="lg-attn__icon">${L.icon('wallet', 20)}</span><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem;line-height:1.25rem">Time to count your Cash</span><span class="lg-row__sub">${agoLabel('cash')}. Small purchases are what drift.</span></span>${ro() ? '' : P.btn('Check', 'checkBalance', 'cash', { small: true, kind: 'secondary' })}</div></div>` : '';
    const owedHtml = owed.length ? `${P.section('Owed to me')}<div class="lg-card lg-card--flush">${owed.map((o) => `<button type="button" class="lg-row" ${act('openTx', o.t.id)}><span class="lg-row__lead">${L.icon('people', 20)}</span><span class="lg-row__body"><span class="lg-row__title">${esc(o.t.owedFrom || o.t.merchant || 'Entry')}</span><span class="lg-row__sub">${esc(o.t.merchant || '')}, ${G.shortDate(o.t.date)}</span></span><span class="lg-row__trail">${P.eur(o.left)}</span></button>`).join('')}</div>` : '';
    return scroll(P.screenHead('Accounts'), `${P.threeFigures()}${prompt}<div class="lg-card lg-card--flush">${list}</div>${owedHtml}<p class="p-note">1 EUR = 1.95583 BAM, a fixed rate.</p>`);
  };
  P.views.account = function (id) {
    const a = D.accounts().find((x) => x.id === id);
    const u = G.untracked(id);
    const earmarked = D.GOALS.filter((g) => g.account === id).reduce((s, g) => s + g.saved, 0);
    const recent = G.filterTx({ account: id }).slice(0, 10);
    const last = G.checks[id];
    return scroll(P.screenHead(esc(a.name), a.kind), `<div class="lg-card"><div class="caption lg-faint">Balance</div><div class="amount-large">${L.money(a.balance, a.cur, a.balance < 0 ? { tone: 'negative' } : undefined)}</div>${a.cur !== 'EUR' ? `<div class="amount-small lg-faint">${L.fmt(a.base, 'EUR')}</div>` : ''}${a.id === 'card' ? '<p class="p-note" style="margin-top:4px">A balance owed counts as negative in the total.</p>' : ''}</div>
      <div class="lg-card lg-stack" style="gap:0">${P.kv('Last balance check', `<b>${G.longDate(last)}</b>`)}${P.kv(`<span class="lg-inline" style="gap:0">Untracked since the start${P.info('Untracked')}</span>`, L.money(u, a.cur, { sign: true, tone: 'neutral' }))}${earmarked ? P.kv('Earmarked for goals', P.eur(earmarked)) : ''}</div>
      ${ro() ? '' : P.btn('Check balance', 'checkBalance', id, { block: true, kind: 'primary', icon: 'check' })}
      ${P.section('Recent', P.link('All', 'drill', P.drillArg({ account: id, label: a.name })))}<div class="lg-card lg-card--flush">${recent.map((t) => P.txRow(t)).join('')}</div>`);
  };
  P.acts.checkBalance = (id) => { st.rec = { id, real: '' }; P.sheet('reconcile'); };
  P.sheets.reconcile = function () {
    const r = st.rec; const a = D.accounts().find((x) => x.id === r.id);
    const entered = r.real !== '';
    const sign = a.balance < 0 ? -1 : 1;
    const real = P.minorOf(r.real) * sign;
    const diff = entered ? real - a.balance : 0;
    const body = !entered ? '' : diff === 0
      ? `<div class="lg-card" style="background:var(--positive-tint);border-color:transparent"><div class="lg-inline" style="color:var(--positive)">${L.icon('check', 20)}<span class="body-small">It matches. Nothing to resolve.</span></div></div>`
      : `<div class="lg-stack" style="gap:0">${P.kv('In Ledgerly', L.money(a.balance, a.cur))}${P.kv('You counted', L.money(real, a.cur))}${P.kv('Difference', L.money(diff, a.cur, { sign: true, tone: 'neutral' }), 'p-kv--total')}</div><p class="p-note" style="margin-top:8px">It is saved as a labelled Untracked adjustment, excluded from income and spending.</p>`;
    return `<h3>Check ${esc(a.name)}</h3><p>Enter the real balance${a.id === 'cash' ? ' in your wallet' : ' from your bank'}. Ledgerly shows ${L.fmt(a.balance, a.cur)}.</p>
      ${P.field(`Real balance, ${a.cur === 'EUR' ? 'EUR' : 'KM'}`, P.input('recReal', r.real, { mode: 'decimal', placeholder: (Math.abs(a.balance) / 100).toFixed(2), label: 'Real balance', focus: true }))}<div style="height:12px"></div>
      ${body}<div style="height:12px"></div>${P.btn(!entered ? 'Enter the balance' : diff ? `Resolve ${L.fmt(Math.abs(diff), a.cur)} as Untracked` : 'Mark as checked', 'recSave', null, { kind: 'primary', block: true, state: entered ? undefined : 'disabled' })}`;
  };
  P.inputs.recReal = (v) => { st.rec.real = v; P.render(); };
  P.acts.recSave = () => {
    const r = st.rec; const a = D.acc(r.id);
    const sign = G.balanceOf(r.id) < 0 ? -1 : 1;
    const real = P.minorOf(r.real) * sign;
    const diff = real - G.balanceOf(r.id);
    st.sheet = null;
    if (st.closeRun) st.closeRun.checked[r.id] = true;
    P.withUndo(diff ? `${a.name} checked. ${L.fmt(diff, a.cur, true)} saved as Untracked.` : `${a.name} checked. It matches.`, () => G.reconcile(r.id, real));
  };

  // ---- Recurring: Planned, Due, Posted. Nothing posts silently ----
  const recRow = (r) => {
    const income = r.kind === 'income';
    const when = r.state === 'due' ? `Due ${G.shortDate(r.date)}` : `${G.shortDate(r.date)} · ${esc(D.acc(r.account).name)}`;
    return `<div class="p-row-action" data-key="${r.id}"><span class="lg-row__body"><span class="lg-row__title">${esc(r.name)}</span><span class="lg-row__sub">${ui.recurring(r.state)}${when}</span></span><span class="p-amount-sm">${L.money(income ? r.amount : -r.amount, r.cur, { sign: income, tone: income ? 'positive' : 'negative' })}</span>${r.state === 'due' && !ro() ? P.btn('Confirm', 'confirmDue', r.id, { small: true, kind: 'secondary' }) : ''}${r.state === 'planned' && !ro() ? P.iconBtn('dots', `Options for ${r.name}`, 'recOpen', r.id) : ''}</div>`;
  };
  P.views.recurring = function () {
    const due = D.RECURRING.filter((r) => r.state === 'due');
    const planned = D.RECURRING.filter((r) => r.state === 'planned').sort((a, b) => (a.date < b.date ? -1 : 1));
    const p = G.current();
    const posted = G.filterTx({ flag: 'recurring', start: p.start, end: p.end }).slice(0, 12);
    const sub = G.subscriptionTotal();
    const subs = `<div class="lg-card"><div class="lg-between"><span class="label">Subscriptions</span><span class="caption lg-faint">${sub.list.length} active</span></div><div class="p-grid2" style="margin-top:8px"><div><div class="caption lg-faint">Per month</div><div class="amount-large">${P.eur(sub.month)}</div></div><div><div class="caption lg-faint">Per year</div><div class="amount-large">${P.eur(sub.year)}</div></div></div></div>`;
    return scroll(P.screenHead('Recurring', '', ro() ? '' : P.iconBtn('plus', 'New recurring item', 'newRec')), `${subs}
      ${due.length ? `${P.section('Due')}<div class="lg-card lg-card--flush">${due.map(recRow).join('')}</div><p class="p-note">Due items wait for one tap, so nothing is posted twice or silently.</p>` : ''}
      ${P.section('Planned')}<div class="lg-card lg-card--flush">${planned.map(recRow).join('')}</div>
      ${P.section('Posted this month')}<div class="lg-card lg-card--flush">${posted.map((t) => P.txRow(t)).join('') || '<div class="lg-state"><p>Nothing posted yet this month.</p></div>'}</div>`);
  };
  P.acts.recOpen = (id) => P.sheet('recItem', id);
  P.sheets.recItem = function (id) {
    const r = D.RECURRING.find((x) => x.id === id);
    return `<h3>${esc(r.name)}</h3><p>${r.every}, next on ${G.longDate(r.date)}, ${L.fmt(r.amount, r.cur)} from ${esc(D.acc(r.account).name)}.</p>
      ${P.field(`Amount, ${r.cur === 'EUR' ? 'EUR' : 'KM'}`, P.input('recAmount', (r.amount / 100).toFixed(2), { arg: id, mode: 'decimal', label: 'Amount' }), 'Changes save themselves.')}<div style="height:12px"></div>
      <div class="lg-stack" style="gap:8px">${P.btn('Mark as due now', 'recDue', id, { kind: 'secondary', block: true })}${P.btn('Stop this item', 'recStop', id, { kind: 'danger', block: true })}</div>`;
  };
  P.inputs.recAmount = (v, id) => { const m = P.minorOf(v); if (m > 0) { D.RECURRING.find((r) => r.id === id).amount = m; G.bump(); P.queue(); } };
  P.acts.recDue = (id) => { st.sheet = null; P.withUndo('Marked as due', () => { const r = D.RECURRING.find((x) => x.id === id); r.state = 'due'; G.bump(); }); };
  P.acts.recStop = (id) => { st.sheet = null; P.withUndo('Recurring item stopped', () => { D.RECURRING.splice(D.RECURRING.findIndex((r) => r.id === id), 1); G.bump(); }); };
  P.acts.newRec = () => { st.nr = { name: '', amount: '', account: 'main', cat: 'subscriptions', day: '15' }; P.sheet('newRec'); };
  P.sheets.newRec = function () {
    const n = st.nr;
    const ok = n.name && P.minorOf(n.amount);
    return `<h3>New recurring item</h3><div class="lg-stack" style="gap:12px">${P.field('Name', P.input('nrName', n.name, { placeholder: 'For example Muzika', label: 'Name', focus: true }))}<div class="p-grid2">${P.field(`Amount, ${D.acc(n.account).cur === 'EUR' ? 'EUR' : 'KM'}`, P.input('nrAmount', n.amount, { mode: 'decimal', placeholder: '9.99', label: 'Amount' }))}${P.field('Day of month', P.input('nrDay', n.day, { mode: 'numeric', label: 'Day of month' }))}</div>${P.field('Account', P.select('nrAccount', n.account, D.ACCOUNTS.map((a) => [a.id, a.name]), { label: 'Account' }))}${P.field('Category', P.select('nrCat', n.cat, G.catIds('expense').map((id) => [id, L.cat(id).name]), { label: 'Category' }))}${P.btn('Save item', 'nrSave', null, { kind: 'primary', block: true, state: ok ? undefined : 'disabled' })}</div>`;
  };
  P.inputs.nrName = (v) => { st.nr.name = v; P.render(); };
  P.inputs.nrAmount = (v) => { st.nr.amount = v; P.render(); };
  P.inputs.nrDay = (v) => { st.nr.day = v; };
  P.inputs.nrAccount = (v) => { st.nr.account = v; P.render(); };
  P.inputs.nrCat = (v) => { st.nr.cat = v; };
  P.acts.nrSave = () => {
    const n = st.nr; const day = Math.min(28, Math.max(1, Number(n.day) || 1));
    const today = Number(G.TODAY.slice(8));
    const date = day > today ? `2026-10-${G.pad(day)}` : `2026-11-${G.pad(day)}`;
    st.sheet = null;
    P.withUndo(`${esc(n.name)} planned for ${G.shortDate(date)}`, () => { D.RECURRING.push({ id: `r${Date.now()}`, name: n.name, cat: n.cat, amount: P.minorOf(n.amount), cur: D.acc(n.account).cur, account: n.account, date, day, every: 'Monthly', state: 'planned' }); G.bump(); });
  };
})(window.Ledgerly);
