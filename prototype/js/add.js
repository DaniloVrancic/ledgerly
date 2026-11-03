// The Add sheet. A common expense is two taps plus the digits: Add, amount, category chip.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, attr, esc } = P;

  const last = { expense: 'main', income: 'main', transfer: ['main', 'euro'] };
  function blank() {
    return { kind: 'expense', amount: '', title: '', merchant: '', repeat: 'Never', account: last.expense, date: G.TODAY, cat: null, panel: null, more: false, keypad: true, save: false, tags: '', note: '', share: '', owedFrom: '', foreign: null, rate: '', split: null, attachments: 0, from: last.transfer[0], to: last.transfer[1], query: '', suggest: [] };
  }
  P.openAdd = function (seed) { if (P.isDesk()) return; st.toast = null; st.add = Object.assign(blank(), seed); P.render(); };
  P.closeAdd = function () { st.add = null; P.render(); };
  P.openAddState = (s, seed) => { s.add = Object.assign(blank(), seed); };

  const minorOf = (s) => { const v = parseFloat(String(s).replace(',', '.')); return Number.isFinite(v) ? Math.round(v * 100) : 0; };
  P.minorOf = minorOf;
  const curOf = (a) => (a.kind === 'transfer' ? D.acc(a.from).cur : D.acc(a.account).cur);
  const shown = (a) => a.foreign || curOf(a);
  function accountAmount(a) {
    const m = minorOf(a.amount);
    if (!a.foreign) return m;
    const eur = Math.round(m * (minorOf(a.rate) / 100));
    return D.acc(a.account).cur === 'EUR' ? eur : Math.round(eur * G.PEG);
  }
  const splitLeft = (a) => minorOf(a.amount) - a.split.reduce((s, r) => s + minorOf(r.amount), 0);
  const needsSave = (a) => a.more || a.save || a.kind === 'transfer';
  function canSave(a) {
    if (!minorOf(a.amount)) return false;
    if (a.kind === 'transfer') return a.from !== a.to;
    if (a.split) return splitLeft(a) === 0 && a.split.every((r) => r.cat);
    if (a.foreign && !minorOf(a.rate)) return false;
    return !!a.cat;
  }

  const TYPES = [{ label: 'Expense', id: 'expense', kind: 'expense', icon: 'down' }, { label: 'Income', id: 'income', kind: 'income', icon: 'up' }, { label: 'Transfer', id: 'transfer', kind: 'transfer', icon: 'transfer' }];
  const dateLabel = (d) => (d === G.TODAY ? 'Today' : d === G.addDays(G.TODAY, -1) ? 'Yesterday' : G.shortDate(d));

  function amountLine(a) {
    const m = minorOf(a.amount);
    const cur = shown(a);
    const text = cur === 'EUR' || cur === 'BAM' ? L.fmt(m, cur) : P.fmtAny(m, cur);
    const conv = a.foreign && minorOf(a.rate) ? `<small class="money">${L.fmt(accountAmount(a), D.acc(a.account).cur)}</small>` : '';
    return `<button type="button" class="p-clickable" ${act('addKeypad')} aria-label="Amount"><span class="lg-add__amount ${m ? '' : 'is-empty'}" aria-live="polite"><span class="money">${text}</span>${conv}</span></button>`;
  }
  function chipsArea(a) {
    if (a.panel === 'account' || a.panel === 'from' || a.panel === 'to') {
      const sel = a.panel === 'account' ? a.account : a[a.panel];
      return `<div class="lg-stack" style="gap:4px"><span class="lg-field__label">${a.panel === 'from' ? 'From' : a.panel === 'to' ? 'To' : 'Account'}</span><div class="lg-add__pills">${D.ACCOUNTS.map((x) => P.pill(`${esc(x.name)} <span class="lg-faint caption">${x.cur === 'EUR' ? 'EUR' : 'KM'}</span>`, x.id === sel, 'addPick', x.id)).join('')}</div></div>`;
    }
    if (a.panel === 'date') {
      const y = G.addDays(G.TODAY, -1);
      return `<div class="lg-add__pills">${P.pill('Today', a.date === G.TODAY, 'addDate', G.TODAY)}${P.pill('Yesterday', a.date === y, 'addDate', y)}<span class="lg-input" style="min-height:44px;flex:1 1 9rem"><input type="date" aria-label="Pick a date" data-in="addDate" value="${a.date}" max="${G.TODAY}"></span></div>`;
    }
    if (a.kind === 'transfer') {
      const m = minorOf(a.amount);
      const from = D.acc(a.from); const to = D.acc(a.to);
      if (from.cur === to.cur) return `<p class="p-note">Moves money between your accounts. Income and spending do not change.</p>`;
      const other = from.cur === 'EUR' ? Math.round(m * G.PEG) : D.toEur(m, from.cur);
      return `<div class="lg-stack" style="gap:0">${P.kv(`Leaves ${esc(from.name)}`, L.money(m, from.cur))}${P.kv(`Arrives in ${esc(to.name)}`, L.money(other, to.cur))}<p class="p-note">Fixed rate: 1 EUR = 1.95583 BAM. Income and spending do not change.</p></div>`;
    }
    const off = !minorOf(a.amount);
    const list = G.chips(a.account, a.kind);
    const ids = a.cat && !list.includes(a.cat) ? [...list.slice(0, 5), a.cat] : list;
    return `<div class="lg-chips" data-chips>${ids.map((id) => P.chip(id, { disabled: off, state: a.cat === id ? 'selected' : undefined, attrs: act('addChip', id) })).join('')}${attr(ui.chipAll({ disabled: off }), act('addPanel', 'all'))}${attr(ui.chipLater({ disabled: off }), act('addLater'))}</div>`;
  }
  function splitBlock(a) {
    if (!a.split) return '';
    const cur = shown(a);
    const opts = [['', 'Choose a category']].concat(G.allCats('expense', a.account).map((id) => [id, L.cat(id).parent ? `${L.cat(L.cat(id).parent).name} · ${L.cat(id).name}` : L.cat(id).name]));
    const left = splitLeft(a);
    const rows = a.split.map((r, i) => `<div class="p-split-row" data-key="sp${r.k}">${P.select('splitCat', r.cat || '', opts, { arg: i, label: `Part ${i + 1} category` })}${P.input('splitAmt', r.amount, { arg: i, mode: 'decimal', placeholder: '0.00', label: `Part ${i + 1} amount` })}<button type="button" class="lg-icon-btn" style="min-width:36px" aria-label="Remove part ${i + 1}" ${act('splitDel', i)}>${L.icon('x', 16)}</button></div>`).join('');
    const tone = left === 0 ? 'var(--positive)' : 'var(--warning)';
    return `<div class="lg-stack" style="gap:8px">${rows}<div class="p-split-left" style="color:${tone}"><span>${left === 0 ? 'Fully split' : left > 0 ? 'Remaining' : 'Over by'}</span><span class="money">${L.fmt(Math.abs(left), cur === 'BAM' ? 'BAM' : 'EUR')}</span></div>${P.btn('Add a part', 'splitAdd', null, { small: true, kind: 'secondary', icon: 'plus' })}</div>`;
  }
  function moreBlock(a) {
    if (!a.more) return '';
    const cur = D.acc(a.account).cur;
    const note = P.field('Note', P.textarea('addNote', a.note, { label: 'Note', placeholder: 'Anything to remember' }));
    if (a.kind === 'transfer') return `<div class="p-more">${note}</div>`;
    const shareLeft = minorOf(a.amount) - minorOf(a.share);
    const foreign = `${P.switch('Different currency', !!a.foreign, 'addForeign')}${a.foreign ? `<div class="p-grid2">${P.field('Currency', P.select('addCur', a.foreign, P.currencies.filter((c) => c !== cur).map((c) => [c, c === 'BAM' ? 'BAM (KM)' : c]), { label: 'Currency' }))}${P.field(`1 ${a.foreign} in EUR`, a.foreign === 'BAM' ? `<span class="lg-input is-disabled"><input disabled value="0.51129"></span>` : P.input('addRate', a.rate, { mode: 'decimal', placeholder: '0.92', label: 'Rate' }), a.foreign === 'BAM' ? 'Fixed rate' : 'Entered by you')}</div>` : ''}`;
    const expenseOnly = a.kind === 'expense' ? `${P.switch('Split across categories', !!a.split, 'addSplit')}${splitBlock(a)}
      ${P.switch('My share is less', a.share !== '', 'addShareOn')}${a.share !== '' ? `<div class="p-grid2">${P.field('My share', P.input('addShare', a.share, { mode: 'decimal', placeholder: '0.00', label: 'My share' }), shareLeft > 0 ? `${L.fmt(shareLeft, cur)} owed to me` : 'Enter the part that is yours')}${P.field('Owed by', P.input('addOwed', a.owedFrom, { placeholder: 'Name', label: 'Owed by' }))}</div>` : ''}` : '';
    const repeat = P.field('Repeat', P.seg(['Never', ...G.EVERY], a.repeat, 'addRepeat', 'Repeat'), a.repeatId && a.repeat !== 'Never' ? 'Already repeats. Choose Never to save this as a one-off.' : a.repeat !== 'Never' ? `Next on ${G.shortDate(G.advance(a.date, a.repeat))}. It waits as Due until you mark it paid.` : 'Set a repeat to make the next one a single tap.');
    const merchant = P.field('Merchant, optional', P.input('addMerchant', a.merchant, { placeholder: 'For example Konzum', label: 'Merchant, optional' }));
    return `<div class="p-more">${repeat}${merchant}${P.field('Tags', P.input('addTags', a.tags, { placeholder: 'trip, car', label: 'Tags' }), 'Separate with commas.')}${expenseOnly}${foreign}${note}
      <div class="lg-between"><span class="label">Attachments${a.attachments ? ` · ${a.attachments}` : ''}</span>${P.btn('Attach receipt', 'attachReceipt', 'add', { small: true, kind: 'secondary', icon: 'receipt' })}</div></div>`;
  }

  function allList(a) {
    const q = G.fold(a.query);
    const ids = G.allCats(a.kind, a.account).filter((id) => !q || G.fold(L.cat(id).name).includes(q));
    const rows = ids.map((id) => {
      const c = L.cat(id);
      return `<button type="button" class="lg-row" data-key="all${id}" ${act('addChip', id)}>${ui.catTile(c)}<span class="lg-row__body"><span class="lg-row__title">${esc(c.name)}</span>${c.parent ? `<span class="lg-row__sub">${esc(L.cat(c.parent).name)}</span>` : ''}</span></button>`;
    }).join('');
    return `<div class="lg-between"><h3 style="margin:0">Choose a category</h3>${P.iconBtn('x', 'Back to the entry', 'addPanel', '')}</div>
      <span class="lg-input lg-search" style="margin:8px 0">${L.icon('search', 20)}<input data-in="addQuery" aria-label="Search categories" placeholder="Search categories" value="${esc(a.query)}" data-autofocus></span>
      <div class="lg-card lg-card--flush">${rows || `<div class="lg-state"><p>No category with that name for this account.</p></div>`}</div>
      <div style="margin-top:12px">${P.btn('New category', 'addNewCat', null, { block: true, kind: 'secondary', icon: 'plus' })}</div>`;
  }

  function repeatHint(a) {
    const r = a.repeatId && a.repeat !== 'Never' && D.RECURRING.find((x) => x.id === a.repeatId);
    if (!r) return '';
    return `<div class="caption lg-faint lg-inline" style="gap:4px">${L.icon('repeat', 16)}${esc(r.name)} repeats. Saving marks the one ${r.state === 'due' ? P.dueWhen(r).toLowerCase() : `on ${G.shortDate(r.date)}`} as paid.</div>`;
  }
  P.addSheet = function () {
    const a = st.add;
    if (a.panel === 'all') return allList(a);
    if (a.panel === 'new') return P.categoryForm('add');
    const titlePill = (m) => P.pill(esc(m.name), G.fold(a.title) === G.fold(m.name), 'addTitle', m.name, L.cat(m.subcat || m.cat).icon);
    const known = a.suggest.map(titlePill).join('');
    // Titles used most in the last 90 days, so a frequent entry is one tap after the amount.
    const frequent = a.kind !== 'transfer' && !a.title ? G.titles().filter((m) => m.type === a.kind).slice(0, 6) : [];
    const tpl = frequent.length ? `<div class="p-templates" aria-label="Frequent titles">${frequent.map(titlePill).join('')}</div>` : '';
    const pills = a.kind === 'transfer'
      ? `${P.pill(esc(D.acc(a.from).name), a.panel === 'from', 'addPanel', 'from', 'wallet')}<span style="align-self:center;color:var(--neutral)">${L.icon('transfer', 16, 'to')}</span>${P.pill(esc(D.acc(a.to).name), a.panel === 'to', 'addPanel', 'to', 'wallet')}`
      : P.pill(esc(D.acc(a.account).name), a.panel === 'account', 'addPanel', 'account', 'wallet');
    const save = needsSave(a) ? P.btn(a.kind === 'transfer' ? 'Save transfer' : 'Save', 'addSave', null, { kind: 'primary', small: true, state: canSave(a) ? undefined : 'disabled' }) : '';
    const keypad = a.keypad ? ui.keypad().replace(/data-key="(\w+|\.)"/g, 'data-key="k$1" data-act="addKey" data-arg="$1"') : '';
    return `<div class="lg-add p-add">${tpl}${amountLine(a)}
      <span class="lg-input"><input data-in="addTitle" aria-label="Title" placeholder="${a.kind === 'transfer' ? 'Title, optional' : 'Title, for example Groceries'}" value="${esc(a.title)}" autocomplete="off"></span>
      ${known ? `<div class="p-suggest" aria-label="Titles you used before">${known}</div>` : ''}${repeatHint(a)}
      ${P.seg(TYPES, a.kind, 'addKind', 'Type')}
      <div class="lg-add__pills">${pills}${P.pill(dateLabel(a.date), a.panel === 'date', 'addPanel', 'date', 'calendar')}</div>
      ${chipsArea(a)}
      <div class="p-add__row"><button type="button" class="lg-add__more" aria-expanded="${a.more}" ${act('addMore')}>More details${L.icon('chevronDown', 20)}</button>${save}</div>
      ${moreBlock(a)}${keypad}</div>`;
  };

  P.acts.addKey = function (k) {
    const a = st.add;
    if (k === 'del') a.amount = a.amount.slice(0, -1);
    else if (k === '.') { if (!a.amount.includes('.')) a.amount = (a.amount || '0') + '.'; } else if (/\.\d\d$/.test(a.amount) || a.amount.replace('.', '').length >= 9) return;
    else a.amount = a.amount === '0' ? k : a.amount + k;
    if (a.split && a.split.length) { const r = a.split[a.split.length - 1]; if (a.split.length === 1) r.amount = a.amount; }
    P.render();
  };
  P.addKey = function (e) {
    if (/^[0-9.]$/.test(e.key)) { P.acts.addKey(e.key); return true; }
    if (e.key === ',') { P.acts.addKey('.'); return true; }
    if (e.key === 'Backspace') { P.acts.addKey('del'); return true; }
    return false;
  };
  P.acts.addKeypad = () => { const a = st.add; a.keypad = !a.keypad || !a.more; P.render(); };
  P.acts.addKind = function (k) {
    const a = st.add;
    a.kind = k; a.cat = null; a.save = false; a.panel = null; a.suggest = [];
    if (k !== 'transfer') a.account = last[k]; else a.more = false;
    if (k !== 'expense') { a.split = null; a.share = ''; }
    P.render();
  };
  P.acts.addPanel = function (p) {
    const a = st.add;
    a.panel = a.panel === p || !p ? null : p;
    if (p === 'all') a.query = '';
    P.render();
  };
  P.acts.addPick = function (id) {
    const a = st.add;
    if (a.panel === 'account') {
      a.account = id;
      if (a.cat && !G.applies(a.cat, id)) { a.cat = null; if (!a.more) a.save = false; }
    } else if (a.panel === 'from') { if (a.to === id) a.to = a.from; a.from = id; } else { if (a.from === id) a.from = a.to; a.to = id; }
    a.panel = null;
    P.render();
  };
  P.acts.addDate = (d) => { st.add.date = d; st.add.panel = null; P.render(); };
  P.inputs.addDate = (v) => { if (v) { st.add.date = v; st.add.panel = null; P.render(); } };
  // Title memory: a title typed before brings back its usual subcategory and account.
  P.inputs.addTitle = function (v) {
    const a = st.add;
    a.title = v;
    a.repeatId = null;
    const q = G.fold(v.trim());
    const known = G.titles().filter((m) => m.type === a.kind);
    const exact = known.find((m) => G.fold(m.name) === q);
    if (exact) { remember(exact); a.suggest = []; } else a.suggest = q && a.kind !== 'transfer' ? known.filter((m) => G.fold(m.name).includes(q)).slice(0, 4) : [];
    P.render();
  };
  P.inputs.addMerchant = (v) => { st.add.merchant = v; };
  const repeatFor = (title, kind) => D.RECURRING.find((r) => r.kind === kind && G.fold(r.name) === G.fold(title));
  function remember(m) {
    const a = st.add;
    a.title = m.name; a.account = m.account; a.cat = m.subcat || m.cat; a.save = true; a.suggest = []; a.panel = null;
    const r = repeatFor(m.name, a.kind);
    a.repeatId = r ? r.id : null;
    if (r) { a.repeat = r.every; a.account = r.account; }
  }
  // With an amount already typed, a title saves at once, like a chip.
  P.acts.addTitle = (name) => {
    const a = st.add;
    remember(G.titles().find((m) => m.name === name));
    if (minorOf(a.amount) && !a.more) { saveNow(); return; }
    P.render();
  };
  P.acts.addRepeat = (v) => { st.add.repeat = v; P.render(); };
  P.acts.addChip = function (id) {
    const a = st.add;
    if (!minorOf(a.amount)) { a.panel = null; P.render(); return; }
    a.cat = a.cat === id && needsSave(a) ? null : id;
    a.panel = null;
    if (needsSave(a)) { P.render(); return; }
    saveNow();
  };
  P.acts.addLater = function () {
    const a = st.add;
    const amount = accountAmount(a);
    const cur = D.acc(a.account).cur;
    const p = { type: a.kind, account: a.account, amount, title: a.title.trim() || null, cat: null, subcat: null, date: a.date, flags: ['review'] };
    st.add = null;
    P.withUndo(`Saved ${L.fmt(amount, cur)} to Needs Review`, () => G.create(p), { moreLabel: 'Add another', more: () => P.openAdd() });
  };
  P.acts.addMore = () => { const a = st.add; a.more = !a.more; if (a.more) a.keypad = !minorOf(a.amount); else a.keypad = true; P.render(); };
  P.acts.addSave = () => { if (canSave(st.add)) saveNow(); };
  P.inputs.addNote = (v) => { st.add.note = v; };
  P.inputs.addTags = (v) => { st.add.tags = v; };
  P.inputs.addRate = (v) => { st.add.rate = v; P.render(); };
  P.inputs.addCur = (v) => { st.add.foreign = v; st.add.rate = v === 'BAM' ? '0.51129' : ''; P.render(); };
  P.inputs.addForeign = (v) => { const a = st.add; a.foreign = v ? (D.acc(a.account).cur === 'EUR' ? 'USD' : 'EUR') : null; a.rate = a.foreign === 'EUR' ? '1' : ''; P.render(); };
  P.inputs.addShareOn = (v) => { const a = st.add; a.share = v ? a.amount || '0' : ''; P.render(); };
  P.inputs.addShare = (v) => { st.add.share = v; P.render(); };
  P.inputs.addOwed = (v) => { st.add.owedFrom = v; };
  let splitKey = 1;
  P.inputs.addSplit = function (v) {
    const a = st.add;
    a.split = v ? [{ k: splitKey++, cat: a.cat || '', amount: a.amount }, { k: splitKey++, cat: '', amount: '' }] : null;
    P.render();
  };
  P.acts.splitAdd = () => { st.add.split.push({ k: splitKey++, cat: '', amount: '' }); P.render(); };
  P.acts.splitDel = (i) => { const a = st.add; a.split.splice(Number(i), 1); if (!a.split.length) a.split = null; P.render(); };
  P.inputs.splitCat = (v, i) => { st.add.split[Number(i)].cat = v; P.render(); };
  P.inputs.splitAmt = (v, i) => { st.add.split[Number(i)].amount = v; P.render(); };
  P.inputs.addQuery = (v) => { st.add.query = v; P.render(); };
  P.acts.addNewCat = function () {
    const a = st.add;
    P.catEdit = { name: a.query || '', kind: a.kind === 'income' ? 'income' : 'expense', icon: 'paw', slot: 9, accounts: [], img: null, error: false };
    a.panel = 'new';
    P.render();
  };

  function saveNow() {
    const a = st.add;
    const amount = accountAmount(a);
    if (a.kind === 'transfer') {
      const from = D.acc(a.from); const to = D.acc(a.to);
      const label = a.title.trim() || (a.to === 'cash' ? 'ATM withdrawal' : a.to === 'card' ? 'Credit card payment' : a.to === 'savings' ? 'To Savings' : `To ${to.name}`);
      const p = { type: 'transfer', account: a.from, to: a.to, amount, title: label, date: a.date, note: a.note || undefined };
      last.transfer = [a.from, a.to];
      st.add = null;
      P.withUndo(`Transfer saved, ${L.fmt(amount, from.cur)} to ${esc(to.name)}`, () => G.create(p), { moreLabel: 'Add another', more: () => P.openAdd({ kind: 'transfer' }) });
      return;
    }
    const cur = D.acc(a.account).cur;
    const cat = a.split ? a.split[0].cat : a.cat;
    const parent = G.parentOf(cat);
    const title = a.title.trim() || (a.split ? 'Split purchase' : L.cat(cat).name);
    const p = { type: a.kind, account: a.account, amount, title, merchant: a.merchant.trim() || null, cat: parent, subcat: parent === cat ? null : cat, date: a.date, flags: [], tags: a.tags.split(',').map((s) => s.trim()).filter(Boolean), note: a.note || undefined };
    if (a.attachments) { p.flags.push('receipt'); p.attachments = a.attachments; }
    if (a.split) {
      p.flags.push('split');
      const parts = a.split.map((r) => { const pc = G.parentOf(r.cat); return [pc, D.toEur(minorOf(r.amount), cur), pc === r.cat ? null : r.cat]; });
      const eur = D.toEur(amount, cur);
      parts[parts.length - 1][1] += eur - parts.reduce((s, x) => s + x[1], 0);
      p.parts = parts;
    }
    if (a.share !== '' && minorOf(a.share) < minorOf(a.amount)) { p.share = minorOf(a.share); p.flags.push('shared'); p.owedFrom = a.owedFrom || null; }
    if (a.foreign) p.orig = { amount: minorOf(a.amount), cur: a.foreign, rate: minorOf(a.rate) / 100 };
    last[a.kind] = a.account;
    const kind = a.kind;
    st.add = null;
    const every = a.repeat !== 'Never' && !a.split ? a.repeat : null;
    const existing = every && a.repeatId && D.RECURRING.find((x) => x.id === a.repeatId);
    if (existing) {
      const next = G.advance(existing.date, existing.every, existing.day);
      P.withUndo(`Saved ${L.fmt(amount, cur)}, ${esc(title)}. Marked paid, next on ${G.shortDate(next)}`, () => {
        const t = G.create(Object.assign(p, { rec: existing.id, every: existing.every, flags: p.flags.concat('recurring') }));
        if (existing.varies) existing.amount = amount;
        G.skip(existing.id);
        return t;
      }, { moreLabel: 'Add another', more: () => P.openAdd({ kind }) });
      return;
    }
    const save = () => {
      const t = G.create(p);
      if (every) { const r = G.addRepeat({ name: title, cat: parent, subcat: p.subcat, amount, account: a.account, every, date: G.advance(a.date, every), kind }); t.rec = r.id; t.every = every; t.flags.push('recurring'); }
      return t;
    };
    P.withUndo(`Saved ${L.fmt(amount, cur)}, ${esc(title)}${every ? `. Repeats ${every.toLowerCase()}, next on ${G.shortDate(G.advance(a.date, every))}` : ''}`, save, { moreLabel: 'Add another', more: () => P.openAdd({ kind }) });
  }

  // Attachments are simulated: the first one asks for permission, the way Android would.
  P.acts.attachReceipt = function (where) {
    const done = () => {
      if (where === 'add') st.add.attachments += 1;
      else { const t = D.transactions.find((x) => x.id === Number(where)); G.update(t.id, { flags: t.flags.includes('receipt') ? t.flags : t.flags.concat('receipt') }); }
      P.toast('Receipt attached. Simulated, a placeholder image is used.', {});
    };
    if (G.S.permissions.camera) { done(); return; }
    P.dialog({ title: 'Allow Ledgerly to use the camera?', text: 'Simulated Android prompt. Photos of receipts stay on this device, inside Ledgerly.', ok: 'Allow', cancel: 'Not now', confirm: () => { G.S.permissions.camera = true; done(); } });
  };

  // One category form for the Add sheet and for the Categories screen.
  P.categoryForm = function (from) {
    const c = P.catEdit;
    const prev = { name: c.name || 'New category', icon: c.icon, slot: c.slot, img: c.img };
    const accounts = c.accounts.map((x) => D.acc(x).name).join(', ') || 'All accounts';
    const icons = ui.iconPicker(c.icon).replace(/data-pick-icon="(\w+)"/g, 'data-act="catIcon" data-arg="$1"');
    const colours = ui.colourPicker(c.slot).replace(/data-pick-colour="(\d+)"/g, 'data-act="catSlot" data-arg="$1"');
    const picker = ui.accountPicker(c.accounts).replace('data-pick-all', 'data-in="catAll"').replace(/data-pick-account="(\w+)"/g, 'data-act="catAccount" data-arg="$1"');
    const parents = [['', 'None, a main category']].concat(G.catIds('expense').filter((id) => id !== 'other').map((id) => [id, L.cat(id).name]));
    return `<div class="lg-cated"><div class="lg-between"><h3 style="margin:0">${c.id ? 'Edit category' : 'New category'}</h3>${P.iconBtn('x', 'Close', from === 'add' ? 'addPanel' : 'closeSheet', from === 'add' ? 'all' : null)}</div>
      <div class="lg-cated__preview">${ui.catTile(prev, 24)}<span class="lg-row__body"><span class="lg-row__title">${esc(prev.name)}</span><span class="lg-row__sub">${esc(accounts)}</span></span></div>
      <div class="lg-field ${c.error ? 'is-error' : ''}"><span class="lg-field__label">Name</span><span class="lg-input ${c.error ? 'is-error' : ''}"><input data-in="catName" aria-label="Name" value="${esc(c.name)}" placeholder="For example Čišćenje" maxlength="32" data-autofocus></span><span class="lg-field__hint">${c.error ? 'Enter a name for this category.' : 'Shown on chips and in reports.'}</span></div>
      ${c.id ? '' : `<div class="lg-field"><span class="lg-field__label">Type</span>${P.seg([{ label: 'Expense', id: 'expense', kind: 'expense', icon: 'down' }, { label: 'Income', id: 'income', kind: 'income', icon: 'up' }], c.kind, 'catKind', 'Type')}</div>`}
      ${c.kind === 'expense' && !c.id ? P.field('Inside', P.select('catParent', c.parent || '', parents, { label: 'Inside a category' }), 'One level of subcategories only.') : ''}
      <div class="lg-field"><span class="lg-field__label">Icon</span>${icons}<label class="lg-btn lg-btn--secondary lg-btn--small lg-btn--block lg-cated__upload">${L.icon('image', 20)}<span>${c.img ? 'Image chosen' : 'Use my own image'}</span><input type="file" accept="image/*" data-in="catImage" aria-label="Use my own image"></label></div>
      <div class="lg-field"><span class="lg-field__label">Colour</span>${colours}</div>
      ${c.parent ? '' : `<div class="lg-field"><span class="lg-field__label">Accounts</span>${picker}<span class="lg-field__hint">It appears on the Add sheet for these accounts. History and reports always keep it.</span></div>`}
      ${P.btn(c.id ? 'Save changes' : 'Save category', 'catSave', from, { kind: 'primary', block: true })}</div>`;
  };
  P.inputs.catName = (v) => { P.catEdit.name = v; P.catEdit.error = false; P.render(); };
  P.inputs.catParent = (v) => { P.catEdit.parent = v || null; P.render(); };
  P.acts.catKind = (k) => { P.catEdit.kind = k; if (k === 'income') P.catEdit.parent = null; P.render(); };
  P.acts.catIcon = (n) => { P.catEdit.icon = n; P.catEdit.img = null; P.render(); };
  P.acts.catSlot = (n) => { P.catEdit.slot = Number(n); P.render(); };
  P.inputs.catAll = (on) => {
    const c = P.catEdit;
    c.accounts = on ? [] : [st.add ? st.add.account : 'main'];
    P.render();
  };
  P.acts.catAccount = (id) => {
    const c = P.catEdit;
    const next = c.accounts.includes(id) ? c.accounts.filter((x) => x !== id) : c.accounts.concat(id);
    if (next.length) c.accounts = next; // At least one account stays chosen.
    P.render();
  };
  P.inputs.catImage = (v, a, el) => {
    const f = el.files && el.files[0];
    if (!f) return;
    const r = new FileReader();
    r.onload = () => { P.catEdit.img = r.result; P.render(); };
    r.readAsDataURL(f);
  };
  P.acts.catSave = function (from) {
    const c = P.catEdit;
    if (!c.name.trim()) { c.error = true; P.render(); return; }
    if (c.id) {
      const cat = L.cat(c.id);
      Object.assign(cat, { name: c.name.trim(), icon: c.icon, slot: c.slot, img: c.img });
      if (!cat.parent) G.setTies(c.id, c.accounts); else G.bump();
      st.sheet = null;
      P.toast(`${esc(c.name.trim())} saved`, {});
      return;
    }
    const id = G.addCategory({ name: c.name.trim(), icon: c.img ? 'image' : c.icon, slot: c.slot, kind: c.kind, img: c.img }, c.accounts, c.parent);
    G.pinChip(id, c.kind);
    if (from === 'add') {
      const a = st.add;
      if (!G.applies(id, a.account)) a.account = c.accounts[0];
      Object.assign(a, { cat: id, panel: null, save: true });
      P.render();
      return;
    }
    st.sheet = null;
    P.toast(`${esc(c.name.trim())} added`, {});
  };
})(window.Ledgerly);
