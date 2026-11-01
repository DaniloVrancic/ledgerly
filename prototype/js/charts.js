// The system's one chart style, taking any date range. Every mark is a focusable button that
// opens the exact transactions behind it. Colours come from tokens; slot 1 is the largest item.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st;
  const { act, esc } = P;
  const W = 320;
  const v = (n) => `var(--${n})`;
  const C = (P.ch = {});

  const niceMax = (m) => { const p = 10 ** Math.floor(Math.log10(m || 1)); return [1, 2, 2.5, 5, 10].map((x) => x * p).find((x) => x >= m); };
  const frame = (q, svg, desc, foot) => `<figure class="lg-chart" style="margin:0"><figcaption class="lg-chart__q">${q}</figcaption><div role="img" aria-label="${esc(desc)}">${svg}</div>${foot || ''}</figure>`;
  const hit = (name, arg, label, sel) => `class="is-hit" tabindex="0" role="button" aria-label="${esc(label)}" ${act(name, JSON.stringify(arg))} ${sel ? 'data-selected="true"' : ''}`;
  const isSel = (id) => st.an.selected === id;
  function pick(id, title, sub, filter) { return { id, title, sub, filter }; }

  // Opens the entries behind a mark in a sheet, with its figures at the top.
  P.acts.chartPick = (json) => { const p = JSON.parse(json); st.an.selected = p.id; P.sheet('chartTx', p); };
  P.sheets.chartTx = function (p) {
    const list = G.filterTx(p.filter);
    const total = list.reduce((s, t) => s + G.countedFor(t, p.filter.cat), 0);
    const income = list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0), 0);
    return `<div class="lg-between"><h3 style="margin:0">${esc(p.title)}</h3>${P.iconBtn('x', 'Close', 'closeSheet')}</div>
      <p style="margin:0 0 8px">${esc(p.sub || '')}</p>
      <div class="lg-between" style="margin-bottom:8px"><span class="body-small lg-muted">${list.length} ${list.length === 1 ? 'entry' : 'entries'}</span><span class="label">${total ? P.eur(-total, { tone: 'negative' }) : ''} ${income ? P.eur(income, { sign: true, tone: 'positive' }) : ''}</span></div>
      <div class="lg-card lg-card--flush">${list.slice(0, 60).map((t) => P.txRow(t)).join('') || '<div class="lg-state"><p>No entries here.</p></div>'}</div>
      ${list.length > 60 ? `<p class="p-note" style="margin-top:8px">Showing the first 60.</p>` : ''}
      <div style="height:12px"></div>${P.btn('Open in Transactions', 'chartOpen', null, { block: true, kind: 'secondary' })}`;
  };
  P.acts.chartOpen = () => { const p = st.sheet.arg; st.sheet = null; P.drill(Object.assign({ label: p.title }, p.filter)); };

  function grid(h, top, bottom, max, left, right) {
    const y = (val) => top + (1 - val / max) * (h - top - bottom);
    const lines = [0, max / 2, max].map((s) => `<line x1="${left}" x2="${W - (right || 0)}" y1="${y(s)}" y2="${y(s)}" stroke="${s === 0 ? v('chart-axis') : v('chart-grid')}"/><text class="lg-axis-value" x="${left - 8}" y="${y(s) + 4}" text-anchor="end">${L.fmtShort(s)}</text>`).join('');
    return { y, lines };
  }

  // Grouped bars start at zero. The net line shares the axis, so there is no second scale.
  C.grouped = function (months, q) {
    const list = months.map((p) => Object.assign({ p }, G.periodStats(p)));
    const h = 200; const left = 36; const top = 12; const bottom = 24;
    const max = niceMax(Math.max(...list.map((m) => Math.max(m.income, m.spending))));
    const g = grid(h, top, bottom, max, left);
    const band = (W - left) / list.length;
    const bw = Math.min(16, band * 0.36);
    const bars = list.map((m, i) => {
      const x = left + band * i + band / 2;
      const name = m.p.short;
      const a = pick(`i${m.p.key}`, `Income, ${m.p.label}`, `Income ${L.fmt(m.income, 'EUR')}, spending ${L.fmt(m.spending, 'EUR')}, net ${L.fmt(m.net, 'EUR', true)}`, { income: true, start: m.p.start, end: m.p.end });
      const b = pick(`s${m.p.key}`, `Spending, ${m.p.label}`, `Income ${L.fmt(m.income, 'EUR')}, spending ${L.fmt(m.spending, 'EUR')}, net ${L.fmt(m.net, 'EUR', true)}`, { spending: true, start: m.p.start, end: m.p.end });
      return `<rect ${hit('chartPick', a, `${name} income ${L.fmt(m.income, 'EUR')}`, isSel(a.id))} x="${x - bw - 1}" y="${g.y(m.income)}" width="${bw}" height="${Math.max(0, g.y(0) - g.y(m.income))}" rx="2" fill="${v('positive-fill')}"/><rect ${hit('chartPick', b, `${name} spending ${L.fmt(m.spending, 'EUR')}`, isSel(b.id))} x="${x + 1}" y="${g.y(m.spending)}" width="${bw}" height="${Math.max(0, g.y(0) - g.y(m.spending))}" rx="2" fill="${v('negative-fill')}"/>${list.length <= 8 || i % 2 === 0 ? `<text x="${x}" y="${h - 8}" text-anchor="middle">${name}</text>` : ''}`;
    }).join('');
    const pts = list.map((m, i) => [left + band * i + band / 2, g.y(Math.max(m.net, 0))]);
    const line = `<polyline points="${pts.map((p) => p.join(',')).join(' ')}" fill="none" stroke="${v('text-primary')}" stroke-width="2"/>${pts.map((p) => `<circle cx="${p[0]}" cy="${p[1]}" r="3" fill="${v('surface-1')}" stroke="${v('text-primary')}" stroke-width="2"/>`).join('')}`;
    const last = list[list.length - 1];
    const key = `<div class="lg-key-list"><span><i style="background:${v('positive-fill')}"></i>Income</span><span><i style="background:${v('negative-fill')}"></i>Spending</span><span><i style="background:transparent;border:2px solid ${v('text-primary')};border-radius:99px"></i>Net</span></div><div class="lg-chart__tip">${last.p.short}: income ${P.eur(last.income)}, spending ${P.eur(last.spending)}, net ${P.eur(last.net, { sign: true })}</div>`;
    return frame(q || 'How did this month compare?', `<svg viewBox="0 0 ${W} ${h}" aria-hidden="false">${g.lines}${bars}${line}</svg>`, `Grouped bars of income and spending over ${list.length} months, with a net line. In ${last.p.short}, income was ${L.fmt(last.income, 'EUR')}, spending ${L.fmt(last.spending, 'EUR')} and net ${L.fmt(last.net, 'EUR', true)}.`, key);
  };

  // Six slices at most: five ranked categories plus Other when more exist.
  C.donut = function (r, prevStats) {
    const s = G.stats(r.start, r.end);
    const top = s.ranked.slice(0, 5);
    const rest = s.ranked.slice(5);
    const other = rest.reduce((n, x) => n + x.amount, 0) + s.uncategorised;
    const data = top.concat(other > 0 ? [{ cat: 'other', amount: other, other: true }] : []);
    const total = data.reduce((n, x) => n + x.amount, 0);
    if (!total) return C.empty('Where did my money go?');
    const R = 80; const ri = 54; const c = 100;
    let a = -Math.PI / 2;
    const color = (d, i) => v(d.other ? 'chart-other' : `chart-${i + 1}`);
    const name = (d) => (d.other ? 'Other' : L.cat(d.cat).name);
    const filterOf = (d) => (d.other ? { spending: true, start: r.start, end: r.end, otherThan: top.map((x) => x.cat) } : { cat: d.cat, spending: true, start: r.start, end: r.end });
    const arcs = data.map((d, i) => {
      const sweep = (d.amount / total) * Math.PI * 2;
      const e0 = a + 0.02; const e1 = a + sweep - 0.02;
      a += sweep;
      const p = (rad, ang) => `${c + rad * Math.cos(ang)} ${c + rad * Math.sin(ang)}`;
      const large = sweep > Math.PI ? 1 : 0;
      const m = pick(`d${d.cat}`, `${name(d)}, ${r.label}`, `${L.fmt(d.amount, 'EUR')}, ${Math.round((d.amount / total) * 100)}% of spending`, filterOf(d));
      return `<path ${hit('chartPick', m, `${name(d)} ${L.fmt(d.amount, 'EUR')}`, isSel(m.id))} d="M${p(R, e0)}A${R} ${R} 0 ${large} 1 ${p(R, e1)}L${p(ri, e1)}A${ri} ${ri} 0 ${large} 0 ${p(ri, e0)}Z" fill="${color(d, i)}"/>`;
    }).join('');
    const prev = prevStats ? prevStats.byCat : {};
    const list = data.map((d, i) => {
      const cat = L.cat(d.cat);
      const change = prev[d.cat] && !d.other ? Math.round(((d.amount - prev[d.cat]) / prev[d.cat]) * 100) : null;
      const open = d.other ? act('chartPick', JSON.stringify(pick('dother', `Other, ${r.label}`, L.fmt(d.amount, 'EUR'), filterOf(d)))) : act('go', `catan:${d.cat}`);
      return `<button type="button" class="lg-rank" ${open}><span class="lg-rank__dot" style="background:${color(d, i)}"></span><span class="lg-rank__name">${L.icon(d.other ? 'dots' : cat.icon, 16)}${esc(name(d))}</span><span class="caption lg-faint">${change == null ? '' : `${change > 0 ? '+' : change < 0 ? '−' : ''}${Math.abs(change)}%`}</span><span class="label">${P.eur(d.amount)}</span></button>`;
    }).join('');
    const svg = `<div style="max-width:200px;margin:0 auto"><svg viewBox="0 0 200 200">${arcs}<text class="is-label lg-axis-value" x="100" y="98" text-anchor="middle" style="font-size:18px">${L.fmtShort(total)}</text><text x="100" y="116" text-anchor="middle">Spending</text></svg></div>`;
    return frame('Where did my money go?', svg, `Donut of spending, ${L.fmt(total, 'EUR')} in total. Largest is ${name(data[0])} at ${L.fmt(data[0].amount, 'EUR')}.`, `<div style="margin-top:8px">${list}</div>`);
  };

  function lines(q, series, desc, o) {
    const h = 180; const left = 36; const top = 12; const bottom = 24; const right = o.right == null ? 90 : o.right;
    const n = series[0].values.length;
    const all = series.flatMap((s) => s.values);
    const low = Math.min(0, ...all);
    const max = niceMax(Math.max(...all, 1));
    const y = (val) => top + (1 - (val - low) / (max - low)) * (h - top - bottom);
    const x = (i) => left + (n > 1 ? (i / (n - 1)) * (W - left - right) : 0);
    const fmtAxis = o.percent ? (s) => `${Math.round(s)}%` : L.fmtShort;
    const ticks = [low, (low + max) / 2, max].map((s) => `<line x1="${left}" x2="${W - right}" y1="${y(s)}" y2="${y(s)}" stroke="${s === low ? v('chart-axis') : v('chart-grid')}"/><text class="lg-axis-value" x="${left - 8}" y="${y(s) + 4}" text-anchor="end">${fmtAxis(s)}</text>`).join('');
    const paths = series.map((s) => {
      const pts = s.values.map((val, i) => `${x(i)},${y(val)}`).join(' ');
      const end = s.values[n - 1];
      const dots = s.values.map((val, i) => {
        const m = s.pick(i);
        return `<circle ${hit('chartPick', m, m.sub, isSel(m.id))} cx="${x(i)}" cy="${y(val)}" r="${i === n - 1 ? 4 : 3}" fill="${i === n - 1 ? v(s.color) : v('surface-1')}" stroke="${v(s.color)}" stroke-width="2"/>`;
      }).join('');
      return `<polyline points="${pts}" fill="none" stroke="${v(s.color)}" stroke-width="2" stroke-dasharray="${s.dash || ''}"/>${dots}${right ? `<text class="is-label" x="${x(n - 1) + 8}" y="${y(end) + 4 + (s.nudge || 0)}">${esc(s.name)}</text>` : ''}`;
    }).join('');
    const every = Math.max(1, Math.ceil(n / 6));
    const labels = o.labels.map((l, i) => (i % every === 0 || i === n - 1 ? `<text x="${x(i)}" y="${h - 8}" text-anchor="middle">${l}</text>` : '')).join('');
    return frame(q, `<svg viewBox="0 0 ${W} ${h}">${ticks}${paths}${labels}</svg>`, desc, o.foot);
  }
  C.trends = function (months, cats) {
    const rows = months.map((p) => Object.assign({ p }, G.periodStats(p)));
    const dash = ['', '6 4', '2 4']; const nudge = [0, 8, -8];
    const series = cats.map((cat, i) => ({
      name: L.cat(cat).name, color: `chart-${i + 1}`, dash: dash[i], nudge: nudge[i], values: rows.map((m) => m.byCat[cat] || m.bySub[cat] || 0),
      pick: (k) => pick(`t${cat}${rows[k].p.key}`, `${L.cat(cat).name}, ${rows[k].p.label}`, L.fmt(rows[k].byCat[cat] || rows[k].bySub[cat] || 0, 'EUR'), { cat, spending: true, start: rows[k].p.start, end: rows[k].p.end }),
    }));
    if (!series.length) return C.empty('Which categories are changing?');
    return lines('Which categories are changing?', series, `Trend lines for ${cats.map((c) => L.cat(c).name).join(', ')} over ${rows.length} months.`, { labels: rows.map((m) => m.p.short) });
  };
  C.balance = function (months) {
    const pts = months.map((p) => { const date = p.end > G.TODAY ? G.TODAY : p.end; return { p, date, value: G.totalAt(date) }; });
    const series = [{ name: 'Balance', color: 'accent', values: pts.map((x) => x.value), pick: (k) => pick(`b${pts[k].p.key}`, `Entries, ${pts[k].p.label}`, `Balance on ${G.shortDate(pts[k].date)}: ${L.fmt(pts[k].value, 'EUR')}`, { start: pts[k].p.start, end: pts[k].p.end }) }];
    const first = pts[0].value; const end = pts[pts.length - 1].value;
    return lines('How has my balance moved?', series, `Total balance moved from ${L.fmt(first, 'EUR')} to ${L.fmt(end, 'EUR')} over ${pts.length} months.`, { labels: pts.map((x) => x.p.short), right: 64, foot: `<p class="lg-chart__note">${L.fmt(end - first, 'EUR', true)} over ${pts.length} months. Transfers between accounts do not change it.</p>` });
  };
  C.savings = function (months) {
    const rows = months.map((p) => Object.assign({ p }, G.periodStats(p)));
    const vals = rows.map((m) => Math.round(m.rate * 100));
    const series = [{ name: 'Rate', color: 'chart-1', values: vals, pick: (k) => pick(`r${rows[k].p.key}`, `Entries, ${rows[k].p.label}`, `Savings rate ${vals[k]}%, net ${L.fmt(rows[k].net, 'EUR', true)} of ${L.fmt(rows[k].income, 'EUR')} income`, { start: rows[k].p.start, end: rows[k].p.end }) }];
    const avg = Math.round(vals.reduce((a, b) => a + b, 0) / vals.length);
    return lines('How much am I keeping?', series, `Savings rate by month, averaging ${avg}%.`, { percent: true, labels: rows.map((m) => m.p.short), right: 44, foot: `<p class="lg-chart__note">Average ${avg}%. Net divided by income, month by month.</p>` });
  };
  C.weekday = function (r) {
    const vals = [0, 0, 0, 0, 0, 0, 0];
    G.stats(r.start, r.end).list.forEach((t) => { vals[G.weekdayOf(t.date)] += D.counted(t); });
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const h = 180; const top = 24; const bottom = 24;
    const max = niceMax(Math.max(...vals, 1));
    const y = (val) => top + (1 - val / max) * (h - top - bottom);
    const band = W / 7;
    const peak = vals.indexOf(Math.max(...vals));
    const bars = vals.map((val, i) => {
      const x = band * i + band * 0.2;
      const m = pick(`w${i}`, `${names[i]}, ${r.label}`, `${L.fmt(val, 'EUR')} of spending`, { weekday: i, spending: true, start: r.start, end: r.end });
      return `<rect ${hit('chartPick', m, `${names[i]} ${L.fmt(val, 'EUR')}`, isSel(m.id))} x="${x}" y="${y(val)}" width="${band * 0.6}" height="${Math.max(0, y(0) - y(val))}" rx="2" fill="${v(i === peak ? 'negative-fill' : 'neutral-fill')}"/><text class="is-label lg-axis-value" x="${x + band * 0.3}" y="${y(val) - 6}" text-anchor="middle">${L.fmtShort(val)}</text><text x="${x + band * 0.3}" y="${h - 8}" text-anchor="middle">${names[i]}</text>`;
    }).join('');
    return frame('Which days cost the most?', `<svg viewBox="0 0 ${W} ${h}"><line x1="0" x2="${W}" y1="${y(0)}" y2="${y(0)}" stroke="${v('chart-axis')}"/>${bars}</svg>`, `Spending by weekday. ${names[peak]} is highest at ${L.fmt(vals[peak], 'EUR')}.`);
  };
  C.mix = function (r) {
    const o = G.costTypes(r.start, r.end);
    const total = o.fixed + o.recurring + o.variable;
    if (!total) return C.empty('What can I actually change?');
    const parts = [['fixed', 'Fixed', 'Rent and bills', 'chart-1'], ['recurring', 'Recurring', 'Subscriptions and memberships', 'chart-2'], ['variable', 'Variable', 'Everything day to day', 'chart-3']];
    const mk = ([id, name], amt) => pick(`m${id}`, `${name} costs, ${r.label}`, `${L.fmt(amt, 'EUR')}, ${Math.round((amt / total) * 100)}% of spending`, { cost: id, start: r.start, end: r.end });
    const bar = `<div class="p-mix" role="group" aria-label="Fixed, recurring and variable costs">${parts.map((p) => `<button type="button" style="flex:${o[p[0]]} 1 0;background:${v(p[3])}" aria-label="${p[1]} ${L.fmt(o[p[0]], 'EUR')}" ${act('chartPick', JSON.stringify(mk(p, o[p[0]])))}></button>`).join('')}</div>`;
    const rows = parts.map((p) => `<button type="button" class="lg-rank" ${act('chartPick', JSON.stringify(mk(p, o[p[0]])))}><span class="lg-rank__dot" style="background:${v(p[3])}"></span><span class="lg-rank__name" style="flex-direction:column;align-items:flex-start;gap:0"><span>${p[1]}</span><span class="caption lg-faint">${p[2]}</span></span><span class="caption lg-faint">${Math.round((o[p[0]] / total) * 100)}%</span><span class="label">${P.eur(o[p[0]])}</span></button>`).join('');
    return `<figure class="lg-chart" style="margin:0"><figcaption class="lg-chart__q">What can I actually change?</figcaption>${bar}${rows}</figure>`;
  };
  C.largest = function (r) {
    const list = G.stats(r.start, r.end).list.filter((t) => D.counted(t) > 0).sort((a, b) => D.counted(b) - D.counted(a)).slice(0, 5);
    return `<figure class="lg-chart" style="margin:0"><figcaption class="lg-chart__q">What were the biggest payments?</figcaption><div style="margin:0 -16px -16px">${list.map((t) => P.txRow(t)).join('') || '<div class="lg-state"><p>No spending in this period.</p></div>'}</div></figure>`;
  };
  C.empty = (q) => L.charts.empty(q);
  C.bars = function (rows, q, name) {
    const h = 170; const left = 36; const top = 12; const bottom = 24;
    const max = niceMax(Math.max(...rows.map((r) => r.value), 1));
    const g = grid(h, top, bottom, max, left);
    const band = (W - left) / rows.length;
    const bars = rows.map((r, i) => {
      const x = left + band * i + band * 0.2;
      return `<rect ${hit('chartPick', r.pick, `${r.label} ${L.fmt(r.value, 'EUR')}`, isSel(r.pick.id))} x="${x}" y="${g.y(r.value)}" width="${band * 0.6}" height="${Math.max(0, g.y(0) - g.y(r.value))}" rx="2" fill="${v(r.limit && r.value > r.limit ? 'negative-fill' : i === rows.length - 1 ? 'chart-1' : 'neutral-fill')}"/><text x="${x + band * 0.3}" y="${h - 8}" text-anchor="middle">${r.label}</text>`;
    }).join('');
    const limit = rows[0] && rows[0].limit ? `<line x1="${left}" x2="${W}" y1="${g.y(rows[0].limit)}" y2="${g.y(rows[0].limit)}" stroke="${v('text-primary')}" stroke-dasharray="6 4"/>` : '';
    return frame(q, `<svg viewBox="0 0 ${W} ${h}">${g.lines}${bars}${limit}</svg>`, `${name || q}: ${rows.map((r) => `${r.label} ${L.fmt(r.value, 'EUR')}`).join(', ')}.`);
  };
})(window.Ledgerly);
