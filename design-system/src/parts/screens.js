// Proof screens. Prototypes only: composed from the components with figures from the one ledger.
(function (L) {
  const D = L.data;
  const ui = L.ui;
  const proto = (name) => `<div class="ds-proto"><span class="lg-badge lg-badge--proto">Prototype</span>${name}</div>`;

  function monthMetrics() {
    const m = D.month(D.CURRENT);
    const p = D.month(D.PREV);
    const delta = (a, b) => `${a >= b ? '+' : '−'}${L.fmt(Math.abs(a - b), 'EUR')} vs Sep`;
    return `<div class="lg-metrics">
      ${ui.metric('Income', m.income, { tone: 'positive', sign: true, delta: delta(m.income, p.income) })}
      ${ui.metric('Spending', -m.spending, { tone: 'negative', delta: delta(m.spending, p.spending) })}
      ${ui.metric('Net', m.net, { sign: true, tone: m.net >= 0 ? 'positive' : 'negative', delta: delta(m.net, p.net) })}
      ${ui.metric('Savings rate', `${Math.round(m.rate * 100)}%`, { raw: true, delta: `${Math.round(p.rate * 100)}% in Sep` })}
    </div>`;
  }

  function topCategories() {
    const m = D.month(D.CURRENT);
    const budgets = D.budgets();
    return `<div class="lg-card lg-stack">${m.ranked.slice(0, 5).map((r) => {
      const b = budgets.find((x) => x.cat === r.cat);
      if (b) return ui.budget(b, { flat: true });
      const c = L.cat(r.cat);
      return `<div class="lg-between"><span class="lg-inline" style="--chip-color:var(--cat-${c.slot})"><span class="lg-chip__icon">${L.icon(c.icon, 20)}</span><span class="label">${c.name}</span></span><span class="body-small">${L.money(r.amount)}</span></div>`;
    }).join('')}</div>`;
  }

  L.screens = {};
  L.screens.home = function () {
    const f = D.forecast();
    const review = D.review().length;
    const due = D.RECURRING.find((r) => r.state === 'due');
    const food = D.budgets().find((b) => b.state === 'warning');
    const recent = D.transactions.filter((t) => t.date <= D.TODAY).slice(0, 4);
    return `<div class="lg-phone">
      <div class="lg-phone__head">${`<span class="lg-inline">${L.appIcon(24)}<span class="lg-wordmark">Ledgerly</span></span>`}<button type="button" class="lg-icon-btn" aria-label="Hide amounts" data-hide>${L.icon('eye', 20)}</button></div>
      <div class="lg-phone__body">
        ${ui.balance()}
        <div class="lg-card"><div class="lg-between"><span class="label">Lowest before payday</span><span class="lg-badge">Estimate</span></div><div class="amount-large">${L.money(f.lowest)}</div><div class="body-small lg-muted">Around 27 Nov, after ${L.money(f.bills)} of bills. Next salary 28 Nov.</div></div>
        ${ui.section('This month')}
        ${monthMetrics()}
        ${ui.section('Where it went', 'All')}
        ${topCategories()}
        ${ui.section('Needs attention')}
        <div class="lg-card lg-card--flush">
          ${ui.attention(due.name, `Due today, ${L.fmt(due.amount, due.cur)}`, 'Confirm', { icon: 'repeat' })}
          ${ui.attention(`${review} entries to review`, 'They need a category', 'Review', { icon: 'flag' })}
          ${ui.attention(`${L.cat(food.cat).name} budget at ${Math.round(food.ratio * 100)}%`, `${L.fmt(food.left, 'EUR')} left for 2 days`, 'View', { icon: 'alert' })}
        </div>
        ${ui.section('Recent', 'History')}
        <div class="lg-card lg-card--flush">${recent.map((t) => ui.tx(t)).join('')}</div>
        <div class="caption lg-faint" style="text-align:center">Backed up 2 days ago</div>
      </div>
      ${ui.nav(0)}
    </div>`;
  };

  L.screens.add = function () {
    return `<div class="lg-phone" data-add data-account="euro" data-kind="expense" style="background:var(--scrim)">
      <div style="min-height:40px"></div>
      <div class="lg-sheet" style="border-radius:16px 16px 0 0">
        <div class="lg-sheet__grip"></div>
        <div class="lg-add">
          <div class="lg-add__amount is-empty" data-amount aria-live="polite"><span class="money">€0.00</span></div>
          <span class="lg-input"><input aria-label="Merchant, optional" placeholder="Merchant (optional)"></span>
          ${ui.segmented([{ label: 'Expense', kind: 'expense', icon: 'down' }, { label: 'Income', kind: 'income', icon: 'up' }, { label: 'Transfer', kind: 'transfer', icon: 'transfer' }], { label: 'Type' })}
          <div class="lg-add__pills"><button type="button" class="lg-pill" data-add-account>${L.icon('wallet', 16)}<span>Euro Account</span></button><button type="button" class="lg-pill">${L.icon('calendar', 16)}Today</button></div>
          <div class="lg-chips" data-chips>${ui.addChips('euro', 'expense', true)}</div>
          <button type="button" class="lg-add__more">More details${L.icon('chevronDown', 20)}</button>
          ${ui.keypad()}
          <div data-toast-slot></div>
        </div>
      </div>
    </div>`;
  };

  L.screens.history = function () {
    const groups = D.dayGroups(D.CURRENT).slice(0, 5);
    return `<div class="lg-phone">
      <div class="lg-phone__head"><h2 class="lg-title">Transactions</h2><button type="button" class="lg-icon-btn" aria-label="Filter">${L.icon('tag', 20)}</button></div>
      <div class="lg-phone__body" style="padding-bottom:8px">
        ${ui.segmented(['List', 'Calendar'], { label: 'View' })}
        ${ui.search()}
        <div class="lg-chips--scroll">${ui.chip('food')}${ui.chip('bills')}</div>
      </div>
      <div class="lg-phone__body lg-phone__body--flush">
        ${groups.map((g) => `${ui.day(g.date, g.net)}<div class="lg-card lg-card--flush" style="margin:0 12px 8px">${g.list.map((t) => ui.tx(t)).join('')}</div>`).join('')}
      </div>
      ${ui.nav(1)}
    </div>`;
  };

  function dayPanel(date) {
    const list = D.transactions.filter((t) => t.date === date);
    const spend = D.daySpend(date);
    const income = list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0), 0);
    const cats = {};
    list.forEach((t) => { if (t.cat && D.counted(t) > 0) cats[t.cat] = (cats[t.cat] || 0) + D.counted(t); });
    const top = Object.keys(cats).sort((a, b) => cats[b] - cats[a])[0];
    return `<div class="lg-between"><h3 style="margin:0">${D.dayLabel(date)}</h3><span class="body-small lg-muted">${list.length} ${list.length === 1 ? 'entry' : 'entries'}</span></div>
      <div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px;margin:8px 0">
        <div><div class="caption lg-faint">Spent</div><div class="amount">${L.money(-spend, 'EUR', { tone: spend ? 'negative' : undefined })}</div></div>
        <div><div class="caption lg-faint">Income</div><div class="amount">${L.money(income, 'EUR', { sign: !!income, tone: income ? 'positive' : undefined })}</div></div>
      </div>
      ${top ? `<div class="body-small lg-muted">Top category: ${L.cat(top).name}</div>` : ''}
      <div class="lg-card lg-card--flush" style="margin-top:8px">${list.slice(0, 3).map((t) => ui.tx(t)).join('') || '<div class="lg-state"><p>No entries on this day.</p></div>'}</div>`;
  }
  L.screens.dayPanel = dayPanel;

  L.screens.calendar = function () {
    return `<div class="lg-phone">
      <div class="lg-phone__head"><h2 class="lg-title">Transactions</h2></div>
      <div class="lg-phone__body">
        ${ui.segmented(['List', 'Calendar'], { label: 'View', selected: 1 })}
        <div class="lg-between"><span class="label">October 2026</span><div style="width:9rem" data-range-toggle>${ui.segmented(['Month', 'Year'], { label: 'Range' })}</div></div>
        <div class="lg-stack" data-range="month">
          ${L.calSummary()}
          ${L.charts.calendar(D.TODAY)}
          ${L.calKey()}
        </div>
        <div data-range="year" hidden>${L.charts.year()}</div>
      </div>
      <div class="lg-sheet" style="border-radius:16px 16px 0 0;padding-bottom:40px" data-range="month"><div class="lg-sheet__grip"></div><div data-day-panel>${dayPanel(D.TODAY)}</div></div>
      ${ui.nav(1)}
    </div>`;
  };

  L.screens.categories = function () {
    const filter = [['', 'All accounts']].concat(D.ACCOUNTS.map((a) => [a.id, a.name]));
    return `<div class="lg-phone" data-cats data-kind="expense" data-account="">
      <div class="lg-phone__head"><h2 class="lg-title">Categories</h2><button type="button" class="lg-icon-btn" aria-label="Add category" data-cat-new>${L.icon('plus', 24)}</button></div>
      <div class="lg-phone__body">
        <div data-cat-kind>${ui.segmented([{ label: 'Expense', kind: 'expense', icon: 'down' }, { label: 'Income', kind: 'income', icon: 'up' }], { label: 'Type' })}</div>
        <div class="lg-add__pills" role="group" aria-label="Filter by account">${filter.map(([id, name]) => `<button type="button" class="lg-pill" aria-pressed="${id === ''}" data-cat-filter="${id}">${name}</button>`).join('')}</div>
        <div class="lg-card lg-card--flush" data-cat-list>${ui.categoryList('expense')}</div>
        ${ui.button('Add category', { kind: 'primary', block: true, icon: 'plus', attr: 'data-cat-new' })}
        <div data-toast-slot></div>
      </div>
      ${ui.nav(4)}
      <div class="lg-phone__overlay" data-cat-overlay hidden><div class="lg-sheet"><div class="lg-sheet__grip"></div>${ui.categoryEditor({ close: true })}</div></div>
    </div>`;
  };
  L.screens.categoryEditor = function () {
    return `<div class="lg-phone" style="background:var(--scrim)"><div style="min-height:40px"></div><div class="lg-sheet" style="border-radius:16px 16px 0 0"><div class="lg-sheet__grip"></div>${ui.categoryEditor({ name: 'Čišćenje', icon: 'sparkle', slot: 3, accounts: ['main', 'cash'] })}<div data-toast-slot></div></div></div>`;
  };

  L.screens.analytics = function () {
    return `<div class="lg-desk">
      ${ui.sidebar(2)}
      <div class="lg-desk__main">
        <div class="lg-between" style="flex-wrap:wrap"><h2 class="lg-title">Analytics</h2><div style="min-width:0;flex:1 1 12rem;max-width:22rem">${ui.segmented(['Month', 'Quarter', 'Year'], { label: 'Range' })}</div></div>
        <div class="body-small lg-muted">October 2026, compared with September 2026</div>
        <div class="lg-grid-4">${monthMetrics().replace('class="lg-metrics"', 'style="display:contents"')}</div>
        <div class="lg-grid-2">
          <div class="lg-card">${L.charts.grouped(6)}</div>
          <div class="lg-card">${L.charts.donut()}</div>
          <div class="lg-card">${L.charts.trends()}</div>
          <div class="lg-card">${L.charts.weekday()}</div>
          <div class="lg-card">${L.charts.balance()}</div>
          <div class="lg-card" style="grid-column:1/-1">${L.charts.year()}</div>
        </div>
      </div>
    </div>`;
  };

  L.proof = (name, fn) => `${proto(name)}<div class="ds-screens"><div data-theme="light" class="lg-root">${fn()}</div><div data-theme="dark" class="lg-root">${fn()}</div></div>`;
  L.proofWide = (name, fn) => `${proto(name)}<div class="ds-screens ds-screens--wide"><div data-theme="light" class="lg-root">${fn()}</div><div data-theme="dark" class="lg-root">${fn()}</div></div>`;
})(window.Ledgerly = window.Ledgerly || {});
