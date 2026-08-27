import test from 'node:test';
import assert from 'node:assert/strict';

import {
  roundEven,
  warmupSuggestion,
  prepSuggestion,
  referenceFromWorkSets,
  previousWorkSets,
  formatKg,
  parseKg,
  formatDate,
  formatElapsed,
} from './logic.js';

test('roundEven arredonda para o par mais próximo', () => {
  assert.equal(roundEven(33), 34);
  assert.equal(roundEven(99), 100);
  assert.equal(roundEven(30), 30);
  assert.equal(roundEven(90), 90);
  assert.equal(roundEven(34), 34);
  assert.equal(roundEven(29), 30);
  assert.equal(roundEven(33.6), 34);
  assert.equal(roundEven(98.9), 98);
  assert.equal(roundEven(0), 0);
});

test('referência 110 kg -> aquecimento 34 kg e preparatória 100 kg (exemplo da spec)', () => {
  assert.equal(warmupSuggestion(110), 34);
  assert.equal(prepSuggestion(110), 100);
});

test('referência 100 kg -> aquecimento 30 kg e preparatória 90 kg (exemplo da spec)', () => {
  assert.equal(warmupSuggestion(100), 30);
  assert.equal(prepSuggestion(100), 90);
});

test('referência = maior carga de trabalho anterior', () => {
  assert.equal(referenceFromWorkSets([100, 100, 110]), 110);
  assert.equal(referenceFromWorkSets([110, 100, 105]), 110);
  assert.equal(referenceFromWorkSets([]), null);
});

test('previousWorkSets ignora aquecimento/preparatória e sessões excluídas', () => {
  const db = {
    sessions: [
      { id: 's1', startedAt: 1000, endedAt: 2000 },
      { id: 's2', startedAt: 3000, endedAt: null },
    ],
    sets: [
      { id: 'a', sessionId: 's1', exerciseId: 'ex', stage: 'aquecimento', weightKg: 30, order: 0 },
      { id: 'b', sessionId: 's1', exerciseId: 'ex', stage: 'preparatoria', weightKg: 90, order: 0 },
      { id: 'c', sessionId: 's1', exerciseId: 'ex', stage: 'trabalho', weightKg: 100, order: 0 },
      { id: 'd', sessionId: 's1', exerciseId: 'ex', stage: 'trabalho', weightKg: 110, order: 1 },
      { id: 'e', sessionId: 's2', exerciseId: 'ex', stage: 'trabalho', weightKg: 500, order: 0 },
    ],
  };
  // Excluindo a sessão atual (s2): referência vem de s1 (110)
  const sets = previousWorkSets(db, 'ex', 's2');
  assert.equal(sets.length, 2);
  assert.equal(referenceFromWorkSets(sets.map((s) => s.weightKg)), 110);
  // Sem excluir: referência é a sessão mais recente (s2 -> 500)
  const sets2 = previousWorkSets(db, 'ex', null);
  assert.equal(referenceFromWorkSets(sets2.map((s) => s.weightKg)), 500);
});

test('formatKg usa vírgula decimal (pt-BR)', () => {
  assert.equal(formatKg(110), '110');
  assert.equal(formatKg(30), '30');
  assert.equal(formatKg(100.5), '100,5');
  assert.equal(formatKg(2.5), '2,5');
});

test('parseKg aceita vírgula e ponto; inválido -> null', () => {
  assert.equal(parseKg('100,5'), 100.5);
  assert.equal(parseKg('100.5'), 100.5);
  assert.equal(parseKg(' 90 '), 90);
  assert.equal(parseKg('abc'), null);
  assert.equal(parseKg(''), null);
  assert.equal(parseKg('-5'), null);
});

test('formatDate no formato da spec', () => {
  assert.equal(formatDate(new Date(2026, 7, 27)), '27 AGO 2026');
});

test('formatElapsed', () => {
  assert.equal(formatElapsed(5 * 60 * 1000 + 4000), '05:04');
  assert.equal(formatElapsed(1 * 3600 * 1000 + 7 * 60 * 1000), '1:07');
});

import { parseDateKey, dateKey } from './logic.js';

test('parseDateKey interpreta como data local', () => {
  const d = parseDateKey('2026-08-27');
  assert.equal(d.getFullYear(), 2026);
  assert.equal(d.getMonth(), 7);
  assert.equal(d.getDate(), 27);
  assert.equal(dateKey(d), '2026-08-27');
});
