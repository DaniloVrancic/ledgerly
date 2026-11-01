// Notebook and Reports.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st;
  const { act, esc } = P;
  const ro = () => P.isDesk();

  // ---- Notebook ----
  const LINK_LABEL = {
    transaction: (id) => { const t = P.byId(id); return t ? `${t.merchant || 'Entry'}, ${G.shortDate(t.date)}` : 'Deleted entry'; },
    category: (id) => L.cat(id).name, account: (id) => D.acc(id).name, date: (id) => G.longDate(id),
    budget: (id) => { const b = G.BUDGETS.find((x) => x.id === id); return b ? `${L.cat(b.cat).name} budget` : 'Deleted budget'; },
    goal: (id) => { const g = D.GOALS.find((x) => x.id === id); return g ? g.name : 'Deleted goal'; },
  };
  const LINK_ICON = { transaction: 'list', category: 'tag', account: 'wallet', date: 'calendar', budget: 'pie', goal: 'target' };
  const preview = (b) => b.split('\n')[0].replace(/\*\*/g, '');
  P.views.notebook = function () {
    const q = st.noteQ || ''; const tag = st.noteTag;
    const n = G.fold(q);
    const list = G.NOTES.filter((x) => (!tag || x.tags.includes(tag)) && (!n || G.fold(`${x.title} ${x.body} ${x.tags.join(' ')}`).includes(n))).sort((a, b) => (a.date < b.date ? 1 : -1));
    const tags = [...new Set(G.NOTES.flatMap((x) => x.tags))];
    const rows = list.map((x) => `<button type="button" class="lg-row" data-key="${x.id}" ${act('go', `note:${x.id}`)}><span class="lg-row__lead">${L.icon(x.day ? 'calendar' : 'note', 20)}</span><span class="lg-row__body"><span class="lg-row__title">${esc(x.title)}</span><span class="lg-row__sub">${G.shortDate(x.date)} · ${esc(preview(x.body))}</span></span></button>`).join('');
    return P.scroll(P.screenHead('Notebook', '', ro() ? '' : P.iconBtn('plus', 'New note', 'newNote')), `<span class="lg-input lg-search">${L.icon('search', 20)}<input data-in="noteQ" aria-label="Search notes" placeholder="Search notes" value="${esc(q)}"></span>
      <div class="app__rowchips">${tags.map((t) => P.pill(`#${esc(t)}`, tag === t, 'noteTag', t)).join('')}</div>
      <div class="lg-card lg-card--flush">${rows || P.state('note', 'No notes found', q ? 'Nothing matches this search.' : 'Notes you add will appear here.', ro() ? '' : P.btn('Add a note', 'newNote', null, { kind: 'primary', icon: 'plus' }))}</div>
      ${ro() ? '' : P.btn('New note', 'newNote', null, { block: true, kind: 'primary', icon: 'plus' })}`, 'app__narrow');
  };
  P.inputs.noteQ = (v) => { st.noteQ = v; P.render(); };
  P.acts.noteTag = (t) => { st.noteTag = st.noteTag === t ? null : t; P.render(); };
  P.acts.newNote = () => {
    const id = `n${Date.now()}`;
    G.NOTES.unshift({ id, title: '', date: G.TODAY, tags: [], body: '', links: [] });
    P.go('note', id);
  };
  P.views.note = function (id) {
    const n = G.NOTES.find((x) => x.id === id);
    if (!n) return P.scroll(P.screenHead('Note'), P.state('note', 'Note removed', 'This note is no longer in Ledgerly.'));
    const links = n.links.map((l, i) => `<div class="lg-inline" data-key="l${i}" style="flex-wrap:nowrap">${P.pill(esc(LINK_LABEL[l.type](l.id)), false, 'noteLinkOpen', `${l.type}|${l.id}`, LINK_ICON[l.type])}${ro() ? '' : P.iconBtn('x', 'Remove link', 'noteUnlink', `${id}|${i}`)}</div>`).join('');
    const atts = `<div class="p-attachments">${Array.from({ length: n.att || 0 }, (_, i) => P.receiptArt({ merchant: n.title }, i)).join('')}</div>`;
    if (ro()) return P.scroll(P.screenHead(esc(n.title), G.longDate(n.date)), `<div class="lg-card"><p class="p-note" style="white-space:pre-wrap">${esc(n.body)}</p></div>${links ? `<div class="lg-field"><span class="lg-field__label">Linked to</span>${links}</div>` : ''}`, 'app__narrow');
    return P.scroll(P.screenHead('Note', G.longDate(n.date)), `<input class="p-title-input" data-in="noteTitle" data-arg="${esc(id)}" aria-label="Title" placeholder="Title" value="${esc(n.title)}" ${n.title ? '' : 'data-autofocus'}>
      <div class="lg-inline">${P.btn('Bold', 'noteFormat', `${id}|bold`, { small: true, kind: 'secondary' })}${P.btn('List', 'noteFormat', `${id}|list`, { small: true, kind: 'secondary' })}</div>
      ${P.textarea('noteBody', n.body, { arg: id, label: 'Note', placeholder: 'Write something short' }).replace('class="p-textarea"', 'class="p-textarea" style="min-height:180px"')}
      ${P.field('Tags', P.input('noteTags', n.tags.join(', '), { arg: id, label: 'Tags', placeholder: 'None' }))}
      <div class="lg-field"><span class="lg-field__label">Linked to</span>${links || '<span class="p-note">Nothing yet.</span>'}<div style="margin-top:4px">${P.btn('Add a link', 'noteLink', id, { small: true, kind: 'secondary', icon: 'plus' })}</div></div>
      <div class="lg-field"><span class="lg-field__label">Attachments</span>${atts}<div style="margin-top:4px">${P.btn('Attach a photo', 'noteAttach', id, { small: true, kind: 'secondary', icon: 'image' })}</div></div>
      <div class="caption lg-faint">Changes save themselves.</div>
      ${P.btn('Delete note', 'noteDelete', id, { kind: 'danger', block: true })}`, 'app__narrow');
  };
  P.inputs.noteTitle = (v, id) => { G.NOTES.find((n) => n.id === id).title = v; };
  P.inputs.noteBody = (v, id) => { G.NOTES.find((n) => n.id === id).body = v; };
  P.inputs.noteTags = (v, id) => { G.NOTES.find((n) => n.id === id).tags = v.split(',').map((s) => s.trim()).filter(Boolean); };
  P.acts.noteFormat = (arg) => {
    const [id, how] = arg.split('|');
    const n = G.NOTES.find((x) => x.id === id);
    n.body = how === 'bold' ? `${n.body}${n.body ? ' ' : ''}**bold text**` : `${n.body}${n.body ? '\n' : ''}- list item`;
    P.render();
  };
  P.acts.noteDelete = (id) => { P.back(); P.withUndo('Note deleted', () => { G.NOTES.splice(G.NOTES.findIndex((n) => n.id === id), 1); G.bump(); }); };
  P.acts.noteUnlink = (arg) => { const [id, i] = arg.split('|'); G.NOTES.find((n) => n.id === id).links.splice(Number(i), 1); P.render(); };
  P.acts.noteAttach = (id) => { const n = G.NOTES.find((x) => x.id === id); const go = () => { n.att = (n.att || 0) + 1; P.toast('Photo attached. Simulated, a placeholder image is used.', {}); }; if (G.S.permissions.photos) { go(); return; } P.dialog({ title: 'Allow Ledgerly to read your photos?', text: 'Simulated Android prompt. Only the photos you pick are copied into Ledgerly.', ok: 'Allow', cancel: 'Not now', confirm: () => { G.S.permissions.photos = true; go(); } }); };
  P.acts.noteLinkOpen = (arg) => {
    const [type, raw] = arg.split('|');
    if (type === 'transaction') P.go('txd', Number(raw));
    else if (type === 'category') P.go('catan', raw);
    else if (type === 'account') P.go('account', raw);
    else if (type === 'budget') P.go('budget', raw);
    else if (type === 'goal') P.go('goal', raw);
    else { st.cal.ym = raw.slice(0, 7); st.cal.day = raw; st.txView = 'calendar'; P.go(P.isWide() ? 'calendar' : 'tx', null, { tab: true }); }
  };
  P.acts.noteLink = (id) => { st.nl = { id, type: 'category', target: 'food' }; P.sheet('noteLink'); };
  P.sheets.noteLink = function () {
    const n = st.nl;
    const opts = {
      category: G.catIds('expense').map((c) => [c, L.cat(c).name]), account: D.ACCOUNTS.map((a) => [a.id, a.name]),
      budget: G.BUDGETS.map((b) => [b.id, `${L.cat(b.cat).name} budget`]), goal: D.GOALS.map((g) => [g.id, g.name]),
      transaction: D.transactions.slice(0, 40).map((t) => [t.id, `${G.shortDate(t.date)} · ${t.merchant || 'No merchant'} · ${L.fmt(t.amount, t.cur)}`]),
    };
    const target = n.type === 'date' ? P.input('nlDate', n.target, { type: 'date', label: 'Date' }) : P.select('nlTarget', n.target, opts[n.type], { label: 'Link to' });
    return `<h3>Add a link</h3><div class="lg-stack" style="gap:12px">${P.field('Type', `<div class="lg-add__pills">${Object.keys(LINK_ICON).map((t) => P.pill(t[0].toUpperCase() + t.slice(1), n.type === t, 'nlType', t, LINK_ICON[t])).join('')}</div>`)}${P.field('Link to', target)}${P.btn('Add link', 'nlSave', null, { kind: 'primary', block: true })}</div>`;
  };
  P.acts.nlType = (t) => { const n = st.nl; n.type = t; n.target = { category: 'food', account: 'main', budget: 'b1', goal: 'g1', date: G.TODAY, transaction: String(D.transactions[0].id) }[t]; P.render(); };
  P.inputs.nlTarget = (v) => { st.nl.target = v; };
  P.inputs.nlDate = (v) => { st.nl.target = v; };
  P.acts.nlSave = () => { const n = st.nl; G.NOTES.find((x) => x.id === n.id).links.push({ type: n.type, id: n.type === 'transaction' ? Number(n.target) : n.target }); P.closeSheet(); };

  // ---- Reports. Last month is preselected, so a report takes one tap ----
  const SECTIONS = [['summary', 'Summary'], ['categories', 'Spending by category'], ['budgets', 'Budgets'], ['accounts', 'Accounts'], ['transfers', 'Transfers'], ['transactions', 'All transactions'], ['notes', 'Notes']];
  st.rep = { span: 'Last month', format: 'PDF', on: { summary: true, categories: true, budgets: true, accounts: true, transfers: false, transactions: false, notes: false }, start: '', end: '' };
  function repRange() {
    const c = G.current(); const r = st.rep;
    if (r.span === 'This month') return c;
    if (r.span === 'Last month') return G.prevPeriod(c);
    if (r.span === 'Last 3 months') { const p = G.prevPeriod(c); const q = G.prevPeriod(G.prevPeriod(p)); return { start: q.start, end: p.end, label: `${q.short} to ${p.short} 2026` }; }
    if (r.span === 'This year') return { start: '2026-01-01', end: G.TODAY, label: '2026 to date' };
    const start = r.start || c.start; const end = r.end || G.TODAY;
    return { start, end, label: `${G.shortDate(start)} to ${G.shortDate(end)}` };
  }
  const pdfMoney = (v, sign) => L.fmt(v, 'EUR', sign);
  function pdfPreview() {
    const r = st.rep; const x = repRange(); const s = G.stats(x.start, x.end);
    const max = Math.max(1, ...s.ranked.map((c) => c.amount));
    const parts = [`<div><h3>Ledgerly report</h3><div>${esc(x.label)}. Made on ${G.longDate(G.TODAY)}. All amounts in EUR.</div></div>`];
    if (r.on.summary) parts.push(`<table><thead><tr><th>Summary</th><th>Amount</th></tr></thead><tbody><tr><td>Income</td><td>${pdfMoney(s.income)}</td></tr><tr><td>Spending</td><td>${pdfMoney(s.spending)}</td></tr><tr><td>Net</td><td>${pdfMoney(s.net, true)}</td></tr><tr><td>Savings rate</td><td>${Math.round(s.rate * 100)}%</td></tr></tbody></table>`);
    if (r.on.categories) parts.push(`<table><thead><tr><th>Category</th><th>Share</th><th>Amount</th></tr></thead><tbody>${s.ranked.map((c) => `<tr><td>${esc(L.cat(c.cat).name)}</td><td><span class="lg-print__bar" style="width:${Math.round((c.amount / max) * 96)}px"></span></td><td>${pdfMoney(c.amount)}</td></tr>`).join('')}</tbody></table>`);
    if (r.on.budgets) parts.push(`<table><thead><tr><th>Budget</th><th>Used</th><th>Spent of limit</th></tr></thead><tbody>${G.BUDGETS.filter((b) => b.every === 'Monthly').map((b) => { const v = G.budgetView(b, x.end > G.TODAY ? G.TODAY : x.end); return `<tr><td>${esc(L.cat(b.cat).name)}</td><td>${Math.round(v.ratio * 100)}%</td><td>${pdfMoney(v.spent)} of ${pdfMoney(v.limit)}</td></tr>`; }).join('')}</tbody></table>`);
    if (r.on.accounts) { const end = x.end > G.TODAY ? G.TODAY : x.end; parts.push(`<table><thead><tr><th>Account on ${G.shortDate(end)}</th><th>Balance</th></tr></thead><tbody>${D.ACCOUNTS.map((a) => `<tr><td>${esc(a.name)}</td><td>${L.fmt(G.balanceOf(a.id, end), a.cur)}</td></tr>`).join('')}<tr><td><b>Total balance</b></td><td><b>${pdfMoney(G.totalAt(end))}</b></td></tr></tbody></table>`); }
    if (r.on.transfers) { const list = s.list.filter((t) => t.type === 'transfer'); parts.push(`<table><thead><tr><th>Transfers, not income or spending</th><th>Amount</th></tr></thead><tbody>${list.slice(0, 6).map((t) => `<tr><td>${G.shortDate(t.date)} · ${D.acc(t.account).name} to ${D.acc(t.to).name}</td><td>${L.fmt(t.amount, t.cur)}</td></tr>`).join('') || '<tr><td>None</td><td></td></tr>'}</tbody></table>`); }
    if (r.on.transactions) parts.push(`<table><thead><tr><th>Transactions</th><th>Amount</th></tr></thead><tbody>${s.list.slice(0, 12).map((t) => `<tr><td>${G.shortDate(t.date)} · ${esc(t.merchant || 'No merchant')}</td><td>${L.fmt(t.amount, t.cur)}</td></tr>`).join('')}${s.list.length > 12 ? `<tr><td>${s.list.length - 12} more entries in the report</td><td></td></tr>` : ''}</tbody></table>`);
    if (r.on.notes) { const n = G.NOTES.filter((y) => y.date >= x.start && y.date <= x.end); parts.push(`<table><thead><tr><th>Notes</th></tr></thead><tbody>${n.map((y) => `<tr><td>${esc(y.title)}</td></tr>`).join('') || '<tr><td>None in this period</td></tr>'}</tbody></table>`); }
    return `<div class="lg-print" style="max-width:none">${parts.join('')}</div>`;
  }
  function csvPreview() {
    const x = repRange(); const rows = G.stats(x.start, x.end).list;
    const line = (t) => `<tr><td>${t.date}</td><td>${t.type}</td><td>${esc(t.merchant || '')}</td><td>${esc(t.cat ? L.cat(t.subcat || t.cat).name : '')}</td><td>${(t.amount / 100).toFixed(2)}</td><td>${t.cur}</td><td>${(t.base / 100).toFixed(2)}</td></tr>`;
    return `<div class="lg-card lg-card--flush"><div class="p-scrollbox"><table class="p-table"><thead><tr>${['date', 'type', 'merchant', 'category', 'amount', 'currency', 'amount_eur'].map((h) => `<th><button type="button" tabindex="-1">${h}</button></th>`).join('')}</tr></thead><tbody>${rows.slice(0, 10).map(line).join('')}</tbody></table></div></div><p class="p-note">${rows.length} rows in this file. All amounts are as entered, with the frozen EUR value beside them.</p>`;
  }
  P.views.reports = function () {
    const r = st.rep; const x = repRange();
    const config = `<div class="lg-card lg-stack">
      ${P.field('Period', `<div class="lg-add__pills">${['Last month', 'This month', 'Last 3 months', 'This year', 'Custom'].map((s) => P.pill(s, r.span === s, 'repSpan', s)).join('')}</div>`)}
      ${r.span === 'Custom' ? `<div class="p-grid2">${P.input('repStart', r.start, { type: 'date', label: 'From' })}${P.input('repEnd', r.end, { type: 'date', label: 'To' })}</div>` : ''}
      ${P.field('Sections', `<div class="lg-stack" style="gap:0">${SECTIONS.map(([id, label]) => P.check(label, r.on[id], 'repOn', id)).join('')}</div>`)}
      ${P.field('Format', P.seg(['PDF', 'CSV'], r.format, 'repFormat', 'Format'))}</div>`;
    const preview2 = r.format === 'PDF' ? pdfPreview() : csvPreview();
    const go = P.btn(`Create ${r.format}`, 'repMake', null, { kind: 'primary', block: true, icon: 'download' });
    if (P.isWide()) return P.scroll(P.screenHead('Reports', esc(x.label)), `<div class="app__desk-col" style="grid-template-columns:minmax(0,5fr) minmax(0,7fr)"><div class="app__col">${go}${config}</div><div class="app__col">${P.section('Preview')}${preview2}</div></div>`, 'app__wide');
    return P.scroll(P.screenHead('Reports', esc(x.label)), `${go}${config}${P.section('Preview')}${preview2}${go}`, 'app__narrow');
  };
  P.acts.repSpan = (s) => { st.rep.span = s; P.render(); };
  P.acts.repFormat = (s) => { st.rep.format = s; P.render(); };
  P.inputs.repOn = (v, id) => { st.rep.on[id] = v; P.render(); };
  P.inputs.repStart = (v) => { st.rep.start = v; P.render(); };
  P.inputs.repEnd = (v) => { st.rep.end = v; P.render(); };
  P.acts.repMake = () => { const r = st.rep; const x = repRange(); P.toast(`Report created, ${esc(x.label)}, ${r.format}. Simulated, no file was written.`, {}); };
})(window.Ledgerly);
