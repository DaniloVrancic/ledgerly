// The single-file design system page.
(function () {
  const L = window.Ledgerly;
  const docs = window.LEDGERLY_DOCS;
  const html = document.documentElement;
  const nav = document.getElementById('nav');
  const bar = document.getElementById('bar');
  const content = document.getElementById('content');
  const store = {
    get(k) { try { return localStorage.getItem(`lg-${k}`); } catch (e) { return null; } },
    set(k, v) { try { localStorage.setItem(`lg-${k}`, v); } catch (e) { /* preference only */ } },
  };
  let mode = store.get('mode') || 'light';

  function inline(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/`([^`]+)`/g, '<code>$1</code>').replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
  }
  function md(text) {
    const lines = text.trim().split('\n');
    let out = '';
    let list = false;
    for (let i = 0; i < lines.length; i++) {
      const l = lines[i];
      if (/^\|/.test(l)) {
        const cells = (r) => r.replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
        const head = cells(l).map((c) => `<th>${inline(c)}</th>`).join('');
        i += 2;
        let body = '';
        for (; i < lines.length && /^\|/.test(lines[i]); i++) body += `<tr>${cells(lines[i]).map((c) => `<td>${inline(c)}</td>`).join('')}</tr>`;
        i--;
        out += `<table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
        continue;
      }
      if (/^- /.test(l)) { if (!list) { out += '<ul>'; list = true; } out += `<li>${inline(l.slice(2))}</li>`; continue; }
      if (list) { out += '</ul>'; list = false; }
      if (/^## /.test(l)) out += `<h2>${inline(l.slice(3))}</h2>`;
      else if (/^# /.test(l)) out += '';
      else if (l.trim()) out += `<p>${inline(l)}</p>`;
    }
    return out + (list ? '</ul>' : '');
  }

  const groups = [...new Set(L.catalog.map((c) => c.group))];
  const prose = [['overview', 'Overview', 'README'], ['contrast', 'Colour and contrast', 'contrast'], ['dataviz', 'Data visualisation', 'data-visualisation'], ['categories', 'Custom categories', 'categories'], ['writing', 'Writing', 'writing'], ['brand', 'Brand, print, privacy', 'also'], ['usage', 'Usage rules', 'usage']];

  nav.innerHTML = `<div class="lg-inline" style="padding:0 12px 12px">${L.appIcon(32)}<span class="lg-wordmark">Ledgerly</span></div>`
    + prose.map(([id, name]) => `<a href="#${id}">${name}</a>`).join('')
    + groups.map((g) => `<div class="site-nav__group">${g}</div><a href="#group-${g}">All ${g.toLowerCase()}</a>`).join('')
    + '<div class="site-nav__group">Files</div><a href="#tokens">Tokens</a>';

  function barHtml() {
    const seg = (items, cur, key) => `<div class="lg-seg lg-seg--small" data-ctl="${key}">${items.map(([v, n]) => `<button type="button" class="lg-seg__item" aria-pressed="${v === cur}" data-v="${v}">${n}</button>`).join('')}</div>`;
    return `<label>Theme ${seg([['light', 'Light'], ['dark', 'Dark'], ['both', 'Both']], mode, 'mode')}</label>
      <label>Accent <select data-ctl="accent">${L.tokens.accents.map((a) => `<option value="${a.id}"${html.dataset.accent === a.id ? ' selected' : ''}>${a.name}</option>`).join('')}</select></label>
      <label>Text size <select data-ctl="scale"><option value="100">100%</option><option value="130">130%</option><option value="200">200%</option></select></label>
      ${L.ui.switch('Hide amounts').replace('lg-switch "', 'lg-switch" data-ctl="hide"')}`;
  }

  function pane(c, theme) {
    const wide = c.group === 'Proof' || c.height > 900;
    return `<div class="site-comp__pane lg-root" ${theme ? `data-theme="${theme}"` : ''} data-render="${c.name}"${wide ? ' data-wide' : ''}></div>`;
  }
  function renderPanes() {
    document.querySelectorAll('[data-spec]').forEach((box) => {
      const c = L.catalog.find((x) => x.name === box.dataset.spec);
      const both = mode === 'both' && c.group !== 'Proof';
      box.innerHTML = both ? pane(c, 'light') + pane(c, 'dark') : pane(c);
    });
    document.querySelectorAll('[data-render]').forEach((el) => {
      const c = L.catalog.find((x) => x.name === el.dataset.render);
      el.innerHTML = c.render();
    });
  }
  function page() {
    const sec = (id, title, body) => `<section class="site-section" id="${id}">${title ? `<h2>${title}</h2>` : ''}${body}</section>`;
    const textual = prose.map(([id, name, key]) => sec(id, name, `<div class="prose ${id === 'contrast' || id === 'usage' ? 'prose--wide' : ''}">${md(docs[key])}</div>`)).join('');
    const comps = groups.map((g) => sec(`group-${g}`, g, L.catalog.filter((c) => c.group === g).map((c) => `<article class="site-comp" id="c-${c.name}"><h3>${c.name}</h3><p class="site-comp__sum">${c.summary}</p><div class="site-comp__spec" data-spec="${c.name}"></div><div class="site-do"><div><b>Do</b><span>${inline(c.guide.do)}</span></div><div><b>Don't</b><span>${inline(c.guide.dont)}</span></div></div></article>`).join(''))).join('');
    const tokens = sec('tokens', 'Tokens', `<div class="prose prose--wide"><p>These are the same tokens in two formats, generated from one source by <code>build.mjs</code>.</p></div><h3 class="title">tokens.css</h3><div class="site-code" tabindex="0"></div><h3 class="title">tokens.json</h3><div class="site-code" tabindex="0"></div>`);
    content.innerHTML = textual + comps + tokens;
    const codes = content.querySelectorAll('.site-code');
    codes[0].textContent = window.LEDGERLY_TOKENS_CSS;
    codes[1].textContent = window.LEDGERLY_TOKENS_JSON;
  }

  function applyMode() {
    html.dataset.theme = mode === 'dark' ? 'dark' : 'light';
    store.set('mode', mode);
    renderPanes();
  }
  bar.innerHTML = barHtml();
  bar.addEventListener('click', (e) => {
    const b = e.target.closest('[data-ctl="mode"] [data-v]');
    if (!b) return;
    mode = b.dataset.v;
    bar.querySelectorAll('[data-ctl="mode"] [data-v]').forEach((x) => x.setAttribute('aria-pressed', x === b));
    applyMode();
  });
  bar.addEventListener('change', (e) => {
    const ctl = e.target.dataset.ctl;
    if (ctl === 'accent') { html.dataset.accent = e.target.value === 'forest' ? '' : e.target.value; store.set('accent', e.target.value); }
    if (ctl === 'scale') html.style.fontSize = `${e.target.value}%`;
    if (e.target.getAttribute('role') === 'switch') html.dataset.amounts = e.target.checked ? 'hidden' : '';
  });
  const savedAccent = store.get('accent');
  if (savedAccent && savedAccent !== 'forest') { html.dataset.accent = savedAccent; bar.querySelector('[data-ctl="accent"]').value = savedAccent; }
  page();
  applyMode();
  L.mount(content);
})();
