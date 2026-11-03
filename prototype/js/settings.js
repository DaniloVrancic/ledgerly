// Settings, Backup and data, data file import, bank statement import, and Categories.
// File handling, encryption and biometrics are simulated and say so on screen.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, esc } = P;
  const ro = () => P.isDesk();
  const narrow = (head, body) => P.scroll(head, body, 'app__narrow');

  P.views.settings = function () {
    const rows = [['Appearance', 'sparkle', 'appearance', `${st.themePref[0].toUpperCase()}${st.themePref.slice(1)}, ${st.accent[0].toUpperCase()}${st.accent.slice(1)}`], ['Regional', 'calendar', 'regional', `Month starts on the ${G.S.monthStart === 1 ? '1st' : `${G.S.monthStart}th`}, EUR and BAM`], ['Security', 'lock', 'security', G.S.lock ? `App lock on, after ${G.S.lockDelay}` : 'App lock off'], ['Backup and data', 'shield', 'backup', { healthy: `Backed up ${G.diffDays(G.TODAY, G.S.backupAt) || 'to'}${G.diffDays(G.TODAY, G.S.backupAt) ? ' days ago' : 'day'}`, overdue: 'Backup overdue', failed: 'Backup failed' }[G.S.backup]], ['Categories', 'tag', 'categories', `${G.catIds('expense').length} expense, ${G.catIds('income').length} income`]];
    const more = [['Home-screen widget', 'plus', 'widget', 'Android quick add'], ['Empty, error and permission states', 'alert', 'states', 'For review']];
    return narrow(P.screenHead('Settings'), `<div class="lg-card lg-card--flush">${rows.map(([title, icon, to, sub]) => P.row({ title, icon, sub, name: 'go', arg: to })).join('')}</div>${P.section('Prototype')}<div class="lg-card lg-card--flush">${more.map(([title, icon, to, sub]) => P.row({ title, icon, sub, name: 'go', arg: to })).join('')}${P.row({ title: 'First launch', icon: 'ledger', sub: 'As on a new install', name: 'firstRun' })}</div>${ro() ? '<p class="p-note">This copy is read-only. Settings change on the phone or tablet.</p>' : ''}`);
  };

  P.views.appearance = function () {
    const accents = (L.tokens.accents || []).map((a) => `<button type="button" class="lg-pill" aria-pressed="${st.accent === a.id}" ${act('setAccent', a.id)}><span style="width:16px;height:16px;border-radius:99px;background:var(--accent-${a.id})"></span><span>${a.name}</span></button>`).join('');
    return narrow(P.screenHead('Appearance'), `<div class="lg-card lg-stack">${P.field('Theme', P.seg([{ label: 'Light', id: 'light' }, { label: 'Dark', id: 'dark' }, { label: 'System', id: 'system' }], st.themePref, 'themeNow', 'Theme'))}${P.field('Accent colour', `<div class="lg-add__pills">${accents}</div>`, 'Used for buttons and selection. Income, spending and warnings keep their own colours.')}${P.switch('Hide amounts on Home', st.hidden, 'setHidden')}</div>`);
  };
  P.acts.setAccent = (a) => { st.accent = a; P.render(); };
  P.inputs.setHidden = (v) => { st.hidden = v; P.render(); };

  const ORD = (n) => (n === 1 || n === 21 ? `${n}st` : n === 2 || n === 22 ? `${n}nd` : n === 3 || n === 23 ? `${n}rd` : `${n}th`);
  const rates = { USD: '0.92', GBP: '1.15', CHF: '1.04' };
  P.views.regional = function () {
    const p = G.current();
    if (ro()) return narrow(P.screenHead('Regional'), `<div class="lg-card lg-stack" style="gap:0">${P.kv('Month starts on', `<b>The ${ORD(G.S.monthStart)}</b>`)}${P.kv('Reporting currency', '<b>EUR</b>')}${P.kv('Second currency', '<b>BAM</b>')}${P.kv('Fixed rate', '<b>1 EUR = 1.95583 BAM</b>')}</div><p class="p-note">These come from the data file. Change them on the phone or tablet.</p>`);
    return narrow(P.screenHead('Regional'), `<div class="lg-card lg-stack">
      ${P.field('Month starts on', P.select('setMonthStart', G.S.monthStart, Array.from({ length: 28 }, (_, i) => [i + 1, `The ${ORD(i + 1)}${i === 0 ? ' (default)' : i === 27 ? ', payday' : ''}`]), { label: 'Month starts on' }), `Budgets, Home and reports follow this. Now: ${esc(p.label)}.`)}
      ${P.kv('Reporting currency', '<b>EUR</b>')}${P.kv('Second currency', '<b>BAM</b>')}${P.kv('Fixed rate', '<b>1 EUR = 1.95583 BAM</b>')}</div>
      ${P.section('Other currencies')}<div class="lg-card lg-stack"><p class="p-note">Entered by you. Each entry keeps the rate it was saved with, so history never changes.</p>${Object.keys(rates).map((c) => P.field(`1 ${c} in EUR`, P.input('setRate', rates[c], { arg: c, mode: 'decimal', label: `1 ${c} in EUR` }))).join('')}</div>
      <div class="lg-card lg-stack" style="gap:0">${P.kv('Language', '<b>English</b>')}${P.kv('Amounts', '<b>€1,234.56 and 1,234.56 KM</b>')}${P.kv('Week starts on', '<b>Monday</b>')}</div>`);
  };
  P.inputs.setMonthStart = (v) => { G.S.monthStart = Number(v); G.bump(); P.render(); };
  P.inputs.setRate = (v, c) => { rates[c] = v; };

  P.views.security = function () {
    if (ro()) return narrow(P.screenHead('Security'), `<div class="lg-card lg-stack" style="gap:0">${P.kv('App lock', `<b>${G.S.lock ? 'On' : 'Off'}</b>`)}${P.kv('Lock after', `<b>${G.S.lockDelay}</b>`)}</div><p class="p-note">App lock belongs to the phone or tablet. App lock hides the app. A password protects an exported file.</p>`);
    return narrow(P.screenHead('Security'), `<div class="lg-card lg-stack">${P.switch('App lock', G.S.lock, 'setLock')}<p class="p-note">Uses this phone's own lock and biometrics. ${P.simulated().trim()}</p>
      ${P.field('Lock after', P.select('setDelay', G.S.lockDelay, ['Immediately', '1 minute', '5 minutes', '30 minutes'].map((x) => [x, x + (x === '5 minutes' ? ' (default)' : '')]), { label: 'Lock after' }), 'A short delay means frequent use does not mean constant unlocking.')}
      ${G.S.lock ? P.btn('See the lock screen', 'showLock', null, { kind: 'secondary', small: true }) : ''}</div>
      <p class="p-note">App lock hides the app. A password protects an exported file.</p>`);
  };
  P.inputs.setLock = (v) => { G.S.lock = v; P.render(); };
  P.inputs.setDelay = (v) => { G.S.lockDelay = v; };
  P.acts.showLock = () => { st.full = { name: 'lock' }; P.render(); };
  P.views.lock = () => `<div class="p-first" style="text-align:center;align-items:center">${L.appIcon(64)}<h2 class="lg-title">Ledgerly is locked</h2><p class="p-note">Use your fingerprint or the phone's lock.</p>${P.btn('Unlock', 'unlock', null, { kind: 'primary', icon: 'lock' })}<div>${P.simulated('No biometric check runs here.')}</div></div>`;
  P.acts.unlock = () => { st.full = null; P.render(); };

  // ---- Backup and data: one calm screen, one file for backup, export and transfer ----
  const contents = 'Data, attachments and settings';
  P.views.backup = function () {
    const b = G.S.backup;
    const ago = G.diffDays(G.TODAY, G.S.backupAt);
    const status = ui.backup(b).replace('Backed up 2 days ago', `Backed up ${ago ? `${ago} days ago` : 'today'}`).replace('<button type="button" class="lg-btn lg-btn--secondary lg-btn--small"', `<button type="button" class="lg-btn lg-btn--secondary lg-btn--small" ${act(b === 'failed' ? 'chooseFolder' : 'backupNow')}`);
    const c = G.counts();
    const details = `<div class="lg-stack" style="gap:0">${P.kv('Last backup', `<b>${b === 'overdue' ? '17 Oct 2026' : G.longDate(G.S.backupAt)}, 22:10</b>`)}${P.kv('Contains', `<b>${contents}</b>`)}${P.kv('Size', `<b>${G.sizeOf(true)}</b>`)}${P.kv('Verification', `<b>${b === 'failed' ? 'Not verified' : `Read back, ${c.transactions.toLocaleString('en-US')} transactions`}</b>`)}${P.kv('Last restore test', `<b>${G.longDate(G.S.restoreTest)}</b>`)}${P.kv('Folder', `<b>${esc(G.S.folder)}</b>`)}</div>`;
    const proto = `<div class="lg-card lg-stack"><div class="lg-inline"><span class="lg-badge lg-badge--proto">Prototype</span><span class="caption lg-faint">See each backup status</span></div>${P.seg([{ label: 'Healthy', id: 'healthy' }, { label: 'Overdue', id: 'overdue' }, { label: 'Failed', id: 'failed' }], b, 'backupDemo', 'Backup status')}</div>`;
    if (ro()) return narrow(P.screenHead('Backup and data'), `${status}<div class="lg-card">${details}</div><p class="p-note">This copy is read-only. Backups, export and import run on the phone or tablet.</p>`);
    return narrow(P.screenHead('Backup and data'), `${status}
      ${P.section('Automatic backups')}<div class="lg-card lg-stack">${details}<div class="p-grid2">${P.btn('Back up now', 'backupNow', null, { kind: 'secondary', small: true })}${P.btn('Choose folder', 'chooseFolder', null, { kind: 'secondary', small: true })}</div><p class="p-note">Backups go to a folder you choose outside the app, because uninstalling Ledgerly deletes its private data. A copy kept only on the phone will not survive losing the phone.</p></div>
      ${P.section('Move or keep a copy')}<div class="lg-card lg-stack">${P.btn('Export all data', 'startExport', null, { kind: 'primary', block: true, icon: 'download' })}${P.btn('Import from a data file', 'startImport', 'settings', { kind: 'secondary', block: true, icon: 'upload' })}<p class="p-note">Backup, export and transfer all use one .ledgerly file. It is an open format, so your data stays readable without Ledgerly unless you set a password.</p></div>
      ${P.section('From your bank')}<div class="lg-card lg-card--flush">${P.row({ title: 'Bank statement CSV', sub: 'Compare a statement with your entries', icon: 'page', name: 'go', arg: 'csv' })}</div>
      ${proto}`);
  };
  P.acts.backupDemo = (v) => { G.S.backup = v; G.bump(); P.render(); };
  P.acts.backupNow = () => { G.S.backup = 'healthy'; G.S.backupAt = G.TODAY; G.bump(); P.toast('Backed up today. Simulated, no file was written.', {}); };
  P.acts.chooseFolder = () => { G.S.folder = 'Documents/Ledgerly'; if (G.S.backup === 'failed') G.S.backup = 'overdue'; G.bump(); P.toast('Folder set to Documents/Ledgerly. Simulated system picker.', {}); };

  P.acts.startExport = () => { st.exp = { attachments: true, usePw: false, pw: '', pw2: '', ack: false, dest: 'Save to a file', result: null }; P.sheet('export'); };
  P.sheets.export = function () {
    const e = st.exp;
    if (e.result) {
      const f = e.result;
      return `<div class="lg-stack" style="gap:12px"><div style="text-align:center">${L.stateMark('shieldCheck')}<h3 style="margin:0">Export verified</h3></div>
        <div class="lg-card" style="background:var(--positive-tint);border-color:transparent"><div class="lg-inline" style="color:var(--positive);flex-wrap:nowrap">${L.icon('check', 20)}<span class="body-small">${f.counts.transactions.toLocaleString('en-US')} transactions, ${f.counts.receipts} receipts, verified</span></div></div>
        <div class="lg-stack" style="gap:0">${P.kv('File', `<b>${esc(f.name)}</b>`)}${P.kv('Size', `<b>${f.size}</b>`)}${P.kv('Password', `<b>${f.password ? 'Set' : 'None'}</b>`)}${P.kv('Saved with', `<b>${esc(f.dest)}</b>`)}</div>
        <div>${P.simulated('No file was written. Ledgerly would read the file back to check it.')}</div>
        ${P.btn('Done', 'closeSheet', null, { kind: 'primary', block: true })}${P.btn('Try this file on a new install', 'firstRun', null, { kind: 'secondary', block: true })}</div>`;
    }
    const mismatch = e.usePw && e.pw2 && e.pw !== e.pw2;
    const ok = !e.usePw || (e.pw && e.pw === e.pw2 && e.ack);
    return `<h3>Export all data</h3><p>One .ledgerly file with everything, to keep safe or to move to another install.</p><div class="lg-stack" style="gap:8px">
      ${P.switch('Include attachments', e.attachments, 'expAtt')}
      ${P.switch('Add a password', e.usePw, 'expPw')}
      ${e.usePw ? `${P.field('Password', P.input('expPass', e.pw, { type: 'password', label: 'Password', focus: true }))}${P.field('Repeat password', P.input('expPass2', e.pw2, { type: 'password', label: 'Repeat password', error: mismatch }), mismatch ? 'The two passwords differ.' : '')}
      <div class="lg-card" style="background:var(--warning-tint);border-color:transparent"><div class="lg-inline" style="color:var(--warning);flex-wrap:nowrap;align-items:flex-start">${L.icon('alert', 20)}<span class="body-small">This password cannot be recovered. Without it, nobody can open this file, including you and Ledgerly.</span></div></div>${P.check('I understand it cannot be recovered', e.ack, 'expAck')}` : ''}
      ${P.kv('Estimated size', `<b>${G.sizeOf(e.attachments)}</b>`)}
      ${P.field('Save with', P.seg(['Save to a file', 'Share'], e.dest, 'expDest', 'Save with'), 'Opens the system file picker or share sheet.')}
      ${P.btn('Export', 'expRun', null, { kind: 'primary', block: true, icon: 'download', state: ok ? undefined : 'disabled' })}</div>`;
  };
  P.inputs.expAtt = (v) => { st.exp.attachments = v; P.render(); };
  P.inputs.expPw = (v) => { st.exp.usePw = v; P.render(); };
  P.inputs.expPass = (v) => { st.exp.pw = v; P.render(); };
  P.inputs.expPass2 = (v) => { st.exp.pw2 = v; P.render(); };
  P.inputs.expAck = (v) => { st.exp.ack = v; P.render(); };
  P.acts.expDest = (v) => { st.exp.dest = v; P.render(); };
  P.acts.expRun = () => { const e = st.exp; e.result = G.exportFile({ attachments: e.attachments, password: e.usePw ? e.pw : null, dest: e.dest }); P.render(); };

  // Import: preview first, a typed confirmation, a safety copy, then a plain result.
  const NOTHING = 'Nothing in Ledgerly was changed.';
  P.acts.startImport = (from) => { st.imp = { from, step: 'pick', file: null, pw: '', pwError: false, typed: '' }; st.sheet = null; st.full = { name: 'import' }; P.render(); };
  P.views.import = function () {
    const m = st.imp;
    const head = `<div class="app__head">${P.iconBtn('x', 'Close', 'importClose')}<div style="flex:1 1 auto"><h2 class="lg-title">Import from a data file</h2></div></div>`;
    const box = (body) => `${head}<div class="app__scroll" data-scroll><div class="app__body app__narrow">${body}</div></div>`;
    if (m.step === 'pick') {
      const own = G.S.files.map((f) => P.row({ title: esc(f.name), sub: `Exported ${esc(f.date)}, ${f.password ? 'password set' : 'no password'}`, icon: 'page', name: 'importPick', arg: f.id })).join('');
      const samples = G.sampleFiles();
      const other = [['bad', 'A damaged file'], ['wrongpw', 'A file with a password you do not know'], ['newer', 'A file from a newer app version']].map(([id, sub]) => { const f = samples.find((x) => x.id === id); return P.row({ title: esc(f.name), sub, icon: 'page', name: 'importPick', arg: id }); }).join('');
      return box(`<p class="p-note">Choose a .ledgerly file. Nothing changes until you confirm. ${P.simulated().trim()}</p>
        ${own ? `${P.section('Files from this session')}<div class="lg-card lg-card--flush">${own}</div>` : '<div class="lg-card"><p class="p-note">Export all data in Backup and data to see your own file here.</p></div>'}
        ${P.section('Sample files')}<div class="lg-card lg-card--flush">${other}</div>`);
    }
    if (m.step === 'failed') {
      const text = { damaged: ['This file could not be read', `It may be damaged. ${NOTHING}`], newer: ['This file needs a newer Ledgerly', `It was made by version ${m.file.version}. This is version 1.0.0. Update Ledgerly and try again. ${NOTHING}`] }[m.file.kind];
      return box(`<div class="lg-state lg-state--error">${L.stateMark('alert')}<h3>${text[0]}</h3><p>${text[1]}</p>${P.btn('Choose another file', 'importBack', null, { kind: 'secondary' })}</div>`);
    }
    if (m.step === 'password') {
      return box(`<p class="p-note">${esc(m.file.name)} has a password.</p>${P.field('Password', P.input('impPw', m.pw, { type: 'password', label: 'Password', focus: true, error: m.pwError }), m.pwError ? `That password did not open the file. ${NOTHING}` : 'The password was set when the file was exported.')}${P.btn('Open file', 'importPw', null, { kind: 'primary', block: true })}${P.btn('Choose another file', 'importBack', null, { block: true })}`);
    }
    if (m.step === 'preview') {
      const c = m.file.counts;
      const ready = m.typed.trim().toUpperCase() === 'REPLACE';
      return box(`<div class="lg-card lg-stack" style="gap:0"><div class="label">${esc(m.file.name)}</div>${P.kv('File date', `<b>${esc(m.file.date)}</b>`)}${P.kv('App version', `<b>${m.file.version}</b>`)}${P.kv('Transactions', `<b>${c.transactions.toLocaleString('en-US')}</b>`)}${P.kv('Accounts', `<b>${c.accounts}</b>`)}${P.kv('Attachments', `<b>${m.file.attachments === false ? 'Not included' : c.receipts}</b>`)}</div>
        <div class="lg-card" style="background:var(--warning-tint);border-color:transparent"><div class="lg-inline" style="color:var(--warning);flex-wrap:nowrap;align-items:flex-start">${L.icon('alert', 20)}<span class="body-small">Import replaces all current data. Ledgerly takes a safety copy first and tells you where it is.</span></div></div>
        ${P.field('Type REPLACE to continue', P.input('impTyped', m.typed, { label: 'Type REPLACE to continue', placeholder: 'REPLACE' }))}
        ${P.btn('Replace all data', 'importRun', null, { kind: 'danger', block: true, state: ready ? undefined : 'disabled' })}${P.btn('Cancel, nothing changes', 'importClose', null, { block: true })}`);
    }
    return box(`<div class="lg-state">${L.stateMark('shieldCheck')}<h3>Import complete</h3><p>${m.file.counts.transactions.toLocaleString('en-US')} transactions are ready on this device.</p></div>
      <div class="lg-card lg-stack" style="gap:0">${P.kv('Safety copy', `<b>${esc(G.S.folder)}/before-import.ledgerly</b>`)}</div>
      <div class="lg-card"><div class="label">This device is now the main one</div><p class="p-note">Make new entries here. The old copy will stop matching from now on.</p></div>
      <div>${P.simulated('The file was not really read. The demo data stays in place.')}</div>
      ${P.btn('Go to Home', 'importDone', null, { kind: 'primary', block: true })}`);
  };
  P.acts.importClose = () => { const from = st.imp && st.imp.from; st.full = from === 'first' ? { name: 'first' } : null; st.imp = null; P.render(); };
  P.acts.importBack = () => { Object.assign(st.imp, { step: 'pick', file: null, pw: '', pwError: false }); P.render(); };
  P.acts.importPick = (id) => {
    const f = G.S.files.find((x) => x.id === id) || G.sampleFiles().find((x) => x.id === id);
    const m = st.imp;
    m.file = f;
    m.step = f.kind === 'damaged' || f.kind === 'newer' ? 'failed' : f.password ? 'password' : 'preview';
    P.render();
  };
  P.inputs.impPw = (v) => { st.imp.pw = v; st.imp.pwError = false; P.render(); };
  P.acts.importPw = () => { const m = st.imp; if (m.pw === m.file.password) m.step = 'preview'; else m.pwError = true; P.render(); };
  P.inputs.impTyped = (v) => { st.imp.typed = v; P.render(); };
  P.acts.importRun = () => { st.imp.step = 'done'; P.render(); };
  P.acts.importDone = () => { st.imp = null; st.full = null; P.go('home', null, { tab: true }); };

  // ---- Bank statement CSV: map, compare, add what is missing ----
  P.views.csv = function () {
    const c = (st.csv = st.csv || { step: 1, map: { date: 'Datum', text: 'Opis', amount: 'Iznos' }, rows: null });
    const head = P.screenHead('Bank statement CSV', `Step ${c.step} of 3`);
    const steps = `<div class="p-steps" aria-hidden="true">${[1, 2, 3].map((n) => `<i class="${n <= c.step ? 'is-on' : ''}"></i>`).join('')}</div>`;
    if (c.step === 1) {
      const cols = ['Datum', 'Opis', 'Iznos', 'Valuta', 'Stanje'];
      const sample = [['24.10.2026', 'BANK FEE OCTOBER', '-4,50', 'BAM', '7.912,34'], ['19.10.2026', 'KONZUM ČENGIĆ VILA', '-23,40', 'BAM', '7.916,84']];
      return narrow(head, `${steps}<div class="lg-card lg-stack" style="gap:0"><div class="label">main-bank-october.csv</div>${P.kv('Rows', `<b>${G.statement().length}</b>`)}${P.kv('Account', '<b>Main Bank</b>')}</div><div>${P.simulated('A sample statement is used.')}</div>
        ${P.section('Match the columns')}<div class="lg-card lg-stack">${[['date', 'Date'], ['text', 'Description'], ['amount', 'Amount']].map(([k, l]) => P.field(l, P.select('csvMap', c.map[k], cols.map((x) => [x, x]), { arg: k, label: l }))).join('')}</div>
        <div class="lg-card lg-card--flush"><div class="p-scrollbox"><table class="p-table"><thead><tr>${cols.map((h) => `<th><button type="button" tabindex="-1">${h}</button></th>`).join('')}</tr></thead><tbody>${sample.map((r) => `<tr>${r.map((x) => `<td>${esc(x)}</td>`).join('')}</tr>`).join('')}</tbody></table></div></div>
        ${P.btn('Compare with my entries', 'csvCompare', null, { kind: 'primary', block: true })}`);
    }
    if (c.step === 2) {
      const row = (r) => {
        const on = r.status === 'missing' ? r.add : !r.skip;
        return `<div class="p-row-action" data-key="${r.id}">${P.check('', on, 'csvToggle', r.id).replace('<span></span></label>', `<span class="lg-sr">Add ${esc(r.text)}</span></label>`)}<span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem">${esc(r.text)}</span><span class="lg-row__sub">${G.shortDate(r.date)}${r.status === 'duplicate' ? `, looks like ${esc(G.titleOf(P.byId(r.tx)))} on ${G.shortDate(P.byId(r.tx).date)}` : r.cat ? ` · ${esc(P.catName(r.subcat || r.cat))}` : ' · Goes to Needs Review'}</span></span><span class="p-amount-sm">${L.money(-r.amount, 'BAM', { tone: 'negative' })}</span></div>`;
      };
      const by = (s) => c.rows.filter((r) => r.status === s);
      return narrow(head, `${steps}
        <div class="lg-metrics"><div class="lg-metric"><span class="lg-metric__label">Matched</span><span class="lg-metric__value">${by('matched').length}</span></div><div class="lg-metric"><span class="lg-metric__label">Missing</span><span class="lg-metric__value">${by('missing').length}</span></div><div class="lg-metric"><span class="lg-metric__label">Likely duplicates</span><span class="lg-metric__value">${by('duplicate').length}</span></div></div>
        ${P.section('Missing rows to add')}<div class="lg-card lg-card--flush">${by('missing').map(row).join('')}</div>
        ${P.section('Likely duplicates')}<div class="lg-card lg-card--flush">${by('duplicate').map(row).join('')}</div><p class="p-note">Left unticked, so nothing is counted twice.</p>
        ${P.section('Matched')}<div class="lg-card lg-card--flush">${by('matched').map((r) => `<div class="p-row-action" data-key="${r.id}"><span style="color:var(--positive)">${L.icon('check', 20)}</span><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem">${esc(r.text)}</span><span class="lg-row__sub">${G.shortDate(r.date)}</span></span><span class="p-amount-sm">${L.money(-r.amount, 'BAM', { tone: 'negative' })}</span></div>`).join('')}</div>
        ${P.btn(`Add ${c.rows.filter((r) => (r.status === 'missing' && r.add) || (r.status === 'duplicate' && !r.skip)).length} entries`, 'csvImport', null, { kind: 'primary', block: true })}`);
    }
    return narrow(head, `${steps}${P.state('check', 'Statement reviewed', `${c.added} ${c.added === 1 ? 'entry was' : 'entries were'} added. Entries without a category wait in Needs Review.`, '')}${P.btn('Go to Needs Review', 'csvDone', 'review', { kind: 'primary', block: true })}${P.btn('Done', 'csvDone', '', { block: true })}`);
  };
  P.inputs.csvMap = (v, k) => { st.csv.map[k] = v; };
  P.acts.csvCompare = () => { st.csv.rows = G.statement(); st.csv.step = 2; P.render(); };
  P.inputs.csvToggle = (v, id) => { const r = st.csv.rows.find((x) => x.id === id); if (r.status === 'missing') r.add = v; else r.skip = !v; P.render(); };
  P.acts.csvImport = () => {
    const c = st.csv;
    c.added = c.rows.filter((r) => (r.status === 'missing' && r.add) || (r.status === 'duplicate' && !r.skip)).length;
    G.importStatement(c.rows);
    c.step = 3; P.render();
  };
  P.acts.csvDone = (to) => { st.csv = null; if (to) { st.stack = []; P.go(to); } else P.back(); };

  // ---- Categories ----
  P.views.categories = function () {
    const c = (st.cats = st.cats || { kind: 'expense', account: '' });
    const ids = G.catIds(c.kind).filter((id) => (!c.account || G.applies(id, c.account)) && !G.state.archived.has(id));
    const row = (id) => {
      const subs = c.kind === 'expense' ? G.subsOf(id).filter((s) => !G.state.archived.has(s.id)) : [];
      const n = G.usage(id);
      const html = P.attr(ui.categoryRow(id), `data-key="c${id}" ${act('editCat', id)}`).replace('</span></span><span class="lg-row__trail', `${n ? ` · ${n} ${n === 1 ? 'entry' : 'entries'}` : ''}</span></span><span class="lg-row__trail`);
      return `${html}${subs.length ? `<div style="padding:0 16px 8px 68px" class="lg-add__pills">${subs.map((s) => P.pill(esc(s.name), false, 'editCat', s.id, s.icon)).join('')}</div>` : ''}`;
    };
    const archived = [...G.state.archived];
    const filter = [['', 'All accounts']].concat(D.ACCOUNTS.map((a) => [a.id, a.name]));
    return narrow(P.screenHead('Categories', '', ro() ? '' : P.iconBtn('plus', 'Add category', 'catNew')), `${P.seg([{ label: 'Expense', id: 'expense', kind: 'expense', icon: 'down' }, { label: 'Income', id: 'income', kind: 'income', icon: 'up' }], c.kind, 'catsKind', 'Type')}
      <div class="lg-add__pills" role="group" aria-label="Filter by account">${filter.map(([id, name]) => P.pill(esc(name), c.account === id, 'catsAccount', id)).join('')}</div>
      <div class="lg-card lg-card--flush">${ids.map(row).join('')}</div>
      ${archived.length ? `${P.section('Archived')}<p class="p-note">Archived categories stay in history and reports.</p><div class="lg-card lg-card--flush">${archived.map((id) => P.attr(ui.categoryRow(id, { state: undefined }), `data-key="ar${id}" ${act('editCat', id)}`)).join('')}</div>` : ''}
      ${ro() ? '' : P.btn('Add category', 'catNew', null, { kind: 'primary', block: true, icon: 'plus' })}`);
  };
  P.acts.catsKind = (k) => { st.cats.kind = k; P.render(); };
  P.acts.catsAccount = (a) => { st.cats.account = a; P.render(); };
  P.acts.catNew = () => { P.catEdit = { name: '', kind: st.cats.kind, icon: 'paw', slot: 9, accounts: [], img: null, error: false }; P.sheet('catForm'); };
  P.acts.editCat = (id) => {
    if (ro()) return;
    const c = L.cat(id);
    P.catEdit = { id, name: c.name, kind: c.kind || st.cats.kind, icon: c.icon, slot: c.slot || 9, accounts: G.tiedTo(id).slice(), img: c.img || null, parent: c.parent || null, error: false };
    P.sheet('catForm');
  };
  P.sheets.catForm = function () {
    const c = P.catEdit;
    const extra = c.id ? `<div class="lg-stack" style="gap:8px;margin-top:12px">${P.btn(G.state.archived.has(c.id) ? 'Restore from archive' : 'Archive', 'catArchive', c.id, { kind: 'secondary', block: true, icon: 'archive' })}${P.btn('Delete', 'catDelete', c.id, { kind: 'danger', block: true })}<p class="p-note">Used by ${G.usage(c.id)} ${G.usage(c.id) === 1 ? 'entry' : 'entries'}. Changing its accounts never moves or hides past entries.</p></div>` : '';
    return `${P.categoryForm('list')}${extra}`;
  };
  P.acts.catArchive = (id) => { const on = !G.state.archived.has(id); st.sheet = null; P.withUndo(on ? `${esc(L.cat(id).name)} archived` : `${esc(L.cat(id).name)} restored`, () => G.archive(id, on)); };
  P.acts.catDelete = (id) => {
    const n = G.usage(id);
    const name = L.cat(id).name;
    const kind = P.catEdit.kind;
    st.catMove = G.allCats(kind).find((x) => x !== id && G.parentOf(x) !== id) || 'other';
    P.dialog({
      title: `Delete ${esc(name)}?`, danger: true, ok: n ? 'Move and delete' : 'Delete',
      text: n ? `${n} ${n === 1 ? 'entry uses' : 'entries use'} this category, so it cannot just disappear. Move them first, or cancel and archive it instead.` : 'No entries use this category.',
      body: n ? P.field('Move entries to', P.select('catMove', st.catMove, G.allCats(kind).filter((x) => x !== id && G.parentOf(x) !== id).map((x) => [x, L.cat(x).name]), { label: 'Move entries to' })) : '',
      confirm: () => { G.reassign(id, st.catMove); st.sheet = null; P.toast(`${esc(name)} deleted. ${n} ${n === 1 ? 'entry' : 'entries'} moved.`, {}); },
    });
  };
  P.inputs.catMove = (v) => { st.catMove = v; };
})(window.Ledgerly);
