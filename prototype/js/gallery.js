// Screen walls: stills of the live views, grouped by the brief's tiers. Nothing here is drawn twice.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP;

  const add = (kind, amount, extra) => ({ route: 'home', setup: (s) => { P.openAddState(s, Object.assign({ kind, amount }, extra)); } });
  const sheet = (route, name, arg, extra) => Object.assign({ route, state: { sheet: { name, arg } } }, extra);
  const phone = (title, c) => Object.assign({ title, layout: 'phone', theme: 'light' }, c);
  const both = (title, c, w) => [Object.assign({ title: `${title}, phone, light`, layout: 'phone', theme: 'light' }, c), Object.assign({ title: `${title}, phone, dark`, layout: 'phone', theme: 'dark' }, c), Object.assign({ title: `${title}, desktop, light`, layout: 'desktop', theme: 'light' }, w || c), Object.assign({ title: `${title}, desktop, dark`, layout: 'desktop', theme: 'dark' }, w || c)];
  const zara = () => D.transactions.find((t) => t.share != null).id;

  P.walls = {
    1: [
      { name: 'Home dashboard', shots: both('Home', { route: 'home' }) },
      { name: 'Add transaction', shots: ['light', 'dark'].flatMap((theme) => [['Expense', add('expense', '12')], ['Income', add('income', '250')], ['Transfer', add('transfer', '200')]].map(([k, c]) => Object.assign({ title: `${k}, ${theme}`, layout: 'phone', theme }, c))) },
      { name: 'Transaction history', shots: both('History', { route: 'tx' }, { route: 'tx', setup: (s) => { s.panelTx = zara(); } }) },
      { name: 'Analytics', shots: both('Analytics', { route: 'analytics', tab: 'analytics', setup: (s) => { s.an.section = 'categories'; } }, { route: 'analytics' }) },
      { name: 'Financial calendar', shots: both('Calendar', { route: 'tx', state: { txView: 'calendar' } }, { route: 'calendar' }) },
    ],
    2: [
      { name: 'Everyday review', shots: [phone('Needs Review', { route: 'review' }), phone('Monthly close', { route: 'close' }), phone('Transaction details', { route: 'txd', arg: 0, setup: (s) => { s.route.arg = zara(); } }), phone('Search and filters', sheet('tx', 'filters')), phone('Daily calendar details', Object.assign(sheet('tx', 'day', '2026-10-18'), { state: { txView: 'calendar', sheet: { name: 'day', arg: '2026-10-18' } } })), phone('Categories', { route: 'categories' })] },
      { name: 'Money', shots: [phone('Budgets', { route: 'budgets' }), phone('Budget details', { route: 'budget', arg: 'b4' }), phone('Accounts', { route: 'accounts' }), phone('Account details', { route: 'account', arg: 'cash' }), phone('Balance check', Object.assign({ route: 'account', arg: 'cash' }, { setup: (s) => { s.rec = { id: 'cash', real: '360.00' }; s.sheet = { name: 'reconcile' }; } })), phone('Category analytics', { route: 'catan', arg: 'food' })] },
      { name: 'Plans and records', shots: [phone('Goals', { route: 'goals' }), phone('Recurring', { route: 'recurring' }), phone('Notebook', { route: 'notebook' }), phone('Note details', { route: 'note', arg: 'n2' }), phone('Reports', { route: 'reports' }), phone('Edit a repeat', { route: 'recurring', setup: (s) => { s.rp = { id: 'r4' }; s.sheet = { name: 'repeat' }; } })] },
    ],
    3: [
      { name: 'Settings', shots: [phone('Settings', { route: 'settings' }), phone('Appearance', { route: 'appearance' }), phone('Regional', { route: 'regional' }), phone('Security', { route: 'security' }), phone('Backup and data', { route: 'backup' }), phone('Bank statement CSV', { route: 'csv', setup: (s) => { s.csv = { step: 2, map: {}, rows: G.statement() }; } })] },
      { name: 'Data files', shots: [phone('Export all data', { route: 'backup', setup: (s) => { s.exp = { attachments: true, usePw: true, pw: 'x', pw2: 'x', ack: true, dest: 'Save to a file' }; s.sheet = { name: 'export' }; } }), phone('Import preview', { route: 'backup', setup: (s) => { s.imp = { step: 'preview', typed: '', from: 'settings', file: { name: 'ledgerly-2026-10-29.ledgerly', date: '29 Oct 2026, 14:51', version: '1.0.0', counts: G.counts() } }; s.full = { name: 'import' }; } }), phone('Damaged file', { route: 'backup', setup: (s) => { s.imp = { step: 'failed', file: { kind: 'damaged' } }; s.full = { name: 'import' }; } }), phone('Moved to a new device', { route: 'backup', setup: (s) => { s.imp = { step: 'done', file: { counts: G.counts() } }; s.full = { name: 'import' }; } }), phone('First launch', { route: 'home', setup: (s) => { s.first = { step: 'choose' }; s.full = { name: 'first' }; } }), phone('First account', { route: 'home', setup: (s) => { s.first = { step: 'account', name: 'Main Bank', cur: 'BAM', open: '' }; s.full = { name: 'first' }; } })] },
      { name: 'States and widget', shots: [phone('Home-screen widget', { route: 'widget' }), phone('Empty, loading, error', { route: 'states' }), phone('Backup overdue', { route: 'backup', setup: () => { P.backupShot = 'overdue'; } }), phone('Backup failed', { route: 'backup', setup: () => { P.backupShot = 'failed'; } }), { title: 'Tablet, light', layout: 'tablet', theme: 'light', route: 'home' }, { title: 'Tablet, dark', layout: 'tablet', theme: 'dark', route: 'calendar' }] },
    ],
  };
  const SIZE = { phone: [390, 844], tablet: [1024, 768], desktop: [1440, 900] };
  P.gallery = function (root, tier) {
    root.innerHTML = `<div class="pw">${P.walls[tier].map((g) => `<section class="pw__group"><h2 class="lg-title">${g.name}</h2><div class="pw__row">${g.shots.map((s) => {
      const [w, h] = SIZE[s.layout];
      P.backupShot = null;
      const realBackup = G.S.backup;
      const html = (() => { const cfg = s; if (cfg.setup) { const orig = cfg.setup; return P.snapshot(Object.assign({}, cfg, { setup: (a, b) => { orig(a, b); if (P.backupShot) G.S.backup = P.backupShot; } })); } return P.snapshot(cfg); })();
      G.S.backup = realBackup;
      return `<figure class="pw__shot"><figcaption class="label">${s.title}</figcaption><div class="pv__device" data-theme="${s.theme}" data-accent="forest" style="width:${w}px;height:${h}px;box-shadow:none" inert>${html}</div></figure>`;
    }).join('')}</div></section>`).join('')}</div>`;
    return P;
  };
})(window.Ledgerly);
