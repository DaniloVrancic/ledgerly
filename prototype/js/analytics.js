// Analytics: eight views in four sections, one shared range, a clear comparison, and every
// chart leading to its transactions. Category analytics opens from the ranked list.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st;
  const { act, esc } = P;
  const SECTIONS = [{ id: 'overview', label: 'Overview' }, { id: 'categories', label: 'Categories' }, { id: 'patterns', label: 'Patterns' }, { id: 'progress', label: 'Progress' }];
  const SPAN = { month: 1, quarter: 3, year: 12 };

  function periods(end, n) {
    const out = []; let p = end;
    for (let i = 0; i < n; i++) { out.unshift(p); p = G.prevPeriod(p); }
    return out;
  }
  function ranges() {
    const n = SPAN[st.an.range];
    let end = G.current();
    for (let i = 0; i < st.an.offset * n; i++) end = G.prevPeriod(end);
    const list = periods(end, n);
    const prevEnd = G.prevPeriod(list[0]);
    const prev = periods(prevEnd, n);
    const name = (l) => (l.length === 1 ? l[0].label : `${l[0].short} ${l[0].start.slice(0, 4)} to ${l[l.length - 1].short} ${l[l.length - 1].end.slice(0, 4)}`);
    const firstKnown = D.months[0];
    const hasPrev = prev[0].end.slice(0, 7) >= firstKnown && prev[0].start.slice(0, 7) >= firstKnown;
    return {
      cur: { start: list[0].start, end: list[list.length - 1].end, label: name(list), short: list.length === 1 ? list[0].short : name(list) },
      prev: { start: prev[0].start, end: prev[prev.length - 1].end, label: name(prev), short: prev.length === 1 ? prev[0].short : 'previous period' },
      hasPrev, end, canBack: G.prevPeriod(list[0]).start.slice(0, 7) >= firstKnown, canNext: st.an.offset > 0,
      history: periods(end, st.an.range === 'year' ? 12 : 6).filter((p) => p.end.slice(0, 7) >= firstKnown),
    };
  }
  function tiles(r) {
    const s = G.stats(r.cur.start, r.cur.end); const b = G.stats(r.prev.start, r.prev.end);
    const d = (x, y) => (r.hasPrev ? `${x >= y ? '+' : '−'}${L.fmt(Math.abs(x - y), 'EUR')} vs ${r.prev.short}` : 'No earlier period');
    const span = { start: r.cur.start, end: r.cur.end };
    const lg = (v) => L.fmt(v, 'EUR').length > 10;
    return `<div class="${P.isDesk() ? 'app__tiles' : 'lg-metrics'}">
      ${P.metric('Income', P.eur(s.income, { sign: true, tone: 'positive' }), { delta: d(s.income, b.income), long: lg(s.income), drill: Object.assign({ income: true, label: `Income, ${r.cur.label}` }, span) })}
      ${P.metric('Spending', P.eur(-s.spending, { tone: 'negative' }), { delta: d(s.spending, b.spending), long: lg(s.spending), drill: Object.assign({ spending: true, label: `Spending, ${r.cur.label}` }, span) })}
      ${P.metric('Net', P.eur(s.net, { sign: true, tone: s.net >= 0 ? 'positive' : 'negative' }), { delta: d(s.net, b.net), long: lg(s.net), drill: Object.assign({ label: `All entries, ${r.cur.label}` }, span) })}
      ${P.metric('Savings rate', `<span class="money">${Math.round(s.rate * 100)}%</span>`, { delta: r.hasPrev ? `${Math.round(b.rate * 100)}% in ${r.prev.short}` : 'No earlier period', drill: Object.assign({ label: `All entries, ${r.cur.label}` }, span) })}
    </div>`;
  }
  const insightCard = (r) => {
    const list = G.insights(r.end).slice(0, 2);
    if (!list.length) return '';
    return `<div class="lg-card lg-stack" style="gap:4px">${list.map((n) => `<div class="p-note">${esc(n.text)}</div>`).join('')}</div>`;
  };
  function trendPicker() {
    const opts = G.periodStats(G.current()).ranked.slice(0, 7).map((x) => x.cat);
    st.an.trend.forEach((c) => { if (!opts.includes(c)) opts.push(c); });
    return `<div class="lg-add__pills" style="margin-top:8px" role="group" aria-label="Categories to compare">${opts.map((c) => P.pill(esc(L.cat(c).name), st.an.trend.includes(c), 'anTrend', c)).join('')}</div>`;
  }
  P.acts.anTrend = (c) => {
    const t = st.an.trend;
    if (t.includes(c)) { if (t.length > 1) t.splice(t.indexOf(c), 1); } else { t.push(c); if (t.length > 3) t.shift(); }
    P.render();
  };
  const card = (html, wide) => `<div class="lg-card" ${wide ? 'style="grid-column:1/-1"' : ''}>${html}</div>`;
  function section(id, r) {
    if (id === 'overview') {
      const chart = P.ch.grouped(r.history, 'How did this month compare?');
      if (!P.isWide()) return card(chart);
      const rows = r.history.slice().reverse().map((p) => { const s = G.periodStats(p); return `<tr tabindex="0" ${act('drill', P.drillArg({ start: p.start, end: p.end, label: `All entries, ${p.label}` }))}><td>${esc(p.label)}</td><td data-end>${P.eur(s.income)}</td><td data-end>${P.eur(s.spending)}</td><td data-end>${P.eur(s.net, { sign: true, tone: s.net >= 0 ? 'positive' : 'negative' })}</td></tr>`; }).join('');
      const head = ['Month', 'Income', 'Spending', 'Net'].map((h, i) => `<th ${i ? 'data-end' : ''}><button type="button" tabindex="-1">${h}</button></th>`).join('');
      return `<div class="lg-card" style="grid-column:1/-1"><div class="lg-grid-2" style="align-items:center">${chart}<div class="p-scrollbox"><table class="p-table"><thead><tr>${head}</tr></thead><tbody>${rows}</tbody></table></div></div></div>`;
    }
    if (id === 'categories') return `${card(P.ch.donut(r.cur, r.hasPrev ? G.stats(r.prev.start, r.prev.end) : null))}${card(`${P.ch.trends(r.history, st.an.trend)}${trendPicker()}`)}`;
    if (id === 'patterns') return `${card(P.ch.weekday(r.cur))}${card(P.ch.mix(r.cur))}${card(P.ch.largest(r.cur))}`;
    return `${card(P.ch.balance(r.history))}${card(P.ch.savings(r.history))}`;
  }
  P.views.analytics = function () {
    const r = ranges();
    const wide = P.isWide();
    const nav = `${P.iconBtn('chevron', 'Earlier', 'anShift', 1).replace('<svg', '<svg style="transform:rotate(180deg)"').replace('<button', r.canBack ? '<button' : '<button disabled')}${P.iconBtn('chevron', 'Later', 'anShift', -1).replace('<button', r.canNext ? '<button' : '<button disabled')}`;
    const selector = `<div class="app__sticky"><div class="lg-between" style="flex-wrap:nowrap"><div style="flex:1 1 auto;max-width:22rem">${P.seg([{ label: 'Month', id: 'month' }, { label: 'Quarter', id: 'quarter' }, { label: 'Year', id: 'year' }], st.an.range, 'anRange', 'Range')}</div><span style="display:inline-flex">${nav}</span></div><div class="body-small lg-muted">${r.cur.label}, ${r.hasPrev ? `compared with ${r.prev.label}` : 'no earlier period to compare'}</div></div>`;
    const head = P.screenHead('Analytics');
    if (wide) {
      const groups = SECTIONS.map((s) => `${P.section(s.label)}<div class="lg-grid-2">${section(s.id, r)}</div>`).join('');
      return `<div class="app__scroll" data-scroll>${head}${selector}<div class="app__body app__wide">${tiles(r)}${insightCard(r)}${groups}</div></div>`;
    }
    const tabs = `<div style="padding:0 12px">${P.seg(SECTIONS, st.an.section, 'anSection', 'Section')}</div>`;
    return `<div class="app__scroll" data-scroll>${head}${selector}<div class="app__body">${st.an.section === 'overview' ? `${tiles(r)}${insightCard(r)}` : ''}</div>${tabs}<div class="app__body">${section(st.an.section, r)}</div></div>`;
  };
  P.acts.anRange = (v) => { st.an.range = v; st.an.offset = 0; st.an.selected = null; P.render(); };
  P.acts.anSection = (v) => { st.an.section = v; P.render(); };
  P.acts.anShift = (n) => { st.an.offset = Math.max(0, st.an.offset + Number(n)); st.an.selected = null; P.render(); };

  // Category analytics and monthly comparisons.
  P.views.catan = function (id) {
    const c = L.cat(id);
    const end = G.current();
    const list = periods(end, 6);
    const rows = list.map((p) => { const s = G.periodStats(p); const value = s.byCat[id] || s.bySub[id] || 0; return { label: p.short, value, pick: { id: `c${id}${p.key}`, title: `${c.name}, ${p.label}`, sub: L.fmt(value, 'EUR'), filter: { cat: id, spending: true, start: p.start, end: p.end } } }; });
    const nowV = rows[rows.length - 1].value; const prevV = rows[rows.length - 2].value;
    const avg = Math.round(rows.slice(0, -1).reduce((s, r) => s + r.value, 0) / 5);
    const s = G.periodStats(end);
    const subs = G.subsOf(id).map((x) => ({ id: x.id, name: x.name, amount: s.bySub[x.id] || 0 })).filter((x) => x.amount).sort((a, b) => b.amount - a.amount);
    const merchants = {};
    G.filterTx({ cat: id, spending: true, start: list[0].start, end: end.end }).forEach((t) => { const k = G.titleOf(t); merchants[k] = merchants[k] || { n: 0, sum: 0 }; merchants[k].n += 1; merchants[k].sum += D.counted(t); });
    const top = Object.keys(merchants).map((k) => Object.assign({ name: k }, merchants[k])).sort((a, b) => b.sum - a.sum).slice(0, 5);
    const pct = prevV ? Math.round(((nowV - prevV) / prevV) * 100) : null;
    const tile = (label, html, delta) => `<div class="lg-metric"><span class="lg-metric__label">${label}</span><span class="lg-metric__value">${html}</span><span class="lg-metric__delta">${delta || ''}</span></div>`;
    return `<div class="app__scroll" data-scroll>${P.screenHead(esc(c.name), `Monthly comparison, ${list[0].short} to ${end.short}`)}<div class="app__body app__wrap">
      <div class="lg-metrics">${tile(end.short, P.eur(nowV), pct == null ? '' : `${pct >= 0 ? '+' : '−'}${Math.abs(pct)}% vs ${list[4].short}`)}${tile('Five-month average', P.eur(avg), `${list[0].short} to ${list[4].short}`)}</div>
      <div class="lg-card">${P.ch.bars(rows, `How does ${esc(c.name)} compare by month?`)}</div>
      ${subs.length ? `${P.section('Subcategories')}<div class="lg-card lg-card--flush">${subs.map((x) => `<button type="button" class="lg-row" ${act('drill', P.drillArg({ cat: x.id, spending: true, start: end.start, end: end.end, label: `${x.name}, ${end.label}` }))}>${P.catIcon(x.id)}<span class="lg-row__body"><span class="lg-row__title">${esc(x.name)}</span></span><span class="lg-row__trail">${P.eur(x.amount)}</span></button>`).join('')}</div>` : ''}
      ${top.length ? `${P.section('Most used titles')}<div class="lg-card lg-card--flush">${top.map((m) => `<div class="lg-row" style="cursor:default"><span class="lg-row__body"><span class="lg-row__title">${esc(m.name)}</span><span class="lg-row__sub">${m.n} ${m.n === 1 ? 'entry' : 'entries'} in six months</span></span><span class="lg-row__trail">${P.eur(m.sum)}</span></div>`).join('')}</div>` : ''}
      ${P.btn('See all transactions', 'drill', P.drillArg({ cat: id, spending: true, label: esc(c.name) }), { block: true, kind: 'secondary' })}
    </div></div>`;
  };
})(window.Ledgerly);
