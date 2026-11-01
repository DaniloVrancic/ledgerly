// One chart style in plain SVG. Colour always comes from tokens. Every mark that can be selected
// is a focusable button, and every chart carries a text description for screen readers.
(function (L) {
  const D = L.data;
  const W = 320;
  const v = (n) => `var(--${n})`;

  function frame(question, svg, desc, foot) {
    return `<figure class="lg-chart" style="margin:0"><figcaption class="lg-chart__q">${question}</figcaption><div role="img" aria-label="${desc}">${svg}</div>${foot || ''}</figure>`;
  }
  const niceMax = (m) => {
    const p = 10 ** Math.floor(Math.log10(m || 1));
    return [1, 2, 2.5, 5, 10].map((x) => x * p).find((x) => x >= m);
  };
  function gridY(h, top, bottom, max, min, left) {
    const zero = min || 0;
    const y = (val) => top + (1 - (val - zero) / (max - zero)) * (h - top - bottom);
    const steps = [0, 0.5, 1].map((f) => zero + f * (max - zero));
    const lines = steps.map((s) => `<line x1="${left}" x2="${W}" y1="${y(s)}" y2="${y(s)}" stroke="${s === 0 ? v('chart-axis') : v('chart-grid')}"/><text class="lg-axis-value" x="${left - 8}" y="${y(s) + 4}" text-anchor="end">${L.fmtShort(s)}</text>`).join('');
    return { y, lines };
  }
  const hit = (attr, label) => `class="is-hit" tabindex="0" role="button" aria-label="${label}" ${attr}`;

  // Grouped bars start at zero. The net line shares the same axis, so there is no second scale.
  L.charts = {};
  L.charts.grouped = function (count) {
    const list = D.series().slice(-(count || 6));
    const h = 200; const left = 36; const top = 12; const bottom = 24;
    const max = niceMax(Math.max(...list.map((m) => Math.max(m.income, m.spending))));
    const g = gridY(h, top, bottom, max, 0, left);
    const band = (W - left) / list.length;
    const bw = Math.min(16, band * 0.36);
    const bars = list.map((m, i) => {
      const x = left + band * i + band / 2;
      const name = D.monthLabel(m.ym);
      const b1 = `<rect ${hit(`data-tip="${name}: income ${L.fmt(m.income, 'EUR')}, spending ${L.fmt(m.spending, 'EUR')}, net ${L.fmt(m.net, 'EUR', true)}"`, `${name} income ${L.fmt(m.income, 'EUR')}`)} x="${x - bw - 1}" y="${g.y(m.income)}" width="${bw}" height="${g.y(0) - g.y(m.income)}" rx="2" fill="${v('positive-fill')}"/>`;
      const b2 = `<rect ${hit(`data-tip="${name}: income ${L.fmt(m.income, 'EUR')}, spending ${L.fmt(m.spending, 'EUR')}, net ${L.fmt(m.net, 'EUR', true)}"`, `${name} spending ${L.fmt(m.spending, 'EUR')}`)} x="${x + 1}" y="${g.y(m.spending)}" width="${bw}" height="${g.y(0) - g.y(m.spending)}" rx="2" fill="${v('negative-fill')}"/>`;
      return `${b1}${b2}<text x="${x}" y="${h - 8}" text-anchor="middle">${name}</text>`;
    }).join('');
    const pts = list.map((m, i) => [left + band * i + band / 2, g.y(Math.max(m.net, 0))]);
    const line = `<polyline points="${pts.map((p) => p.join(',')).join(' ')}" fill="none" stroke="${v('text-primary')}" stroke-width="2"/>${pts.map((p) => `<circle cx="${p[0]}" cy="${p[1]}" r="3.5" fill="${v('surface-1')}" stroke="${v('text-primary')}" stroke-width="2"/>`).join('')}`;
    const last = list[list.length - 1];
    const svg = `<svg viewBox="0 0 ${W} ${h}" aria-hidden="true">${g.lines}${bars}${line}</svg>`;
    const key = `<div class="lg-key-list"><span><i style="background:${v('positive-fill')}"></i>Income</span><span><i style="background:${v('negative-fill')}"></i>Spending</span><span><i style="background:transparent;border:2px solid ${v('text-primary')};border-radius:99px"></i>Net</span></div><div class="lg-chart__tip" data-chart-tip>${D.monthLabel(last.ym)}: income ${L.money(last.income)}, spending ${L.money(last.spending)}, net ${L.money(last.net, 'EUR', { sign: true })}</div>`;
    return frame('How did this month compare?', svg, `Grouped bars of income and spending over ${list.length} months, with a net line. In ${D.monthLabel(last.ym)}, income was ${L.fmt(last.income, 'EUR')}, spending ${L.fmt(last.spending, 'EUR')} and net ${L.fmt(last.net, 'EUR', true)}.`, key);
  };

  // Six slices at most: five ranked categories plus Other when more exist.
  function slices(ym) {
    const r = D.month(ym).ranked;
    const top = r.slice(0, 5);
    const rest = r.slice(5).reduce((s, x) => s + x.amount, 0);
    return top.concat(rest ? [{ cat: 'other', amount: rest, other: true }] : []);
  }
  L.charts.donut = function () {
    const data = slices(D.CURRENT);
    const prev = D.month(D.PREV).byCat;
    const total = data.reduce((s, x) => s + x.amount, 0);
    const R = 80; const r = 54; const c = 100;
    let a = -Math.PI / 2;
    const arcs = data.map((d, i) => {
      const sweep = (d.amount / total) * Math.PI * 2;
      const gap = 0.02;
      const s = a + gap; const e = a + sweep - gap;
      a += sweep;
      const p = (rad, ang) => `${c + rad * Math.cos(ang)} ${c + rad * Math.sin(ang)}`;
      const large = sweep > Math.PI ? 1 : 0;
      const name = d.other ? 'Other' : L.cat(d.cat).name;
      return `<path ${hit(`data-tip="${name}: ${L.fmt(d.amount, 'EUR')}"`, `${name} ${L.fmt(d.amount, 'EUR')}`)} d="M${p(R, s)}A${R} ${R} 0 ${large} 1 ${p(R, e)}L${p(r, e)}A${r} ${r} 0 ${large} 0 ${p(r, s)}Z" fill="${v(d.other ? 'chart-other' : `chart-${i + 1}`)}"/>`;
    }).join('');
    const list = data.map((d, i) => {
      const cat = L.cat(d.cat);
      const name = d.other ? 'Other' : cat.name;
      const change = prev[d.cat] && !d.other ? Math.round(((d.amount - prev[d.cat]) / prev[d.cat]) * 100) : null;
      return `<button type="button" class="lg-rank"><span class="lg-rank__dot" style="background:${v(d.other ? 'chart-other' : `chart-${i + 1}`)}"></span><span class="lg-rank__name">${L.icon(d.other ? 'dots' : cat.icon, 16)}${name}</span><span class="caption lg-faint">${change == null ? '' : `${change > 0 ? '+' : change < 0 ? '−' : ''}${Math.abs(change)}%`}</span><span class="label">${L.money(d.amount)}</span></button>`;
    }).join('');
    const top = data[0];
    const svg = `<div style="max-width:200px;margin:0 auto"><svg viewBox="0 0 200 200" aria-hidden="true">${arcs}<text class="is-label" x="100" y="98" text-anchor="middle" style="font-size:18px">${L.fmtShort(total)}</text><text x="100" y="116" text-anchor="middle">Spending</text></svg></div>`;
    return frame('Where did my money go?', svg, `Donut of October spending, ${L.fmt(total, 'EUR')} in total. Largest is ${L.cat(top.cat).name} at ${L.fmt(top.amount, 'EUR')}.`, `<div style="margin-top:8px">${list}</div>`);
  };

  function lines(question, series, desc, opts) {
    const h = 180; const left = 36; const top = 12; const bottom = 24; const right = 90;
    const all = series.flatMap((s) => s.values);
    const max = niceMax(Math.max(...all));
    const min = opts && opts.floor != null ? opts.floor : 0;
    const zero = min;
    const y = (val) => top + (1 - (val - zero) / (max - zero)) * (h - top - bottom);
    const n = series[0].values.length;
    const x = (i) => left + (i / (n - 1)) * (W - left - right);
    const grid = [zero, (zero + max) / 2, max].map((s) => `<line x1="${left}" x2="${W - right}" y1="${y(s)}" y2="${y(s)}" stroke="${s === zero ? v('chart-axis') : v('chart-grid')}"/><text class="lg-axis-value" x="${left - 8}" y="${y(s) + 4}" text-anchor="end">${L.fmtShort(s)}</text>`).join('');
    const paths = series.map((s, si) => {
      const pts = s.values.map((val, i) => `${x(i)},${y(val)}`).join(' ');
      const end = s.values[n - 1];
      return `<polyline points="${pts}" fill="none" stroke="${v(s.color)}" stroke-width="2" stroke-dasharray="${s.dash || ''}"/><circle cx="${x(n - 1)}" cy="${y(end)}" r="3.5" fill="${v(s.color)}"/><text class="is-label" x="${x(n - 1) + 8}" y="${y(end) + 4 + (s.nudge || 0)}">${s.name}</text>`;
    }).join('');
    const labels = opts.labels.map((l, i) => (i % opts.every === 0 || i === n - 1 ? `<text x="${x(i)}" y="${h - 8}" text-anchor="middle">${l}</text>` : '')).join('');
    return frame(question, `<svg viewBox="0 0 ${W} ${h}" aria-hidden="true">${grid}${paths}${labels}</svg>`, desc);
  }
  L.charts.trends = function () {
    const list = D.series().slice(-6);
    const pick = ['food', 'shopping', 'transport'];
    const dash = ['', '6 4', '2 4'];
    const nudge = [0, 0, 6];
    const series = pick.map((cat, i) => ({ name: L.cat(cat).name, color: `chart-${i + 1}`, dash: dash[i], nudge: nudge[i], values: list.map((m) => m.byCat[cat] || 0) }));
    return lines('Which categories are changing?', series, `Trend lines for ${pick.map((c) => L.cat(c).name).join(', ')} over six months.`, { labels: list.map((m) => D.monthLabel(m.ym)), every: 1 });
  };
  L.charts.balance = function () {
    const list = D.months;
    const values = list.map((ym) => {
      const last = ym === D.CURRENT ? D.TODAY : `${ym}-28`;
      return balanceAt(last);
    });
    const first = values[0]; const end = values[values.length - 1];
    return lines('How has my balance moved?', [{ name: 'Balance', color: 'accent', values }], `Total balance rose from ${L.fmt(first, 'EUR')} to ${L.fmt(end, 'EUR')} over 14 months.`, { labels: list.map(D.monthLabel), every: 3 });
  };
  function balanceAt(date) {
    return D.accounts().reduce((s, a) => s + D.toEur(balanceBefore(a, date), a.cur), 0);
  }
  function balanceBefore(a, date) {
    let sum = a.balance;
    D.transactions.forEach((t) => {
      if (t.date <= date) return;
      if (t.account === a.id) sum -= t.type === 'income' || t.type === 'refund' ? t.amount : -t.amount;
      if (t.to === a.id) sum -= a.cur === t.cur ? t.amount : t.cur === 'EUR' ? Math.round(t.amount * D.PEG) : D.toEur(t.amount, t.cur);
    });
    return sum;
  }
  L.charts.weekday = function () {
    const vals = D.weekdays(D.CURRENT);
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const h = 180; const left = 0; const top = 24; const bottom = 24;
    const max = niceMax(Math.max(...vals));
    const y = (val) => top + (1 - val / max) * (h - top - bottom);
    const band = (W - left) / 7;
    const peak = vals.indexOf(Math.max(...vals));
    const bars = vals.map((val, i) => {
      const x = left + band * i + band * 0.2;
      return `<rect ${hit(`data-tip="${names[i]}: ${L.fmt(val, 'EUR')}"`, `${names[i]} ${L.fmt(val, 'EUR')}`)} x="${x}" y="${y(val)}" width="${band * 0.6}" height="${y(0) - y(val)}" rx="2" fill="${v(i === peak ? 'negative-fill' : 'neutral-fill')}"/><text class="is-label lg-axis-value" x="${x + band * 0.3}" y="${y(val) - 6}" text-anchor="middle">${L.fmtShort(val)}</text><text x="${x + band * 0.3}" y="${h - 8}" text-anchor="middle">${names[i]}</text>`;
    }).join('');
    return frame('Which days cost the most?', `<svg viewBox="0 0 ${W} ${h}" aria-hidden="true"><line x1="${left}" x2="${W}" y1="${y(0)}" y2="${y(0)}" stroke="${v('chart-axis')}"/>${bars}</svg>`, `October spending by weekday. ${names[peak]} is highest at ${L.fmt(vals[peak], 'EUR')}.`);
  };

  // Heat steps come from the spend relative to a fixed set of EUR limits.
  L.heatStep = (minor) => (minor <= 0 ? 0 : minor < 2000 ? 1 : minor < 5000 ? 2 : minor < 10000 ? 3 : minor < 30000 ? 4 : 5);
  L.heatKey = () => `<div class="lg-heat-key"><span style="margin-right:4px">Spent less</span>${[0, 1, 2, 3, 4, 5].map((i) => `<i style="background:var(--heat-${i})"></i>`).join('')}<span style="margin-left:4px">Spent more</span></div>`;
  function dayFacts(date) {
    const list = D.transactions.filter((t) => t.date === date);
    const spend = D.daySpend(date);
    const income = list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0), 0);
    const net = income - spend;
    const cats = {};
    list.forEach((t) => { if (t.cat && D.counted(t) > 0) cats[t.cat] = (cats[t.cat] || 0) + D.counted(t); });
    const cat = Object.keys(cats).sort((a, b) => cats[b] - cats[a])[0];
    return { list, spend, income, net, cat };
  }
  const dayTip = (date, f) => `${D.dayLabel(date)}: spent ${L.fmt(f.spend, 'EUR')}, income ${L.fmt(f.income, 'EUR')}, net ${L.fmt(f.net, 'EUR', f.net > 0)}`;

  // The grid runs Monday to Sunday and includes the days around the month, so it has no gaps.
  L.charts.calendar = function (selected) {
    const start = new Date('2026-09-28T12:00:00Z');
    const heads = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => `<div class="lg-cal__head">${d}</div>`).join('');
    const cells = Array.from({ length: 35 }, (_, i) => {
      const dt = new Date(start.getTime() + i * 864e5);
      const date = dt.toISOString().slice(0, 10);
      const day = dt.getUTCDate();
      const outside = !date.startsWith(D.CURRENT);
      if (date > D.TODAY) {
        const planned = D.RECURRING.filter((r) => r.date === date && r.state === 'planned');
        if (!planned.length) return L.ui.dayCell({ day, state: 'disabled' });
        const sum = planned.reduce((s, r) => s + D.toEur(r.amount, r.cur), 0);
        return L.ui.dayCell({ day, date, outside, planned: true, amount: L.fmtCell(-sum), full: L.fmt(-sum, 'EUR'), marks: ['planned'], cat: planned[0].cat, label: `${day}, planned ${L.fmt(-sum, 'EUR')}`, tip: `${planned[0].name} is planned for this day, ${L.fmt(-sum, 'EUR')}` });
      }
      const f = dayFacts(date);
      const marks = [];
      if (f.list.some((t) => t.flags.includes('recurring')) || D.RECURRING.some((r) => r.date === date && r.state === 'due')) marks.push('recurring');
      if (f.income) marks.push('income');
      if (f.spend >= 30000) marks.push('high');
      const n = f.list.length;
      return L.ui.dayCell({
        day, date, outside, marks, cat: f.cat, today: date === D.TODAY, selected: date === selected,
        heat: L.heatStep(f.spend), up: f.net > 0, amount: L.fmtCell(f.net), full: L.fmt(f.net, 'EUR', f.net > 0),
        count: n ? `${n} ${n === 1 ? 'entry' : 'entries'}` : '', label: dayTip(date, f), tip: dayTip(date, f),
      });
    }).join('');
    return `<div class="lg-calwrap"><div class="lg-cal" role="group" aria-label="October 2026">${heads}${cells}</div></div>`;
  };
  L.calSummary = function () {
    const m = D.month(D.CURRENT);
    const cell = (label, html) => `<div><div class="caption lg-faint">${label}</div><div class="amount">${html}</div></div>`;
    return `<div class="lg-calsum">${cell('Spent', L.money(-m.spending, 'EUR', { tone: 'negative' }))}${cell('Income', L.money(m.income, 'EUR', { sign: true, tone: 'positive' }))}${cell('Net', L.money(m.net, 'EUR', { sign: true, tone: m.net >= 0 ? 'positive' : 'negative' }))}</div>`;
  };
  L.calKey = () => `<div class="lg-stack" style="gap:8px">${L.heatKey()}<div class="lg-key-list" style="margin:0"><span><i style="background:var(--positive-tint);border:1px solid var(--positive)"></i>Net gain</span><span>${L.icon('repeat', 16)}Recurring</span><span>${L.icon('up', 16)}Income</span><span>${L.icon('flag', 16)}€300 or more</span><span>${L.icon('clock', 16)}Planned</span></div></div>`;
  L.charts.calendarFull = function (selected) {
    const f = dayFacts(selected);
    return `<figure class="lg-chart lg-stack" style="margin:0"><figcaption class="lg-chart__q" style="margin:0">How did October go?</figcaption>${L.calSummary()}${L.charts.calendar(selected)}${L.calKey()}<div class="lg-chart__tip" data-chart-tip style="margin:0">${dayTip(selected, f)}</div></figure>`;
  };

  // Year ledger: one line per month, like the lines of a ledger. Spending rises above the line,
  // income hangs below it, and days share a column, so rent and payday line up down the year.
  const STEP_HEIGHT = [0, 5, 10, 15, 20, 24];
  const LINE = 25;
  function ledgerLine(ym) {
    const [y, m] = ym.split('-').map(Number);
    const days = new Date(Date.UTC(y, m, 0)).getUTCDate();
    let marks = '';
    for (let d = 1; d <= days; d++) {
      const date = `${ym}-${String(d).padStart(2, '0')}`;
      if (date <= D.TODAY) {
        const f = dayFacts(date);
        const step = L.heatStep(f.spend);
        const x = (d - 1) * 6 + 1;
        if (step) marks += `<rect x="${x}" y="${LINE - STEP_HEIGHT[step]}" width="4" height="${STEP_HEIGHT[step]}" fill="${v(step === 5 ? 'negative' : 'negative-fill')}"/>`;
        if (f.income) marks += `<rect x="${x}" y="${LINE + 2}" width="4" height="8" fill="${v('positive-fill')}"/>`;
      }
    }
    return `<svg class="lg-year__line" viewBox="0 0 186 36" preserveAspectRatio="none" aria-hidden="true"><line x1="0" x2="186" y1="${LINE}" y2="${LINE}" stroke="${v('chart-axis')}" vector-effect="non-scaling-stroke"/>${marks}</svg>`;
  }
  function monthTip(ym) {
    const m = D.month(ym);
    const days = [...new Set(m.list.map((t) => t.date))];
    const peak = days.sort((a, b) => D.daySpend(b) - D.daySpend(a))[0];
    return `${D.monthLabel(ym)}: spent ${L.fmt(m.spending, 'EUR')}, income ${L.fmt(m.income, 'EUR')}, net ${L.fmt(m.net, 'EUR', true)}. Busiest day ${D.dayLabel(peak)}, ${L.fmt(D.daySpend(peak), 'EUR')}.`;
  }
  L.charts.year = function () {
    const list = D.months.slice(-12);
    const total = list.reduce((s, ym) => s + D.month(ym).spending, 0);
    const ruler = `<div class="lg-year__row lg-year__row--ruler" aria-hidden="true"><span></span><span class="lg-year__days">${[1, 8, 15, 22, 29].map((d) => `<span style="left:${((d - 1) / 31) * 100}%">${d}</span>`).join('')}</span><span></span></div>`;
    const rows = list.map((ym) => {
      const m = D.month(ym);
      return `<button type="button" class="lg-year__row" aria-pressed="${ym === D.CURRENT}" aria-label="${monthTip(ym)}" data-tip="${monthTip(ym)}"><span class="lg-year__month">${D.monthLabel(ym)}</span>${ledgerLine(ym)}<span class="lg-year__total money money--negative">${L.fmtWhole(-m.spending)}</span></button>`;
    }).join('');
    const key = `<div class="lg-key-list"><span><i style="background:${v('negative-fill')}"></i>Spent, taller is more</span><span><i style="background:${v('positive-fill')}"></i>Income, below the line</span><span><i style="background:${v('negative')}"></i>€300 or more</span></div>`;
    return `<figure class="lg-chart lg-year" style="margin:0"><figcaption class="lg-chart__q">How did the year move?</figcaption><p class="lg-chart__sub">${L.fmt(total, 'EUR')} spent over 12 months. Each line is a month, days 1 to 31.</p>${ruler}${rows}${key}<div class="lg-chart__tip" data-chart-tip>${monthTip(D.CURRENT)}</div></figure>`;
  };
  L.charts.empty = (q) => `<figure class="lg-chart" style="margin:0"><figcaption class="lg-chart__q">${q}</figcaption><div class="lg-state">${L.stateMark('chart')}<p>A chart appears after your first month of entries.</p></div></figure>`;
})(window.Ledgerly = window.Ledgerly || {});
