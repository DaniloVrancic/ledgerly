/* @ds-bundle: {"format":4,"namespace":"Ledgerly","components":[{"name":"ColourTokens"},{"name":"TypeScale"},{"name":"Money"},{"name":"HiddenAmounts"},{"name":"IconSet"},{"name":"Button"},{"name":"TextInput"},{"name":"SearchField"},{"name":"Switch"},{"name":"SegmentedControl"},{"name":"Checkbox"},{"name":"Card"},{"name":"ListRow"},{"name":"SectionHeader"},{"name":"Tooltip"},{"name":"BottomSheet"},{"name":"Dialog"},{"name":"Toast"},{"name":"BottomNav"},{"name":"NavRail"},{"name":"Sidebar"},{"name":"ReadOnlyLabel"},{"name":"StatePatterns"},{"name":"Keypad"},{"name":"CategoryChip"},{"name":"AddTransaction"},{"name":"TransactionRow"},{"name":"TransferRow"},{"name":"DayGroupHeader"},{"name":"BalanceCard"},{"name":"MetricTile"},{"name":"BudgetBar"},{"name":"GoalProgress"},{"name":"NeedsAttentionRow"},{"name":"RecurringBadge"},{"name":"CalendarDayCell"},{"name":"BackupStatus"},{"name":"QuickAddWidget"},{"name":"CategoryIdentity"},{"name":"CategoryRow"},{"name":"IconPicker"},{"name":"CategoryColourPicker"},{"name":"AccountPicker"},{"name":"CategoryEditor"},{"name":"ChartGroupedBars"},{"name":"ChartDonut"},{"name":"ChartTrendLines"},{"name":"ChartWeekdayBars"},{"name":"ChartBalanceLine"},{"name":"ChartCalendarHeat"},{"name":"ChartYearLedger"},{"name":"ChartPalette"},{"name":"ChartEmpty"},{"name":"AppIcon"},{"name":"PrintStyle"},{"name":"ScreenHome"},{"name":"ScreenAddTransaction"},{"name":"ScreenCategories"},{"name":"ScreenCategoryEditor"},{"name":"ScreenHistory"},{"name":"ScreenCalendar"},{"name":"ScreenAnalytics"}]} */
window.Ledgerly = window.Ledgerly || {};
window.Ledgerly.tokens = {"color":["background","surface-1","surface-2","surface-3","surface-overlay","surface-inverse","on-inverse","border-inverse","surface-tint","text-primary","text-secondary","text-tertiary","text-disabled","border-subtle","border-control","primary","on-primary","primary-tint","positive","positive-fill","positive-tint","negative","negative-fill","negative-tint","warning","warning-fill","warning-mark","on-warning","warning-tint","neutral","neutral-fill","neutral-tint","accent","on-accent","accent-text","accent-forest","accent-lake","accent-plum","accent-slate","scrim","brand-tile","brand-page","brand-page-shade","brand-edge","brand-edge-dark","brand-cover","brand-cover-dark","brand-shadow","brand-chart","brand-chart-side","cat-1","cat-2","cat-3","cat-4","cat-5","cat-6","cat-7","cat-8","cat-9","cat-10","cat-11","cat-12","chart-1","chart-2","chart-3","chart-4","chart-5","chart-6","chart-other","chart-grid","chart-axis","heat-0","heat-1","heat-2","heat-3","heat-4","heat-5","on-heat-low","on-heat-high"],"type":[["balance","€12,483.36"],["amount-large","−€1,482.50"],["amount","39.12 KM"],["amount-small","€20.00"],["title-large","Transactions"],["title","This month"],["subtitle","Konzum Čengić Vila"],["body","Backed up 2 days ago."],["body-small","Expected lowest balance before payday."],["label","Confirm"],["caption","Estimate"]],"categories":[["housing","Housing",1,"home"],["food","Food",2,"basket"],["transport","Transportation",3,"bus"],["shopping","Shopping",4,"bag"],["health","Health",5,"pulse"],["entertainment","Entertainment",6,"ticket"],["bills","Bills",7,"receipt"],["travel","Travel",8,"plane"],["education","Education",9,"book"],["personal","Personal Care",10,"sparkle"],["gifts","Gifts",11,"gift"],["subscriptions","Subscriptions",12,"repeat"],["salary","Salary",3,"briefcase"],["freelance","Freelance",4,"pen"],["business","Business",6,"store"],["investments","Investments",5,"trend"],["rental","Rental Income",7,"key"],["other","Other",0,"dots"]],"accents":[{"id":"forest","name":"Forest"},{"id":"lake","name":"Lake"},{"id":"plum","name":"Plum"},{"id":"slate","name":"Slate"}]};
// One line icon set: 24px grid, 1.75 stroke, round caps, no fills. Original to Ledgerly.
(function (L) {
  const P = {
    home: 'M4 11l8-7 8 7M6 9.5V20h12V9.5M10 20v-6h4v6',
    list: 'M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01',
    plus: 'M12 5v14M5 12h14',
    chart: 'M5 20V10M12 20V4M19 20v-7',
    menu: 'M4 7h16M4 12h16M4 17h16',
    calendar: 'M4 9h16M8 3v4M16 3v4M5 5h14a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z',
    wallet: 'M4 7h15a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a2 2 0 0 1 2-2h11M16 13h.01',
    target: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 12h.01',
    pie: 'M12 3a9 9 0 1 0 9 9h-9V3zM16 3.5A9 9 0 0 1 20.5 8H16V3.5z',
    gear: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M18.4 5.6l-2.1 2.1M7.7 16.3l-2.1 2.1',
    search: 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4',
    x: 'M6 6l12 12M18 6L6 18',
    check: 'M5 12.5l4.5 4.5L19 7.5',
    chevron: 'M9 6l6 6-6 6',
    chevronDown: 'M6 9l6 6 6-6',
    info: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5M12 8h.01',
    alert: 'M12 4l9 16H3L12 4zM12 10v4M12 17h.01',
    transfer: 'M4 9h14M14 5l4 4-4 4M20 15H6M10 11l-4 4 4 4',
    up: 'M12 19V5M6 11l6-6 6 6',
    down: 'M12 5v14M6 13l6 6 6-6',
    receipt: 'M6 3v18l3-2 3 2 3-2 3 2V3l-3 2-3-2-3 2-3-2zM9 9h6M9 13h6',
    split: 'M12 21v-7M12 14L6 8M12 14l6-6M6 13V8h5M18 13V8h-5',
    people: 'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM3 20c0-3.3 2.7-6 6-6s6 2.7 6 6M16 11a3 3 0 0 0 0-6M17.5 14.5c2.1.7 3.5 2.8 3.5 5.5',
    repeat: 'M17 3l4 4-4 4M21 7H7a4 4 0 0 0-4 4v1M7 21l-4-4 4-4M3 17h14a4 4 0 0 0 4-4v-1',
    undo: 'M8 5L4 9l4 4M4 9h10a6 6 0 0 1 0 12h-3',
    flag: 'M5 21V4M5 4h12l-2 4 2 4H5',
    backspace: 'M9 5h11a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H9l-6-7 6-7zM12 9.5l5 5M17 9.5l-5 5',
    eye: 'M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
    eyeOff: 'M3 3l18 18M10 5.7c.6-.1 1.3-.2 2-.2 6 0 9.5 6.5 9.5 6.5a16 16 0 0 1-3 3.8M6.5 7.2A16 16 0 0 0 2.5 12S6 18.5 12 18.5c1.7 0 3.2-.5 4.5-1.2M10 10a3 3 0 0 0 4.1 4.1',
    shield: 'M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3z',
    shieldCheck: 'M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3zM8.5 12l2.5 2.5 4.5-5',
    clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3.5 2',
    lock: 'M6 11h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1zM8 11V8a4 4 0 0 1 8 0v3',
    note: 'M6 3h9l4 4v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM14 3v5h5M9 13h6M9 17h4',
    download: 'M12 4v11M7 11l5 5 5-5M5 20h14',
    tag: 'M4 4h8l8 8-8 8-8-8V4zM8.5 8.5h.01',
    dots: 'M6 12h.01M12 12h.01M18 12h.01',
    basket: 'M4 10h16l-1.5 9.2a1 1 0 0 1-1 .8h-11a1 1 0 0 1-1-.8L4 10zM8 10l3-6M16 10l-3-6M10 14v2M14 14v2',
    bus: 'M6 4h12a2 2 0 0 1 2 2v11H4V6a2 2 0 0 1 2-2zM4 11h16M7.5 20v-3M16.5 20v-3M8 14h.01M16 14h.01',
    bag: 'M6 8h12l1 12H5L6 8zM9 8V7a3 3 0 0 1 6 0v1',
    pulse: 'M3 12h4l2.5-6 4 12 2.5-6h5',
    ticket: 'M4 7h16v3.5a1.5 1.5 0 0 0 0 3V17H4v-3.5a1.5 1.5 0 0 0 0-3V7zM14 7v2M14 11v2M14 15v2',
    plane: 'M3 12.5l18-8-5 16-4.5-6L3 12.5zM11.5 14.5L21 4.5',
    book: 'M12 6c-2-1.5-4.5-2-8-2v15c3.5 0 6 .5 8 2 2-1.5 4.5-2 8-2V4c-3.5 0-6 .5-8 2zM12 6v15',
    sparkle: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3zM18.5 16.5l.7 2 2 .7-2 .7-.7 2-.7-2-2-.7 2-.7.7-2z',
    gift: 'M4 11h16v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-9zM3 7h18v4H3V7zM12 7v14M12 7S10.5 3 8 3a2 2 0 0 0 0 4h4zM12 7s1.5-4 4-4a2 2 0 0 1 0 4h-4z',
    briefcase: 'M4 8h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1zM9 8V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v3M3 13h18',
    pen: 'M4 20l1-4L16 5a2 2 0 0 1 3 3L8 19l-4 1zM14 7l3 3',
    store: 'M4 10v10h16V10M3 9l2-5h14l2 5a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0zM10 20v-5h4v5',
    trend: 'M3 17l6-6 4 4 8-8M15 7h6v6',
    key: 'M8 21a5 5 0 1 0 0-10 5 5 0 0 0 0 10zM11.5 12.5L20 4M16 8l3 3',
    inbox: 'M3 13h5l2 3h4l2-3h5M5.5 5h13L21 13v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-6l2.5-8z',
    page: 'M6 3h12a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM9 8h6M9 12h6M9 16h3',
    laptop: 'M5 5h14a1 1 0 0 1 1 1v10H4V6a1 1 0 0 1 1-1zM2 19h20',
    ledger: 'M12 4l9 4.5-9 4.5-9-4.5L12 4zM7.5 6.25l9 4.5M3 8.5v7l9 4.5 9-4.5v-7M12 13v7',
    dollar: 'M16.5 7.5C16 6 14.5 5 12 5 9.5 5 7.5 6.3 7.5 8.5s2 3 4.5 3.5 4.5 1.5 4.5 3.7S14.5 19 12 19c-2.5 0-4-1-4.5-2.5M12 3v18',
    euro: 'M18 6.5A7.5 7.5 0 1 0 18 17.5M4 10.5h10M4 13.5h9',
    paw: 'M12 12c-2.5 0-5 2.5-5 5 0 1.7 1.3 2.5 2.5 2.5 1 0 1.5-.5 2.5-.5s1.5.5 2.5.5c1.2 0 2.5-.8 2.5-2.5 0-2.5-2.5-5-5-5zM3.5 10.5a1.5 2 0 1 0 3 0 1.5 2 0 1 0-3 0zM7.5 6.5a1.5 2 0 1 0 3 0 1.5 2 0 1 0-3 0zM13.5 6.5a1.5 2 0 1 0 3 0 1.5 2 0 1 0-3 0zM17.5 10.5a1.5 2 0 1 0 3 0 1.5 2 0 1 0-3 0z',
    coffee: 'M5 9h12v6a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5V9zM17 10h1.5a2.5 2.5 0 0 1 0 5H17M8 3v3M12 3v3',
    car: 'M5 11l1.8-5a1.5 1.5 0 0 1 1.4-1h7.6a1.5 1.5 0 0 1 1.4 1L19 11M4 11h16a1 1 0 0 1 1 1v5H3v-5a1 1 0 0 1 1-1zM6 17v2M18 17v2M7 14h.01M17 14h.01',
    fuel: 'M5 20V5a1 1 0 0 1 1-1h7a1 1 0 0 1 1 1v15M3 20h13M14 11h2a1.5 1.5 0 0 1 1.5 1.5V16a1.5 1.5 0 0 0 3 0V8l-3-3M8 8h3',
    dumbbell: 'M6.5 6.5v11M17.5 6.5v11M3 9v6M21 9v6M6.5 12h11',
    music: 'M9 18V6l10-2v12M9 18a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0zM19 16a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z',
    game: 'M7 8h10a4 4 0 0 1 4 4v3a3 3 0 0 1-5.4 1.8L14 15h-4l-1.6 1.8A3 3 0 0 1 3 15v-3a4 4 0 0 1 4-4zM7 11v3M5.5 12.5h3M15.5 11.5h.01M17.5 13.5h.01',
    leaf: 'M5 19C5 10 11 5 20 4c0 9-4 15-12 15H5zM4 21c2-5 5-8 9-10',
    wrench: 'M15 6.5a4 4 0 0 1 5-1l-3 3 1.5 1.5 3-3a4 4 0 0 1-5.4 5L8 20a2 2 0 0 1-3-3l7.5-7.5a4 4 0 0 1 2.5-3z',
    phone: 'M8 3h8a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM11 18h2',
    bolt: 'M13 3L5 13h6l-1 8 8-10h-6l1-8z',
    shirt: 'M8 4L3 7l2 4 2-1v10h10V10l2 1 2-4-5-3c-.5 1.5-2 2.5-4 2.5S8.5 5.5 8 4z',
    fork: 'M7 3v7M5 3v6a2 2 0 0 0 2 2 2 2 0 0 0 2-2V3M7 11v10M17 21v-7h-2V7c0-2.5 1-4 3-4v18',
    heart: 'M12 20s-8-4.6-8-10.5A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 8 2.5C20 15.4 12 20 12 20z',
    image: 'M5 4h14a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1zM4 16l5-5 4 4 3-3 4 4M15 8.5h.01',
    upload: 'M12 16V5M7 10l5-5 5 5M5 20h14',
    archive: 'M4 5h16v4H4V5zM6 9v10h12V9M10 13h4',
  };
  L.iconNames = Object.keys(P);
  // What a person can choose for their own category.
  L.pickIcons = ['basket', 'fork', 'coffee', 'home', 'car', 'bus', 'fuel', 'plane', 'bag', 'shirt', 'gift', 'heart', 'pulse', 'dumbbell', 'sparkle', 'paw', 'leaf', 'book', 'music', 'game', 'ticket', 'phone', 'bolt', 'wrench', 'receipt', 'repeat', 'briefcase', 'pen', 'store', 'trend', 'key', 'wallet', 'target', 'tag', 'ledger', 'dots'];
  L.icon = function (name, size, label) {
    const px = size || 20;
    const a = label ? `role="img" aria-label="${label}"` : 'aria-hidden="true"';
    return `<svg class="lg-icon" width="${px}" height="${px}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" ${a}><path d="${P[name] || P.dots}"/></svg>`;
  };
})(window.Ledgerly = window.Ledgerly || {});

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

// Component builders. Each returns an HTML string that uses only the classes in ledgerly.css.
// React components can wrap the same class names; these keep the system free of dependencies.
(function (L) {
  const icon = L.icon;
  const D = L.data;
  const CATS = {};
  (L.tokens ? L.tokens.categories : []).forEach(([id, name, slot, ic]) => { CATS[id] = { id, name, slot, icon: ic }; });
  L.cat = (id) => CATS[id] || D.CUSTOM.find((c) => c.id === id) || { id: 'other', name: 'Needs review', slot: 0, icon: 'flag' };
  const catColor = (c) => (c.slot ? `var(--cat-${c.slot})` : 'var(--neutral)');
  const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');

  // Grouping and the sign are written here so formatting cannot vary between screens.
  function number(minor) {
    return (Math.abs(minor) / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  L.fmt = function (minor, cur, sign) {
    const n = number(minor);
    const body = cur === 'EUR' ? `€${n}` : `${n} KM`;
    if (minor < 0) return `−${body}`;
    return sign ? `+${body}` : body;
  };
  // Compact form for chart labels and calendar cells only. Rows and cards show every digit.
  L.fmtShort = function (minor) {
    const v = Math.abs(minor) / 100;
    const s = v >= 1e6 ? `${(v / 1e6).toFixed(2)}M` : v >= 10000 ? `${Math.round(v / 1000)}k` : v >= 1000 ? `${(v / 1000).toFixed(1)}k` : `${Math.round(v)}`;
    return `${minor < 0 ? '−' : ''}${s}`;
  };
  // Signed and in whole currency, for calendar cells and ledger lines.
  L.fmtCell = function (minor) {
    const v = Math.abs(minor) / 100;
    const n = v >= 10000 ? `${Math.round(v / 1000)}k` : v >= 1000 ? `${(v / 1000).toFixed(1)}k` : `${Math.round(v)}`;
    if (Math.round(v) === 0) return '€0';
    return `${minor < 0 ? '\u2212' : '+'}€${n}`;
  };
  L.fmtWhole = function (minor) {
    const n = Math.round(Math.abs(minor) / 100).toLocaleString('en-US');
    return `${minor < 0 ? '\u2212' : ''}€${n}`;
  };
  L.money = function (minor, cur, o) {
    const opt = o || {};
    const cls = opt.tone ? ` money--${opt.tone}` : '';
    return `<span class="money${cls}">${L.fmt(minor, cur || 'EUR', opt.sign)}</span>`;
  };
  // The original amount sits first. The converted amount is smaller, below, and never coloured.
  L.moneyPair = function (minor, cur, base, o) {
    const main = L.money(minor, cur, o);
    if (cur === 'EUR') return `<span class="money-pair">${main}</span>`;
    return `<span class="money-pair">${main}<span class="money-pair__sub money">${L.fmt(Math.abs(base), 'EUR')}</span></span>`;
  };
  const fitLevel = (text, a, b) => (text.length > b ? 2 : text.length > a ? 1 : 0);

  const ui = {};
  ui.button = (label, o) => {
    const p = o || {};
    const cls = ['lg-btn', p.kind && `lg-btn--${p.kind}`, p.small && 'lg-btn--small', p.block && 'lg-btn--block', p.state && `is-${p.state}`].filter(Boolean).join(' ');
    const dis = p.state === 'disabled' ? ' disabled' : '';
    const inner = p.state === 'loading' ? `<span class="lg-spinner" aria-hidden="true"></span>${label}` : (p.icon ? icon(p.icon, 20) : '') + label;
    return `<button type="button" class="${cls}"${dis}${p.attr ? ` ${p.attr}` : ''}>${inner}</button>`;
  };
  ui.input = (o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    const icoR = p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : '';
    const hint = p.state === 'error' ? `<span class="lg-field__hint">${icon('alert', 16)}${p.error || 'Enter an amount above zero.'}</span>` : p.hint ? `<span class="lg-field__hint">${p.hint}</span>` : '';
    return `<label class="lg-field ${st}"><span class="lg-field__label">${p.label || 'Merchant'}</span><span class="lg-input ${st}"><input value="${esc(p.value || '')}" placeholder="${esc(p.placeholder || '')}"${p.state === 'disabled' ? ' disabled' : ''}>${icoR}</span>${hint}</label>`;
  };
  ui.search = (o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    const right = p.value ? `<span class="lg-faint">${icon('x', 16)}</span>` : p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : '';
    return `<span class="lg-input lg-search ${st}">${icon('search', 20)}<input aria-label="Search transactions" value="${esc(p.value || '')}" placeholder="Search merchant or amount"${p.state === 'disabled' ? ' disabled' : ''}>${right}</span>`;
  };
  ui.switch = (label, o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    return `<label class="lg-switch ${st}"><input type="checkbox" role="switch"${p.on || p.state === 'selected' ? ' checked' : ''}${p.state === 'disabled' ? ' disabled' : ''}><span class="lg-switch__track"></span><span>${label}</span></label>`;
  };
  ui.checkbox = (label, o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    return `<label class="lg-check ${st}"><input type="checkbox"${p.on || p.state === 'selected' ? ' checked' : ''}${p.state === 'disabled' ? ' disabled' : ''}><span class="lg-check__box">${icon('check', 16)}</span><span>${label}</span></label>`;
  };
  ui.segmented = (items, o) => {
    const p = o || {};
    return `<div class="lg-seg" role="group"${p.label ? ` aria-label="${p.label}"` : ''} data-seg>${items.map((it, i) => {
      const t = typeof it === 'string' ? { label: it } : it;
      const cls = p.states && p.states[i] ? `is-${p.states[i]}` : '';
      return `<button type="button" class="lg-seg__item ${cls}" aria-pressed="${i === (p.selected || 0)}"${t.kind ? ` data-kind="${t.kind}"` : ''}>${t.icon ? icon(t.icon, 16) : ''}${t.label}</button>`;
    }).join('')}</div>`;
  };
  ui.section = (title, action) => `<div class="lg-section"><h3 class="lg-section__title">${title}</h3>${action ? `<button type="button" class="lg-link">${action}</button>` : ''}</div>`;
  ui.row = (o) => {
    const p = o || {};
    return `<button type="button" class="lg-row ${p.state ? `is-${p.state}` : ''}"${p.state === 'disabled' ? ' disabled' : ''}><span class="lg-row__lead">${icon(p.icon || 'wallet', 20)}</span><span class="lg-row__body"><span class="lg-row__title">${p.title}</span>${p.sub ? `<span class="lg-row__sub">${p.sub}</span>` : ''}</span><span class="lg-row__trail">${p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : p.trail || icon('chevron', 20)}</span></button>`;
  };
  ui.tooltip = (term, def) => `<div class="lg-tip" role="tooltip"><b>${term}.</b> ${def}</div>`;
  ui.info = (term, def) => `<button type="button" class="lg-icon-btn" aria-label="${esc(`${term}: ${def}`)}" title="${esc(def)}" style="min-width:24px;min-height:24px">${icon('info', 16)}</button>`;
  ui.toast = (text, o) => {
    const p = o || {};
    return `<div class="lg-toast ${p.state ? `is-${p.state}` : ''}" role="status"><span class="lg-toast__text">${text}</span>${p.undo === false ? '' : ui.button('Undo', { small: true, attr: 'data-undo' })}${p.more ? ui.button(p.more, { small: true }) : ''}</div>`;
  };
  ui.nav = (active, o) => {
    const p = o || {};
    const items = [['Home', 'home'], ['Transactions', 'list'], null, ['Analytics', 'chart'], ['More', 'menu']];
    return `<nav class="lg-nav" aria-label="Main">${items.map((it, i) => {
      if (!it) return `<button type="button" class="lg-nav__add ${p.addState ? `is-${p.addState}` : ''}" aria-label="Add transaction">${icon('plus', 24)}</button>`;
      const on = i === active;
      return `<button type="button" class="lg-nav__item ${p.states && p.states[i] ? `is-${p.states[i]}` : ''}"${on ? ' aria-current="page"' : ''}>${icon(it[1], 24)}<span>${it[0] === 'Transactions' ? 'History' : it[0]}</span></button>`;
    }).join('')}</nav>`;
  };
  ui.rail = (active, st) => `<nav class="lg-rail" aria-label="Main">${['home', 'list', 'plus', 'chart', 'calendar', 'wallet', 'menu'].map((ic, i) => `<button type="button" class="lg-rail__item ${i === active ? 'is-selected' : ''} ${st && st[i] ? `is-${st[i]}` : ''}" aria-label="${['Home', 'Transactions', 'Add', 'Analytics', 'Calendar', 'Accounts', 'More'][i]}">${icon(ic, 24)}</button>`).join('')}</nav>`;
  ui.sidebar = (active, st) => {
    const items = [['Home', 'home'], ['Transactions', 'list'], ['Analytics', 'chart'], ['Calendar', 'calendar'], ['Budgets', 'pie'], ['Goals', 'target'], ['Accounts', 'wallet'], ['Reports', 'page'], ['Settings', 'gear']];
    return `<nav class="lg-side" aria-label="Main"><div class="lg-inline" style="padding:8px 12px 16px">${L.appIcon(32)}<span class="lg-wordmark">Ledgerly</span></div>${items.map(([n, ic], i) => `<button type="button" class="lg-side__item ${i === active ? 'is-selected' : ''} ${st && st[i] ? `is-${st[i]}` : ''}"${i === active ? ' aria-current="page"' : ''}>${icon(ic, 20)}${n}</button>`).join('')}<div style="flex:1;min-height:16px"></div>${ui.readOnly()}</nav>`;
  };
  ui.readOnly = () => `<div class="lg-readonly">${icon('eye', 16)}<span>Read-only copy<br>File from 29 Oct 2026, 08:14</span></div>`;
  ui.state = (kind) => {
    if (kind === 'loading') return `<div class="lg-stack" style="padding:16px" aria-busy="true" aria-label="Loading"><span class="lg-skel" style="width:40%"></span><span class="lg-skel" style="width:90%"></span><span class="lg-skel" style="width:72%"></span></div>`;
    if (kind === 'error') return `<div class="lg-state lg-state--error">${L.stateMark('alert')}<h3>This file could not be read</h3><p>It may be damaged. Nothing in Ledgerly was changed.</p>${ui.button('Choose another file', { kind: 'secondary' })}</div>`;
    return `<div class="lg-state">${L.stateMark('plus')}<h3>Nothing here yet</h3><p>Transactions you add will appear here, grouped by day.</p>${ui.button('Add a transaction', { kind: 'primary', icon: 'plus' })}</div>`;
  };
  ui.key = (label, st, attr) => `<button type="button" class="lg-key ${st ? `is-${st}` : ''}"${attr ? ` ${attr}` : ''}>${label}</button>`;
  ui.keypad = () => `<div class="lg-keypad" data-keypad>${['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'].map((k) => ui.key(k, '', `data-key="${k}"`)).join('')}${ui.key(icon('backspace', 24, 'Delete digit'), '', 'data-key="del"')}</div>`;
  ui.chip = (id, o) => {
    const p = o || {};
    const c = L.cat(id);
    const color = catColor(c);
    const st = p.state ? `is-${p.state}` : '';
    return `<button type="button" class="lg-chip ${st}" style="--chip-color:${color}"${p.state === 'disabled' || p.disabled ? ' disabled' : ''}${p.state === 'selected' ? ' aria-pressed="true"' : ''} data-chip="${c.name}"><span class="lg-chip__icon">${icon(c.icon, 20)}</span>${p.label || c.name}</button>`;
  };
  ui.chipAll = (o) => `<button type="button" class="lg-chip lg-chip--all ${o && o.state ? `is-${o.state}` : ''}"${o && o.disabled ? ' disabled' : ''}><span class="lg-chip__icon">${icon('search', 20)}</span>All</button>`;
  ui.chipLater = (o) => `<button type="button" class="lg-chip lg-chip--later ${o && o.state ? `is-${o.state}` : ''}"${o && o.disabled ? ' disabled' : ''} data-chip="Later"><span class="lg-chip__icon">${icon('clock', 20)}</span>Later</button>`;

  const FLAG = { receipt: ['receipt', 'Receipt'], split: ['split', 'Split'], shared: ['people', 'Shared cost'], recurring: ['repeat', 'Recurring'], refund: ['undo', 'Refund'], review: ['flag', 'Needs review'] };
  ui.flags = (flags) => (flags && flags.length ? `<span class="lg-tx__flags">${flags.map((f) => `<span class="${f === 'review' ? 'lg-tx__flag--review' : ''}">${icon(FLAG[f][0], 16, FLAG[f][1])}</span>`).join('')}</span>` : '');
  ui.tx = (t, o) => {
    const p = o || {};
    const st = p.state ? `is-${p.state}` : '';
    if (t.type === 'transfer') {
      const to = D.acc(t.to);
      return `<button type="button" class="lg-tx lg-tx--transfer ${st}"><span class="lg-tx__lead">${icon('transfer', 20, 'Transfer')}</span><span class="lg-tx__body"><span class="lg-tx__name">${t.merchant}</span><span class="lg-tx__meta">${D.acc(t.account).name} to ${to.name}</span></span><span class="lg-tx__amount">${L.moneyPair(t.amount, t.cur, t.base, { tone: 'neutral' })}</span></button>`;
    }
    const c = L.cat(t.cat);
    const color = c.slot ? `var(--cat-${c.slot})` : 'var(--warning)';
    const isIn = t.type === 'income' || t.type === 'refund';
    const money = L.moneyPair(isIn ? t.amount : -t.amount, t.cur, t.base, { sign: isIn, tone: isIn ? 'positive' : 'negative' });
    const meta = t.type === 'adjustment' ? 'Balance check, not counted' : t.sub || (t.cat ? `${c.name} · ${D.acc(t.account).name}` : `Needs a category · ${D.acc(t.account).name}`);
    const flags = t.flags.slice();
    return `<button type="button" class="lg-tx ${st}" style="--chip-color:${color}"><span class="lg-tx__lead">${p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : icon(c.icon, 20)}</span><span class="lg-tx__body"><span class="lg-tx__name">${t.merchant ? esc(t.merchant) : 'No merchant'}</span><span class="lg-tx__meta">${meta}${ui.flags(flags)}</span></span><span class="lg-tx__amount">${money}</span></button>`;
  };
  ui.day = (date, net) => `<div class="lg-day"><span>${D.dayLabel(date)}</span>${L.money(net, 'EUR', { sign: true, tone: net > 0 ? 'positive' : net < 0 ? 'negative' : 'neutral' })}</div>`;

  ui.balance = (o) => {
    const p = o || {};
    const s = D.summary();
    const total = p.value != null ? p.value : s.total;
    const text = L.fmt(total, 'EUR');
    const delta = s.total - s.lastMonth;
    const dir = delta >= 0;
    const body = p.state === 'loading'
      ? '<span class="lg-skel" style="height:2.25rem;width:70%;margin:8px 0"></span>'
      : `<span class="lg-balance__value" data-fit="${fitLevel(text, 13, 16)}">${L.money(total, 'EUR')}</span>`;
    const rows = D.accounts().map((a) => `<div class="lg-balance__row"><span>${a.name}</span>${L.money(a.balance, a.cur)}</div>`).join('');
    return `<section class="lg-balance ${p.open ? 'is-open' : ''} ${p.state ? `is-${p.state}` : ''}"><button type="button" class="lg-balance__toggle" aria-expanded="${!!p.open}" data-balance><span class="lg-balance__label"><span>Total balance</span><span class="lg-balance__chev">${icon('chevronDown', 20)}</span></span>${body}<span class="lg-balance__change">${icon(dir ? 'up' : 'down', 16)}${L.money(delta, 'EUR', { sign: true })} from last month</span></button><div class="lg-balance__list">${rows}<div class="lg-balance__row lg-balance__row--strong" style="margin-top:8px"><span>Earmarked for goals</span>${L.money(s.earmarked, 'EUR')}</div><div class="lg-balance__row lg-balance__row--strong"><span>Free to use</span>${L.money(s.free, 'EUR')}</div></div></section>`;
  };
  const DEFS = { Income: 'Income transactions only.', Spending: 'Expenses minus refunds.', Net: 'Income minus spending.', 'Savings rate': 'Net divided by income.' };
  ui.metric = (label, value, o) => {
    const p = o || {};
    const v = p.raw ? value : L.money(value, 'EUR', { sign: p.sign, tone: p.tone });
    const len = p.raw ? 4 : L.fmt(value, 'EUR', p.sign).length;
    return `<div class="lg-metric ${p.state ? `is-${p.state}` : ''}"><span class="lg-metric__label">${label}${ui.info(label, DEFS[label] || '')}</span><span class="lg-metric__value" data-fit="${len > 12 ? 1 : 0}">${p.state === 'loading' ? '<span class="lg-skel" style="height:1.5rem;width:70%;margin:4px 0"></span>' : v}</span><span class="lg-metric__delta">${p.delta || ''}</span></div>`;
  };
  ui.budget = (b, o) => {
    const p = o || {};
    const c = L.cat(b.cat);
    const pct = Math.round(b.ratio * 100);
    const label = { normal: `${pct}%, on track`, warning: `${pct}%, near the limit`, over: `${pct}%, over the limit` }[b.state];
    const ico = { normal: 'check', warning: 'alert', over: 'alert' }[b.state];
    const rem = b.left >= 0 ? `${L.money(b.left, 'EUR')} left` : `${L.money(-b.left, 'EUR')} over`;
    return `<div class="${p.flat ? '' : 'lg-card'}"><div class="lg-between"><span class="lg-inline" style="--chip-color:var(--cat-${c.slot})"><span class="lg-chip__icon">${icon(c.icon, 20)}</span><span class="label">${c.name}</span></span><span class="body-small">${L.money(b.spent, 'EUR')} <span class="lg-faint">of ${L.money(b.limit, 'EUR')}</span></span></div><div class="lg-bar lg-bar--${b.state === 'normal' ? 'ok' : b.state}" role="img" aria-label="${c.name} budget ${pct} percent used, expected pace ${Math.round(D.PACE * 100)} percent"><span class="lg-bar__fill" style="width:${Math.min(100, pct)}%"></span><span class="lg-bar__pace" style="left:${D.PACE * 100}%"></span></div><div class="lg-between"><span class="lg-budget__status lg-budget__status--${b.state}">${icon(ico, 16)}${label}</span><span class="caption lg-faint">${rem}</span></div></div>`;
  };
  ui.goal = (g) => {
    const pct = Math.round((g.saved / g.target) * 100);
    return `<div class="lg-card"><div class="lg-between"><span class="lg-inline">${icon(g.icon, 20)}<span class="label">${g.name}</span></span><span class="caption lg-muted">${pct}%</span></div><div class="lg-bar lg-bar--accent" role="img" aria-label="${pct} percent of goal"><span class="lg-bar__fill" style="width:${pct}%"></span></div><div class="body-small lg-muted">${L.money(g.saved, 'EUR')} of ${L.money(g.target, 'EUR')}</div></div>`;
  };
  ui.attention = (title, sub, action, o) => {
    const p = o || {};
    const ic = p.icon || 'alert';
    return `<div class="lg-attn ${p.state ? `is-${p.state}` : ''}"><span class="lg-attn__icon">${icon(ic, 20)}</span><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem;line-height:1.25rem">${title}</span><span class="lg-row__sub">${sub}</span></span>${ui.button(action, { kind: 'secondary', small: true, state: p.state === 'disabled' ? 'disabled' : p.state === 'loading' ? 'loading' : undefined, attr: 'data-attn' })}</div>`;
  };
  ui.recurring = (state) => {
    const m = { planned: ['Planned', 'clock', ''], due: ['Due', 'alert', 'lg-badge--due'], posted: ['Posted', 'check', 'lg-badge--posted'] }[state];
    return `<span class="lg-badge ${m[2]}">${icon(m[1], 16)}${m[0]}</span>`;
  };
  ui.dayCell = (o) => {
    const p = o || {};
    const h = p.heat || 0;
    const style = p.up ? '--cell-bg:var(--positive-tint);--cell-fg:var(--positive)' : `--cell-bg:var(--heat-${h});--cell-fg:var(--on-heat-${h === 5 ? 'high' : 'low'})`;
    const marks = (p.marks || []).map((m) => ({ recurring: icon('repeat', 12, 'Recurring'), income: icon('up', 12, 'Income'), high: icon('flag', 12, 'High spending'), planned: icon('clock', 12, 'Planned') }[m])).join('');
    const cls = ['lg-cell', p.state && `is-${p.state}`, p.today && 'is-today', p.outside && 'is-outside', p.planned && 'is-planned'].filter(Boolean).join(' ');
    const cat = p.cat ? `<span class="lg-cell__cat">${icon(L.cat(p.cat).icon, 16)}</span>` : '';
    return `<button type="button" class="${cls}" style="${style}"${p.date ? ` data-day="${p.date}"` : ''}${p.selected ? ' aria-pressed="true"' : ''}${p.label ? ` aria-label="${esc(p.label)}"` : ''}${p.tip ? ` data-tip="${esc(p.tip)}"` : ''}><span class="lg-cell__top"><span class="lg-cell__date">${p.day}</span>${cat}</span><span class="lg-cell__amount"><span class="is-short">${p.amount || ''}</span><span class="is-full">${p.full || p.amount || ''}</span></span><span class="lg-cell__foot"><span class="lg-cell__marks">${marks}</span>${p.count ? `<span class="lg-cell__count">${p.count}</span>` : ''}</span></button>`;
  };
  ui.backup = (state) => {
    const m = {
      healthy: ['shieldCheck', 'Backed up 2 days ago', 'Data, attachments and settings. Verified.', ''],
      overdue: ['clock', 'Last backup 12 days ago', 'Open Ledgerly with your backup folder available.', 'Back up now'],
      failed: ['alert', 'Backup failed', 'Ledgerly could not write to your backup folder. Your data is safe on this phone.', 'Choose folder'],
    }[state];
    return `<div class="lg-card lg-card--flush"><div class="lg-backup lg-backup--${state}"><span class="lg-backup__icon">${icon(m[0], 24)}</span><span class="lg-row__body"><span class="lg-row__title" style="font-size:.875rem;line-height:1.25rem">${m[1]}</span><span class="lg-row__sub">${m[2]}</span>${m[3] ? `<span style="display:block;margin-top:8px">${ui.button(m[3], { kind: 'secondary', small: true })}</span>` : ''}</span></div></div>`;
  };
  ui.widget = (st) => `<div class="lg-widget ${st ? `is-${st}` : ''}"><span class="lg-widget__brand">${L.appIcon(32)}Add expense</span><button type="button" class="lg-widget__add ${st ? `is-${st}` : ''}" aria-label="Add a transaction">${icon('plus', 24)}</button></div>`;


  // ---- Categories ----
  ui.catTile = (c, size) => `<span class="lg-tile" style="--chip-color:${catColor(c)}">${c.img ? `<img src="${c.img}" alt="">` : icon(c.icon, size || 20)}</span>`;
  ui.categoryRow = (id, o) => {
    const p = o || {};
    const c = L.cat(id);
    const sub = p.state === 'error' ? 'Could not save this change' : p.state === 'disabled' ? 'Archived, kept in history' : D.accountsLabel(id);
    return `<button type="button" class="lg-row ${p.state ? `is-${p.state}` : ''}"${p.state === 'disabled' ? ' disabled' : ''}>${ui.catTile(c)}<span class="lg-row__body"><span class="lg-row__title">${esc(c.name)}</span><span class="lg-row__sub">${c.custom ? `<span class="lg-badge">Yours</span>` : ''}${sub}</span></span><span class="lg-row__trail lg-faint">${p.state === 'loading' ? '<span class="lg-spinner" aria-hidden="true"></span>' : icon('chevron', 20)}</span></button>`;
  };
  ui.categoryList = (kind, account) => D.categories(kind, account).map((id) => ui.categoryRow(id)).join('');
  ui.addChips = (account, kind, disabled) => `${D.categories(kind, account).slice(0, 6).map((id) => ui.chip(id, { disabled })).join('')}${ui.chipAll({ disabled })}${ui.chipLater({ disabled })}`;
  ui.iconPicker = (selected, o) => {
    const p = o || {};
    const names = p.names || L.pickIcons;
    return `<div class="lg-iconpick" role="group" aria-label="Icon">${names.map((n, i) => `<button type="button" class="lg-iconpick__item ${p.states && p.states[i] ? `is-${p.states[i]}` : ''}" aria-pressed="${n === selected}" aria-label="${n}" data-pick-icon="${n}"${p.states && p.states[i] === 'disabled' ? ' disabled' : ''}>${icon(n, 24)}</button>`).join('')}</div>`;
  };
  const SWATCHES = ['Indigo', 'Leaf', 'Sky', 'Orchid', 'Pine', 'Violet', 'Lavender', 'Periwinkle', 'Olive', 'Rose', 'Berry', 'Deep purple'];
  ui.colourPicker = (selected, o) => {
    const p = o || {};
    return `<div class="lg-colourpick" role="group" aria-label="Colour">${SWATCHES.map((n, i) => `<button type="button" class="lg-colourpick__item ${p.states && p.states[i] ? `is-${p.states[i]}` : ''}" style="--chip-color:var(--cat-${i + 1})" aria-pressed="${i + 1 === selected}" aria-label="${n}" data-pick-colour="${i + 1}"${p.states && p.states[i] === 'disabled' ? ' disabled' : ''}><span>${icon('check', 16)}</span></button>`).join('')}</div>`;
  };
  ui.accountPicker = (selected, o) => {
    const p = o || {};
    const all = !selected || !selected.length;
    return `<div class="lg-stack" data-pick-accounts style="gap:4px">${ui.switch('All accounts', { on: all }).replace('<input', '<input data-pick-all')}<div class="lg-accountpick" role="group" aria-label="Accounts">${D.ACCOUNTS.map((a, i) => {
      const on = !all && selected.includes(a.id);
      const st = p.states && p.states[i];
      return `<button type="button" class="lg-accountpick__item ${st ? `is-${st}` : ''}" aria-pressed="${on}" data-pick-account="${a.id}"${all || st === 'disabled' ? ' disabled' : ''}><span class="lg-accountpick__check">${icon('check', 16)}</span>${a.name}<span class="lg-faint caption">${a.cur === 'EUR' ? 'EUR' : 'KM'}</span></button>`;
    }).join('')}</div></div>`;
  };
  let editors = 0;
  ui.categoryEditor = (o) => {
    const p = o || {};
    editors += 1;
    const seed = { name: p.name || '', icon: p.icon || 'paw', slot: p.slot || 9 };
    const preview = { name: seed.name || 'New category', icon: seed.icon, slot: seed.slot };
    return `<div class="lg-cated" data-cat-editor data-kind="expense" data-icon="${seed.icon}" data-slot="${seed.slot}">
      <div class="lg-between"><h3 style="margin:0">New category</h3>${p.close ? `<button type="button" class="lg-icon-btn" aria-label="Close" data-cat-close>${icon('x', 20)}</button>` : ''}</div>
      <div class="lg-cated__preview" data-cat-preview>${ui.catTile(preview, 24)}<span class="lg-row__body"><span class="lg-row__title">${esc(preview.name)}</span><span class="lg-row__sub">${(p.accounts || []).map((a) => D.acc(a).name).join(', ') || 'All accounts'}</span></span></div>
      <div class="lg-field" data-cat-name><label class="lg-field__label" for="cat-name-${editors}">Name</label><span class="lg-input"><input id="cat-name-${editors}" value="${esc(seed.name)}" placeholder="For example Čišćenje" maxlength="32"></span><span class="lg-field__hint" data-cat-hint>Shown on chips and in reports.</span></div>
      <div class="lg-field"><span class="lg-field__label">Type</span>${ui.segmented([{ label: 'Expense', kind: 'expense', icon: 'down' }, { label: 'Income', kind: 'income', icon: 'up' }], { label: 'Type' })}</div>
      <div class="lg-field"><span class="lg-field__label">Icon</span>${ui.iconPicker(seed.icon)}<label class="lg-btn lg-btn--secondary lg-btn--small lg-btn--block lg-cated__upload">${icon('image', 20)}<span data-cat-upload-label>Use my own image</span><input type="file" accept="image/*" data-pick-image></label></div>
      <div class="lg-field"><span class="lg-field__label">Colour</span>${ui.colourPicker(seed.slot)}</div>
      <div class="lg-field"><span class="lg-field__label">Accounts</span>${ui.accountPicker(p.accounts)}<span class="lg-field__hint">It appears on the Add sheet for these accounts. History and reports always keep it.</span></div>
      ${ui.button('Save category', { kind: 'primary', block: true, attr: 'data-cat-save' })}
    </div>`;
  };

  // Forced-state grid used by the component specimens.
  ui.states = (cells) => `<div class="ds-states">${cells.map(([name, html]) => `<div class="ds-state"><div class="ds-state__name">${name}</div>${html}</div>`).join('')}</div>`;
  L.ui = ui;
})(window.Ledgerly = window.Ledgerly || {});

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
      <div class="lg-phone__head">${`<span class="lg-inline">${L.appIcon(32)}<span class="lg-wordmark">Ledgerly</span></span>`}<button type="button" class="lg-icon-btn" aria-label="Hide amounts" data-hide>${L.icon('eye', 20)}</button></div>
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

// Behaviour for specimens and proof screens. All of it is demonstration. Nothing is saved.
(function (L) {
  const D = L.data;
  L.mount = function (root) {
    root.addEventListener('click', function (e) {
      const t = e.target;
      const seg = t.closest('[data-seg] .lg-seg__item');
      if (seg && !seg.classList.contains('is-disabled')) {
        seg.parentNode.querySelectorAll('.lg-seg__item').forEach((b) => b.setAttribute('aria-pressed', b === seg));
        const range = seg.closest('[data-range-toggle]');
        if (range) {
          const isYear = seg.textContent === 'Year';
          seg.closest('.lg-phone').querySelectorAll('[data-range]').forEach((p) => { p.hidden = (p.dataset.range === 'year') !== isYear; });
        }
        const add = seg.closest('[data-add]');
        if (add && seg.dataset.kind) { add.dataset.kind = seg.dataset.kind; refreshChips(add); }
        const ed = seg.closest('[data-cat-editor]');
        if (ed && seg.dataset.kind) ed.dataset.kind = seg.dataset.kind;
        const cats = seg.closest('[data-cat-kind]');
        if (cats) { const phone = seg.closest('[data-cats]'); phone.dataset.kind = seg.dataset.kind; refreshCategories(phone); }
      }
      const pill = t.closest('[data-add-account]');
      if (pill) {
        const add = pill.closest('[data-add]');
        const order = D.ACCOUNTS.map((a) => a.id);
        add.dataset.account = order[(order.indexOf(add.dataset.account) + 1) % order.length];
        pill.querySelector('span').textContent = D.acc(add.dataset.account).name;
        paintAmount(add);
        refreshChips(add);
      }
      const filter = t.closest('[data-cat-filter]');
      if (filter) {
        const phone = filter.closest('[data-cats]');
        phone.querySelectorAll('[data-cat-filter]').forEach((b) => b.setAttribute('aria-pressed', b === filter));
        phone.dataset.account = filter.dataset.catFilter;
        refreshCategories(phone);
      }
      if (t.closest('[data-cat-new]')) t.closest('[data-cats]').querySelector('[data-cat-overlay]').hidden = false;
      if (t.closest('[data-cat-close]')) t.closest('[data-cat-overlay]').hidden = true;
      const pickIcon = t.closest('[data-pick-icon]');
      if (pickIcon) {
        const ed = pickIcon.closest('[data-cat-editor]');
        pickIcon.parentNode.querySelectorAll('[data-pick-icon]').forEach((b) => b.setAttribute('aria-pressed', b === pickIcon));
        if (ed) { ed.dataset.icon = pickIcon.dataset.pickIcon; ed.image = null; ed.querySelector('[data-cat-upload-label]').textContent = 'Use my own image'; paintPreview(ed); }
      }
      const pickColour = t.closest('[data-pick-colour]');
      if (pickColour) {
        const ed = pickColour.closest('[data-cat-editor]');
        pickColour.parentNode.querySelectorAll('[data-pick-colour]').forEach((b) => b.setAttribute('aria-pressed', b === pickColour));
        if (ed) { ed.dataset.slot = pickColour.dataset.pickColour; paintPreview(ed); }
      }
      const pickAccount = t.closest('[data-pick-account]');
      if (pickAccount) {
        pickAccount.setAttribute('aria-pressed', pickAccount.getAttribute('aria-pressed') !== 'true');
        const ed = pickAccount.closest('[data-cat-editor]');
        if (ed) paintPreview(ed);
      }
      const save = t.closest('[data-cat-save]');
      if (save) saveCategory(save.closest('[data-cat-editor]'));
      const bal = t.closest('[data-balance]');
      if (bal) {
        const open = bal.parentNode.classList.toggle('is-open');
        bal.setAttribute('aria-expanded', open);
      }
      const hide = t.closest('[data-hide]');
      if (hide) {
        const el = document.documentElement;
        el.dataset.amounts = el.dataset.amounts === 'hidden' ? '' : 'hidden';
      }
      const key = t.closest('[data-key]');
      if (key) press(key);
      const chip = t.closest('[data-add] [data-chip]');
      if (chip && !chip.disabled) saved(chip);
      const undo = t.closest('[data-undo]');
      if (undo) {
        if (undo.dataset.undoCat) {
          D.removeCategory(undo.dataset.undoCat);
          const phone = undo.closest('[data-cats]');
          if (phone) refreshCategories(phone);
        }
        undo.closest('.lg-toast').remove();
      }
      const attn = t.closest('[data-attn]');
      if (attn) {
        const row = attn.closest('.lg-attn');
        row.innerHTML = `<span class="lg-attn__icon" style="color:var(--positive)">${L.icon('check', 20)}</span><span class="lg-row__body"><span class="lg-row__sub">Done</span></span>`;
      }
      const cell = t.closest('[data-day]');
      if (cell) {
        const phone = cell.closest('.lg-phone') || root;
        phone.querySelectorAll('[data-day]').forEach((c) => c.setAttribute('aria-pressed', c === cell));
        const panel = phone.querySelector('[data-day-panel]');
        if (panel) panel.innerHTML = L.screens.dayPanel(cell.dataset.day);
        const figure = cell.closest('.lg-chart');
        const note = figure && figure.querySelector('[data-chart-tip]');
        if (note) note.textContent = cell.dataset.tip;
      }
      const line = t.closest('.lg-year__row[data-tip]');
      if (line) {
        const fig = line.closest('.lg-year');
        fig.querySelectorAll('[data-tip]').forEach((b) => b.setAttribute('aria-pressed', b === line));
        fig.querySelector('[data-chart-tip]').textContent = line.dataset.tip;
      }
      const mark = t.closest('.lg-chart .is-hit');
      if (mark) {
        const fig = mark.closest('.lg-chart');
        fig.querySelectorAll('[data-selected]').forEach((m) => m.removeAttribute('data-selected'));
        mark.setAttribute('data-selected', 'true');
        const tip = fig.querySelector('[data-chart-tip]');
        if (tip) tip.textContent = mark.dataset.tip;
      }
    });
    root.addEventListener('input', function (e) {
      const ed = e.target.closest('[data-cat-name]');
      if (ed) {
        ed.classList.remove('is-error');
        ed.querySelector('.lg-input').classList.remove('is-error');
        ed.querySelector('[data-cat-hint]').textContent = 'Shown on chips and in reports.';
        paintPreview(e.target.closest('[data-cat-editor]'));
      }
    });
    root.addEventListener('change', function (e) {
      const all = e.target.closest('[data-pick-all]');
      if (all) {
        const box = all.closest('[data-pick-accounts]');
        box.querySelectorAll('[data-pick-account]').forEach((b) => {
          b.disabled = all.checked;
          if (all.checked) b.setAttribute('aria-pressed', 'false');
        });
        paintPreview(all.closest('[data-cat-editor]'));
      }
      const image = e.target.closest('[data-pick-image]');
      if (image && image.files[0]) {
        const ed = image.closest('[data-cat-editor]');
        const reader = new FileReader();
        reader.onload = () => {
          ed.image = reader.result;
          ed.querySelectorAll('[data-pick-icon]').forEach((b) => b.setAttribute('aria-pressed', false));
          ed.querySelector('[data-cat-upload-label]').textContent = image.files[0].name;
          paintPreview(ed);
        };
        reader.readAsDataURL(image.files[0]);
      }
    });
    root.addEventListener('keydown', function (e) {
      if ((e.key === 'Enter' || e.key === ' ') && e.target.classList && e.target.classList.contains('is-hit')) {
        e.preventDefault();
        e.target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      }
    });
  };
  const curOf = (add) => D.acc(add.dataset.account).cur;
  const amountOf = (add) => Math.round(parseFloat(add.dataset.value || '0') * 100);
  function paintAmount(add) {
    const minor = amountOf(add);
    const out = add.querySelector('[data-amount]');
    out.innerHTML = L.money(minor, curOf(add));
    out.classList.toggle('is-empty', !minor);
  }
  // Chips follow the type and the account, because categories belong to accounts.
  function refreshChips(add) {
    const box = add.querySelector('[data-chips]');
    const minor = amountOf(add);
    if (add.dataset.kind === 'transfer') {
      box.innerHTML = L.ui.button('Save transfer', { kind: 'primary', block: true, state: minor ? undefined : 'disabled', attr: 'data-chip="Transfer"' });
      return;
    }
    box.innerHTML = L.ui.addChips(add.dataset.account, add.dataset.kind, !minor);
  }
  function press(key) {
    const add = key.closest('[data-add]');
    if (!add) return;
    const k = key.dataset.key;
    let v = add.dataset.value || '';
    if (k === 'del') v = v.slice(0, -1);
    else if (k === '.') { if (!v.includes('.')) v += v ? '.' : '0.'; }
    else if (!/\.\d\d$/.test(v) && v.length < 9) v += k;
    add.dataset.value = v;
    paintAmount(add);
    refreshChips(add);
  }
  function saved(chip) {
    const add = chip.closest('[data-add]');
    const minor = amountOf(add);
    const name = chip.dataset.chip;
    const where = name === 'Later' ? 'to Needs Review' : name === 'Transfer' ? 'as a transfer' : `in ${name}`;
    add.querySelector('[data-toast-slot]').innerHTML = L.ui.toast(`Saved ${L.money(minor, curOf(add))} ${where}`, { more: 'Add another' });
    add.dataset.value = '';
    paintAmount(add);
    refreshChips(add);
  }
  function refreshCategories(phone) {
    phone.querySelector('[data-cat-list]').innerHTML = L.ui.categoryList(phone.dataset.kind, phone.dataset.account || undefined);
  }
  function chosenAccounts(ed) {
    return [...ed.querySelectorAll('[data-pick-account][aria-pressed="true"]')].map((b) => b.dataset.pickAccount);
  }
  function paintPreview(ed) {
    const name = ed.querySelector('[data-cat-name] input').value.trim() || 'New category';
    const allOn = ed.querySelector('[data-pick-all]').checked;
    const accounts = chosenAccounts(ed).map((id) => D.acc(id).name).join(', ');
    const sub = allOn ? 'All accounts' : accounts || 'Choose at least one account';
    const tile = L.ui.catTile({ name, icon: ed.dataset.icon, slot: Number(ed.dataset.slot), img: ed.image }, 24);
    const box = ed.querySelector('[data-cat-preview]');
    box.innerHTML = `${tile}<span class="lg-row__body"><span class="lg-row__title"></span><span class="lg-row__sub">${sub}</span></span>`;
    box.querySelector('.lg-row__title').textContent = name;
  }
  function saveCategory(ed) {
    const field = ed.querySelector('[data-cat-name]');
    const input = field.querySelector('input');
    const name = input.value.trim();
    if (!name) {
      field.classList.add('is-error');
      field.querySelector('.lg-input').classList.add('is-error');
      field.querySelector('[data-cat-hint]').textContent = 'Give it a name first.';
      input.focus();
      return;
    }
    const allOn = ed.querySelector('[data-pick-all]').checked;
    const accounts = allOn ? [] : chosenAccounts(ed);
    if (!allOn && !accounts.length) { paintPreview(ed); return; }
    const id = `custom-${Date.now()}`;
    D.addCategory({ id, name, slot: Number(ed.dataset.slot), icon: ed.dataset.icon, img: ed.image, kind: ed.dataset.kind }, accounts);
    const phone = ed.closest('[data-cats]');
    if (phone) {
      refreshCategories(phone);
      ed.closest('[data-cat-overlay]').hidden = true;
    }
    const slot = (phone || ed.parentNode).querySelector('[data-toast-slot]');
    slot.innerHTML = L.ui.toast(`Added ${name.replace(/</g, '&lt;')}`);
    slot.querySelector('[data-undo]').dataset.undoCat = id;
    input.value = '';
    paintPreview(ed);
  }
})(window.Ledgerly = window.Ledgerly || {});

// The component catalogue: guidance and a live specimen for each component. build.mjs writes each
// entry out as a preview and a README. A note under `na` explains any state that cannot apply.
(function (L) {
  const ui = L.ui;
  const D = L.data;
  const ALL = ['default', 'pressed', 'focused', 'disabled', 'selected', 'loading', 'error'];
  const each = (fn) => ui.states(ALL.map((s) => [s[0].toUpperCase() + s.slice(1), fn(s === 'default' ? undefined : s)]));
  const sample = (flag) => D.transactions.find((t) => t.flags.includes(flag));
  const cat = [];
  const add = (group, name, height, summary, guide, render) => cat.push({ group, name, height, summary, guide, render });

  add('Foundations', 'ColourTokens', 520, 'Every semantic colour token for the current theme.', { provides: 'Nothing. Use the tokens by name.', do: 'Use `negative` for an expense amount as text.', dont: 'Use `negative-fill` for text. It only reaches 3:1.' }, () => `<div class="ds-swatches">${L.tokens.color.filter((t) => !/^(cat|chart|heat|on-heat)/.test(t)).map((t) => `<div class="ds-swatch"><i style="background:var(--${t})"></i><span>${t}</span></div>`).join('')}</div>`);
  add('Foundations', 'TypeScale', 460, 'The Inter type scale, with the balance as the largest element.', { provides: 'Class names such as `balance` and `amount`.', do: 'Set money in `balance`, `amount-large`, `amount` or `amount-small`.', dont: 'Set text below 12px, or body text below 14px.' }, () => L.tokens.type.map(([n, s]) => `<div class="lg-between" style="border-top:1px solid var(--border-subtle);padding:8px 0"><span class="${n}">${s}</span><span class="caption lg-faint">${n}</span></div>`).join(''));
  add('Foundations', 'Money', 300, 'Money with tabular numerals, a real minus and a primary amount above its conversion.', { provides: 'Minor units, currency, and an optional tone and sign.', do: 'Show the original amount first and the conversion smaller below it.', dont: 'Use a hyphen as a minus, or colour without a sign.' }, () => `<div class="lg-stack">
    <div class="lg-between"><span class="body-small lg-muted">Euro and marka</span><span class="amount">${L.money(123456, 'EUR')} · ${L.money(123456, 'BAM')}</span></div>
    <div class="lg-between"><span class="body-small lg-muted">Negative and positive</span><span class="amount">${L.money(-123456, 'EUR', { tone: 'negative' })} · ${L.money(123456, 'EUR', { sign: true, tone: 'positive' })}</span></div>
    <div class="lg-between"><span class="body-small lg-muted">Primary with conversion</span><span class="amount">${L.moneyPair(-3912, 'BAM', 2000, { tone: 'negative' })}</span></div>
    <div class="lg-between"><span class="body-small lg-muted">Very large, stepped down on a card</span></div>
    <div class="ds-do">${ui.balance({ value: 1234567890 })}${ui.metric('Spending', -98765432, { tone: 'negative' })}</div></div>`);
  add('Foundations', 'HiddenAmounts', 160, 'Masks every money value without moving the layout.', { provides: '`data-amounts="hidden"` on any ancestor.', do: 'Mask with the same dots whatever the length, so the mask reveals nothing.', dont: 'Leave chart axes or the real value in the accessibility tree. The app must render the label "Hidden amount" instead.' }, () => `<div data-amounts="hidden" class="lg-card lg-card--flush">${ui.tx(sample('split'))}${ui.tx(sample('refund'))}</div>`);
  add('Foundations', 'IconSet', 320, 'One 24px line icon set with a 1.75 stroke.', { provides: 'A name and a size of 16, 20 or 24.', do: 'Give an icon a label when it stands alone.', dont: 'Mix filled icons or another set.' }, () => `<div class="lg-inline">${L.iconNames.map((n) => `<span title="${n}" style="width:40px;height:40px;display:inline-flex;align-items:center;justify-content:center">${L.icon(n, 24)}</span>`).join('')}</div>`);

  add('Actions', 'Button', 240, 'The main action control.', { provides: 'A label, a kind and an optional icon.', do: 'Use one primary button per view.', dont: 'Use coral for a normal action. Danger is only for delete and reset.' }, () => `<div class="lg-stack"><div class="lg-inline">${ui.button('Primary', { kind: 'primary' })}${ui.button('Secondary', { kind: 'secondary' })}${ui.button('Quiet')}${ui.button('Delete category', { kind: 'danger' })}</div>${each((s) => ui.button('Confirm', { kind: 'primary', state: s, block: true }))}</div>`);
  add('Actions', 'TextInput', 260, 'A labelled field with hint and error.', { provides: 'A label, a value and an error message.', do: 'Keep the label above the field.', dont: 'Use the placeholder as the label.' }, () => each((s) => ui.input({ state: s, placeholder: 'Merchant', value: s === 'error' ? '0' : '', label: 'Merchant' })));
  add('Actions', 'SearchField', 170, 'Sticky search that also matches amounts.', { provides: 'A value. Results apply as you type.', do: 'Let 12.50 find amounts.', dont: 'Add a Search or Apply button.' }, () => each((s) => ui.search({ state: s, value: s === 'selected' ? '12.50' : '' })));
  add('Actions', 'Switch', 150, 'A setting that takes effect at once.', { provides: 'A label and a value.', do: 'Apply the change immediately.', dont: 'Pair it with a Save button.' }, () => each((s) => ui.switch('App lock', { state: s })));
  add('Actions', 'SegmentedControl', 170, 'Two to four options, one always selected.', { provides: 'Items and the selected index.', do: 'Keep labels to one word.', dont: 'Use it for actions.' }, () => `<div class="lg-stack">${ui.segmented(['List', 'Calendar'])}${ui.states([['Pressed', ui.segmented(['A', 'B'], { selected: 1, states: ['pressed'] })], ['Focused', ui.segmented(['A', 'B'], { selected: 1, states: ['focused'] })], ['Disabled', ui.segmented(['A', 'B'], { selected: 1, states: ['disabled'] })], ['Error', ui.segmented(['A', 'B'], { selected: 1, states: ['error'] })]])}</div>`);
  add('Actions', 'Checkbox', 150, 'One of many independent choices.', { provides: 'A label and a value.', do: 'Use it in multi-select and report sections.', dont: 'Use it for one instant setting. That is a switch.' }, () => each((s) => ui.checkbox('Include receipts', { state: s })));

  add('Layout', 'Card', 170, 'The base container, with a border instead of a heavy shadow.', { provides: 'Content, and an action if the whole card is pressable.', do: 'Keep padding at `space-4`.', dont: 'Nest cards.' }, () => each((s) => `<div class="lg-card ${s ? `is-${s}` : ''}">${s === 'loading' ? '<span class="lg-skel"></span>' : '<span class="label">Card</span>'}</div>`));
  add('Layout', 'ListRow', 260, 'A pressable row with lead, body and trailing content.', { provides: 'A title, a subtitle, an icon and trailing content.', do: 'Let long Bosnian names wrap.', dont: 'Truncate amounts.' }, () => `<div class="lg-card lg-card--flush">${[undefined, 'pressed', 'focused', 'disabled', 'selected', 'loading', 'error'].map((s) => ui.row({ title: s || 'Default', sub: s === 'error' ? 'Could not load this account' : 'Main Bank', state: s })).join('')}</div>`);
  add('Layout', 'SectionHeader', 90, 'Names a group, with one optional link.', { provides: 'A title and an optional action.', do: 'Keep it to two or three words.', dont: 'Add more than one action.' }, () => `${ui.section('Where it went', 'All')}${ui.section('Needs attention')}`);
  add('Layout', 'Tooltip', 110, 'A short definition, opened from the info icon.', { provides: 'A term and one sentence.', do: 'Define every metric the same way everywhere.', dont: 'Put actions in a tooltip.' }, () => `<div class="lg-inline">${ui.tooltip('Net', 'Income minus spending.')}${ui.tooltip('Spending', 'Expenses minus refunds.')}</div>`);

  add('Overlays', 'BottomSheet', 220, 'The default overlay on phones.', { provides: 'A title and content.', do: 'Keep actions at the bottom, in thumb reach.', dont: 'Stack two sheets.' }, () => `<div class="lg-scrim"><div class="lg-sheet"><div class="lg-sheet__grip"></div><h3>Date</h3><p>Choose a day for this entry.</p><div class="lg-stack">${ui.button('Yesterday', { kind: 'secondary', block: true })}</div></div></div>`);
  add('Overlays', 'Dialog', 240, 'Only for what Undo cannot reverse: restore, reset, deleting a category.', { provides: 'A title, a consequence and two actions.', do: 'Name the action on the button.', dont: 'Use a dialog when Undo would work.' }, () => `<div class="lg-scrim lg-scrim--center"><div class="lg-dialog"><h3>Delete category?</h3><p>Move its 42 transactions to another category first. This cannot be undone.</p><div class="lg-dialog__actions">${ui.button('Keep')}${ui.button('Delete', { kind: 'danger' })}</div></div></div>`);
  add('Overlays', 'Toast', 150, 'Confirms an action and offers Undo for 5 seconds.', { provides: 'A message and the Undo handler.', do: 'Say what happened, then offer Undo.', dont: 'Celebrate. No exclamation marks.' }, () => `<div class="lg-stack">${ui.toast(`Saved ${L.money(1250)} in Food`, { more: 'Add another' })}${ui.toast('Transaction deleted')}${ui.toast('Backup failed', { state: 'error', undo: false })}</div>`);

  add('Navigation', 'BottomNav', 180, 'Five items with a raised central Add button.', { provides: 'The active index.', do: 'Keep Add in the centre on every screen.', dont: 'Show more than five items.' }, () => `<div style="padding-top:28px">${ui.nav(0)}</div><div style="padding-top:28px">${ui.nav(1, { states: [undefined, undefined, undefined, 'pressed', 'focused'], addState: 'pressed' })}</div><div class="caption lg-faint" style="margin-top:8px">Second bar shows Add pressed, Analytics pressed and More focused. Items are never disabled; loading and error do not apply.</div>`);
  add('Navigation', 'NavRail', 380, 'The compact icon rail for tablets.', { provides: 'The active index.', do: 'Keep labels available to screen readers.', dont: 'Stretch the phone bar across a tablet.' }, () => ui.rail(0, [undefined, 'pressed', undefined, 'focused', 'disabled']));
  add('Navigation', 'Sidebar', 560, 'The labelled desktop sidebar, always with the read-only label.', { provides: 'The active index and the file date.', do: 'Keep the file date visible at all times.', dont: 'Add an Add button. Desktop is read-only.' }, () => `<div style="display:flex;height:540px">${ui.sidebar(2, [undefined, 'pressed', undefined, 'focused', 'disabled'])}</div>`);
  add('Navigation', 'ReadOnlyLabel', 80, 'Persistent reminder that desktop is a copy.', { provides: 'The file date.', do: 'Show the date and time of the file.', dont: 'Hide it to save space.' }, () => ui.readOnly());

  add('Patterns', 'StatePatterns', 460, 'Empty, loading and error patterns, in one visual style.', { provides: 'A heading, one sentence and at most one action.', do: 'Use the line ledger with one icon rising out of it.', dont: 'Use full-colour illustrations, mascots or guilt.' }, () => `<div class="lg-grid-2"><div class="lg-card lg-card--flush">${ui.state('empty')}</div><div class="lg-card lg-card--flush">${ui.state('error')}</div><div class="lg-card lg-card--flush">${ui.state('loading')}</div></div>`);

  add('Entry', 'Keypad', 280, 'The on-screen numeric keypad. Typing 12 means 12.00.', { provides: 'Key handlers.', do: 'Keep keys 56px tall or taller and the pad at phone width, 360px at most.', dont: 'Stretch the pad across a wide layout. Keys turn into thin bars.' }, () => `<div class="lg-stack">${ui.keypad()}${ui.states([['Default', ui.key('7')]].concat(['pressed', 'focused', 'disabled', 'selected', 'error'].map((s) => [s[0].toUpperCase() + s.slice(1), ui.key('7', s)])))}<div class="caption lg-faint">Loading does not apply: keys respond at once.</div></div>`);
  add('Entry', 'CategoryChip', 280, 'One tap saves in the normal flow. All and Later are the two special chips.', { provides: 'A category, or the All or Later variant.', do: 'Let chips take the width their label needs and flow onto the next row.', dont: 'Force chips into equal columns. Long names clip.' }, () => `<div class="lg-stack"><div class="lg-chips" style="max-width:336px">${ui.addChips('main', 'expense')}</div>${each((s) => ui.chip('food', { state: s }))}</div>`);
  add('Entry', 'AddTransaction', 640, 'The Add sheet: everything sits in thumb reach above the keypad.', { provides: 'Recent chips, the last used account, and templates.', do: 'Save on the chip tap. Show Undo and Add another afterwards.', dont: 'Add a Save button to the normal flow.' }, () => `<div style="max-width:360px;margin:0 auto">${L.screens.add()}</div>`);

  add('Ledger', 'TransactionRow', 420, 'A row with name, meta, indicators and amount.', { provides: 'A transaction.', do: 'Pair every colour with a sign.', dont: 'Show more than the small icons in a row.' }, () => `<div class="lg-card lg-card--flush">${['receipt', 'split', 'shared', 'recurring', 'refund', 'review'].map((f) => ui.tx(sample(f))).join('')}</div>${ui.states([['Pressed', ''], ['Focused', ''], ['Disabled', ''], ['Selected', ''], ['Loading', ''], ['Error', '']].map(([n]) => [n, `<div class="lg-card lg-card--flush">${ui.tx(sample('receipt'), { state: n.toLowerCase() })}</div>`]))}`);
  add('Ledger', 'TransferRow', 100, 'Neutral, with a two-way arrow. Never income or spending.', { provides: 'A transfer.', do: 'Name both accounts.', dont: 'Colour it green or coral.' }, () => `<div class="lg-card lg-card--flush">${ui.tx(D.transactions.find((t) => t.type === 'transfer'))}</div>`);
  add('Ledger', 'DayGroupHeader', 100, 'A sticky day label with the daily net.', { provides: 'A date and net.', do: 'Always show the sign.', dont: 'Count transfers in the daily net.' }, () => D.dayGroups(D.CURRENT).slice(0, 3).map((g) => ui.day(g.date, g.net)).join(''));
  add('Ledger', 'BalanceCard', 360, 'The largest element on any screen. Tap to expand every account in place.', { provides: 'Total, accounts, earmarked and free amounts.', do: 'Keep Total balance, Earmarked for goals and Free to use separate.', dont: 'Add anything larger on the same screen.' }, () => `<div class="ds-do">${ui.balance()}${ui.balance({ open: true })}${ui.balance({ state: 'loading' })}</div>`);
  add('Ledger', 'MetricTile', 200, 'Income, spending, net and savings rate, with a definition.', { provides: 'A label, a value and a comparison.', do: 'Keep the definition one tap away.', dont: 'Invent a new metric name.' }, () => {
    const m = D.month(D.CURRENT);
    return `<div class="lg-metrics">${ui.metric('Income', m.income, { sign: true, tone: 'positive', delta: 'Salary and freelance' })}${ui.metric('Spending', -m.spending, { tone: 'negative', delta: 'After refunds' })}${ui.metric('Net', m.net, { sign: true, tone: 'positive' })}${ui.metric('Savings rate', `${Math.round(m.rate * 100)}%`, { raw: true })}</div>${ui.states(['pressed', 'selected', 'disabled', 'loading', 'error'].map((s) => [s[0].toUpperCase() + s.slice(1), ui.metric('Net', m.net, { state: s, delta: s === 'error' ? 'Could not calculate' : '' })]))}`;
  });
  add('Ledger', 'BudgetBar', 240, 'Budget progress with a marker for today\'s expected pace.', { provides: 'Limit, spent and pace.', do: 'State the percentage in words beside the bar.', dont: 'Rely on the bar colour alone.' }, () => {
    return `<div class="lg-stack">${['normal', 'warning', 'over'].map((s) => ui.budget(D.budgets().find((b) => b.state === s))).join('')}</div>`;
  });
  add('Ledger', 'GoalProgress', 130, 'Money earmarked inside an account, not moved or spent.', { provides: 'Name, target and saved amount.', do: 'Call it earmarked.', dont: 'Subtract it from the total balance.' }, () => `<div class="lg-grid-2">${D.GOALS.map(ui.goal).join('')}</div>`);
  add('Ledger', 'NeedsAttentionRow', 230, 'A row with its action inside it.', { provides: 'A title, a reason and one action.', do: 'Show at most three on Home, hidden when empty.', dont: 'Link away when the action can run in the row.' }, () => `<div class="lg-card lg-card--flush">${ui.attention('BH Telecom Mobile', 'Due today, 35.00 KM', 'Confirm', { icon: 'repeat' })}${ui.attention('Pressed', 'Row pressed', 'Confirm', { state: 'pressed' })}${ui.attention('Selected', 'In bulk selection', 'Confirm', { state: 'selected' })}${ui.attention('Disabled', 'Already confirmed elsewhere', 'Confirm', { state: 'disabled' })}${ui.attention('Loading', 'Saving', 'Confirm', { state: 'loading' })}</div>`);
  add('Ledger', 'RecurringBadge', 70, 'Planned, Due and Posted. Due waits for one tap.', { provides: 'The state.', do: 'Keep icon and word together.', dont: 'Post silently.' }, () => `<div class="lg-inline">${ui.recurring('planned')}${ui.recurring('due')}${ui.recurring('posted')}</div>`);
  add('Ledger', 'CalendarDayCell', 300, 'Date, a signed amount with its currency, activity markers and a shade.', { provides: 'Day, net amount, heat step and markers.', do: 'Show the sign and the currency in every cell.', dont: 'Use the shade alone.' }, () => {
    const cell = (o) => `<div style="max-width:64px;container-type:inline-size">${ui.dayCell(o)}</div>`;
    return ui.states([['No spending', cell({ day: 10, amount: '€0' })]].concat([1, 2, 3, 4, 5].map((h) => [`Heat ${h}`, cell({ day: 12 + h, heat: h, amount: L.fmtCell(-h * 2100), marks: h === 5 ? ['high'] : h === 2 ? ['recurring'] : [] })]), [['Net gain', cell({ day: 28, up: true, amount: L.fmtCell(199386), marks: ['recurring', 'income'] })], ['Planned', cell({ day: 1, outside: true, planned: true, amount: L.fmtCell(-46016), marks: ['planned'] })], ['Around the month', cell({ day: 30, outside: true, amount: L.fmtCell(-3120) })]], ['pressed', 'focused', 'selected', 'disabled', 'loading', 'error'].map((s) => [s[0].toUpperCase() + s.slice(1), cell({ day: 9, heat: 2, amount: '\u2212€42', state: s })])));
  });
  add('Ledger', 'BackupStatus', 270, 'Healthy, overdue or failed, in plain words.', { provides: 'The state and dates.', do: 'Say that the data is safe when it is.', dont: 'Imply a server or an online state.' }, () => `<div class="lg-stack">${ui.backup('healthy')}${ui.backup('overdue')}${ui.backup('failed')}</div>`);
  add('Ledger', 'QuickAddWidget', 90, 'An Android home-screen shortcut. It shows no balances.', { provides: 'Nothing. It only opens the Add sheet.', do: 'Open straight to the keypad.', dont: 'Put any amount on the home screen.' }, () => `<div class="ds-do">${ui.widget()}${ui.widget('pressed')}${ui.widget('disabled')}</div>`);

  add('Category', 'CategoryIdentity', 420, 'Twelve curated colours and an open icon choice.', { provides: 'A category id.', do: 'Pick colours from the set. Income categories share colours with expense categories because they never appear in one chart.', dont: 'Offer a free colour picker.' }, () => `<div class="lg-chips">${L.tokens.categories.map(([id]) => ui.chip(id)).join('')}${ui.chip('pets')}</div>`);
  add('Category', 'CategoryRow', 300, 'A category in the management list, with the accounts it belongs to.', { provides: 'A category id.', do: 'Name the accounts on the row.', dont: 'Hide which accounts a category uses.' }, () => `<div class="lg-card lg-card--flush">${ui.categoryRow('pets')}${ui.categoryRow('bills')}${[['pressed'], ['selected'], ['disabled'], ['loading'], ['error']].map(([s]) => ui.categoryRow('food', { state: s })).join('')}</div>`);
  add('Category', 'IconPicker', 320, 'Any icon from the line set, or the person\'s own image.', { provides: 'The selected icon.', do: 'Offer the whole set and an image upload.', dont: 'Limit people to one icon per category family.' }, () => `<div class="lg-stack">${ui.iconPicker('paw')}${ui.states(['pressed', 'focused', 'disabled', 'selected'].map((s) => [s[0].toUpperCase() + s.slice(1), ui.iconPicker('', { names: ['paw'], states: [s] })]))}<div class="caption lg-faint">Loading and error do not apply to a local choice.</div></div>`);
  add('Category', 'CategoryColourPicker', 170, 'The twelve curated colours. There is no free colour picker.', { provides: 'The selected slot.', do: 'Mark the selected colour with a tick and a ring.', dont: 'Rely on the colour alone to show selection.' }, () => ui.colourPicker(9));
  add('Category', 'AccountPicker', 210, 'Ties a category to all accounts, or to the ones chosen.', { provides: 'The chosen account ids.', do: 'Default to All accounts.', dont: 'Allow saving with no account chosen.' }, () => `<div class="ds-do">${ui.accountPicker([])}${ui.accountPicker(['main', 'cash'])}</div>`);
  add('Category', 'CategoryEditor', 860, 'The form for a new category: name, type, icon, colour and accounts.', { provides: 'A save handler.', do: 'Show a live preview at the top.', dont: 'Make people leave the Add sheet to create one.' }, () => `<div style="max-width:360px;margin:0 auto">${ui.categoryEditor({ name: 'Pets', icon: 'paw', slot: 9, accounts: ['main', 'cash'] })}</div>`);

  add('Charts', 'ChartGroupedBars', 340, 'Grouped income and spending bars with a net line on the same axis.', { provides: 'Monthly totals.', do: 'Start the axis at zero.', dont: 'Use a second axis for net.' }, () => L.charts.grouped(6));
  add('Charts', 'ChartDonut', 560, 'A donut of at most six slices, always with a ranked list.', { provides: 'Ranked categories.', do: 'Colour by rank, and name the category with its icon.', dont: 'Add a seventh slice. Group the rest as Other.' }, () => L.charts.donut());
  add('Charts', 'ChartTrendLines', 260, 'Up to three lines, labelled directly, with dashes as a second cue.', { provides: 'Series.', do: 'Label the line ends.', dont: 'Rely on a legend.' }, () => L.charts.trends());
  add('Charts', 'ChartWeekdayBars', 260, 'Spending by weekday, with the peak picked out.', { provides: 'Seven totals.', do: 'Label each bar.', dont: 'Sort the days.' }, () => L.charts.weekday());
  add('Charts', 'ChartBalanceLine', 260, 'One line of total balance over time.', { provides: 'Daily or monthly balances.', do: 'Start at zero unless values cross it.', dont: 'Fill under the line with a gradient.' }, () => L.charts.balance());
  add('Charts', 'ChartCalendarHeat', 720, 'A month of daily net amounts, signed and in euros, with month totals. Wide layouts add the top category and the entry count.', { provides: 'Daily totals.', do: 'Show plus or minus and the currency in every cell.', dont: 'Leave blank gaps at the start of a month.' }, () => L.charts.calendarFull(D.TODAY));
  add('Charts', 'ChartYearLedger', 720, 'Twelve months as twelve ledger lines. Spending rises above the line and income hangs below it.', { provides: 'Daily totals.', do: 'Keep days in columns, so rent and payday line up down the year.', dont: 'Use a grid of squares by week.' }, () => L.charts.year());
  add('Charts', 'ChartPalette', 170, 'Six rank slots, a neutral Other and the sequential heat scale.', { provides: 'Slots, by rank.', do: 'Reuse slot 1 for the largest item.', dont: 'Use semantic colours as slots.' }, () => `<div class="ds-swatches">${[1, 2, 3, 4, 5, 6].map((i) => `<div class="ds-swatch"><i style="background:var(--chart-${i})"></i><span>chart-${i}</span></div>`).join('')}<div class="ds-swatch"><i style="background:var(--chart-other)"></i><span>chart-other</span></div></div><div style="margin-top:12px">${L.heatKey()}</div>`);
  add('Charts', 'ChartEmpty', 180, 'What a chart shows before there is data.', { provides: 'The question.', do: 'Keep the question as the title.', dont: 'Draw fake data.' }, () => L.charts.empty('Where did my money go?'));

  add('Brand', 'AppIcon', 200, 'An open isometric ledger with a solid line chart rising out of it. Temporary, because Ledgerly is a working name.', { provides: 'A size.', do: 'Use it at 32px or larger in the interface.', dont: 'Add currency signs or income and expense colours. The mark stays forest and mint.' }, () => `<div class="lg-stack"><div class="ds-iconrow">${L.appIcon(128)}${L.appIcon(72)}${L.appIcon(48)}${L.appIcon(32)}${L.appIcon(24)}</div><div class="lg-inline"><span class="lg-badge lg-badge--proto">Temporary</span>${L.appIcon(32)}<span class="lg-wordmark">Ledgerly</span></div></div>`);
  add('Brand', 'PrintStyle', 460, 'PDF reports: light only and readable in black and white.', { provides: 'Report data.', do: 'Use patterns and words instead of colour.', dont: 'Print the dark theme.' }, () => {
    const m = D.month(D.CURRENT);
    const top = m.ranked[0].amount;
    return `<div class="lg-print"><h3>October 2026</h3><div>Income ${L.fmt(m.income, 'EUR')} · Spending ${L.fmt(m.spending, 'EUR')} · Net ${L.fmt(m.net, 'EUR', true)}</div><table><thead><tr><th>Category</th><th></th><th>Spent</th></tr></thead><tbody>${m.ranked.slice(0, 6).map((r) => `<tr><td>${L.cat(r.cat).name}</td><td><span class="lg-print__bar" style="width:${Math.round((r.amount / top) * 160)}px"></span></td><td>${L.fmt(r.amount, 'EUR')}</td></tr>`).join('')}</tbody></table></div>`;
  });

  add('Proof', 'ScreenHome', 1700, 'Prototype. Home on phone, light and dark.', { provides: 'Nothing. A composition.', do: 'Check figures against the other screens.', dont: 'Treat this as implemented.' }, () => L.proof('Home on phone', L.screens.home));
  add('Proof', 'ScreenAddTransaction', 820, 'Prototype. The Add sheet on phone. The keypad, type switch and account pill work.', { provides: 'Nothing. A composition.', do: 'Tap the account pill and watch the chips follow it.', dont: 'Treat this as implemented.' }, () => L.proof('Add transaction on phone', L.screens.add));
  add('Proof', 'ScreenCategories', 1040, 'Prototype. Custom categories on phone. Filter by account, then add one.', { provides: 'Nothing. A composition.', do: 'Add a category and watch it join the list.', dont: 'Treat this as implemented.' }, () => L.proof('Categories on phone', L.screens.categories));
  add('Proof', 'ScreenCategoryEditor', 1000, 'Prototype. The new category sheet on phone.', { provides: 'Nothing. A composition.', do: 'Change the icon, colour and accounts.', dont: 'Treat this as implemented.' }, () => L.proof('New category on phone', L.screens.categoryEditor));
  add('Proof', 'ScreenHistory', 1040, 'Prototype. Transaction history on phone.', { provides: 'Nothing. A composition.', do: 'Check the daily totals against Calendar.', dont: 'Treat this as implemented.' }, () => L.proof('Transaction history on phone', L.screens.history));
  add('Proof', 'ScreenCalendar', 1120, 'Prototype. Calendar month on phone. Tap a day.', { provides: 'Nothing. A composition.', do: 'Tap a day to see its details.', dont: 'Treat this as implemented.' }, () => L.proof('Calendar month on phone', L.screens.calendar));
  add('Proof', 'ScreenAnalytics', 2800, 'Prototype. Analytics overview on desktop with sidebar.', { provides: 'Nothing. A composition.', do: 'Select a bar to see its figures.', dont: 'Treat this as implemented.' }, () => L.proofWide('Analytics overview on desktop', L.screens.analytics));

  L.catalog = cat;
  L.renderCard = function (name, el) {
    const c = cat.find((x) => x.name === name);
    el.classList.add('lg-root');
    el.innerHTML = c.render();
    L.mount(el);
  };
})(window.Ledgerly = window.Ledgerly || {});
