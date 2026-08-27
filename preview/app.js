// Nexus Gym — protótipo web interativo (espelha o app Flutter).
// Mesma lógica de negócio em logic.js; persistência em localStorage.
import * as L from './logic.js';

// ------------------------------------------------------------------ estado

const KEY = 'nexus_gym_v1';

function freshDb() {
  return { exercises: [], templates: [], sessions: [], sets: [], cardio: [], active: null };
}

function loadDb() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return freshDb();
    const db = JSON.parse(raw);
    return { ...freshDb(), ...db };
  } catch {
    return freshDb();
  }
}

let db = loadDb();
let view = { name: 'home' };
let editorDraft = null; // { name, items }
let inputs = {}; // { [exerciseId]: { wW, wR, pW, pR, kW, kR } } — valores dos campos durante o treino
let cardioDraft = { type: null, duration: 20, distance: '', note: '' };
let editingSet = null; // { set, weightText, repsText }
let picker = null; // { templateDraftRef }
let toastTimer = null;

function save() {
  localStorage.setItem(KEY, JSON.stringify(db));
}

// ------------------------------------------------------------------ helpers

const $ = (sel, el = document) => el.querySelector(sel);
const root = () => $('#root');
const esc = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));

const I = {
  plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
  chevronR: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 6 6 6-6 6"/></svg>',
  chevronL: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m15 6-6 6 6 6"/></svg>',
  back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5m0 0 7 7m-7-7 7-7"/></svg>',
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="m4.5 12.5 5 5 10-11"/></svg>',
  trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/></svg>',
  close: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>',
  drag: '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="9" cy="6" r="1.6"/><circle cx="15" cy="6" r="1.6"/><circle cx="9" cy="12" r="1.6"/><circle cx="15" cy="12" r="1.6"/><circle cx="9" cy="18" r="1.6"/><circle cx="15" cy="18" r="1.6"/></svg>',
  history: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3.5 2"/></svg>',
  clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
  dumbbell: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6.5 6.5v11M17.5 6.5v11M3 9v6M21 9v6M6.5 12h11"/></svg>',
  play: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l11-6.5z"/></svg>',
  edit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h4L19.5 8.5a2.1 2.1 0 0 0-3-3L5 17z"/><path d="m13.5 6.5 3 3"/></svg>',
  search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>',
  flag: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21V4m0 1h13l-2.5 4L18 13H5"/></svg>',
  insights: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 19V5m0 14h16M8 15v-4m4 4V8m4 7v-6"/></svg>',
  checkBig: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" width="44" height="44"><path d="m4.5 12.5 5 5 10-11"/></svg>',
};

function byId(id, list = []) {
  return list.find((x) => x.id === id);
}

function currentWorkout() {
  if (!db.active) return null;
  const session = byId(db.active.sessionId, db.sessions);
  if (!session) return null;
  const template = session.templateId ? byId(session.templateId, db.templates) : null;
  const items = template ? template.items : [];
  return { session, items, page: db.active.page };
}

function referenceFor(exerciseId, sessionId) {
  const prev = L.previousWorkSets(db, exerciseId, sessionId);
  return L.referenceFromWorkSets(prev.map((s) => s.weightKg));
}

function exerciseSets(exerciseId) {
  const session = db.active;
  if (!session) return [];
  return db.sets.filter((s) => s.sessionId === session.sessionId && s.exerciseId === exerciseId);
}

function getInputs(exerciseId) {
  if (!inputs[exerciseId]) {
    inputs[exerciseId] = { wW: '', wR: '10', pW: '', pR: '10', kW: '', kR: '10' };
  }
  return inputs[exerciseId];
}

function showToast(msg, undoFn) {
  const el = $('#toast-root');
  el.innerHTML = '';
  const t = document.createElement('div');
  t.className = 'toast';
  t.innerHTML = `<span>${esc(msg)}</span>`;
  if (undoFn) {
    const b = document.createElement('button');
    b.textContent = 'DESFAZER';
    b.onclick = () => { undoFn(); el.innerHTML = ''; };
    t.appendChild(b);
  }
  el.appendChild(t);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.innerHTML = ''; }, 4000);
}

function closeModal() { $('#modal-root').innerHTML = ''; }

// ------------------------------------------------------------------ render

function render() {
  const el = root();
  const fab = $('#fab');
  switch (view.name) {
    case 'home': el.innerHTML = renderHome(); break;
    case 'history': el.innerHTML = renderHistory(); break;
    case 'template': el.innerHTML = renderTemplate(); break;
    case 'editor': el.innerHTML = renderEditor(); break;
    case 'workout': el.innerHTML = renderWorkout(); break;
    case 'summary': el.innerHTML = renderSummary(); break;
    case 'session': el.innerHTML = renderSessionDetail(); break;
    case 'exerciseHistory': el.innerHTML = renderExerciseHistory(); break;
    default: el.innerHTML = renderHome();
  }
  fab.style.display = view.name === 'home' ? 'flex' : 'none';
  startTimer();
}

function renderHistory() {
  return `
    <div class="screen">
      <div class="home-head">
        <div class="brand">NEXUS <span class="dot">●</span></div>
        <div class="body-faint">${L.formatDayLabel(new Date())}</div>
      </div>
      <div class="topbar" style="padding:14px 24px 0">
        <div class="title">HISTÓRICO</div>
      </div>
      <div style="flex:1;display:flex;flex-direction:column;min-height:0">
        <div style="flex:1;overflow-y:auto;display:flex;flex-direction:column">
          ${renderHistoryList()}
        </div>
        <div class="bottom-nav">
          <button class="nav-tab" data-action="tab" data-tab="0">${I.dumbbell}<span>TREINOS</span></button>
          <button class="nav-tab selected" data-action="tab" data-tab="1">${I.history}<span>HISTÓRICO</span></button>
        </div>
      </div>
    </div>
  `;
}

function renderTemplate() {
  const t = byId(view.templateId, db.templates);
  if (!t) { view = { name: 'home' }; return renderHome(); }
  return `
    <div class="screen">
      <div class="topbar">
        <button class="icon-btn" data-action="back">${I.back}</button>
        <div style="flex:1"></div>
      </div>
      <div style="padding:8px 24px 0">
        <div class="display-l">${esc(t.name.toUpperCase())}</div>
        <div class="body-dim mt-8">${t.items.length ? `${t.items.length} exercícios` : 'nenhum exercício ainda'}</div>
      </div>
      <div style="flex:1;overflow-y:auto;padding:24px 24px 8px">
        ${
          t.items.length === 0
            ? `<div class="body-faint" style="padding:16px 0">Adicione exercícios para iniciar o treino.</div>`
            : t.items
                .map(
                  (it, i) => {
                    const ex = byId(it.exerciseId, db.exercises);
                    return `<div style="display:flex;align-items:center;gap:12px;margin-bottom:10px">
                      <div class="num" style="width:30px;font-size:17px;color:var(--faint)">${i + 1}</div>
                      <div class="card" style="flex:1;margin:0;cursor:default">
                        <div style="font-size:15px;font-weight:700">${esc(ex ? ex.name : 'Exercício')}</div>
                        <div style="font-size:10.5px;letter-spacing:1.2px;color:var(--faint);font-weight:600;margin-top:2px">${ex ? esc(ex.muscleGroup.toUpperCase()) : ''}</div>
                      </div>
                      <div style="display:flex;gap:6px;flex:none">
                        ${it.warmup ? `<span class="stage-chip" style="padding:4px 8px;font-size:9.5px">AQ</span>` : ''}
                        ${it.prep ? `<span class="stage-chip" style="padding:4px 8px;font-size:9.5px">PR</span>` : ''}
                      </div>
                    </div>`;
                  }
                )
                .join('')
        }
      </div>
      <div style="padding:8px 24px 24px;display:flex;flex-direction:column;gap:10px">
        <button class="btn" data-action="start-workout" data-id="${t.id}" ${t.items.length === 0 ? 'disabled' : ''}>${I.play} Iniciar treino</button>
        <button class="btn ghost" data-action="edit-template" data-id="${t.id}">Editar treino</button>
      </div>
    </div>
  `;
}

// ------------------------------------------------------------------ home

function renderHome() {
  const templates = [...db.templates].sort((a, b) => b.updatedAt - a.updatedAt);
  const lastRun = new Map();
  db.sessions
    .filter((s) => s.endedAt)
    .forEach((s) => {
      if (!s.templateId) return;
      const prev = lastRun.get(s.templateId);
      if (!prev || s.startedAt > prev) lastRun.set(s.templateId, s.startedAt);
    });

  const active = db.active ? byId(db.active.sessionId, db.sessions) : null;

  const cards =
    templates.length === 0
      ? `<div class="empty">
          <div class="icon-circle">${I.dumbbell}</div>
          <div style="font-size:17px;font-weight:700">Nenhum treino ainda</div>
          <div class="body-dim">Crie seu primeiro treino e adicione os exercícios.</div>
          <button class="btn mt-22" data-action="new-template">Criar primeiro treino</button>
        </div>`
      : `<div class="list">
          ${templates.map((t) => {
            const lr = lastRun.get(t.id);
            const meta =
              t.items.length === 0
                ? 'adicione exercícios'
                : `${t.items.length} exercícios${lr ? ` · último ${L.formatDateShort(new Date(lr))}` : ''}`;
            return `<div class="card" data-action="open-template" data-id="${t.id}">
              <div class="card-title">${esc(t.name.toUpperCase())}</div>
              <div class="card-meta">${meta}</div>
            </div>`;
          }).join('')}
        </div>`;

  const activeCard = active
    ? `<div class="card active" data-action="resume" data-id="${active.id}" style="margin:0 24px 14px">
        <div class="label accent">Treino em andamento</div>
        <div style="font-size:17px;font-weight:800;letter-spacing:.3px;margin-top:6px">${esc(active.templateName.toUpperCase())}</div>
        <div class="card-meta" style="margin-top:2px">iniciado às ${L.formatTime(new Date(active.startedAt))}</div>
      </div>`
    : '';

  const history = view.name === 'history' ? 1 : 0;

  return `
    <div class="screen">
      <div class="home-head">
        <div class="brand">NEXUS <span class="dot">●</span></div>
        <div class="body-faint">${L.formatDayLabel(new Date())}</div>
      </div>
      <div style="padding-top:18px">
        ${activeCard}
        ${view.name === 'home' ? cards : renderHistoryList()}
      </div>
    </div>
    ${view.name === 'home' ? `
    <div class="bottom-nav">
      <button class="nav-tab selected" data-action="tab" data-tab="0">
        ${I.dumbbell}<span>TREINOS</span>
      </button>
      <button class="nav-tab" data-action="tab" data-tab="1">
        ${I.history}<span>HISTÓRICO</span>
      </button>
    </div>` : `
    <div class="bottom-nav">
      <button class="nav-tab" data-action="tab" data-tab="0">${I.dumbbell}<span>TREINOS</span></button>
      <button class="nav-tab selected" data-action="tab" data-tab="1">${I.history}<span>HISTÓRICO</span></button>
    </div>`}
  `;
}

function renderHistoryList() {
  const summaries = db.sessions
    .filter((s) => s.endedAt)
    .sort((a, b) => b.startedAt - a.startedAt);
  if (summaries.length === 0) {
    return `<div class="empty">
      <div class="icon-circle">${I.history}</div>
      <div class="body-dim">Nenhum treino realizado ainda</div>
    </div>`;
  }
  const groups = [];
  summaries.forEach((s) => {
    const k = L.dateKey(new Date(s.startedAt));
    let g = groups.find((x) => x.key === k);
    if (!g) { g = { key: k, items: [] }; groups.push(g); }
    g.items.push(s);
  });
  return `<div class="list" style="padding-bottom:110px">
    ${groups
      .map(
        (g) => `<div class="date-group">
          <div class="label" style="padding:0 24px">${L.formatDate(L.parseDateKey(g.key)).toUpperCase()}</div>
          ${g.items
            .map((s) => {
              const c = db.cardio.find((x) => x.sessionId === s.id);
              const meta = `${Math.max(1, Math.round((s.endedAt - s.startedAt) / 60000))} min · ${s.exerciseCount} exercícios${c ? ` · ${c.type} ${c.durationMinutes} min` : ''}`;
              return `<div class="card" data-action="open-session" data-id="${s.id}" style="margin-left:24px;margin-right:24px">
                <div class="card-title">${esc(s.templateName.toUpperCase())}</div>
                <div class="card-meta">${meta}</div>
              </div>`;
            })
            .join('')}
        </div>`
      )
      .join('')}
  </div>`;
}

// ------------------------------------------------------------------ editor

function openEditor(templateId) {
  const t = templateId ? byId(templateId, db.templates) : null;
  editorDraft = t
    ? { name: t.name, items: t.items.map((i) => ({ ...i })), originalId: t.id }
    : { name: '', items: [], originalId: null };
  view = { name: 'editor' };
  render();
}

function renderEditor() {
  const d = editorDraft;
  if (!d) { view = { name: 'home' }; return renderHome(); }
  const itemsHtml = d.items
    .map(
      (it, i) => {
        const ex = byId(it.exerciseId, db.exercises);
        return `<div class="editor-item" draggable="true" data-drag="${i}">
          <span class="drag">${I.drag}</span>
          <div class="info">
            <div class="e-name">${esc(ex ? ex.name : 'Exercício')}</div>
            <div class="e-muscle">${esc(ex ? ex.muscleGroup.toUpperCase() : '')}</div>
          </div>
          <button class="stage-toggle ${it.warmup ? 'on' : ''}" data-action="toggle-warmup" data-i="${i}">AQ</button>
          <button class="stage-toggle ${it.prep ? 'on' : ''}" data-action="toggle-prep" data-i="${i}">PR</button>
          <button class="del" data-action="remove-item" data-i="${i}">${I.close}</button>
        </div>`;
      }
    )
    .join('');

  return `
    <div class="screen" style="padding-bottom:0">
      <div class="topbar">
        <button class="icon-btn" data-action="back">${I.back}</button>
        <input class="name-input" data-bind="editor-name" placeholder="NOME DO TREINO" value="${esc(d.name)}" />
      </div>
      <div class="divider" style="margin:6px 0 12px"></div>
      <div style="flex:1;overflow-y:auto;padding:0 24px 8px">
        ${
          d.items.length === 0
            ? `<div class="empty" style="flex:none;padding:60px 36px"><div class="body-faint">Toque em "Adicionar exercício"<br/>para montar o treino</div></div>`
            : itemsHtml
        }
      </div>
      <div class="editor-actions">
        <button class="btn ghost small" data-action="open-picker">${I.plus} Adicionar exercício</button>
        ${d.originalId ? `<button class="btn-text danger" style="align-self:center" data-action="delete-template">EXCLUIR TREINO</button>` : ''}
        <button class="btn" data-action="save-template">Salvar treino</button>
      </div>
    </div>
  `;
}

function renderPicker() {
  const search = picker && picker.search ? picker.search : '';
  const filtered = db.exercises
    .filter((e) => !search || e.name.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => a.name.localeCompare(b.name, 'pt'));
  const inTemplate = new Set(editorDraft.items.map((i) => i.exerciseId));

  const listHtml =
    filtered.length === 0
      ? `<div class="body-faint" style="padding:20px 6px">Nenhum exercício encontrado</div>`
      : filtered
          .map(
            (ex) => `<div class="row" data-action="add-exercise" data-id="${ex.id}" ${inTemplate.has(ex.id) ? 'style="opacity:.45;cursor:default"' : ''}>
            <div class="info">
              <div class="n">${esc(ex.name)}</div>
              <div class="g">${esc(ex.muscleGroup.toUpperCase())}</div>
            </div>
            <span class="ic ${inTemplate.has(ex.id) ? 'added' : ''}">${inTemplate.has(ex.id) ? I.check : I.plus}</span>
          </div>`
          )
          .join('');

  openModal(`
    <div style="display:flex;align-items:center;justify-content:space-between">
      <div class="section-title">EXERCÍCIOS</div>
      <button class="icon-btn" data-action="close-modal">${I.close}</button>
    </div>
    <div class="search-wrap mt-16">
      ${I.search}
      <input class="text-input" data-bind="picker-search" placeholder="Buscar exercício" value="${esc(search)}" />
    </div>
    <div class="exercise-list">${listHtml}</div>
    <div class="divider"></div>
    <div class="label" style="margin-bottom:10px">Novo exercício</div>
    <input class="text-input" data-bind="new-exercise-name" placeholder="Nome (ex.: Supino reto)" value="${esc(picker && picker.newName ? picker.newName : '')}" />
    <div class="chips mt-10">
      ${L.MUSCLE_GROUPS.map(
        (g) => `<button class="chip sm ${picker && picker.group === g ? 'selected' : ''}" data-action="picker-group" data-g="${esc(g)}">${esc(g)}</button>`
      ).join('')}
    </div>
    <button class="btn small mt-16" data-action="create-exercise">Criar e adicionar</button>
  `);
}

// ------------------------------------------------------------------ workout

function renderWorkout() {
  const w = currentWorkout();
  if (!w) { view = { name: 'home' }; return renderHome(); }
  const total = w.items.length;
  const atCardio = w.page >= total;
  const progress = total === 0 ? 1 : (w.page + 1) / (total + 1);

  const page = atCardio ? renderCardioPage() : renderExercisePage(w, w.page);

  const footer = atCardio
    ? ''
    : `<div class="workout-footer">
        <button class="btn" data-action="next-exercise">
          ${w.page === total - 1 ? 'Ir para cardio' : 'Próximo exercício'}
          ${I.chevronR}
        </button>
      </div>`;

  return `
    <div class="screen" style="padding:0;display:flex">
      <div style="display:flex;flex-direction:column;min-height:0;flex:1">
        <div class="progress-bar"><div style="width:${Math.round(progress * 100)}%"></div></div>
        <div class="workout-header">
          ${w.page > 0 ? `<button class="icon-btn" data-action="prev-exercise">${I.chevronL}</button>` : ''}
          <div class="names">
            <div class="w-name">${esc(w.session.templateName.toUpperCase())}</div>
            <div class="w-page">${atCardio ? 'CARDIO' : `EXERCÍCIO ${Math.min(w.page + 1, total)}/${total}`}</div>
          </div>
          <div class="num" id="timer" style="font-size:15px;font-weight:600;color:var(--dim)">00:00</div>
          <button class="btn-text" data-action="confirm-end">ENCERRAR</button>
        </div>
        <div style="flex:1;overflow-y:auto" class="swipe-zone" data-swipe>${page}</div>
        ${footer}
      </div>
    </div>
  `;
}

function renderExercisePage(w, idx) {
  const item = w.items[idx];
  const ex = byId(item.exerciseId, db.exercises);
  const exerciseId = item.exerciseId;
  const ref = referenceFor(exerciseId, w.session.id);
  const inp = getInputs(exerciseId);
  // pré-preenchimento (não sobrescreve)
  if (ref != null) {
    if (item.warmup && !inp.wW) inp.wW = L.formatKg(L.warmupSuggestion(ref));
    if (item.prep && !inp.pW) inp.pW = L.formatKg(L.prepSuggestion(ref));
    if (!inp.kW) inp.kW = L.formatKg(ref);
  }
  const mine = exerciseSets(exerciseId);
  const warmupSet = mine.find((s) => s.stage === 'aquecimento');
  const prepSet = mine.find((s) => s.stage === 'preparatoria');
  const workSets = mine.filter((s) => s.stage === 'trabalho').sort((a, b) => b.order - a.order);

  const stageHtml = (title, suggestion, recorded, wKey, rKey) => {
    const input = recorded
      ? setRowHtml(recorded, w.session.id)
      : `<div class="input-row">
          ${fieldHtml(wKey, inp[wKey])}
          ${repsFieldHtml(rKey, inp[rKey])}
          <button class="register-btn" data-action="register" data-stage="${title === 'AQUECIMENTO' ? 'aquecimento' : 'preparatoria'}">Registrar</button>
        </div>`;
    return `<div class="stage">
      <div class="stage-head">
        <div class="label">${title}</div>
        ${suggestion != null ? `<div class="stage-chip">${L.formatKg(suggestion)} kg</div>` : ''}
      </div>
      ${input}
    </div>`;
  };

  return `
    <div class="exercise-page">
      <div class="display-l" style="max-width:100%;overflow-wrap:anywhere">${esc(ex ? ex.name : 'Exercício')}</div>
      <div class="label mt-8">${esc(ex ? ex.muscleGroup.toUpperCase() : '')}</div>
      <div class="ref-row">
        <div class="label">Última referência</div>
        ${
          ref != null
            ? `<div class="ref-value"><span class="num">${L.formatKg(ref)}</span> <span class="unit">kg</span></div>`
            : `<div class="body-faint mt-8">sem histórico — informe a carga</div>`
        }
      </div>
      ${item.warmup ? stageHtml('AQUECIMENTO', ref == null ? null : L.warmupSuggestion(ref), warmupSet, 'wW', 'wR') : ''}
      ${item.prep ? stageHtml('PREPARATÓRIA', ref == null ? null : L.prepSuggestion(ref), prepSet, 'pW', 'pR') : ''}
      <div class="stage">
        <div class="stage-head"><div class="label">Séries de trabalho</div></div>
        <div class="input-row">
          ${fieldHtml('kW', inp.kW)}
          ${repsFieldHtml('kR', inp.kR)}
          <button class="register-btn" data-action="register" data-stage="trabalho">Registrar</button>
        </div>
        <div class="mt-8">
          ${
            workSets.length === 0
              ? `<div class="body-faint">Nenhuma série registrada</div>`
              : workSets.map((s) => setRowHtml(s, w.session.id)).join('')
          }
        </div>
      </div>
    </div>
  `;
}

function fieldHtml(key, value) {
  return `<div class="field grow">
    <button class="step" data-action="step" data-key="${key}" data-delta="-2.5">−</button>
    <input data-bind="workout-${key}" data-type="weight" value="${esc(value)}" inputmode="decimal" />
    <button class="step" data-action="step" data-key="${key}" data-delta="2.5">+</button>
  </div>`;
}

function repsFieldHtml(key, value) {
  return `<div class="field reps">
    <button class="step" data-action="step" data-key="${key}" data-delta="-1">−</button>
    <input data-bind="workout-${key}" data-type="reps" value="${esc(value)}" inputmode="numeric" />
    <button class="step" data-action="step" data-key="${key}" data-delta="1">+</button>
  </div>`;
}

function setRowHtml(set, sessionId) {
  return `<div class="set-row" data-action="edit-set" data-id="${set.id}">
    <span class="check">${I.check}</span>
    <span class="set-weight">${L.formatKg(set.weightKg)}</span>
    <span class="set-unit">kg</span>
    <span class="set-reps">× ${set.reps}</span>
    ${
      set.stage !== 'trabalho'
        ? `<span class="set-tag">${set.stage === 'aquecimento' ? 'AQUECIMENTO' : 'PREPARATÓRIA'}</span>`
        : `<button class="set-del" data-action="delete-set" data-id="${set.id}" title="Excluir">${I.trash}</button>`
    }
  </div>`;
}

function renderCardioPage() {
  const d = cardioDraft;
  return `
    <div class="exercise-page" style="padding-bottom:60px">
      <div class="display-l">CARDIO</div>
      <div class="body-dim mt-8">Finalização — registre o cardio ou pule</div>
      <div class="stage">
        <div class="stage-head"><div class="label">Tipo</div></div>
        <div class="chips">
          ${L.CARDIO_TYPES.map(
            (t) => `<button class="chip ${d.type === t ? 'selected' : ''}" data-action="cardio-type" data-t="${esc(t)}">${esc(t)}</button>`
          ).join('')}
        </div>
      </div>
      <div class="stage">
        <div class="stage-head"><div class="label">Duração</div></div>
        <div class="duration-row">
          <button class="round-step" data-action="cardio-duration" data-delta="-1">−</button>
          <span class="v">${d.duration}</span>
          <span class="body-dim">min</span>
          <button class="round-step" data-action="cardio-duration" data-delta="1">+</button>
        </div>
      </div>
      <div class="stage">
        <div class="stage-head"><div class="label">Distância (opcional)</div></div>
        <div class="suffix-input">
          <input class="text-input" data-bind="cardio-distance" value="${esc(d.distance)}" placeholder="0,0" inputmode="decimal" />
          <span class="suffix">km</span>
        </div>
      </div>
      <div class="stage">
        <div class="stage-head"><div class="label">Observação (opcional)</div></div>
        <input class="text-input" data-bind="cardio-note" value="${esc(d.note)}" placeholder="Ex.: ritmo forte, fadiga 6/10" maxlength="120" />
      </div>
      <div style="margin-top:34px;display:flex;flex-direction:column;gap:12px">
        <button class="btn" data-action="finish-workout" data-cardio="1">${I.flag} Finalizar treino</button>
        <button class="btn ghost" data-action="finish-workout" data-cardio="0">Pular cardio</button>
      </div>
    </div>
  `;
}

// ------------------------------------------------------------------ summary / history

function renderSummary() {
  const s = byId(view.sessionId, db.sessions);
  if (!s) { view = { name: 'home' }; return renderHome(); }
  const sets = db.sets.filter((x) => x.sessionId === s.id);
  const cardio = db.cardio.find((x) => x.sessionId === s.id);
  const dur = Math.max(1, Math.round((s.endedAt - s.startedAt) / 60000));
  return `
    <div class="screen">
      <div class="summary">
        <div class="check-circle">${I.checkBig}</div>
        <div class="display-m" style="text-align:center">TREINO CONCLUÍDO</div>
        <div class="body-dim" style="text-align:center;margin-top:8px">${esc(s.templateName.toUpperCase())} · ${dur} min</div>
        <div class="stats">
          <div class="stat"><div class="v">${dur}</div><div class="label">Minutos</div></div>
          <div class="stat"><div class="v">${s.exerciseCount}</div><div class="label">Exercícios</div></div>
          <div class="stat"><div class="v">${sets.length}</div><div class="label">Séries</div></div>
        </div>
        ${cardio ? `<div class="body-dim" style="text-align:center;margin-top:20px">${esc(cardio.type)} · ${cardio.durationMinutes} min${cardio.distanceKm != null ? ` · ${L.formatKg(cardio.distanceKm)} km` : ''}</div>` : ''}
        <div style="flex:1"></div>
        <button class="btn" data-action="go-home">Início</button>
        <div class="mt-8">
          <button class="btn ghost" data-action="go-history">Ver histórico</button>
        </div>
      </div>
    </div>
  `;
}

function renderSessionDetail() {
  const s = byId(view.sessionId, db.sessions);
  if (!s) { view = { name: 'home' }; return renderHome(); }
  const sets = db.sets
    .filter((x) => x.sessionId === s.id)
    .sort((a, b) => a.createdAt - b.createdAt || a.order - b.order);
  const byEx = new Map();
  const exOrder = [];
  sets.forEach((st) => {
    if (!byEx.has(st.exerciseId)) { byEx.set(st.exerciseId, []); exOrder.push(st.exerciseId); }
    byEx.get(st.exerciseId).push(st);
  });
  const dur = Math.max(1, Math.round((s.endedAt - s.startedAt) / 60000));
  const cardio = db.cardio.find((x) => x.sessionId === s.id);

  return `
    <div class="screen">
      <div class="topbar">
        <button class="icon-btn" data-action="back">${I.back}</button>
        <div style="flex:1"></div>
        <div class="body-faint">${L.formatDate(new Date(s.startedAt)).toUpperCase()}</div>
      </div>
      <div style="padding:12px 24px 32px;overflow-y:auto">
        <div class="display-l">${esc(s.templateName.toUpperCase())}</div>
        <div class="body-dim mt-8">${dur} min · ${s.totalSets} séries</div>
        <div class="mt-26">
          ${
            exOrder.length === 0
              ? '<div class="body-faint">Sem séries registradas</div>'
              : exOrder
                  .map((exId) => {
                    const ex = byId(exId, db.exercises);
                    const list = byEx.get(exId).sort((a, b) => a.order - b.order);
                    const work = list.filter((x) => x.stage === 'trabalho');
                    const maxW = work.length ? Math.max(...work.map((x) => x.weightKg)) : null;
                    return `<div class="ex-block">
                      <div class="ex-head" data-action="open-exercise-history" data-id="${exId}">
                        <span class="name">${esc(ex ? ex.name : 'Exercício')}</span>
                        <span class="hist">${I.history}</span>
                      </div>
                      <div class="mt-10">
                        ${list
                          .map(
                            (st) => `<div class="ex-set">
                            <span class="w">${L.formatKg(st.weightKg)}</span>
                            <span class="r"> × ${st.reps}</span>
                            ${st.stage !== 'trabalho' ? `<span class="set-tag" style="margin-left:auto">${st.stage === 'aquecimento' ? 'AQUECIMENTO' : 'PREPARATÓRIA'}</span>` : ''}
                          </div>`
                          )
                          .join('')}
                      </div>
                      ${maxW != null ? `<div class="ex-max">MÁX ${L.formatKg(maxW)} kg</div>` : ''}
                    </div>`;
                  })
                  .join('')
          }
          ${
            cardio
              ? `<div class="ex-block">
                  <div class="label">Cardio</div>
                  <div style="font-size:15px;font-weight:700;margin-top:8px">${esc(cardio.type)} · ${cardio.durationMinutes} min${cardio.distanceKm != null ? ` · ${L.formatKg(cardio.distanceKm)} km` : ''}</div>
                  ${cardio.note ? `<div class="body-faint mt-8">${esc(cardio.note)}</div>` : ''}
                </div>`
              : ''
          }
        </div>
      </div>
    </div>
  `;
}

function renderExerciseHistory() {
  const ex = byId(view.exerciseId, db.exercises);
  const sessions = db.sessions
    .filter((s) => db.sets.some((st) => st.sessionId === s.id && st.exerciseId === view.exerciseId))
    .sort((a, b) => b.startedAt - a.startedAt);
  return `
    <div class="screen">
      <div class="topbar">
        <button class="icon-btn" data-action="back">${I.back}</button>
        <div style="flex:1;min-width:0">
          <div class="display-m" style="font-size:22px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(ex ? ex.name : 'Exercício')}</div>
          ${ex ? `<div class="label mt-8">${esc(ex.muscleGroup.toUpperCase())}</div>` : ''}
        </div>
      </div>
      <div style="padding:14px 24px 32px;overflow-y:auto">
        ${
          sessions.length === 0
            ? `<div class="empty" style="flex:none;padding:60px 36px"><div class="icon-circle">${I.insights}</div><div class="body-dim">Sem treinos registrados ainda</div></div>`
            : sessions
                .map((s) => {
                  const list = db.sets
                    .filter((st) => st.sessionId === s.id && st.exerciseId === view.exerciseId)
                    .sort((a, b) => a.order - b.order);
                  const work = list.filter((x) => x.stage === 'trabalho');
                  const maxW = work.length ? Math.max(...work.map((x) => x.weightKg)) : null;
                  const workSummary = work.map((x) => `${L.formatKg(x.weightKg)}×${x.reps}`).join(' · ');
                  const extras = [
                    ...list.filter((x) => x.stage === 'aquecimento').map((x) => `AQ ${L.formatKg(x.weightKg)}×${x.reps}`),
                    ...list.filter((x) => x.stage === 'preparatoria').map((x) => `PR ${L.formatKg(x.weightKg)}×${x.reps}`),
                  ];
                  return `<div class="card" style="cursor:default">
                    <div style="display:flex;justify-content:space-between;align-items:center">
                      <div style="font-size:12.5px;font-weight:700;letter-spacing:.6px;color:var(--dim)">${L.formatDate(new Date(s.startedAt)).toUpperCase()}</div>
                      ${maxW != null ? `<div><span style="font-size:10.5px;font-weight:800;letter-spacing:1px;color:var(--faint)">MÁX </span><span class="num" style="font-size:15px;color:var(--accent)">${L.formatKg(maxW)} kg</span></div>` : ''}
                    </div>
                    ${workSummary ? `<div class="num mt-8" style="font-size:15px;font-weight:600">${workSummary}</div>` : ''}
                    ${extras.length ? `<div class="body-faint mt-8" style="font-size:11px">${extras.join(' · ')}</div>` : ''}
                    <div style="font-size:10px;letter-spacing:1.2px;color:var(--faint);font-weight:700;margin-top:6px">${esc(s.templateName.toUpperCase())}</div>
                  </div>`;
                })
                .join('')
        }
      </div>
    </div>
  `;
}

// ------------------------------------------------------------------ modais

function openModal(html, kind = 'sheet') {
  $('#modal-root').innerHTML = `<div class="overlay" data-action="close-overlay"><div class="${kind}">${html}</div></div>`;
}

function openEndDialog() {
  openModal(
    `<h3>Encerrar treino?</h3>
     <p>As séries já registradas serão salvas no histórico.</p>
     <div class="actions">
       <button class="btn-text" data-action="close-modal">CONTINUAR</button>
       <button class="btn-text danger" data-action="do-end">ENCERRAR</button>
     </div>`,
    'dialog'
  );
}

function openEditSet(setId) {
  const set = db.sets.find((s) => s.id === setId);
  if (!set) return;
  editingSet = { set, weightText: L.formatKg(set.weightKg), repsText: String(set.reps) };
  openModal(`
    <div class="label" style="margin-bottom:18px">Editar série</div>
    <div class="input-row">
      <div style="flex:11">
        <div class="label mb-8">Peso (kg)</div>
        ${fieldHtml('eW', editingSet.weightText)}
      </div>
      <div style="flex:6">
        <div class="label mb-8">Reps</div>
        ${repsFieldHtml('eR', editingSet.repsText)}
      </div>
    </div>
    <button class="btn mt-22" data-action="save-edit">Salvar</button>
    <div style="text-align:center;margin-top:8px">
      <button class="btn-text danger" data-action="delete-edit">EXCLUIR SÉRIE</button>
    </div>
  `);
}

// ------------------------------------------------------------------ ações

function doRegister(stage) {
  const w = currentWorkout();
  if (!w) return;
  const item = w.items[w.page];
  if (!item) return;
  const inp = getInputs(item.exerciseId);
  const isWork = stage === 'trabalho';
  const weightText = isWork ? inp.kW : stage === 'aquecimento' ? inp.wW : inp.pW;
  const repsText = isWork ? inp.kR : stage === 'aquecimento' ? inp.wR : inp.pR;
  const weight = L.parseKg(weightText);
  const reps = parseInt(repsText, 10);
  if (weight == null || !Number.isFinite(reps) || reps <= 0) {
    showToast('Informe peso e repetições');
    return;
  }
  const order = db.sets.filter(
    (s) => s.sessionId === w.session.id && s.exerciseId === item.exerciseId && s.stage === stage
  ).length;
  db.sets.push({
    id: L.uid('set'),
    sessionId: w.session.id,
    exerciseId: item.exerciseId,
    stage,
    weightKg: weight,
    reps,
    order,
    createdAt: Date.now(),
  });
  save();
  render();
}

function doStep(key, delta) {
  const w = currentWorkout();
  if (!w) return;
  const item = w.items[w.page];
  if (!item) return;
  const inp = getInputs(item.exerciseId);
  if (key.startsWith('e')) {
    // edição (modal)
    if (!editingSet) return;
    const isWeight = key === 'eW';
    const cur = isWeight ? L.parseKg(editingSet.weightText) ?? 0 : parseInt(editingSet.repsText, 10) ?? 0;
    const next = Math.round((cur + delta) * 100) / 100;
    if (isWeight) editingSet.weightText = next <= 0 ? '' : L.formatKg(next);
    else editingSet.repsText = next < 1 ? '' : String(next);
    // atualiza inputs do modal sem re-render completo
    const el = $(`[data-bind="workout-${key}"]`);
    if (el) el.value = isWeight ? editingSet.weightText : editingSet.repsText;
    return;
  }
  const isWeight = key.endsWith('W');
  const cur = isWeight ? L.parseKg(inp[key]) ?? 0 : parseInt(inp[key], 10) ?? 0;
  const next = Math.round((cur + delta) * 100) / 100;
  inp[key] = next <= 0 ? '' : isWeight ? L.formatKg(next) : String(Math.max(0, Math.floor(next)));
  const el = $(`[data-bind="workout-${key}"]`);
  if (el) el.value = inp[key];
}

function doFinishWorkout(withCardio, toSummary) {
  const w = currentWorkout();
  if (!w) return;
  const session = w.session;
  const now = Date.now();
  session.endedAt = now;
  const sessionSets = db.sets.filter((s) => s.sessionId === session.id);
  session.exerciseCount = new Set(sessionSets.map((s) => s.exerciseId)).size;
  session.totalSets = sessionSets.length;
  if (withCardio && cardioDraft.type) {
    db.cardio = db.cardio.filter((c) => c.sessionId !== session.id);
    db.cardio.push({
      id: L.uid('cardio'),
      sessionId: session.id,
      type: cardioDraft.type,
      durationMinutes: cardioDraft.duration,
      distanceKm: L.parseKg(cardioDraft.distance),
      note: cardioDraft.note.trim() || null,
    });
  }
  const sessionId = session.id;
  db.active = null;
  inputs = {};
  cardioDraft = { type: null, duration: 20, distance: '', note: '' };
  save();
  view = toSummary ? { name: 'summary', sessionId } : { name: 'home' };
  render();
}

function doDeleteSet(setId, silent) {
  const idx = db.sets.findIndex((s) => s.id === setId);
  if (idx < 0) return;
  const [removed] = db.sets.splice(idx, 1);
  save();
  render();
  if (!silent) {
    showToast('Série excluída', () => {
      db.sets.push(removed);
      save();
      render();
    });
  }
}

function deleteTemplate() {
  openModal(
    `<h3>Excluir treino?</h3>
     <p>Os treinos já realizados permanecem no histórico.</p>
     <div class="actions">
       <button class="btn-text" data-action="close-modal">CANCELAR</button>
       <button class="btn-text danger" data-action="do-delete-template">EXCLUIR</button>
     </div>`,
    'dialog'
  );
}

// ------------------------------------------------------------------ eventos

document.addEventListener('click', (e) => {
  const target = e.target.closest('[data-action]');
  if (!target) return;
  const a = target.dataset.action;
  const id = target.dataset.id;

  switch (a) {
    case 'new-template': openEditor(null); break;
    case 'open-template': view = { name: 'template', templateId: id }; render(); break;
    case 'edit-template': openEditor(id); break;
    case 'start-workout': {
      const t = byId(id, db.templates);
      if (!t || t.items.length === 0) break;
      if (db.active) break; // já existe treino em andamento
      const session = {
        id: L.uid('sess'),
        templateId: t.id,
        templateName: t.name,
        startedAt: Date.now(),
        endedAt: null,
        exerciseCount: 0,
        totalSets: 0,
      };
      db.sessions.push(session);
      db.active = { sessionId: session.id, page: 0 };
      inputs = {};
      save();
      view = { name: 'workout' };
      render();
      break;
    }
    case 'back':
      if (view.name === 'session' || view.name === 'exerciseHistory') view = { name: 'history' };
      else view = { name: 'home' };
      render();
      break;
    case 'tab': view = { name: target.dataset.tab === '0' ? 'home' : 'history' }; render(); break;
    case 'resume': {
      const s = byId(id, db.sessions);
      if (s && !s.endedAt) {
        db.active = { sessionId: s.id, page: 0 };
        save();
        view = { name: 'workout' };
        render();
      }
      break;
    }
    case 'save-template': {
      const name = editorDraft.name.trim();
      if (!name) { showToast('Dê um nome ao treino'); return; }
      const now = Date.now();
      const original = editorDraft.originalId ? byId(editorDraft.originalId, db.templates) : null;
      const t = {
        id: original ? original.id : L.uid('tpl'),
        name,
        items: editorDraft.items.map((it, i) => ({ ...it, position: i })),
        updatedAt: now,
      };
      if (original) {
        db.templates = db.templates.map((x) => (x.id === t.id ? t : x));
      } else {
        db.templates.push(t);
      }
      save();
      view = { name: 'home' };
      render();
      break;
    }
    case 'delete-template': deleteTemplate(); break;
    case 'do-delete-template': {
      db.templates = db.templates.filter((x) => x.id !== editorDraft.originalId);
      save();
      closeModal();
      view = { name: 'home' };
      render();
      break;
    }
    case 'toggle-warmup': {
      const i = +target.dataset.i;
      editorDraft.items[i].warmup = !editorDraft.items[i].warmup;
      render();
      break;
    }
    case 'toggle-prep': {
      const i = +target.dataset.i;
      editorDraft.items[i].prep = !editorDraft.items[i].prep;
      render();
      break;
    }
    case 'remove-item': {
      const i = +target.dataset.i;
      editorDraft.items.splice(i, 1);
      render();
      break;
    }
    case 'open-picker':
      picker = { search: '', newName: '', group: L.MUSCLE_GROUPS[0] };
      renderPicker();
      break;
    case 'add-exercise': {
      if (!picker) break;
      const inTemplate = editorDraft.items.some((i) => i.exerciseId === id);
      if (inTemplate) break;
      editorDraft.items.push({ id: L.uid('item'), exerciseId: id, warmup: true, prep: true, position: editorDraft.items.length });
      picker = null;
      closeModal();
      render();
      break;
    }
    case 'picker-group':
      picker.group = target.dataset.g;
      renderPicker();
      break;
    case 'create-exercise': {
      const name = (picker.newName || '').trim();
      if (!name) return;
      const ex = { id: L.uid('ex'), name, muscleGroup: picker.group, createdAt: Date.now() };
      db.exercises.push(ex);
      editorDraft.items.push({ id: L.uid('item'), exerciseId: ex.id, warmup: true, prep: true, position: editorDraft.items.length });
      save();
      picker = null;
      closeModal();
      render();
      break;
    }
    case 'next-exercise':
      if (db.active) { db.active.page += 1; save(); render(); }
      break;
    case 'prev-exercise':
      if (db.active) { db.active.page = Math.max(0, db.active.page - 1); save(); render(); }
      break;
    case 'register': doRegister(target.dataset.stage); break;
    case 'step': doStep(target.dataset.key, +target.dataset.delta); break;
    case 'edit-set': openEditSet(id); break;
    case 'delete-set': e.stopPropagation(); doDeleteSet(id); break;
    case 'save-edit': {
      if (!editingSet) break;
      const w = L.parseKg(editingSet.weightText);
      const r = parseInt(editingSet.repsText, 10);
      if (w == null || !r) return;
      editingSet.set.weightKg = w;
      editingSet.set.reps = r;
      editingSet = null;
      save();
      closeModal();
      render();
      break;
    }
    case 'delete-edit': {
      const sid = editingSet ? editingSet.set.id : null;
      editingSet = null;
      closeModal();
      if (sid) doDeleteSet(sid, true);
      break;
    }
    case 'cardio-type':
      cardioDraft.type = target.dataset.t;
      render();
      break;
    case 'cardio-duration': {
      cardioDraft.duration = Math.max(1, cardioDraft.duration + (+target.dataset.delta));
      render();
      break;
    }
    case 'confirm-end': openEndDialog(); break;
    case 'do-end': doFinishWorkout(false, false); break;
    case 'finish-workout': doFinishWorkout(target.dataset.cardio === '1', true); break;
    case 'go-home': view = { name: 'home' }; render(); break;
    case 'go-history': view = { name: 'history' }; render(); break;
    case 'open-session': view = { name: 'session', sessionId: id }; render(); break;
    case 'open-exercise-history': view = { name: 'exerciseHistory', exerciseId: id }; render(); break;
    case 'close-modal': picker = null; editingSet = null; closeModal(); break;
    case 'close-overlay':
      if (e.target.classList.contains('overlay')) {
        picker = null;
        editingSet = null;
        closeModal();
      }
      break;
  }
});

// inputs (sem re-render para não perder o foco)
document.addEventListener('input', (e) => {
  const bind = e.target.dataset && e.target.dataset.bind;
  if (!bind) return;
  const v = e.target.value;
  if (bind === 'editor-name') {
    if (editorDraft) editorDraft.name = v;
  } else if (bind === 'picker-search') {
    if (picker) { picker.search = v; rerenderPickerList(); }
  } else if (bind === 'new-exercise-name') {
    if (picker) picker.newName = v;
  } else if (bind.startsWith('workout-')) {
    const key = bind.slice(8);
    const w = currentWorkout();
    if (key === 'eW' || key === 'eR') {
      if (editingSet) {
        if (key === 'eW') editingSet.weightText = v;
        else editingSet.repsText = v;
      }
    } else if (w) {
      const item = w.items[w.page];
      if (item) getInputs(item.exerciseId)[key] = v;
    }
  } else if (bind === 'cardio-distance') {
    cardioDraft.distance = v;
  } else if (bind === 'cardio-note') {
    cardioDraft.note = v;
  }
});

function rerenderPickerList() {
  // re-renderiza apenas a lista de exercícios do picker
  const sheet = $('#modal-root .sheet');
  if (!sheet) return;
  const filtered = db.exercises
    .filter((ex) => !picker.search || ex.name.toLowerCase().includes(picker.search.toLowerCase()))
    .sort((a, b) => a.name.localeCompare(b.name, 'pt'));
  const inTemplate = new Set(editorDraft.items.map((i) => i.exerciseId));
  const listEl = $('.exercise-list', sheet);
  if (listEl) {
    listEl.innerHTML =
      filtered.length === 0
        ? `<div class="body-faint" style="padding:20px 6px">Nenhum exercício encontrado</div>`
        : filtered
            .map(
              (ex) => `<div class="row" data-action="add-exercise" data-id="${ex.id}" ${inTemplate.has(ex.id) ? 'style="opacity:.45;cursor:default"' : ''}>
            <div class="info">
              <div class="n">${esc(ex.name)}</div>
              <div class="g">${esc(ex.muscleGroup.toUpperCase())}</div>
            </div>
            <span class="ic ${inTemplate.has(ex.id) ? 'added' : ''}">${inTemplate.has(ex.id) ? I.check : I.plus}</span>
          </div>`
            )
            .join('');
  }
}

// drag & drop no editor
let dragIndex = null;
document.addEventListener('dragstart', (e) => {
  const row = e.target.closest && e.target.closest('[data-drag]');
  if (!row) return;
  dragIndex = +row.dataset.drag;
  row.classList.add('dragging');
  e.dataTransfer.effectAllowed = 'move';
});
document.addEventListener('dragend', (e) => {
  const row = e.target.closest && e.target.closest('[data-drag]');
  if (row) row.classList.remove('dragging');
  dragIndex = null;
});
document.addEventListener('dragover', (e) => {
  const row = e.target.closest && e.target.closest('[data-drag]');
  if (row && dragIndex != null) {
    e.preventDefault();
    const to = +row.dataset.drag;
    if (to !== dragIndex) {
      const items = editorDraft.items;
      const [moved] = items.splice(dragIndex, 1);
      items.splice(to > dragIndex ? to - 1 : to, 0, moved);
      dragIndex = to > dragIndex ? to - 1 : to;
      render();
    }
  }
});

// swipe horizontal no treino
let swipeStart = null;
document.addEventListener('pointerdown', (e) => {
  const zone = e.target.closest('[data-swipe]');
  if (!zone) return;
  if (e.target.closest('input, button')) return;
  swipeStart = { x: e.clientX, y: e.clientY };
});
document.addEventListener('pointerup', (e) => {
  if (!swipeStart) return;
  const dx = e.clientX - swipeStart.x;
  const dy = e.clientY - swipeStart.y;
  swipeStart = null;
  if (view.name !== 'workout' || !db.active) return;
  if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy) * 1.5) return;
  const total = currentWorkout()?.items.length ?? 0;
  if (dx < 0 && db.active.page < total) { db.active.page += 1; save(); render(); }
  else if (dx > 0 && db.active.page > 0) { db.active.page -= 1; save(); render(); }
});

// timer do treino
let timerHandle = null;
function startTimer() {
  if (timerHandle) clearInterval(timerHandle);
  if (view.name !== 'workout' || !db.active) return;
  const tick = () => {
    const el = $('#timer');
    if (!el || !db.active) return;
    const s = byId(db.active.sessionId, db.sessions);
    if (!s) return;
    el.textContent = L.formatElapsed(Date.now() - s.startedAt);
  };
  tick();
  timerHandle = setInterval(tick, 1000);
}

// ESC fecha modais
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') { picker = null; editingSet = null; closeModal(); }
});

// ------------------------------------------------------------------ init

render();
