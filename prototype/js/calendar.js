// Financial calendar: a month grid, a Year ledger, and each day's details.
(function (L) {
  'use strict';
  const D = L.data; const G = window.Ledger; const P = window.LP; const st = P.st; const ui = L.ui;
  const { act, esc } = P;

  let dayMap = null; let dayV = 0;
  function dayList(date) {
    if (!dayMap || dayV !== G.state.v) {
      dayMap = new Map(); dayV = G.state.v;
      D.transactions.forEach((t) => { if (!dayMap.has(t.date)) dayMap.set(t.date, []); dayMap.get(t.date).push(t); });
    }
    return dayMap.get(date) || [];
  }
  function facts(date) {
    const list = dayList(date);
    const spend = list.reduce((s, t) => s + D.counted(t), 0);
    const income = list.reduce((s, t) => s + (t.type === 'income' ? t.base : 0), 0);
    const cats = {};
    list.forEach((t) => { if (t.cat && D.counted(t) > 0) cats[t.cat] = (cats[t.cat] || 0) + D.counted(t); });
    const cat = Object.keys(cats).sort((a, b) => cats[b] - cats[a])[0];
    return { list, spend, income, net: income - spend, cat };
  }
  P.dayFacts = facts;
  // Daily repeats stay off the grid, so every day does not carry a marker.
  const plannedOn = (date) => (date > G.TODAY ? G.occurrences(date, date, (r) => r.every !== 'Daily').map((o) => Object.assign({}, o.r, { date, state: 'planned' })) : []);
  const dueOn = (date) => D.RECURRING.filter((r) => r.date === date && r.state === 'due');
  const tip = (date, f) => `${D.dayLabel(date)}: spent ${L.fmt(f.spend, 'EUR')}, income ${L.fmt(f.income, 'EUR')}, net ${L.fmt(f.net, 'EUR', f.net > 0)}`;

  function grid(ym) {
    const [y, m] = ym.split('-').map(Number);
    const first = `${ym}-01`;
    const start = G.addDays(first, -G.weekdayOf(first));
    const last = `${ym}-${G.pad(G.daysInMonth(y, m))}`;
    const count = Math.ceil((G.diffDays(last, start) + 1) / 7) * 7;
    const heads = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => `<div class="lg-cal__head">${d}</div>`).join('');
    const cells = Array.from({ length: count }, (_, i) => {
      const date = G.addDays(start, i);
      const day = Number(date.slice(8));
      const outside = !date.startsWith(ym);
      if (date > G.TODAY) {
        const planned = plannedOn(date);
        if (!planned.length) return ui.dayCell({ day, state: 'disabled' });
        const sum = planned.reduce((s, r) => s + (r.kind === 'income' ? 1 : -1) * D.toEur(r.amount, r.cur), 0);
        return ui.dayCell({ day, date, outside, planned: true, up: sum > 0, amount: L.fmtCell(sum), full: L.fmt(sum, 'EUR', sum > 0), marks: ['planned'], cat: planned[0].cat, label: `${day}, planned ${L.fmt(sum, 'EUR', sum > 0)}`, selected: st.cal.day === date });
      }
      const f = facts(date);
      const marks = [];
      if (f.list.some((t) => t.flags.includes('recurring')) || dueOn(date).length) marks.push('recurring');
      if (f.income) marks.push('income');
      if (f.spend >= 30000) marks.push('high');
      const n = f.list.length;
      return ui.dayCell({ day, date, outside, marks, cat: f.cat, today: date === G.TODAY, selected: st.cal.day === date, heat: L.heatStep(f.spend), up: f.net > 0, amount: L.fmtCell(f.net), full: L.fmt(f.net, 'EUR', f.net > 0), count: n ? `${n} ${n === 1 ? 'entry' : 'entries'}` : '', label: tip(date, f) });
    }).join('').replace(/data-day="([\d-]+)"/g, 'data-act="calDay" data-arg="$1"');
    return `<div class="lg-calwrap"><div class="lg-cal" role="group" aria-label="${G.MONTH[m - 1]} ${y}">${heads}${cells}</div></div>`;
  }
  function monthSummary(ym) {
    const [y, m] = ym.split('-').map(Number);
    const s = G.stats(`${ym}-01`, `${ym}-${G.pad(G.daysInMonth(y, m))}`);
    const cell = (label, html, term) => `<div><div class="caption lg-faint lg-inline" style="gap:0;min-height:24px">${label}${P.info(term || label)}</div><div class="amount">${html}</div></div>`;
    return `<div class="lg-calsum">${cell('Spent', P.eur(-s.spending, { tone: 'negative' }), 'Spending')}${cell('Income', P.eur(s.income, { sign: true, tone: 'positive' }))}${cell('Net', P.eur(s.net, { sign: true, tone: s.net >= 0 ? 'positive' : 'negative' }))}</div>`;
  }
  const shift = (ym, n) => { let [y, m] = ym.split('-').map(Number); m += n; while (m > 12) { m -= 12; y += 1; } while (m < 1) { m += 12; y -= 1; } return `${y}-${G.pad(m)}`; };
  const FIRST = D.months[0];
  const LAST = '2026-11';
  P.acts.calShift = (n) => { const next = shift(st.cal.ym, Number(n)); if (next >= FIRST && next <= LAST) { st.cal.ym = next; st.cal.day = null; st.cal.note = false; P.render(); } };
  P.acts.calMode = (m) => { st.cal.mode = m === 'Year' ? 'year' : 'month'; P.render(); };
  P.acts.calYear = (ym) => { st.cal.ym = ym; st.cal.mode = 'month'; st.cal.day = null; P.render(); };
  P.acts.calDay = (date) => {
    st.cal.day = date;
    if (P.isWide()) { P.render(); return; }
    P.sheet('day', date);
  };

  function year() {
    let i = 0;
    const list = D.months.slice(-12);
    return L.charts.year().replace(/<button type="button" class="lg-year__row" aria-pressed/g, () => `<button type="button" class="lg-year__row" ${act('calYear', list[i++])} aria-pressed`);
  }

  // Day details: totals, top category, transactions, a day note and attachments.
  const dayNote = (date) => G.NOTES.find((n) => n.day && n.links.some((l) => l.type === 'date' && l.id === date));
  P.dayNote = dayNote;
  P.dayPanel = function (date, closeAct) {
    const f = facts(date);
    const planned = date > G.TODAY ? plannedOn(date) : dueOn(date);
    const note = dayNote(date);
    const ro = P.isDesk();
    const cell = (label, html) => `<div><div class="caption lg-faint">${label}</div><div class="amount">${html}</div></div>`;
    const receipts = f.list.filter((t) => t.flags.includes('receipt'));
    const noteBlock = ro
      ? (note ? `<div class="lg-field"><span class="lg-field__label">Day note</span><p class="p-note" style="white-space:pre-wrap">${esc(note.body)}</p></div>` : '')
      : `<div class="lg-field"><span class="lg-field__label">Day note</span>${P.textarea('dayNote', note ? note.body : '', { arg: date, label: 'Day note', placeholder: 'Add a note for this day' })}${note ? `<span class="lg-field__hint">Saved in Notebook, linked to this date. ${P.link('Open note', 'go', `note:${note.id}`)}</span>` : '<span class="lg-field__hint">A day note is a Notebook entry linked to this date.</span>'}</div>`;
    return `<div class="lg-between"><h3 style="margin:0">${D.dayLabel(date)}${date.slice(0, 4) !== '2026' ? ` ${date.slice(0, 4)}` : ''}</h3>${closeAct ? P.iconBtn('x', 'Close', closeAct) : `<span class="body-small lg-muted">${f.list.length} ${f.list.length === 1 ? 'entry' : 'entries'}</span>`}</div>
      <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin:8px 0">${cell('Spent', P.eur(-f.spend, { tone: f.spend ? 'negative' : undefined }))}${cell('Income', P.eur(f.income, { sign: !!f.income, tone: f.income ? 'positive' : undefined }))}${cell('Net', P.eur(f.net, { sign: f.net > 0, tone: f.net > 0 ? 'positive' : f.net < 0 ? 'negative' : undefined }))}</div>
      ${f.cat ? `<div class="body-small lg-muted" style="margin-bottom:8px">Top category: ${esc(L.cat(f.cat).name)}</div>` : ''}
      ${planned.length ? `<div class="lg-card lg-card--flush" style="margin-bottom:8px">${planned.map((r) => `<div class="p-row-action"><span class="lg-row__body"><span class="lg-row__title">${esc(r.name)}</span><span class="lg-row__sub">${ui.recurring(r.state)}${L.fmt(r.amount, r.cur)}</span></span>${r.state === 'due' && !ro ? P.btn('Mark paid', 'confirmDue', r.id, { small: true, kind: 'secondary' }) : ''}</div>`).join('')}</div>` : ''}
      <div class="lg-card lg-card--flush" style="margin-bottom:12px">${f.list.map((t) => P.txRow(t)).join('') || '<div class="lg-state"><p>No entries on this day.</p></div>'}</div>
      ${noteBlock}
      ${receipts.length ? `<div class="lg-field" style="margin-top:12px"><span class="lg-field__label">Attachments</span><div class="p-attachments">${receipts.map((t, i) => P.receiptArt(t, i)).join('')}</div></div>` : ''}`;
  };
  P.sheets.day = (date) => P.dayPanel(date);
  P.inputs.dayNote = function (v, date) {
    const n = dayNote(date);
    if (n) { n.body = v; return; }
    if (!v) return;
    G.NOTES.unshift({ id: `n${Date.now()}`, title: `Day note, ${G.longDate(date)}`, date, tags: ['day'], body: v, links: [{ type: 'date', id: date }], day: true });
    G.bump(); P.render();
  };

  P.calendarBody = function () {
    const c = st.cal;
    const [y, m] = c.ym.split('-').map(Number);
    const title = c.mode === 'year' ? `${D.months.slice(-12)[0].slice(0, 4)} to 2026` : `${G.MONTH[m - 1]} ${y}`;
    const head = `<div class="p-cal-head">${c.mode === 'month' ? P.iconBtn('chevron', 'Previous month', 'calShift', -1).replace('<svg', '<svg style="transform:rotate(180deg)"') : ''}<span class="label" style="flex:1 1 auto;${c.mode === 'month' ? 'text-align:center' : ''}">${title}</span>${c.mode === 'month' ? P.iconBtn('chevron', 'Next month', 'calShift', 1) : ''}<div style="width:9rem;flex:none">${P.seg(['Month', 'Year'], c.mode === 'year' ? 'Year' : 'Month', 'calMode', 'Range')}</div></div>`;
    if (c.mode === 'year') return `${head}<div class="lg-card">${year()}</div>`;
    return `${head}${monthSummary(c.ym)}${grid(c.ym)}${L.calKey()}`;
  };
  P.views.calendar = function () {
    const wide = P.isWide();
    const seg = !wide ? P.seg(['List', 'Calendar'], 'Calendar', 'txSwitch', 'View') : '';
    const head = wide ? P.screenHead('Calendar') : `<div class="app__head app__head--root"><h2 class="lg-title">Transactions</h2></div>`;
    const body = `<div class="app__scroll" data-scroll>${head}<div class="app__body ${wide ? 'app__wrap' : ''}">${seg}${P.calendarBody()}</div></div>`;
    if (!wide) return body;
    const date = st.cal.day || (st.cal.ym === D.CURRENT ? G.TODAY : null);
    return `<div class="app__split">${body}<aside class="app__panel" aria-label="Day details"><div class="app__panel-body" style="gap:0">${date ? P.dayPanel(date) : `<div class="lg-state"><p>Select a day to see its details.</p></div>`}</div></aside></div>`;
  };
})(window.Ledgerly);
