// ─────────────────────────────────────────────
//  «Música en espera»: canción original para explorar Torre Velaria, compuesta aquí desde cero.
//  Terror suave de oficina: sintetizadores fríos en do menor, un arpegio que no para (como un ordenador pensando),
//  el pitido de «su llamada es importante para nosotros» y el teclear de alguien que sigue trabajando a las tantas.
//  El gancho es la sintonía de la empresa, cuatro notas que dicen «Ve-la-ri-a» (do, mi bemol, sol y un re arriba que
//  brilla); la melodía empieza con ellas. En la parte B la sintonía suena lenta y con la última nota mal (re bemol).
//
//  Dos capas: la base (arpegio, manto, campanitas, bajo, sintonía, pitido y teclado) suena siempre; la de ritmo
//  (batería de sintetizador, una segunda voz y un latido en la parte B) entra con zombis despiertos.
//
//  node tools/musica-en-espera.mjs [--juego]  → tools/efectos/elegir/musica-en-espera.ogg (y -tranquila.ogg);
//  con --juego, también assets/musica/musica-en-espera-<capa>.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr, azar, crearSvf, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'musica-en-espera';

// ── Instrumentos ────────────────────────────────
const INS = {
  arpe:    { onda: 'sierra', voces: 2, abrir: 10, ancho: 0.6, vol: 0.13, ataque: 0.003, caida: 0.18, sosten: 0.2, gate: 0.6, suelta: 0.08, eco: 0.35, sala: 0.3, pan: -0.15, filtro: 700, filtroEnv: 2.5, reso: 1.5 },
  manto:   { onda: 'sierra', voces: 6, abrir: 24, ancho: 0.9, vol: 0.05, ataque: 1.2, caida: 2, sosten: 1, gate: 1, suelta: 1.2, eco: 0, sala: 0.55, pan: 0, filtro: 1100 },
  cristal: { onda: 'fm', ratio: 2, indice: 1.3, indiceCae: 0.5, vol: 0.17, ataque: 0.004, caida: 1.2, sosten: 0.2, gate: 0.95, suelta: 0.4, eco: 0.35, sala: 0.5, pan: 0.2 },
  bajo:    { onda: 'sierra', vol: 0.22, ataque: 0.004, caida: 0.15, sosten: 0.5, gate: 0.7, suelta: 0.04, eco: 0, pan: 0, filtro: 260, filtroEnv: 2.5, reso: 1.2 },
  sintonia: { onda: 'fm', ratio: 1, indice: 2, indiceCae: 0.3, vol: 0.16, ataque: 0.003, caida: 0.6, sosten: 0.3, gate: 0.9, suelta: 0.5, eco: 0.3, sala: 0.55, pan: 0 },
  // los de la capa de ritmo
  voz2:    { onda: 'pulso', duty: 0.5, vol: 0.08, ataque: 0.15, caida: 1, sosten: 0.9, gate: 0.97, suelta: 0.3, eco: 0.4, sala: 0.5, pan: -0.4, filtro: 1600, vibrato: 0.12, glide: 0.2, capa: 'ritmo' },
};

// En 4/4, a 84 pulsos por minuto: 40 compases, 114 segundos
const { B, nota, melodia, acorde, sonido, bombo, caja16, charles, guardar } = crearMotor({
  bpm: 84, compas: 4, compases: 40, instrumentos: INS, capas: { percusion: 'ritmo' },
  sala: { tamano: 0.88, apagar: 0.4 }, eco: { pulsos: 0.75, fb: 0.4 },
});

// El pitido de la llamada en espera: dos notas suaves, muy bajito
function pitido(t, vol = 1) {
  for (const [p, f] of [[0, 880], [0.4, 660]]) {
    let fase = 0;
    sonido(t + p, 0.3, (s) => {
      fase = (fase + f / SR) % 1;
      return Math.sin(2 * Math.PI * fase) * Math.min(1, s / 0.01, (0.3 - s) / 0.05) * 0.05 * vol;
    }, 0.5, 0.3, 0.2);
  }
}
// Alguien tecleando: golpecitos de plástico, siempre los mismos (sin azar de verdad)
function teclado(c, vol = 1) {
  const r = azar(c * 31 + 5);
  for (let k = 0; k < 16; k++) {
    if (r() < 0.1) continue;
    const t = B(c, k / 4 + (r() * 0.06));
    const ru = azar(c * 97 + k);
    const bp = crearSvf();
    const g = Math.tan(Math.PI * (2400 + r() * 900) / SR);
    const v = (0.5 + 0.5 * Math.abs(r())) * vol;
    sonido(t, 0.05, (s) => { bp.paso(ru(), g, 2); return bp.band * Math.exp(-s / 0.008) * 0.12 * v; }, -0.5, 0, 0.15);
  }
}

// ── PARTITURA ───────────────────────────────────
const ACORDE = {
  Cm: { raiz: 'C2', notas: ['C4', 'Eb4', 'G4', 'D5'] },
  Ab: { raiz: 'Ab1', notas: ['Ab3', 'C4', 'Eb4', 'G4'] },
  Eb: { raiz: 'Eb2', notas: ['Bb3', 'Eb4', 'G4', 'D5'] },
  Bb: { raiz: 'Bb1', notas: ['Bb3', 'D4', 'F4', 'C5'] },
  Fm: { raiz: 'F1', notas: ['Ab3', 'C4', 'F4', 'G4'] },
  G:  { raiz: 'G1', notas: ['G3', 'B3', 'D4', 'F4'] },
  Gm: { raiz: 'G1', notas: ['G3', 'Bb3', 'D4', 'F4'] },
};
const ACORDES_A = ['Cm', 'Ab', 'Eb', 'Bb', 'Cm', 'Ab', 'Fm', 'G'];
const ACORDES_B = ['Ab', 'Bb', 'Gm', 'Cm', 'Ab', 'Bb', 'G', 'G'];

// El arpegio: semicorcheas que suben y bajan por las cuatro notas del acorde
const SUBE_BAJA = [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 1];
function arpe(c, a, vol = 1) {
  const n = ACORDE[a].notas;
  SUBE_BAJA.forEach((j, k) => nota('arpe', B(c, k / 4), 0.25, n[j], vol * (k % 4 === 0 ? 1 : 0.7)));
}
// El bajo de sintetizador: corcheas, la octava en la última de cada pulso
function bajo(c, a, vol = 1) {
  const r = ACORDE[a].raiz;
  for (let k = 0; k < 8; k++) nota('bajo', B(c, k / 2), 0.5, k % 4 === 3 ? tr(r, 12) : r, vol * (k % 2 ? 0.7 : 1));
}
const manto = (c, a, vol = 1) => acorde('manto', B(c), 4, ACORDE[a].notas, vol);
// La sintonía: «Ve-la-ri-a»; en la parte B, lenta y con la última nota mal
function sintonia(t, mal = false, vol = 1) {
  const p = mal ? 1 : 0.5;
  ['C5', 'Eb5', 'G5', mal ? 'Db6' : 'D6'].forEach((n, k) => nota('sintonia', t + k * p, k === 3 ? 3 : p, n, vol));
}

// La melodía empieza por la sintonía
const MELODIA_A = [   // sobre Cm Ab Eb Bb Cm Ab Fm G
  [['C5', 0.5], ['Eb5', 0.5], ['G5', 0.5], ['D6', 2.5]],
  [['C6', 1], ['Bb5', 1], ['G5', 2]],
  [['Bb4', 0.5], ['Eb5', 0.5], ['G5', 0.5], ['D6', 2.5]],
  [['C6', 1], ['D6', 1], ['F5', 2]],
  [['C5', 0.5], ['Eb5', 0.5], ['G5', 0.5], ['D6', 2.5]],
  [['Eb6', 1], ['D6', 1], ['C6', 1], ['G5', 1]],
  [['Ab5', 1.5], ['G5', 0.5], ['F5', 1], ['C5', 1]],
  [['B4', 2], ['D5', 1], ['F5', 1]],
];
const MELODIA_B = [   // sobre Ab Bb Gm Cm Ab Bb G G: grave y quieta (el primer compás, la sintonía mal)
  [['-', 4]],
  [['D5', 3], ['Bb4', 1]],
  [['D5', 1], ['G5', 1], ['F5', 1], ['D5', 1]],
  [['Eb5', 4]],
  [['Eb5', 2], ['F5', 1], ['G5', 1]],
  [['Ab5', 2], ['G5', 1], ['F5', 1]],
  [['G5', 2], ['B5', 2]],
  [['D6', 2], ['~Db6', 2]],
];
// La segunda voz (capa de ritmo): notas largas por debajo
const VOZ2_A = [
  [['G4', 4]], [['Eb4', 4]], [['G4', 4]], [['F4', 4]],
  [['G4', 4]], [['C5', 4]], [['C5', 2], ['Ab4', 2]], [['G4', 2], ['B4', 2]],
];
const VOZ2_B = [
  [['C5', 4]], [['Bb4', 4]], [['Bb4', 4]], [['G4', 4]],
  [['C5', 4]], [['D5', 4]], [['D5', 2], ['B4', 2]], [['B4', 2], ['~Ab4', 2]],
];

// 1. Entrada (0-3): sintonía, pitido, manto y el teclado; el arpegio entra despacio
sintonia(B(0));
pitido(B(2, 2));
['Cm', 'Ab', 'Eb', 'G'].forEach((a, k) => {
  manto(k, a, 0.8);
  if (k >= 1) arpe(k, a, 0.3 + k * 0.2);
  teclado(k, 0.8);
});
nota('bajo', B(2), 8, 'C2', 0.6);

// 2. A (4-11), 3. A' (12-19, con manto) y 5. A'' (28-35): la melodía de cristal
// 4. B (20-27): la sintonía mal, la melodía grave
// 6. Final (36-39): sintonía, pitido y teclado; empalma con la entrada
for (const c0 of [4, 12, 28]) {
  melodia('cristal', c0, MELODIA_A, c0 === 4 ? 0.9 : 1);
  ACORDES_A.forEach((a, k) => {
    arpe(c0 + k, a, 0.85);
    bajo(c0 + k, a, c0 === 4 ? 0.8 : 1);
    if (c0 !== 4) manto(c0 + k, a, 0.7);
  });
}
sintonia(B(20), true);
melodia('cristal', 20, MELODIA_B, 0.95);
ACORDES_B.forEach((a, k) => {
  arpe(20 + k, a, 0.75);
  nota('bajo', B(20 + k), 4, ACORDE[a].raiz, 0.8);
  manto(20 + k, a, 0.9);
});
for (const c of [11, 27]) pitido(B(c, 2), 0.8);
for (let c = 20; c < 24; c++) teclado(c, 0.5);
sintonia(B(36), false, 0.9);
pitido(B(38, 2));
['Cm', 'Ab', 'Fm', 'G'].forEach((a, k) => {
  manto(36 + k, a, 0.8);
  arpe(36 + k, a, 0.8 - k * 0.12);
  teclado(36 + k, 0.8);
  nota('bajo', B(36 + k), 4, ACORDE[a].raiz, 0.6 - k * 0.1);
});

// ── La capa de ritmo (con zombis despiertos) ──
function bateria(c, vol = 1) {
  bombo(B(c), 0.9 * vol); bombo(B(c, 2), 0.8 * vol); bombo(B(c, 2.5), 0.4 * vol);
  caja16(B(c, 1), 0.8 * vol); caja16(B(c, 3), 0.8 * vol);
  for (let k = 0; k < 8; k++) charles(B(c, k / 2), (k % 2 ? 0.7 : 1.1) * vol);
}
function latido(c, vol = 1) {
  for (const p of [0, 2]) { bombo(B(c, p), 0.7 * vol, true); bombo(B(c, p + 0.4), 0.4 * vol, true); }
}
for (let c = 0; c < 4; c++) latido(c, 0.5 + c * 0.12);
for (let c = 4; c < 20; c++) bateria(c, c < 12 ? 0.8 : 1);
for (let c = 20; c < 28; c++) { latido(c); charles(B(c, 1), 0.8, true); charles(B(c, 3), 0.8, true); }
for (let c = 28; c < 36; c++) bateria(c);
for (let c = 36; c < 40; c++) latido(c, 0.8 - (c - 36) * 0.1);
melodia('voz2', 4, VOZ2_A, 0.8);
melodia('voz2', 12, VOZ2_A);
melodia('voz2', 20, VOZ2_B);
melodia('voz2', 28, VOZ2_A);

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ["A''", 28, 36], ['final', 36, 40]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
