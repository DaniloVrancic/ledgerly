// The Ledgerly mark: an open isometric ledger with a rising chart and two currency coins.
// One drawing serves the app icon, the exported SVG files and the empty-state line art.
(function (L) {
  const pts = (list) => list.map((p) => p.join(',')).join(' ');
  const poly = (list, fill) => `<polygon points="${pts(list)}" fill="${fill}"/>`;

  // An upright isometric column standing at (x, y).
  function column(x, y, hw, h, c) {
    const hh = hw / 2;
    return poly([[x - hw, y - h], [x, y - h + hh], [x, y + hh], [x - hw, y]], c.barLeft)
      + poly([[x, y - h + hh], [x + hw, y - h], [x + hw, y], [x, y + hh]], c.barRight)
      + poly([[x - hw, y - h], [x, y - h - hh], [x + hw, y - h], [x, y - h + hh]], c.bar);
  }

  const GLYPH = {
    dollar: 'M4.2-3.4C3.4-5 1.9-5.8 0-5.8c-2.5 0-4.2 1.3-4.2 3 0 2 2.1 2.5 4.2 2.9s4.2.9 4.2 2.9c0 1.7-1.7 3-4.2 3-1.9 0-3.4-.8-4.2-2.4M0-8.2V8.2',
    euro: 'M5.2-5.6A6.9 6.9 0 1 0 5.2 5.6M-7.4-1.7H2.6M-7.4 1.7H1.8',
  };
  function coin(x, y, r, tilt, glyph, c, fill, side, weight) {
    return `<g transform="translate(${x} ${y}) skewY(${tilt})"><circle cx="1.6" cy="1.6" r="${r}" fill="${side}"/><circle r="${r}" fill="${fill}"/><path d="${GLYPH[glyph]}" transform="scale(${r / 11})" fill="none" stroke="${c.tile}" stroke-width="${weight}" stroke-linecap="round" stroke-linejoin="round"/></g>`;
  }

  const VARS = {};
  ['tile', 'page', 'page-shade', 'edge', 'edge-dark', 'cover', 'cover-dark', 'bar', 'bar-left', 'bar-right', 'income', 'income-side', 'expense', 'expense-side'].forEach((n) => {
    VARS[n.replace(/-(\w)/, (_, a) => a.toUpperCase())] = `var(--brand-${n})`;
  });

  // Art only, on the 96 grid. Small sizes drop the fine lines and enlarge the coins.
  L.markArt = function (c, small) {
    const cover = poly([[9, 70], [48, 89.5], [48, 93], [9, 73.5]], c.coverDark)
      + poly([[48, 89.5], [87, 70], [87, 73.5], [48, 93]], c.cover)
      + poly([[9, 70], [48, 50.5], [87, 70], [48, 89.5]], c.cover);
    const path = (d, fill) => `<path d="${d}" fill="${fill}"/>`;
    const block = poly([[12, 64], [48, 82], [48, 88], [12, 70]], c.edgeDark)
      + path('M48 82Q57 72 66 76Q75 64 84 64V70L48 88Z', c.edge);
    const pages = path('M12 64Q21 54 30 58L66 76Q57 72 48 82Z', c.page)
      + path('M30 58Q39 46 48 46L84 64Q75 64 66 76Z', c.pageShade);
    const rules = small ? '' : `<path d="M25 66l18 9M20.5 68.5l18 9" stroke="${c.edgeDark}" stroke-width="1.5" stroke-linecap="round"/>`;
    const spine = `<path d="M30 58l36 18" stroke="${c.edgeDark}" stroke-width="1.5" stroke-linecap="round"/>`;
    const ribbon = path('M63.5 78.5l5-2.5v13.5l-2.5-.5-2.5 3z', c.expense);
    const columns = column(60, 59, 6.5, 34, c) + column(49, 64.5, 6.5, 24, c) + column(38, 70, 6.5, 14, c);
    const r = small ? 13 : 11;
    const coins = coin(23, small ? 33 : 34, r, 10, 'dollar', c, c.expense, c.expenseSide, small ? 3 : 2.400)
      + coin(small ? 75 : 77, small ? 27 : 26, r, -10, 'euro', c, c.income, c.incomeSide, small ? 3 : 2.400);
    return cover + block + ribbon + pages + rules + spine + columns + coins;
  };

  // The full tile. `c` is a palette of token values; the default follows tokens.css.
  L.markSvg = function (size, c, label) {
    const p = c || VARS;
    const small = size <= 36;
    const a = label === false ? 'aria-hidden="true"' : 'role="img" aria-label="Ledgerly"';
    return `<svg class="lg-appicon" xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 96 96" ${a}><rect width="96" height="96" rx="22" fill="${p.tile}"/>${L.markArt(p, small)}</svg>`;
  };
  L.appIcon = (size) => L.markSvg(size);

  // Empty, error and first-run states: the ledger as line art, with the subject rising out of it.
  L.stateMark = function (icon) {
    return `<span class="lg-state__mark">${L.icon(icon, 24)}<svg class="lg-state__book" width="72" height="42" viewBox="0 0 72 42" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M36 3L68 19 36 35 4 19 36 3zM20 11l32 16M4 19v5l32 16 32-16v-5M36 35v5"/></svg></span>`;
  };
})(window.Ledgerly = window.Ledgerly || {});
