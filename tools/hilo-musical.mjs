// ─────────────────────────────────────────────
//  «Hilo musical»: canción original para explorar el Centro comercial, compuesta aquí desde cero.
//  Terror suave: la música de ascensor de un centro comercial vacío. Una bossa alegre en fa mayor con vibráfono y
//  piano eléctrico, que de vez en cuando se tuerce: un acorde menor que no toca (si bemol menor), la cinta que se
//  estira y desafina, y en la parte B todo se va medio tono abajo. El gancho es el «ding-dong» de megafonía
//  (do, la, fa), que en la parte B suena con la última nota mal (fa sostenido).
//
//  Dos capas: la base (vibráfono, piano, bajo, megafonía) suena siempre; la de ritmo (batería de bossa, un latido y
//  un theremín que canta por debajo, como un fantasma) entra con zombis despiertos.
//
//  node tools/hilo-musical.mjs [--juego]  → tools/efectos/elegir/hilo-musical.ogg (y -tranquila.ogg, solo la base);
//  con --juego, también assets/musica/hilo-musical-<capa>.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'hilo-musical';
const BPM = 92, COMPASES = 40;
const LARGO = COMPASES * 4 * 60 / BPM;   // segundos

// La cinta: tiembla un poco siempre y mucho en la parte B (compases 20-27), y vuelve sola. Vueltas enteras en la
// canción, para que el bucle empalme
const vueltas = (hz) => Math.round(hz * LARGO) / LARGO;
const W1 = vueltas(0.45), W2 = vueltas(0.13);
const enB = (s) => {
  const c = s / LARGO * COMPASES;
  return c < 19 || c > 29 ? 0 : Math.sin(Math.PI * (c - 19) / 10) ** 2;
};
const cinta = (s) => 7 * Math.sin(2 * Math.PI * W1 * s) + enB(s) * (22 * Math.sin(2 * Math.PI * W2 * s) - 18);

// ── Instrumentos ────────────────────────────────
const INS = {
  vibra:  { onda: 'fm', ratio: 4, indice: 1.4, indiceCae: 0.25, vol: 0.2, ataque: 0.003, caida: 0.9, sosten: 0.15, gate: 0.9, suelta: 0.35, eco: 0.25, sala: 0.35, pan: 0.15, tremolo: { hz: 4.8, prof: 0.25 }, cinta: true },
  piano:  { onda: 'fm', ratio: 1, indice: 1.1, indiceCae: 0.35, vol: 0.075, ataque: 0.004, caida: 0.6, sosten: 0.3, gate: 0.9, suelta: 0.15, eco: 0.1, sala: 0.25, pan: -0.25, filtro: 3200, cinta: true },
  flauta: { onda: 'seno', vol: 0.09, ataque: 0.05, caida: 1, sosten: 0.85, gate: 0.95, suelta: 0.12, eco: 0.2, sala: 0.35, pan: -0.35, vibrato: 0.1, cinta: true },
  bajo:   { onda: 'triangulo', vol: 0.34, ataque: 0.004, caida: 0.4, sosten: 0.6, gate: 0.85, suelta: 0.05, eco: 0, pan: 0, filtro: 1400, cinta: true },
  dingdong: { onda: 'fm', ratio: 2, indice: 1.8, indiceCae: 0.5, vol: 0.16, ataque: 0.002, caida: 1.4, sosten: 0, suena: 2.2, suelta: 0.6, eco: 0.3, sala: 0.55, pan: 0 },
  manto:  { onda: 'sierra', voces: 5, abrir: 22, ancho: 0.8, vol: 0.05, ataque: 1.2, caida: 2, sosten: 1, gate: 1, suelta: 1.2, eco: 0, sala: 0.6, pan: 0, filtro: 850, cinta: true },
  // los de la capa de ritmo
  theremin: { onda: 'seno', vol: 0.11, ataque: 0.25, caida: 1, sosten: 1, gate: 1, suelta: 0.4, eco: 0.35, sala: 0.6, pan: 0.4, vibrato: 0.3, glide: 0.35, cinta: true, capa: 'ritmo' },
};

const { B, nota, melodia, acorde, sonido, bombo, charles, guardar } = crearMotor({
  bpm: BPM, compas: 4, compases: COMPASES, instrumentos: INS, capas: { percusion: 'ritmo', sonido: 'ritmo' },
  sala: { tamano: 0.84, apagar: 0.45 }, cinta, eco: { pulsos: 0.75, fb: 0.3 },
});

// ── PARTITURA ───────────────────────────────────
// Cada acorde: su nota grave y cómo lo toca el piano
const ACORDE = {
  Fmaj7:  { raiz: 'F2',  piano: ['A3', 'C4', 'E4', 'F4'] },
  Am7:    { raiz: 'A1',  piano: ['G3', 'C4', 'E4', 'A4'] },
  Bbmaj7: { raiz: 'Bb1', piano: ['A3', 'D4', 'F4', 'Bb4'] },
  Bbm6:   { raiz: 'Bb1', piano: ['G3', 'Db4', 'F4', 'Bb4'] },   // el acorde que no toca: el escalofrío
  Gm7:    { raiz: 'G1',  piano: ['F3', 'Bb3', 'D4', 'G4'] },
  C7b9:   { raiz: 'C2',  piano: ['E3', 'Bb3', 'Db4', 'G4'] },
  Dbmaj7: { raiz: 'Db2', piano: ['Ab3', 'C4', 'F4', 'Ab4'] },
  Cm7:    { raiz: 'C2',  piano: ['G3', 'Bb3', 'Eb4', 'G4'] },
  Bbm7:   { raiz: 'Bb1', piano: ['Ab3', 'Db4', 'F4', 'Ab4'] },
  A7b9:   { raiz: 'A1',  piano: ['G3', 'Bb3', 'C#4', 'E4'] },
  DmMaj7: { raiz: 'D2',  piano: ['A3', 'C#4', 'F4', 'A4'] },
  Gm6:    { raiz: 'G1',  piano: ['E3', 'Bb3', 'D4', 'G4'] },
};
const ACORDES_A = ['Fmaj7', 'Am7', 'Bbmaj7', 'Bbm6', 'Fmaj7', 'Am7', 'Gm7', 'C7b9'];
const ACORDES_B = ['Dbmaj7', 'Cm7', 'Bbm7', 'A7b9', 'DmMaj7', 'Bbmaj7', 'Gm6', 'C7b9'];

// El piano de bossa: cuatro toques por compás, el último adelantado
const TOQUES = [[0, 1, 1], [1.5, 0.5, 0.7], [2.5, 0.75, 0.85], [3.5, 0.4, 0.6]];
function piano(c, a, vol = 1) {
  for (const [p, d, v] of TOQUES) acorde('piano', B(c, p), d, ACORDE[a].piano, vol * v);
}
// El bajo de bossa: la raíz, la quinta adelantada, la quinta y otra vez la raíz
function bajo(c, a, vol = 1) {
  const r = ACORDE[a].raiz, q = tr(r, 7);
  nota('bajo', B(c), 1.5, r, vol);
  nota('bajo', B(c, 1.5), 0.5, q, vol * 0.75);
  nota('bajo', B(c, 2), 1.5, q, vol * 0.9);
  nota('bajo', B(c, 3.5), 0.5, r, vol * 0.7);
}
// El «ding-dong» de megafonía: do, la y fa (en la parte B, la última, fa sostenido)
function megafonia(c, mal = false, vol = 1) {
  nota('dingdong', B(c), 1, 'C6', vol);
  nota('dingdong', B(c, 1), 1, 'A5', vol);
  nota('dingdong', B(c, 2), 2, mal ? 'F#5' : 'F5', vol);
}

// Melodías: [nota, pulsos] por compás; «~» = llega deslizándose, «-» = silencio
const MELODIA_A = [   // sobre Fmaj7 Am7 Bbmaj7 Bbm6 Fmaj7 Am7 Gm7 C7b9
  [['A4', 1], ['C5', 0.5], ['E5', 1.5], ['D5', 0.5], ['C5', 0.5]],
  [['E5', 1.5], ['D5', 0.5], ['C5', 1], ['A4', 1]],
  [['D5', 1], ['F5', 0.5], ['A5', 1.5], ['G5', 0.5], ['F5', 0.5]],
  [['G5', 1.5], ['F5', 0.5], ['Db5', 2]],
  [['A4', 1], ['C5', 0.5], ['E5', 1.5], ['D5', 0.5], ['C5', 0.5]],
  [['G5', 1.5], ['E5', 0.5], ['C5', 1], ['A4', 1]],
  [['Bb4', 1], ['D5', 0.5], ['F5', 1.5], ['E5', 0.5], ['D5', 0.5]],
  [['Db5', 1.5], ['C5', 0.5], ['G4', 1], ['E4', 1]],
];
const MELODIA_B = [   // sobre Dbmaj7 Cm7 Bbm7 A7b9 DmMaj7 Bbmaj7 Gm6 C7b9 (el primer compás, la megafonía mal)
  [['-', 4]],
  [['Eb5', 1.5], ['D5', 0.5], ['G4', 2]],
  [['F5', 1.5], ['Eb5', 0.5], ['Db5', 2]],
  [['C#5', 1], ['E5', 1], ['G5', 1], ['Bb5', 1]],
  [['A5', 2], ['C#5', 2]],
  [['D5', 1], ['F5', 1], ['A5', 2]],
  [['G5', 1.5], ['E5', 0.5], ['Bb4', 2]],
  [['Db5', 1.5], ['C5', 0.5], ['G4', 1], ['E4', 1]],
];
// El fantasma: notas largas medio tono al lado de la melodía
const FANTASMA_A = [
  [['E5', 4]], [['~Eb5', 2], ['~D5', 2]], [['D5', 4]], [['Db5', 4]],
  [['C5', 4]], [['B4', 4]], [['Bb4', 4]], [['~Db5', 2], ['~C5', 2]],
];
const FANTASMA_B = [
  [['Ab4', 4]], [['~G4', 4]], [['F4', 2], ['~Gb4', 2]], [['G4', 4]],
  [['A4', 2], ['~Bb4', 2]], [['A4', 4]], [['~Bb4', 4]], [['Db5', 2], ['~C5', 2]],
];

// 1. Entrada (0-3): la megafonía y el piano solo; el vibráfono anuncia el tema
megafonia(0);
['Fmaj7', 'Am7', 'Bbmaj7', 'C7b9'].forEach((a, k) => {
  piano(k, a, 0.8);
  nota('bajo', B(k), 4, ACORDE[a].raiz, 0.7);
});
melodia('vibra', 2, [[['-', 2], ['A4', 1], ['C5', 1]], [['E5', 2], ['Db5', 1], ['C5', 1]]], 0.7);

// 2. A (4-11): el tema con el vibráfono
// 3. A' (12-19): otra vez, con la flauta una octava abajo
// 4. B (20-27): todo medio tono abajo, la cinta se estira, entra el manto de cuerdas
// 5. A'' (28-35): vuelve el tema como si nada
// 6. Final (36-39): la megafonía y el piano; empalma con la entrada
for (const c0 of [4, 12, 28]) {
  melodia('vibra', c0, MELODIA_A, c0 === 4 ? 0.95 : 1);
  ACORDES_A.forEach((a, k) => { piano(c0 + k, a); bajo(c0 + k, a); });
}
melodia('flauta', 12, MELODIA_A, 1, -1);
megafonia(20, true);
melodia('vibra', 20, MELODIA_B);
ACORDES_B.forEach((a, k) => {
  piano(20 + k, a, 0.85);
  bajo(20 + k, a, 0.9);
  acorde('manto', B(20 + k), 4, ACORDE[a].piano.slice(0, 3), 1);
});
megafonia(36, false, 0.9);
['Fmaj7', 'Am7', 'Bbm6', 'C7b9'].forEach((a, k) => {
  piano(36 + k, a, 0.8 - k * 0.05);
  nota('bajo', B(36 + k), 4, ACORDE[a].raiz, 0.7);
});
melodia('vibra', 38, [[['-', 2], ['Db5', 1], ['C5', 1]], [['G4', 2], ['E4', 2]]], 0.6);

// ── La capa de ritmo (con zombis despiertos) ──
// Golpe de aro de la bossa: un «toc» de madera
function aro(t, vol = 1) {
  let fase = 0;
  sonido(t, 0.08, (s) => {
    fase = (fase + 1750 / SR) % 1;
    return Math.sin(2 * Math.PI * fase) * Math.exp(-s / 0.012) * 0.18 * vol;
  }, -0.3, 0, 0.2);
}
const CLAVE = [0, 1.5, 3, 5, 6.5];   // la clave de bossa, en pulsos a lo largo de dos compases
function bossa(c, vol = 1) {
  bombo(B(c), 0.65 * vol); bombo(B(c, 1.5), 0.3 * vol); bombo(B(c, 2), 0.55 * vol); bombo(B(c, 3.5), 0.3 * vol);
  for (const p of CLAVE) if (Math.floor(p / 4) === c % 2) aro(B(c, p % 4), vol);
  for (let k = 0; k < 8; k++) charles(B(c, k / 2), (k % 2 ? 0.8 : 1.3) * vol, false, 0.35);
}
function latido(c, vol = 1) {
  for (const p of [0, 2]) { bombo(B(c, p), 0.55 * vol, true); bombo(B(c, p + 0.4), 0.3 * vol, true); }
  for (let k = 0; k < 4; k++) charles(B(c, k + 0.5), 0.5 * vol, false, -0.3);
}
for (let c = 0; c < 4; c++) latido(c, 0.7 + c * 0.1);
for (let c = 4; c < 20; c++) bossa(c, c < 12 ? 0.85 : 1);
for (let c = 20; c < 28; c++) latido(c);
for (let c = 28; c < 36; c++) bossa(c);
for (let c = 36; c < 40; c++) latido(c, 0.9 - (c - 36) * 0.1);
melodia('theremin', 12, FANTASMA_A, 0.8);
melodia('theremin', 20, FANTASMA_B, 1);
melodia('theremin', 28, FANTASMA_A, 0.9, 1);

const capas = guardar(path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`),
  [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ["A''", 28, 36], ['final', 36, 40]]);
sacarCancion(ROOT, NOMBRE, path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`), capas, { juego: process.argv.includes('--juego') });
