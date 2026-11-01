// One sample ledger. Every figure on every proof screen is derived from it here, so screens
// cannot disagree. Amounts are integer minor units; each entry freezes its EUR value when made.
(function (L) {
  const PEG = 1.95583;
  const TODAY = '2026-10-29';
  const ACCOUNTS = [
    { id: 'main', name: 'Main Bank', cur: 'BAM', open: 412000, icon: 'wallet' },
    { id: 'euro', name: 'Euro Account', cur: 'EUR', open: 140000, icon: 'wallet' },
    { id: 'savings', name: 'Savings', cur: 'EUR', open: 610000, icon: 'shield' },
    { id: 'cash', name: 'Cash', cur: 'BAM', open: 26000, icon: 'wallet' },
    { id: 'card', name: 'Credit Card', cur: 'EUR', open: -42000, icon: 'wallet' },
  ];
  const acc = (id) => ACCOUNTS.find((a) => a.id === id);
  const toEur = (minor, cur) => (cur === 'EUR' ? minor : Math.round(minor / PEG));

  let seed = 20261024;
  const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296;
  const between = (a, b) => Math.round(a + rnd() * (b - a));
  const pick = (list) => list[Math.floor(rnd() * list.length)];

  const T = [];
  let nid = 1;
  function add(date, type, account, amount, merchant, cat, extra) {
    if (date > TODAY) return null;
    const cur = acc(account).cur;
    const t = Object.assign({ id: nid++, date, type, account, amount, cur, base: toEur(amount, cur), merchant, cat, flags: [] }, extra);
    if (t.share != null) t.shareBase = toEur(t.share, cur);
    T.push(t);
    return t;
  }
  const expense = (d, a, amt, m, c, x) => add(d, 'expense', a, amt, m, c, x);
  const transfer = (d, from, to, amt, label) => add(d, 'transfer', from, amt, label, null, { to });

  const months = [];
  for (let y = 2025, m = 9; y < 2026 || m <= 10; m === 12 ? (y++, (m = 1)) : m++) months.push(`${y}-${String(m).padStart(2, '0')}`);
  const day = (ym, d) => `${ym}-${String(d).padStart(2, '0')}`;

  months.forEach((ym, i) => {
    const rec = { flags: ['recurring'] };
    const isOct = ym === '2026-10';
    add(day(ym, 28), 'income', 'main', 391166, 'Salary', 'salary', rec);
    expense(day(ym, 1), 'main', 90000, 'Rent', 'housing', rec);
    expense(day(ym, 3), 'card', 1299, 'Netflix', 'subscriptions', rec);
    expense(day(ym, 5), 'main', between(9000, 15000), 'Elektroprivreda BiH', 'bills', rec);
    expense(day(ym, 8), 'main', 5900, 'BH Telecom Internet', 'bills', rec);
    expense(day(ym, 12), 'card', 699, 'Spotify', 'subscriptions', rec);
    if (!isOct) expense(day(ym, 25), 'main', 3500, 'BH Telecom Mobile', 'bills', rec);
    transfer(day(ym, 15), 'main', 'cash', 20000, 'ATM withdrawal');
    transfer(day(ym, 20), 'euro', 'card', 18000, 'Credit card payment');
    transfer(day(ym, 2), 'euro', 'savings', 60000, 'To Savings');
    transfer(day(ym, 2), 'main', 'euro', 156466, 'To Euro Account');

    for (let n = 0; n < 7; n++) expense(day(ym, between(1, 27)), pick(['main', 'main', 'cash']), between(1800, 9400), pick(['Konzum', 'Bingo', 'Mercator', 'Pekara Đulić']), 'food');
    for (let n = 0; n < 4; n++) expense(day(ym, between(1, 27)), pick(['main', 'cash']), between(900, 4800), pick(['Ćevabdžinica Željo', 'Kafić Šišmiš', 'Bistro Čaršija']), 'food');
    for (let n = 0; n < 2; n++) expense(day(ym, between(1, 27)), 'main', between(6000, 9000), pick(['INA', 'Hifa Petrol']), 'transport');
    expense(day(ym, between(1, 27)), 'cash', between(1500, 3000), 'Gras', 'transport');
    expense(day(ym, between(4, 26)), 'card', between(2500, 9000), pick(['Zara', 'H&M', 'Decathlon']), 'shopping');
    if (i % 2 === 0) expense(day(ym, between(2, 26)), 'main', between(1500, 8000), pick(['Apoteka', 'Dom zdravlja']), 'health');
    expense(day(ym, between(2, 26)), 'card', between(1000, 4500), pick(['Cinema City', 'Muzej', 'Knjižara']), 'entertainment');
    expense(day(ym, between(2, 26)), 'cash', between(1500, 4000), 'Frizer Šefik', 'personal');
    if (i % 3 === 1) add(day(ym, between(9, 22)), 'income', 'euro', between(32000, 62000), 'Freelance project', 'freelance');
  });

  // Months that are not typical.
  expense('2025-12-18', 'card', 21000, 'Gifts for family', 'gifts');
  expense('2026-02-10', 'euro', 34000, 'Language course', 'education');
  expense('2026-08-06', 'card', 64000, 'Dubrovnik apartment', 'travel');
  expense('2026-08-07', 'card', 18500, 'Ferry and dining', 'travel');

  // October carries one of everything the components need to show.
  const mine = { flags: ['receipt'] };
  expense('2026-10-18', 'euro', 8500, 'Mercator', 'food', { flags: ['split', 'receipt'], sub: 'Split across 3 categories',
    parts: [['food', 6000], ['shopping', 1500], ['personal', 1000]] });
  const orig = expense('2026-10-09', 'card', 5990, 'Zara', 'shopping', mine);
  add('2026-10-14', 'refund', 'card', 2990, 'Zara refund', 'shopping', { flags: ['refund'], of: orig.id });
  expense('2026-10-22', 'euro', 4000, 'Bistro Čaršija', 'food', { flags: ['shared'], share: 2500, sub: 'My share €25.00, €15.00 owed to me' });
  expense('2026-10-21', 'main', 3912, 'Bingo', 'food');
  expense('2026-10-17', 'cash', 4500, 'Pet shop Mačak', 'pets');
  expense('2026-10-28', 'cash', 1200, null, null, { flags: ['review'] });
  expense('2026-10-29', 'main', 2750, 'Hifa Petrol', null, { flags: ['review'] });
  expense('2026-10-29', 'cash', 640, 'Pekara Đulić', 'food');
  add('2026-10-12', 'adjustment', 'cash', 1200, 'Untracked', null, { flags: [] });

  T.sort((a, b) => (a.date === b.date ? b.id - a.id : a.date < b.date ? 1 : -1));

  // The amount that counts as spending for one entry, in EUR minor units.
  function spendOf(t) {
    if (t.type === 'expense' && t.cat) return t.share != null ? t.shareBase : t.base;
    if (t.type === 'refund') return -t.base;
    return 0;
  }
  // Entries still in Needs Review have no category, but the money has left, so they count as uncategorised spending.
  const reviewSpend = (t) => (t.type === 'expense' && !t.cat ? t.base : 0);
  const counted = (t) => spendOf(t) + reviewSpend(t);

  function balanceOf(id, upTo) {
    const a = acc(id);
    let sum = a.open;
    T.forEach((t) => {
      if (upTo && t.date > upTo) return;
      if (t.account === id) sum += t.type === 'income' || t.type === 'refund' ? t.amount : -t.amount;
      if (t.to === id) sum += a.cur === t.cur ? t.amount : t.cur === 'EUR' ? Math.round(t.amount * PEG) : toEur(t.amount, t.cur);
    });
    return sum;
  }
  const accounts = () => ACCOUNTS.map((a) => {
    const balance = balanceOf(a.id);
    return Object.assign({}, a, { balance, base: toEur(balance, a.cur) });
  });
  function totalAt(date) {
    return ACCOUNTS.reduce((s, a) => s + toEur(balanceOf(a.id, date), a.cur), 0);
  }

  function month(ym) {
    const list = T.filter((t) => t.date.startsWith(ym));
    const income = list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0), 0);
    const spending = list.reduce((s, t) => s + counted(t), 0);
    const byCat = {};
    list.forEach((t) => {
      if (t.parts) t.parts.forEach(([c, m]) => { byCat[c] = (byCat[c] || 0) + m; });
      else if (spendOf(t) && t.cat) byCat[t.cat] = (byCat[t.cat] || 0) + spendOf(t);
    });
    const ranked = Object.keys(byCat).map((cat) => ({ cat, amount: byCat[cat] })).sort((a, b) => b.amount - a.amount);
    return { ym, list, income, spending, net: income - spending, rate: income ? (income - spending) / income : 0, ranked, byCat };
  }

  const CURRENT = '2026-10';
  const PREV = '2026-09';

  function dayGroups(ym) {
    const map = new Map();
    month(ym).list.forEach((t) => {
      if (!map.has(t.date)) map.set(t.date, []);
      map.get(t.date).push(t);
    });
    return [...map.entries()].map(([date, list]) => ({ date, list, net: dayNet(list) }));
  }
  const dayNet = (list) => list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0) - counted(t), 0);
  const daySpend = (date) => T.filter((t) => t.date === date).reduce((s, t) => s + counted(t), 0);

  function weekdays(ym) {
    const sum = [0, 0, 0, 0, 0, 0, 0];
    month(ym).list.forEach((t) => { sum[(new Date(`${t.date}T12:00:00Z`).getUTCDay() + 6) % 7] += counted(t); });
    return sum;
  }

  // Budget limits in EUR minor units. Spent comes from the ledger.
  const BUDGETS = [['food', 40000], ['transport', 12000], ['entertainment', 6000], ['shopping', 10000], ['bills', 12000]];
  function budgets() {
    const m = month(CURRENT);
    return BUDGETS.map(([cat, limit]) => {
      const spent = m.byCat[cat] || 0;
      const ratio = spent / limit;
      return { cat, limit, spent, ratio, left: limit - spent, state: ratio >= 1 ? 'over' : ratio >= 0.8 ? 'warning' : 'normal' };
    });
  }
  const PACE = 29 / 31;

  const GOALS = [
    { name: 'Emergency fund', target: 600000, saved: 410000, icon: 'shield' },
    { name: 'Summer in Croatia', target: 150000, saved: 64000, icon: 'plane' },
    { name: 'New laptop', target: 120000, saved: 38000, icon: 'laptop' },
  ];
  function summary() {
    const list = accounts();
    const total = list.reduce((s, a) => s + a.base, 0);
    const earmarked = GOALS.reduce((s, g) => s + g.saved, 0);
    return { total, earmarked, free: total - earmarked, lastMonth: totalAt('2026-09-29') };
  }

  // Recurring items in their three states. Due waits for one tap; Planned has not arrived.
  const RECURRING = [
    { name: 'BH Telecom Mobile', cat: 'bills', amount: 3500, cur: 'BAM', date: '2026-10-29', state: 'due' },
    { name: 'Salary', cat: 'salary', amount: 391166, cur: 'BAM', date: '2026-10-28', state: 'posted' },
    { name: 'Rent', cat: 'housing', amount: 90000, cur: 'BAM', date: '2026-11-01', state: 'planned' },
    { name: 'Netflix', cat: 'subscriptions', amount: 1299, cur: 'EUR', date: '2026-11-03', state: 'planned' },
  ];
  const BILLS_BEFORE_PAYDAY = [90000, 12500, 5900, 3500].reduce((s, m) => s + toEur(m, 'BAM'), 1299 + 699);

  function forecast() {
    const liquid = accounts().filter((a) => a.id !== 'savings').reduce((s, a) => s + a.base, 0);
    const last3 = ['2026-07', '2026-08', '2026-09'].map(month);
    const variable = last3.reduce((s, m) => s + m.list.reduce((x, t) => x + (t.flags.includes('recurring') ? 0 : counted(t)), 0), 0);
    const perDay = Math.round(variable / 92);
    const days = 30;
    return { liquid, perDay, days, bills: BILLS_BEFORE_PAYDAY, lowest: liquid - BILLS_BEFORE_PAYDAY - perDay * days };
  }

  // Categories belong to accounts. An entry in `ties` limits a category to those accounts;
  // without one it applies to all of them. History and reports are not affected.
  const CUSTOM = [{ id: 'pets', name: 'Pets', slot: 9, icon: 'paw', kind: 'expense', custom: true }];
  const TIES = {
    housing: ['main'], bills: ['main'], subscriptions: ['card'], health: ['main', 'cash'], education: ['euro', 'card'],
    salary: ['main'], freelance: ['euro'], business: ['euro'], investments: ['savings'], rental: ['main'], pets: ['main', 'cash'],
  };
  const EXPENSE = ['food', 'transport', 'shopping', 'bills', 'personal', 'entertainment', 'pets', 'health', 'housing', 'travel', 'education', 'gifts', 'subscriptions', 'other'];
  const INCOME = ['salary', 'freelance', 'business', 'investments', 'rental', 'other'];
  const tiedTo = (id) => TIES[id] || [];
  const appliesTo = (id, account) => !tiedTo(id).length || tiedTo(id).includes(account);
  function categories(kind, account) {
    const list = kind === 'income' ? INCOME : EXPENSE;
    return account ? list.filter((id) => appliesTo(id, account)) : list.slice();
  }
  const accountsLabel = (id) => (tiedTo(id).length ? tiedTo(id).map((a) => acc(a).name).join(', ') : 'All accounts');
  function addCategory(c, accounts) {
    CUSTOM.push(Object.assign({ custom: true }, c));
    if (accounts.length) TIES[c.id] = accounts;
    const list = c.kind === 'income' ? INCOME : EXPENSE;
    list.splice(list.length - 1, 0, c.id);
  }
  function removeCategory(id) {
    CUSTOM.splice(CUSTOM.findIndex((c) => c.id === id), 1);
    delete TIES[id];
    [INCOME, EXPENSE].forEach((list) => { if (list.includes(id)) list.splice(list.indexOf(id), 1); });
  }

  const series = () => months.map((ym) => month(ym));
  const review = () => T.filter((t) => t.flags.includes('review'));
  const owed = () => T.reduce((s, t) => s + (t.share != null ? t.base - t.shareBase : 0), 0);

  const WEEK = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  function dayLabel(date) {
    const d = new Date(`${date}T12:00:00Z`);
    if (date === TODAY) return 'Today';
    if (date === '2026-10-28') return 'Yesterday';
    return `${WEEK[d.getUTCDay()]}, ${d.getUTCDate()} ${MON[d.getUTCMonth()]}`;
  }
  const monthLabel = (ym) => MON[Number(ym.slice(5)) - 1];

  L.data = { ACCOUNTS, CUSTOM, categories, accountsLabel, tiedTo, addCategory, removeCategory, RECURRING, PEG, TODAY, CURRENT, PREV, PACE, GOALS, acc, accounts, month, dayGroups, daySpend, dayNet, weekdays, budgets, summary, forecast, series, review, owed, counted, dayLabel, monthLabel, toEur, transactions: T, months };
})(window.Ledgerly = window.Ledgerly || {});
