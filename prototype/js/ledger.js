// Prototype only. Extends the design system's one sample ledger in place, so the system's own
// builders and this prototype read the same entries. Nothing here is saved: every change lasts
// for the session. Amounts are integer minor units; each entry freezes its EUR value when made.
(function (L) {
  'use strict';
  const D = L.data;
  const T = D.transactions;
  const PEG = D.PEG;
  const TODAY = D.TODAY;

  let seed = 7204611;
  const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296;
  const between = (a, b) => Math.round(a + rnd() * (b - a));
  const pick = (list) => list[Math.floor(rnd() * list.length)];
  const pad = (n) => String(n).padStart(2, '0');
  const ymd = (y, m, d) => `${y}-${pad(m)}-${pad(d)}`;
  const toDate = (s) => new Date(`${s}T12:00:00Z`);
  const fromDate = (d) => d.toISOString().slice(0, 10);
  const addDays = (s, n) => fromDate(new Date(toDate(s).getTime() + n * 864e5));
  const diffDays = (a, b) => Math.round((toDate(a) - toDate(b)) / 864e5);
  const daysInMonth = (y, m) => new Date(Date.UTC(y, m, 0)).getUTCDate();
  const WEEK = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const MONTH = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const shortDate = (s) => { const d = toDate(s); return `${d.getUTCDate()} ${MON[d.getUTCMonth()]}`; };
  const longDate = (s) => { const d = toDate(s); return `${d.getUTCDate()} ${MON[d.getUTCMonth()]} ${d.getUTCFullYear()}`; };
  const weekdayOf = (s) => (toDate(s).getUTCDay() + 6) % 7;

  // ---- Categories: one level of subcategories, stored beside the system's own list ----
  const SUBS = {
    housing: [['rent', 'Rent', 'home'], ['repairs', 'Repairs', 'wrench'], ['furnishing', 'Furnishing', 'store']],
    food: [['groceries', 'Groceries', 'basket'], ['dining', 'Dining out', 'fork'], ['coffee', 'Coffee', 'coffee']],
    transport: [['fuel', 'Fuel', 'fuel'], ['transit', 'Public transport', 'bus'], ['parking', 'Parking', 'car'], ['carservice', 'Car service', 'wrench']],
    shopping: [['clothes', 'Clothes', 'shirt'], ['household', 'Household', 'home'], ['electronics', 'Electronics', 'laptop']],
    health: [['pharmacy', 'Pharmacy', 'pulse'], ['doctor', 'Doctor', 'heart'], ['fitness', 'Fitness', 'dumbbell']],
    entertainment: [['cinema', 'Cinema', 'ticket'], ['events', 'Events', 'music'], ['games', 'Games', 'game'], ['bookshop', 'Books', 'book']],
    bills: [['electricity', 'Electricity', 'bolt'], ['utilities', 'Utilities', 'receipt'], ['internet', 'Internet', 'bolt'], ['mobile', 'Phone', 'phone']],
    travel: [['stays', 'Stays', 'home'], ['trips', 'Trips', 'plane']],
    education: [['courses', 'Courses', 'book']],
    personal: [['haircut', 'Haircut', 'sparkle'], ['cosmetics', 'Cosmetics', 'leaf']],
    gifts: [['family', 'Family', 'gift'], ['friends', 'Friends', 'heart']],
    subscriptions: [['streaming', 'Streaming', 'ticket'], ['musicapp', 'Music', 'music'], ['software', 'Software', 'laptop']],
  };
  Object.keys(SUBS).forEach((parent) => {
    SUBS[parent].forEach(([id, name, icon]) => D.CUSTOM.push({ id, name, icon, parent, slot: L.cat(parent).slot, kind: 'expense' }));
  });
  D.CUSTOM.push({ id: 'overall', name: 'All spending', icon: 'wallet', slot: 0, kind: 'expense', hidden: true });

  const ties = {};
  [...D.categories('expense'), ...D.categories('income')].forEach((id) => { ties[id] = D.tiedTo(id).slice(); });
  ties.gifts = [];
  const archived = new Set();
  const parentOf = (id) => (L.cat(id).parent || id);
  const tiedTo = (id) => ties[parentOf(id)] || [];
  const applies = (id, account) => !tiedTo(id).length || tiedTo(id).includes(account);
  D.tiedTo = tiedTo;
  D.accountsLabel = (id) => (tiedTo(id).length ? tiedTo(id).map((a) => D.acc(a).name).join(', ') : 'All accounts');
  function catIds(kind) {
    const list = D.categories(kind);
    if (kind === 'income' && !list.includes('gifts')) list.splice(list.length - 1, 0, 'gifts');
    return list;
  }
  const subsOf = (parent) => D.CUSTOM.filter((c) => c.parent === parent);

  // ---- The rest of the 14 months: same accounts, same merchants, more of daily life ----
  let nextId = T.reduce((m, t) => Math.max(m, t.id), 0) + 1;
  function add(date, type, account, amount, merchant, cat, extra) {
    if (date > TODAY) return null;
    const cur = D.acc(account).cur;
    const t = Object.assign({ id: nextId++, date, type, account, amount, cur, base: D.toEur(amount, cur), merchant, cat, flags: [] }, extra);
    T.push(t);
    return t;
  }
  const expense = (d, a, amt, m, c, sub, x) => add(d, 'expense', a, amt, m, c, Object.assign({ subcat: sub }, x));
  const recur = () => ({ flags: ['recurring'] });

  D.months.forEach((ym, i) => {
    const day = (d) => `${ym}-${pad(d)}`;
    const mon = Number(ym.slice(5));
    expense(day(10), 'main', between(1800, 2600), 'Vodovod Sarajevo', 'bills', 'utilities', recur());
    if (mon >= 11 || mon <= 3) expense(day(14), 'main', between(9000, 12500), 'Toplane Sarajevo', 'bills', 'utilities', recur());
    add(day(3), 'transfer', 'main', 7000, 'ATM withdrawal', null, { to: 'cash' });
    expense(day(6), 'main', 5000, 'Fitness Zona', 'health', 'fitness', recur());
    expense(day(17), 'card', 299, 'Google One', 'subscriptions', 'software', recur());
    for (let n = 0; n < 8; n++) expense(day(between(1, 27)), 'cash', pick([300, 350, 400, 450, 600]), pick(['Kafić Šišmiš', 'Caffe Tito']), 'food', 'coffee');
    for (let n = 0; n < 6; n++) expense(day(between(1, 27)), 'cash', 180, 'Gras', 'transport', 'transit');
    for (let n = 0; n < 4; n++) expense(day(between(1, 27)), 'main', between(1200, 4200), pick(['Konzum', 'Bingo']), 'food', 'groceries');
    for (let n = 0; n < 2; n++) expense(day(between(1, 27)), 'cash', between(200, 500), 'Parking Skenderija', 'transport', 'parking');
    if (i % 2 === 1) expense(day(between(3, 25)), 'main', between(1200, 3800), pick(['Apoteka', 'DM Drogerie']), 'personal', 'cosmetics');
    if (i % 4 === 2) expense(day(between(3, 25)), 'card', between(2500, 6500), pick(['Sportsko društvo', 'Bosnian Film Fest', 'Koncert u BKC']), 'entertainment', 'events');
  });

  // Months that are not typical.
  expense('2025-11-29', 'card', 15900, 'Black Friday, Tehnika', 'shopping', 'electronics', { flags: ['receipt'] });
  expense('2026-01-17', 'card', 26000, 'Jahorina weekend', 'travel', 'stays');
  const ikea = expense('2026-03-07', 'card', 18900, 'IKEA Beograd', 'shopping', 'household', { flags: ['receipt'] });
  add('2026-03-15', 'refund', 'card', 4900, 'IKEA Beograd refund', 'shopping', { subcat: 'household', flags: ['refund'], of: ikea.id });
  expense('2026-04-21', 'euro', 42000, 'Auto servis Hadžić', 'transport', 'carservice', { flags: ['receipt'] });
  expense('2026-06-09', 'euro', 18000, 'Stomatološka ordinacija', 'health', 'doctor', { flags: ['receipt'] });
  add('2026-06-14', 'income', 'euro', 10000, 'Birthday gift', 'gifts');
  add('2025-12-31', 'income', 'savings', 2150, 'Savings interest', 'investments');
  add('2026-03-31', 'income', 'savings', 2230, 'Savings interest', 'investments');
  add('2026-06-30', 'income', 'savings', 2310, 'Savings interest', 'investments');
  add('2026-09-30', 'income', 'savings', 2380, 'Savings interest', 'investments');
  expense('2026-08-24', 'card', 2249, 'Udemy', 'education', 'courses', { orig: { amount: 2499, cur: 'USD', rate: 0.9 }, flags: ['receipt'] });
  expense('2026-10-07', 'card', 1656, 'Humble Bundle', 'entertainment', 'games', { orig: { amount: 1800, cur: 'USD', rate: 0.92 } });
  expense('2026-10-26', 'card', 1890, 'Knjižara Buybook', null, null, { flags: ['review'] });

  const SUB_BY_MERCHANT = {
    Konzum: 'groceries', Bingo: 'groceries', Mercator: 'groceries', 'Pekara Đulić': 'groceries', 'Ćevabdžinica Željo': 'dining', 'Bistro Čaršija': 'dining', 'Kafić Šišmiš': 'coffee',
    INA: 'fuel', 'Hifa Petrol': 'fuel', Gras: 'transit', Zara: 'clothes', 'H&M': 'clothes', Decathlon: 'clothes', Apoteka: 'pharmacy', 'Dom zdravlja': 'doctor', 'Cinema City': 'cinema',
    Muzej: 'events', Knjižara: 'bookshop', 'Frizer Šefik': 'haircut', 'Elektroprivreda BiH': 'electricity', 'BH Telecom Internet': 'internet', 'BH Telecom Mobile': 'mobile', Rent: 'rent',
    Netflix: 'streaming', Spotify: 'musicapp', 'Gifts for family': 'family', 'Language course': 'courses', 'Dubrovnik apartment': 'stays', 'Ferry and dining': 'trips', 'Zara refund': 'clothes',
  };
  T.forEach((t) => {
    if (t.cat && !t.subcat && !t.parts && SUB_BY_MERCHANT[t.merchant]) t.subcat = SUB_BY_MERCHANT[t.merchant];
    if (t.parts) { t.parts[0][2] = 'groceries'; t.parts[1][2] = 'household'; t.parts[2][2] = null; }
    if (t.share != null) { t.owedFrom = 'Lejla'; delete t.sub; }
    if (t.flags.includes('split')) delete t.sub;
  });

  // Every entry is a title and a subcategory. The merchant is optional and kept only when it adds something.
  const TITLE = {
    Konzum: 'Groceries', Bingo: 'Groceries', Mercator: 'Groceries', 'Pekara Đulić': 'Bread', 'Kafić Šišmiš': 'Coffee', 'Caffe Tito': 'Coffee', 'Ćevabdžinica Željo': 'Lunch', 'Bistro Čaršija': 'Dinner',
    INA: 'Fuel', 'Hifa Petrol': 'Fuel', Gras: 'Bus ticket', 'Parking Skenderija': 'Parking', Zara: 'Clothes', 'H&M': 'Clothes', Decathlon: 'Sports gear', Apoteka: 'Pharmacy', 'DM Drogerie': 'Cosmetics',
    'Dom zdravlja': 'Doctor', 'Cinema City': 'Cinema', Muzej: 'Museum', Knjižara: 'Books', 'Frizer Šefik': 'Haircut', 'Elektroprivreda BiH': 'Electricity', 'BH Telecom Internet': 'Internet',
    'BH Telecom Mobile': 'Phone bill', 'Vodovod Sarajevo': 'Water', 'Toplane Sarajevo': 'Heating', 'Fitness Zona': 'Gym', 'Sportsko društvo': 'Football match', 'Bosnian Film Fest': 'Film festival',
    'Koncert u BKC': 'Concert', 'Black Friday, Tehnika': ['Headphones', 'Tehnika'], 'IKEA Beograd': 'Shelves', 'IKEA Beograd refund': ['Shelves refund', 'IKEA Beograd'], 'Zara refund': ['Clothes refund', 'Zara'],
    'Auto servis Hadžić': 'Car service', 'Stomatološka ordinacija': 'Dentist', Udemy: 'Online course', 'Humble Bundle': 'Game bundle', 'Pet shop Mačak': 'Cat food',
  };
  const PLAIN = new Set(['Elektroprivreda BiH', 'BH Telecom Internet', 'BH Telecom Mobile', 'Vodovod Sarajevo', 'Toplane Sarajevo', 'Fitness Zona']);
  T.forEach((t) => {
    const m = t.merchant; const v = TITLE[m];
    if (t.type === 'expense' && !t.cat) { t.title = null; return; }
    if (t.parts) { t.title = 'Weekly shop'; return; }
    if (Array.isArray(v)) { t.title = v[0]; t.merchant = v[1]; } else if (v) { t.title = v; if (PLAIN.has(m)) t.merchant = null; } else { t.title = m; t.merchant = null; }
  });
  const titleOf = (t) => t.title || t.merchant || 'No title';
  T.sort((a, b) => (a.date === b.date ? a.id - b.id : a.date < b.date ? -1 : 1));
  let shop = 0;
  T.forEach((t) => {
    t.time = `${pad(between(7, 21))}:${pad(between(0, 59))}`;
    t.tags = t.tags || [];
    if ((t.cat === 'shopping' || t.subcat === 'doctor') && t.type === 'expense' && !t.flags.includes('receipt') && ++shop % 4 === 0) t.flags.push('receipt');
  });
  const sortT = () => T.sort((a, b) => (a.date === b.date ? (a.time === b.time ? b.id - a.id : a.time < b.time ? 1 : -1) : a.date < b.date ? 1 : -1));
  sortT();
  T.filter((t) => t.date >= '2026-10-01' && t.cat === 'travel').forEach((t) => t.tags.push('trip'));
  T.filter((t) => t.date >= '2026-08-01' && t.date <= '2026-08-31' && t.cat === 'travel').forEach((t) => t.tags.push('dubrovnik'));
  T.filter((t) => t.subcat === 'carservice').forEach((t) => t.tags.push('car'));

  // ---- Everything else that belongs to the one ledger ----
  D.ACCOUNTS.forEach((a) => { a.kind = { main: 'Bank account', euro: 'Bank account', savings: 'Savings', cash: 'Cash', card: 'Credit card' }[a.id]; });
  D.ACCOUNTS.find((a) => a.id === 'card').icon = 'receipt';
  D.ACCOUNTS.find((a) => a.id === 'cash').icon = 'dollar';
  const checks = { main: '2026-09-30', euro: '2026-09-30', savings: '2026-09-30', cash: '2026-10-12', card: '2026-09-30' };

  D.GOALS.forEach((g, i) => Object.assign(g, { id: `g${i + 1}`, account: i === 2 ? 'euro' : 'savings', by: ['', '2027-06-01', '2027-02-01'][i] }));
  // Repeats: a title the person chose, how often, and the next date. Nothing posts by itself:
  // a repeat becomes Due on its date and waits until it is marked paid or skipped.
  const EVERY = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  const PER_MONTH = { Daily: 365 / 12, Weekly: 52 / 12, Monthly: 1, Yearly: 1 / 12 };
  function advance(date, every, day) {
    if (every === 'Daily') return addDays(date, 1);
    if (every === 'Weekly') return addDays(date, 7);
    let [y, m] = date.split('-').map(Number);
    if (every === 'Yearly') y += 1; else { m += 1; if (m > 12) { m = 1; y += 1; } }
    return ymd(y, m, Math.min(day || Number(date.slice(8)), daysInMonth(y, m)));
  }
  D.RECURRING.length = 0;
  [['Rent', 'housing', 'rent', 90000, 'main', 'Monthly', '2026-11-01'], ['Netflix', 'subscriptions', 'streaming', 1299, 'card', 'Monthly', '2026-11-03'], ['Phone bill', 'bills', 'mobile', 3500, 'main', 'Monthly', '2026-10-25'],
    ['Electricity', 'bills', 'electricity', 12500, 'main', 'Monthly', '2026-11-05', true], ['Gym', 'health', 'fitness', 5000, 'main', 'Monthly', '2026-11-06'], ['Internet', 'bills', 'internet', 5900, 'main', 'Monthly', '2026-11-08'],
    ['Water', 'bills', 'utilities', 2200, 'main', 'Monthly', '2026-11-10', true], ['Spotify', 'subscriptions', 'musicapp', 699, 'card', 'Monthly', '2026-11-12'], ['Heating', 'bills', 'utilities', 10500, 'main', 'Monthly', '2026-11-14', true],
    ['Google One', 'subscriptions', 'software', 299, 'card', 'Monthly', '2026-11-17'], ['Parking at work', 'transport', 'parking', 200, 'cash', 'Daily', '2026-10-29'], ['Cleaning', 'shopping', 'household', 3000, 'cash', 'Weekly', '2026-10-30'],
    ['Car registration', 'transport', 'carservice', 18500, 'euro', 'Yearly', '2027-04-20'], ['Salary', 'salary', null, 391166, 'main', 'Monthly', '2026-11-28', false, 'income']]
    .forEach(([name, cat, subcat, amount, account, every, date, varies, kind], i) => D.RECURRING.push({ id: `r${i + 1}`, name, cat, subcat, amount, cur: D.acc(account).cur, account, every, date, day: Number(date.slice(8)), varies: !!varies, kind: kind || 'expense' }));
  const refreshStates = () => D.RECURRING.forEach((r) => { r.state = r.date <= TODAY ? 'due' : 'planned'; });
  refreshStates();
  T.forEach((t) => { if (t.flags.includes('recurring')) { const r = D.RECURRING.find((x) => x.name === t.title); if (r) { t.rec = r.id; t.every = r.every; } } });

  const BUDGETS = [
    { id: 'b0', cat: 'overall', scope: 'Overall', limit: 170000, every: 'Monthly' },
    { id: 'b1', cat: 'food', scope: 'Category', limit: 40000, every: 'Monthly' },
    { id: 'b2', cat: 'transport', scope: 'Category', limit: 12000, every: 'Monthly' },
    { id: 'b3', cat: 'entertainment', scope: 'Category', limit: 6000, every: 'Monthly' },
    { id: 'b4', cat: 'shopping', scope: 'Category', limit: 10000, every: 'Monthly' },
    { id: 'b5', cat: 'bills', scope: 'Category', limit: 12000, every: 'Monthly' },
    { id: 'b6', cat: 'dining', scope: 'Subcategory', limit: 9000, every: 'Monthly' },
    { id: 'b7', cat: 'groceries', scope: 'Subcategory', limit: 7500, every: 'Weekly' },
  ];
  const zaraId = T.find((t) => t.merchant === 'Zara' && t.date === '2026-10-09').id;
  const dubrovnikId = T.find((t) => t.title === 'Dubrovnik apartment').id;
  const NOTES = [
    { id: 'n1', title: 'September close', date: '2026-10-01', tags: ['monthly'], body: 'Spending was close to normal. Shopping ran over because of the winter jacket.\nMove the laptop goal up if freelance comes in this month.', links: [{ type: 'goal', id: 'g3' }] },
    { id: 'n2', title: 'Dubrovnik trip costs', date: '2026-08-12', tags: ['trip', 'dubrovnik'], body: 'Apartment was the big cost. Ferry and dining stayed under what I planned.\n- Book earlier next time\n- Cash is enough for the islands', links: [{ type: 'transaction', id: dubrovnikId }, { type: 'category', id: 'travel' }] },
    { id: 'n3', title: 'Car service in spring', date: '2026-04-22', tags: ['car'], body: 'Hadžić replaced the brake pads and front discs. Next check at 120,000 km.', links: [{ type: 'category', id: 'transport' }] },
    { id: 'n4', title: 'Day note', date: '2026-10-18', tags: ['day'], body: 'Big shop for the week at Mercator. Split it into groceries, household and personal care.', links: [{ type: 'date', id: '2026-10-18' }], day: true },
    { id: 'n5', title: 'Cash check habit', date: '2026-10-12', tags: ['habit'], body: 'Count the wallet on the 12th and the 28th. Small coffee purchases are what drift.', links: [{ type: 'account', id: 'cash' }] },
    { id: 'n6', title: 'Zara return', date: '2026-10-14', tags: ['returns'], body: 'Returned the shirt, kept the trousers. Refund came back to the card five days later.', links: [{ type: 'transaction', id: zaraId }, { type: 'budget', id: 'b4' }] },
  ];

  const S = {
    monthStart: 1, closed: {}, backup: 'healthy', backupAt: '2026-10-27', restoreTest: '2026-09-14', lastExport: null, files: [],
    lock: false, lockDelay: '5 minutes', folder: 'SD card/Ledgerly backups', statementDone: false, permissions: { camera: false, photos: false },
  };
  const state = { v: 1, S, BUDGETS, NOTES, checks, archived };

  // ---- Periods follow the chosen month start ----
  function periodOf(date, startDay) {
    const sd = startDay || S.monthStart;
    let [y, m, d] = date.split('-').map(Number);
    const at = (yy, mm) => Math.min(sd, daysInMonth(yy, mm));
    if (d < at(y, m)) { m -= 1; if (!m) { m = 12; y -= 1; } }
    const start = ymd(y, m, at(y, m));
    const ny = m === 12 ? y + 1 : y;
    const nm = m === 12 ? 1 : m + 1;
    const end = addDays(ymd(ny, nm, at(ny, nm)), -1);
    return { key: start, start, end, days: diffDays(end, start) + 1, label: sd === 1 ? `${MONTH[m - 1]} ${y}` : `${shortDate(start)} to ${shortDate(end)}`, short: sd === 1 ? MON[m - 1] : shortDate(start) };
  }
  const current = () => periodOf(TODAY);
  const prevPeriod = (p) => periodOf(addDays(p.start, -1));
  const nextPeriod = (p) => periodOf(addDays(p.end, 1));
  function weekOf(date) {
    const start = addDays(date, -weekdayOf(date));
    return { key: start, start, end: addDays(start, 6), days: 7, label: `Week of ${shortDate(start)}`, short: shortDate(start) };
  }

  // ---- Calculation. Income and spending come only from postings with a category ----
  let cache = {};
  const memo = (key, fn) => (key in cache ? cache[key] : (cache[key] = fn()));
  function stats(start, end) {
    return memo(`s|${start}|${end}`, () => {
      const list = T.filter((t) => t.date >= start && t.date <= end);
      let income = 0; let spending = 0;
      const byCat = {}; const bySub = {}; const incomeByCat = {};
      const bump = (o, k, v) => { o[k] = (o[k] || 0) + v; };
      list.forEach((t) => {
        if (t.type === 'income') { income += t.base; bump(incomeByCat, t.cat || 'other', t.base); return; }
        const c = D.counted(t);
        spending += c;
        if (t.parts) t.parts.forEach(([cat, m, sub]) => { bump(byCat, cat, m); if (sub) bump(bySub, sub, m); });
        else if (t.cat && c) { bump(byCat, t.cat, c); if (t.subcat) bump(bySub, t.subcat, c); }
      });
      const ranked = Object.keys(byCat).map((cat) => ({ cat, amount: byCat[cat] })).sort((a, b) => b.amount - a.amount);
      const uncategorised = spending - ranked.reduce((s, r) => s + r.amount, 0);
      return { start, end, list, income, spending, net: income - spending, rate: income ? (income - spending) / income : 0, byCat, bySub, incomeByCat, ranked, uncategorised };
    });
  }
  const periodStats = (p) => stats(p.start, p.end);

  function move(t, id) {
    let m = 0;
    if (t.account === id) m += t.type === 'income' || t.type === 'refund' || t.type === 'repayment' ? t.amount : -t.amount;
    if (t.to === id) m += t.toAmount != null ? t.toAmount : D.acc(id).cur === t.cur ? t.amount : t.cur === 'EUR' ? Math.round(t.amount * PEG) : D.toEur(t.amount, t.cur);
    return m;
  }
  function balanceOf(id, upTo) {
    return memo(`b|${id}|${upTo || ''}`, () => T.reduce((s, t) => s + (upTo && t.date > upTo ? 0 : move(t, id)), D.acc(id).open));
  }
  const totalAt = (date) => D.ACCOUNTS.reduce((s, a) => s + D.toEur(balanceOf(a.id, date), a.cur), 0);
  const lastMonthDate = () => { const [y, m, d] = TODAY.split('-').map(Number); const pm = m === 1 ? 12 : m - 1; const py = m === 1 ? y - 1 : y; return ymd(py, pm, Math.min(d, daysInMonth(py, pm))); };

  D.accounts = () => D.ACCOUNTS.map((a) => { const balance = balanceOf(a.id); return Object.assign({}, a, { balance, base: D.toEur(balance, a.cur) }); });
  D.summary = () => {
    const total = D.accounts().reduce((s, a) => s + a.base, 0);
    const earmarked = D.GOALS.reduce((s, g) => s + g.saved, 0);
    return { total, earmarked, free: total - earmarked, lastMonth: totalAt(lastMonthDate()) };
  };
  function owedList() {
    return T.filter((t) => t.share != null).map((t) => {
      const owedTotal = t.base - t.shareBase;
      const repaid = T.filter((r) => r.type === 'repayment' && r.of === t.id).reduce((s, r) => s + r.base, 0);
      return { t, owed: owedTotal, repaid, left: owedTotal - repaid };
    }).filter((o) => o.left > 0);
  }
  D.owed = () => owedList().reduce((s, o) => s + o.left, 0);

  const nextPayday = () => D.RECURRING.filter((r) => r.kind === 'income' && r.date > TODAY).map((r) => r.date).sort()[0];
  // Every date a repeat falls on in a range. A Due repeat counts once, on its own date.
  function occurrences(start, end, filter) {
    const out = [];
    D.RECURRING.filter(filter || (() => true)).forEach((r) => {
      let d = r.date; let n = 0;
      while (d <= end && n < 400) { if (d >= start) out.push({ r, date: d }); d = advance(d, r.every, r.day); n += 1; }
    });
    return out.sort((a, b) => (a.date < b.date ? -1 : 1));
  }
  // Normal daily spending leaves out monthly and yearly repeats, since they are counted as bills.
  // Daily and weekly repeats stay in it, so they are not counted twice.
  const isBill = (r) => r.every === 'Monthly' || r.every === 'Yearly';
  function dailyNormal() {
    const days = 92; const start = addDays(TODAY, -days);
    const sum = T.reduce((s, t) => s + (t.date > start && t.date <= TODAY && !(t.flags.includes('recurring') && !['Daily', 'Weekly'].includes(t.every)) ? D.counted(t) : 0), 0);
    return Math.round(sum / days);
  }
  function forecast() {
    const liquid = D.accounts().filter((a) => a.id !== 'savings').reduce((s, a) => s + a.base, 0);
    const payday = nextPayday();
    const perDay = dailyNormal();
    const bills = occurrences('0000', addDays(payday, -1), (r) => r.kind !== 'income' && isBill(r)).map((o) => ({ name: o.r.name, amount: o.r.amount, cur: o.r.cur, date: o.date }));
    let bal = liquid; let lowest = liquid; let lowestDate = TODAY; const curve = [];
    for (let d = addDays(TODAY, 1); d < payday; d = addDays(d, 1)) {
      bal -= perDay + bills.filter((b) => b.date === d || (b.date <= TODAY && d === addDays(TODAY, 1))).reduce((s, b) => s + D.toEur(b.amount, b.cur), 0);
      curve.push({ date: d, bal });
      if (bal < lowest) { lowest = bal; lowestDate = d; }
    }
    const billTotal = bills.reduce((s, b) => s + D.toEur(b.amount, b.cur), 0);
    const days = diffDays(payday, TODAY) - 1;
    return { liquid, perDay, days, bills, billTotal, lowest, lowestDate, payday, curve };
  }
  D.forecast = forecast;

  function budgetRange(b, date) { return b.every === 'Weekly' ? weekOf(date || TODAY) : periodOf(date || TODAY); }
  function spentIn(b, r) {
    const s = stats(r.start, r.end);
    if (b.cat === 'overall') return s.spending;
    return L.cat(b.cat).parent ? s.bySub[b.cat] || 0 : s.byCat[b.cat] || 0;
  }
  function budgetView(b, date) {
    const r = budgetRange(b, date);
    const spent = spentIn(b, r);
    const ratio = spent / b.limit;
    const left = b.limit - spent;
    const elapsed = Math.min(r.days, Math.max(1, diffDays(TODAY, r.start) + 1));
    const remaining = Math.max(1, r.days - elapsed + 1);
    const pct = Math.round(ratio * 100);
    return Object.assign({}, b, { range: r, spent, ratio, left, state: pct >= 100 ? 'over' : pct >= 80 ? 'warning' : 'normal', pace: elapsed / r.days, remaining, safe: Math.max(0, Math.round(left / remaining)) });
  }
  D.budgets = () => BUDGETS.map((b) => budgetView(b));
  function budgetHistory(b, n) {
    const out = []; let r = budgetRange(b);
    for (let i = 0; i < n; i++) {
      const v = spentIn(b, r);
      out.unshift({ label: r.short, range: r, spent: v, limit: b.limit, ratio: v / b.limit });
      r = b.every === 'Weekly' ? weekOf(addDays(r.start, -1)) : prevPeriod(r);
    }
    return out;
  }

  const FIXED = ['housing', 'bills'];
  function costType(t) {
    if (!t.flags.includes('recurring')) return 'variable';
    return FIXED.includes(t.cat) ? 'fixed' : 'recurring';
  }
  function costTypes(start, end) {
    const o = { fixed: 0, recurring: 0, variable: 0 };
    stats(start, end).list.forEach((t) => { o[costType(t)] += D.counted(t); });
    return o;
  }
  function subscriptionTotal() {
    const list = D.RECURRING.filter((r) => r.cat === 'subscriptions');
    const month = Math.round(list.reduce((s, r) => s + D.toEur(r.amount, r.cur) * PER_MONTH[r.every], 0));
    return { list, month, year: month * 12 };
  }

  // Insights are computed, and they carry the figures they rely on.
  function insights(p) {
    const now = periodStats(p);
    const prior = []; let r = p;
    for (let i = 0; i < 3; i++) { r = prevPeriod(r); prior.push(periodStats(r)); }
    const avg = (k) => Math.round(prior.reduce((s, m) => s + (m.bySub[k] || 0), 0) / 3);
    const moves = Object.keys(now.bySub).map((k) => ({ k, now: now.bySub[k], avg: avg(k), diff: now.bySub[k] - avg(k) })).filter((x) => x.avg > 0).sort((a, b) => Math.abs(b.diff) - Math.abs(a.diff));
    const top = moves[0];
    const out = [];
    if (top) out.push({ cat: top.k, text: `${L.cat(top.k).name} is ${L.fmt(Math.abs(top.diff), 'EUR')} ${top.diff >= 0 ? 'above' : 'below'} its three-month average of ${L.fmt(top.avg, 'EUR')}.` });
    const wk = [0, 0, 0, 0, 0, 0, 0];
    now.list.forEach((t) => { wk[weekdayOf(t.date)] += D.counted(t); });
    const peak = wk.indexOf(Math.max(...wk));
    const peakName = ['Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays', 'Fridays', 'Saturdays', 'Sundays'][peak];
    if (now.spending) out.push({ weekday: peak, text: `${peakName} took ${Math.round((wk[peak] / now.spending) * 100)}% of spending, ${L.fmt(wk[peak], 'EUR')} of ${L.fmt(now.spending, 'EUR')}.` });
    return out;
  }

  // ---- Title memory, chips and search. Titles typed before are offered again ----
  function titles() {
    return memo('titles', () => {
      const map = {};
      const since = addDays(TODAY, -90);
      T.forEach((t) => {
        if (!t.title || !t.cat || (t.type !== 'expense' && t.type !== 'income')) return;
        const key = fold(t.title);
        const m = (map[key] = map[key] || { name: t.title, type: t.type, count: 0, recent: 0, uses: {}, last: t });
        m.count += 1;
        if (t.date >= since) m.recent += 1;
        const k = `${t.cat}|${t.subcat || ''}|${t.account}`;
        m.uses[k] = (m.uses[k] || 0) + 1;
      });
      return Object.values(map).map((m) => {
        const [cat, subcat, account] = Object.keys(m.uses).sort((a, b) => m.uses[b] - m.uses[a])[0].split('|');
        return { name: m.name, type: m.type, count: m.count, recent: m.recent, cat, subcat: subcat || null, account, amount: m.last.amount };
      }).sort((a, b) => b.recent - a.recent || b.count - a.count);
    });
  }
  const frozen = {};
  function chips(account, kind) {
    const key = `${account}|${kind}`;
    if (!frozen[key]) {
      const count = {};
      const since = addDays(TODAY, -90);
      T.forEach((t) => {
        if (t.account !== account || t.type !== kind || !t.cat || t.date < since) return;
        const id = t.subcat || t.cat;
        count[id] = (count[id] || 0) + 1;
      });
      const used = Object.keys(count).sort((a, b) => count[b] - count[a]);
      const fill = catIds(kind).filter((id) => id !== 'other' && !used.some((u) => parentOf(u) === id));
      frozen[key] = used.concat(fill).slice(0, 24);
    }
    return frozen[key].filter((id) => applies(id, account) && !archived.has(id) && !archived.has(parentOf(id))).slice(0, 6);
  }
  function pinChip(id, kind) {
    D.ACCOUNTS.forEach((a) => {
      const key = `${a.id}|${kind}`;
      chips(a.id, kind);
      frozen[key] = frozen[key].filter((x) => x !== id);
      frozen[key].splice(Math.min(5, frozen[key].length), 0, id);
    });
  }
  const allCats = (kind, account) => {
    const out = [];
    catIds(kind).forEach((id) => {
      if (archived.has(id) || (account && !applies(id, account))) return;
      out.push(id);
      if (kind === 'expense') subsOf(id).forEach((c) => { if (!archived.has(c.id)) out.push(c.id); });
    });
    return out;
  };

  const fold = (s) => String(s || '').toLowerCase().replace(/[čć]/g, 'c').replace(/đ/g, 'd').replace(/š/g, 's').replace(/ž/g, 'z');
  function matches(t, q) {
    const n = fold(q).trim();
    if (!n) return true;
    if (/^[\d.,]+$/.test(n)) {
      const v = n.replace(',', '.');
      const money = [t.amount, t.base, t.orig && t.orig.amount].filter((x) => x != null).map((x) => (Math.abs(x) / 100).toFixed(2));
      return money.some((m) => m === v || m.startsWith(v.includes('.') ? v : `${v}.`) || m.replace(/\.00$/, '') === v);
    }
    const hay = [t.title, t.merchant, t.note, t.owedFrom, ...(t.tags || []), t.cat && L.cat(t.cat).name, t.subcat && L.cat(t.subcat).name, D.acc(t.account).name, t.to && D.acc(t.to).name].map(fold).join(' ');
    return n.split(/\s+/).every((w) => hay.includes(w));
  }
  // A split payment counts only its matching part when one category is being looked at.
  function countedFor(t, cat) {
    if (!cat || !t.parts) return D.counted(t);
    return t.parts.filter(([c, , s]) => c === cat || s === cat).reduce((n, p) => n + p[1], 0);
  }
  function filterTx(f) {
    const p = f || {};
    return T.filter((t) => {
      if (p.start && t.date < p.start) return false;
      if (p.end && t.date > p.end) return false;
      if (p.account && t.account !== p.account && t.to !== p.account) return false;
      if (p.type && t.type !== p.type && !(p.type === 'expense' && t.type === 'refund')) return false;
      if (p.spending && !D.counted(t)) return false;
      if (p.income && t.type !== 'income') return false;
      if (p.flag && !t.flags.includes(p.flag)) return false;
      if (p.tag && !(t.tags || []).includes(p.tag)) return false;
      if (p.weekday != null && weekdayOf(t.date) !== p.weekday) return false;
      if (p.cost && (costType(t) !== p.cost || !D.counted(t))) return false;
      if (p.cat) {
        if (p.income) { if (t.cat !== p.cat) return false; } else {
          const inPart = t.parts && t.parts.some(([c, , s]) => c === p.cat || s === p.cat);
          if (t.cat !== p.cat && t.subcat !== p.cat && !inPart) return false;
          if (t.parts && !inPart) return false;
        }
      }
      if (p.uncategorised && t.cat) return false;
      if (p.otherThan && t.cat && p.otherThan.includes(t.cat)) return false;
      return matches(t, p.q);
    });
  }
  const tags = () => [...new Set(T.flatMap((t) => t.tags || []))].sort();

  // ---- Changes. Each returns what the toast needs; `checkpoint` is the Undo ----
  function bump() { state.v += 1; cache = {}; refreshStates(); sortT(); }
  function checkpoint() {
    const save = { T: T.map((t) => Object.assign({}, t, { flags: t.flags.slice(), tags: (t.tags || []).slice(), parts: t.parts && t.parts.map((p) => p.slice()) })), R: D.RECURRING.map((r) => Object.assign({}, r)), G: D.GOALS.map((g) => Object.assign({}, g)), B: BUDGETS.map((b) => Object.assign({}, b)), N: NOTES.map((n) => Object.assign({}, n, { links: n.links.slice(), tags: n.tags.slice() })), C: Object.assign({}, checks), S: Object.assign({}, S, { closed: Object.assign({}, S.closed) }) };
    return () => {
      T.length = 0; T.push(...save.T);
      D.RECURRING.length = 0; D.RECURRING.push(...save.R);
      D.GOALS.length = 0; D.GOALS.push(...save.G);
      BUDGETS.length = 0; BUDGETS.push(...save.B);
      NOTES.length = 0; NOTES.push(...save.N);
      Object.assign(checks, save.C); Object.assign(S, save.S);
      bump();
    };
  }
  let clock = 14 * 60 + 12;
  const nowTime = () => { clock += 3; return `${pad(Math.floor(clock / 60) % 24)}:${pad(clock % 60)}`; };
  function create(p) {
    const cur = D.acc(p.account).cur;
    const t = Object.assign({ id: nextId++, date: TODAY, time: nowTime(), type: 'expense', cur, base: D.toEur(p.amount, cur), title: null, merchant: null, cat: null, flags: [], tags: [] }, p);
    if (t.share != null) t.shareBase = D.toEur(t.share, cur);
    T.push(t); bump();
    return t;
  }
  function update(id, patch) {
    const t = T.find((x) => x.id === id);
    Object.assign(t, patch);
    t.cur = D.acc(t.account).cur;
    t.base = D.toEur(t.amount, t.cur);
    if (t.share != null) t.shareBase = D.toEur(t.share, t.cur); else delete t.shareBase;
    t.flags = t.flags.filter((f) => f !== 'review');
    if (t.type === 'expense' && !t.cat) t.flags.push('review');
    bump();
    return t;
  }
  function remove(ids) {
    [].concat(ids).forEach((id) => { const i = T.findIndex((t) => t.id === id); if (i >= 0) T.splice(i, 1); });
    bump();
  }
  function duplicate(id) {
    const t = T.find((x) => x.id === id);
    const copy = Object.assign({}, t, { id: nextId++, date: TODAY, time: nowTime(), flags: t.flags.filter((f) => f !== 'receipt'), tags: (t.tags || []).slice(), parts: t.parts && t.parts.map((p) => p.slice()) });
    T.push(copy); bump();
    return copy;
  }
  function refund(id, amount) {
    const t = T.find((x) => x.id === id);
    return create({ type: 'refund', account: t.account, amount, title: `${titleOf(t)} refund`, merchant: t.merchant, cat: t.cat, subcat: t.subcat, flags: ['refund'], of: id });
  }
  function repay(id, amount, account) {
    const t = T.find((x) => x.id === id);
    return create({ type: 'repayment', account: account || t.account, amount, title: `Repaid for ${titleOf(t)}`, cat: null, of: id, flags: [] });
  }
  function markPaid(id, amount) {
    const r = D.RECURRING.find((x) => x.id === id);
    const amt = amount || r.amount;
    const date = r.every === 'Daily' ? r.date : TODAY;
    const t = create({ type: r.kind === 'income' ? 'income' : 'expense', account: r.account, amount: amt, title: r.name, cat: r.cat, subcat: r.subcat, flags: ['recurring'], date, rec: r.id, every: r.every });
    if (r.varies) r.amount = amt;
    r.date = advance(r.date, r.every, r.day);
    bump();
    return t;
  }
  function skip(id) { const r = D.RECURRING.find((x) => x.id === id); r.date = advance(r.date, r.every, r.day); bump(); }
  function addRepeat(p) {
    const r = Object.assign({ id: `r${nextId++}`, kind: 'expense', varies: false }, p);
    r.cur = D.acc(r.account).cur; r.day = Number(r.date.slice(8));
    D.RECURRING.push(r); bump();
    return r;
  }
  function editRepeat(id, patch) {
    const r = D.RECURRING.find((x) => x.id === id);
    Object.assign(r, patch);
    r.cur = D.acc(r.account).cur;
    if (patch.date) r.day = Number(patch.date.slice(8));
    bump();
    return r;
  }
  function stopRepeat(id) { D.RECURRING.splice(D.RECURRING.findIndex((r) => r.id === id), 1); bump(); }
  function reconcile(id, real) {
    const a = D.acc(id);
    const diff = balanceOf(id) - real;
    checks[id] = TODAY;
    if (!diff) { bump(); return null; }
    return create({ type: 'adjustment', account: id, amount: diff, title: 'Untracked', cat: null, flags: [] });
  }
  const untracked = (id) => T.filter((t) => t.type === 'adjustment' && t.account === id).reduce((s, t) => s - t.amount, 0);
  function isReconciled(t) { return t.date <= (checks[t.account] || ''); }
  function addCategory(c, accounts, parent) {
    const id = `c${nextId++}`;
    if (parent) D.CUSTOM.push(Object.assign({ custom: true }, c, { id, parent, slot: c.slot || L.cat(parent).slot, kind: 'expense' }));
    else { D.addCategory(Object.assign({}, c, { id }), []); ties[id] = accounts.slice(); }
    bump();
    return id;
  }
  function usage(id) {
    return T.filter((t) => t.cat === id || t.subcat === id || (t.parts && t.parts.some(([c, , s]) => c === id || s === id))).length;
  }
  function reassign(from, to) {
    const toParent = parentOf(to); const toSub = to === toParent ? null : to;
    T.forEach((t) => {
      if (t.cat === from || t.subcat === from) { t.cat = toParent; t.subcat = toSub; }
      if (t.parts) t.parts = t.parts.map((p) => (p[0] === from || p[2] === from ? [toParent, p[1], toSub] : p));
    });
    D.CUSTOM.filter((c) => c.parent === from).forEach((c) => { c.parent = toParent; });
    const i = D.CUSTOM.findIndex((c) => c.id === from);
    if (i >= 0) { if (D.CUSTOM[i].parent) D.CUSTOM.splice(i, 1); else D.removeCategory(from); }
    bump();
  }
  function setTies(id, accounts) { ties[id] = accounts.slice(); bump(); }
  function archive(id, on) { if (on) archived.add(id); else archived.delete(id); bump(); }

  // First launch, Start empty: the session continues with one account and no history.
  function startEmpty(a) {
    T.length = 0; D.RECURRING.length = 0; D.GOALS.length = 0; BUDGETS.length = 0; NOTES.length = 0;
    D.ACCOUNTS.splice(0, D.ACCOUNTS.length, { id: 'main', name: a.name, cur: a.cur, open: a.open, icon: 'wallet', kind: 'Bank account' });
    Object.keys(checks).forEach((k) => delete checks[k]);
    checks.main = TODAY;
    Object.keys(frozen).forEach((k) => delete frozen[k]);
    Object.keys(ties).forEach((k) => { ties[k] = []; });
    bump();
  }

  // Simulated files. The size is derived from what the file would hold.
  const counts = () => ({ transactions: T.length, accounts: D.ACCOUNTS.length, receipts: T.filter((t) => t.flags.includes('receipt')).length, notes: NOTES.length, budgets: BUDGETS.length, goals: D.GOALS.length });
  const sizeOf = (attachments) => { const c = counts(); const kb = Math.round(c.transactions * 0.42 + 180 + (attachments ? c.receipts * 210 : 0)); return kb >= 1024 ? `${(kb / 1024).toFixed(1)} MB` : `${kb} KB`; };
  function exportFile(o) {
    const c = counts();
    const f = { id: `f${nextId++}`, name: 'ledgerly-2026-10-29.ledgerly', date: `${longDate(TODAY)}, ${nowTime()}`, version: '1.0.0', size: sizeOf(o.attachments), attachments: o.attachments, password: o.password || null, counts: c, kind: 'good', dest: o.dest };
    S.files.unshift(f); S.lastExport = f; S.backup = 'healthy'; S.backupAt = TODAY; bump();
    return f;
  }
  const sampleFiles = () => [
    { id: 'bad', name: 'ledgerly-2026-09-30.ledgerly', date: '30 Sep 2026, 21:40', version: '1.0.0', kind: 'damaged', size: '1.2 MB', counts: null },
    { id: 'wrongpw', name: 'ledgerly-locked.ledgerly', date: '12 Oct 2026, 19:02', version: '1.0.0', kind: 'locked', password: 'unknown', size: '3.4 MB', counts: counts() },
    { id: 'newer', name: 'ledgerly-tablet.ledgerly', date: '28 Oct 2026, 09:12', version: '2.1.0', kind: 'newer', size: '3.1 MB', counts: null },
  ];

  // A simulated statement for Main Bank: rows that match, rows that are missing, a likely duplicate.
  function statement() {
    const recent = T.filter((t) => t.account === 'main' && t.type === 'expense' && t.date >= '2026-10-01' && t.date <= '2026-10-27').slice(0, 7);
    const rows = recent.map((t, i) => ({ id: `s${i}`, date: t.date, text: (t.merchant || t.title || 'Card payment').toUpperCase(), amount: t.amount, status: 'matched', tx: t.id }));
    rows.push({ id: 'm1', date: '2026-10-24', text: 'BANK FEE OCTOBER', amount: 450, status: 'missing', cat: 'bills', add: true });
    rows.push({ id: 'm2', date: '2026-10-19', text: 'KONZUM ČENGIĆ VILA', amount: 2340, status: 'missing', cat: 'food', subcat: 'groceries', add: true });
    rows.push({ id: 'm3', date: '2026-10-11', text: 'TERMINAL 4471 ŠIŠMIŠ', amount: 680, status: 'missing', cat: null, add: true });
    const base = recent[1] || recent[0];
    rows.push({ id: 'd1', date: addDays(base.date, 1), text: `${(base.merchant || base.title || 'Card').toUpperCase()} POS`, amount: base.amount, status: 'duplicate', tx: base.id, skip: true });
    return rows.sort((a, b) => (a.date < b.date ? 1 : -1));
  }
  function importStatement(rows) {
    rows.filter((r) => r.status === 'missing' && r.add).forEach((r) => create({ account: 'main', amount: r.amount, title: r.text, cat: r.cat, subcat: r.subcat, date: r.date, flags: r.cat ? ['imported'].slice(1) : ['review'] }));
    rows.filter((r) => r.status === 'duplicate' && !r.skip).forEach((r) => create({ account: 'main', amount: r.amount, title: r.text, cat: null, date: r.date, flags: ['review'] }));
  }

  window.Ledger = {
    state, S, BUDGETS, NOTES, EVERY, PER_MONTH, SUBS, MON, MONTH, WEEK, checks, TODAY, PEG,
    addDays, diffDays, toDate, shortDate, longDate, weekdayOf, daysInMonth, pad, ymd,
    parentOf, tiedTo, applies, catIds, subsOf, allCats, chips, pinChip, titles, titleOf, fold, matches, filterTx, countedFor, tags,
    periodOf, current, prevPeriod, nextPeriod, weekOf, stats, periodStats, balanceOf, totalAt, forecast, dailyNormal, nextPayday, occurrences, advance,
    budgetView, budgetHistory, costType, costTypes, subscriptionTotal, insights, owedList,
    checkpoint, bump, create, update, remove, duplicate, refund, repay, markPaid, skip, addRepeat, editRepeat, stopRepeat, reconcile, untracked, isReconciled,
    addCategory, usage, reassign, setTies, archive, counts, sizeOf, exportFile, sampleFiles, statement, importStatement, startEmpty,
  };
})(window.Ledgerly);
