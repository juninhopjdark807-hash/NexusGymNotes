// Regras de negócio do Nexus Gym — espelham exatamente
// lib/domain/logic/progression.dart e lib/core/format.dart do app Flutter.
// (Este arquivo é usado pelo protótipo web E pelos testes em Node.)

export const MUSCLE_GROUPS = [
  'Peito', 'Costas', 'Ombros', 'Bíceps', 'Tríceps', 'Pernas',
  'Glúteos', 'Abdômen', 'Trapézio', 'Pescoço', 'Outros',
];

export const CARDIO_TYPES = ['Esteira', 'Bicicleta', 'Elíptico', 'Escada', 'Remo', 'Pular corda', 'Outro'];

// ------------------------------------------------------------------ progressão

/** Arredonda para o número par mais próximo (meio para cima). */
export function roundEven(value) {
  if (value <= 0) return 0;
  return 2 * Math.round(value / 2);
}

/** Aquecimento: 30% da referência, arredondado para par. */
export function warmupSuggestion(referenceKg) {
  return roundEven(referenceKg * 0.3);
}

/** Preparatória: 90% da referência, arredondado para par. */
export function prepSuggestion(referenceKg) {
  return roundEven(referenceKg * 0.9);
}

/**
 * Referência do próximo treino: maior carga entre as séries de TRABALHO
 * da execução anterior. null quando não há histórico.
 */
export function referenceFromWorkSets(workWeights) {
  if (!workWeights.length) return null;
  return Math.max(...workWeights);
}

/**
 * Séries de trabalho da execução anterior do exercício
 * (excluindo a sessão atual), usando o estado `db` em memória.
 */
export function previousWorkSets(db, exerciseId, excludeSessionId) {
  const sessionsWithWork = db.sessions
    .filter((s) => s.id !== excludeSessionId)
    .filter((s) =>
      db.sets.some(
        (st) => st.sessionId === s.id && st.exerciseId === exerciseId && st.stage === 'trabalho'
      )
    )
    .sort((a, b) => b.startedAt - a.startedAt);
  const latest = sessionsWithWork[0];
  if (!latest) return [];
  return db.sets
    .filter((st) => st.sessionId === latest.id && st.exerciseId === exerciseId && st.stage === 'trabalho')
    .sort((a, b) => a.order - b.order);
}

// ------------------------------------------------------------------ formatação

const MESES = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
const DIAS = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

/** 110 -> "110", 100.5 -> "100,5" */
export function formatKg(kg) {
  if (Math.round(kg * 10) % 10 === 0) return String(Math.round(kg));
  return kg.toFixed(1).replace('.', ',');
}

/** Aceita vírgula ou ponto. */
export function parseKg(raw) {
  const s = String(raw ?? '').trim().replace(',', '.');
  if (!s) return null;
  const v = Number(s);
  if (!Number.isFinite(v) || v < 0) return null;
  return v;
}

export function formatDate(d) {
  return `${d.getDate()} ${MESES[d.getMonth()]} ${d.getFullYear()}`;
}

export function formatDateShort(d) {
  return `${d.getDate()} ${MESES[d.getMonth()]}`;
}

export function formatDayLabel(d) {
  return `${DIAS[d.getDay()]} · ${formatDateShort(d)}`;
}

export function formatTime(d) {
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

export function formatElapsed(ms) {
  const totalSec = Math.max(0, Math.floor(ms / 1000));
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}`;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

export function dateKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/** Converte a chave "YYYY-MM-DD" em data local (sem ambiguidade de fuso). */
export function parseDateKey(key) {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, m - 1, d);
}

// ------------------------------------------------------------------ helpers

let seq = 0;
export function uid(prefix = 'id') {
  seq += 1;
  return `${prefix}-${Date.now().toString(36)}-${seq.toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}
