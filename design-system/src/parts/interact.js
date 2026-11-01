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
