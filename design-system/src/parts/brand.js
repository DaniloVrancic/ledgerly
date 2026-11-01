// The Ledgerly mark: an open isometric ledger with a solid line chart rising out of it.
// One drawing serves the app icon, the SVG files and the empty-state line art.
(function (L) {
  const pts = (list) => list.map((p) => p.join(',')).join(' ');
  const poly = (list, fill) => `<polygon points="${pts(list)}" fill="${fill}"/>`;
  const path = (d, fill) => `<path d="${d}" fill="${fill}"/>`;
  const stroke = (d, color, width, shift) => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"${shift ? ` transform="translate(${shift} ${shift})"` : ''}/>`;

  function ledger(c, small) {
    const ribbon = small ? '' : path('M63.5 78.5l5-2.5v13.5l-2.5-.5-2.5 3z', c.chart);
    const rules = small ? '' : `<path d="M25 66l18 9M20.5 68.5l18 9" stroke="${c.edgeDark}" stroke-width="1.5" stroke-linecap="round"/>`;
    return `${poly([[8, 76], [48, 94], [88, 76], [48, 58]], c.shadow)}<g transform="translate(48 72) scale(.94) translate(-48 -72)">${poly([[9, 70], [48, 89.5], [48, 93], [9, 73.5]], c.coverDark)}${poly([[48, 89.5], [87, 70], [87, 73.5], [48, 93]], c.cover)}${poly([[9, 70], [48, 50.5], [87, 70], [48, 89.5]], c.cover)}${poly([[12, 64], [48, 82], [48, 88], [12, 70]], c.edgeDark)}${path('M48 82Q57 72 66 76Q75 64 84 64V70L48 88Z', c.edge)}${ribbon}${path('M12 64Q21 54 30 58L66 76Q57 72 48 82Z', c.page)}${path('M30 58Q39 46 48 46L84 64Q75 64 66 76Z', c.pageShade)}${rules}<path d="M30 58l36 18" stroke="${c.edgeDark}" stroke-width="${small ? 2.5 : 1.5}" stroke-linecap="round"/></g>`;
  }

  // The line chart: a halo lifts it off the pages, stacked strokes give it depth.
  const POINTS = [[21, 60], [37, 40], [52, 50]];
  function chart(c, small) {
    const weight = small ? 7.5 : 6;
    const tip = small ? 17 : 15;
    const line = `M${POINTS.map((p) => p.join(' ')).join('L')}L78 16`;
    const head = `M${78 - tip} 16H78V${16 + tip}`;
    const both = (color, width, shift) => stroke(line, color, width, shift) + stroke(head, color, width, shift);
    const depth = [3, 2.25, 1.5, 0.75].map((shift) => both(c.chartSide, weight, shift)).join('');
    const dots = small ? '' : POINTS.map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.9" fill="${c.tile}"/>`).join('');
    return both(c.tile, weight + 5, 1.5) + depth + both(c.chart, weight) + dots;
  }

  const VARS = {};
  ['tile', 'shadow', 'page', 'page-shade', 'edge', 'edge-dark', 'cover', 'cover-dark', 'chart', 'chart-side'].forEach((n) => {
    VARS[n.replace(/-(\w)/, (_, a) => a.toUpperCase())] = `var(--brand-${n})`;
  });

  // At 36px and below the line thickens and the fine details drop out.
  L.markArt = (c, small) => ledger(c, small) + chart(c, small);

  // The full tile. `c` is a palette of token values; the default follows tokens.css.
  L.markSvg = function (size, c, label) {
    const p = c || VARS;
    const a = label === false ? 'aria-hidden="true"' : 'role="img" aria-label="Ledgerly"';
    return `<svg class="lg-appicon" xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 96 96" ${a}><rect width="96" height="96" rx="22" fill="${p.tile}"/>${L.markArt(p, size <= 36)}</svg>`;
  };
  L.appIcon = (size) => L.markSvg(size);

  // Empty, error and first-run states: the ledger as line art, with the subject rising out of it.
  L.stateMark = function (icon) {
    return `<span class="lg-state__mark">${L.icon(icon, 24)}<svg class="lg-state__book" width="72" height="42" viewBox="0 0 72 42" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M36 3L68 19 36 35 4 19 36 3zM20 11l32 16M4 19v5l32 16 32-16v-5M36 35v5"/></svg></span>`;
  };
})(window.Ledgerly = window.Ledgerly || {});
