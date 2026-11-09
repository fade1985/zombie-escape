// ─────────────────────────────────────────────
//  «Horas extra»: canción original para explorar Torre Velaria, compuesta aquí desde cero.
//  Montaje en 8 bits (solo ondas de la NES): rápida, en mi menor, con un riff sincopado (dos notas repetidas que
//  empujan y luego suben), arpegios en tresillos y un puente que acaba en mi MAYOR (el momento heroico). El gancho es
//  el «ding» del ascensor: abre cada parte, y en el respiro suena una vez por compás, cada vez una planta más arriba.
//
//  Dos capas: la base (bajo, arpegio, riff, ascensor) suena siempre; la de ritmo (batería, segunda voz y golpes de
//  acorde) entra con zombis despiertos.
//
//  node tools/horas-extra.mjs [--juego]  → tools/efectos/elegir/horas-extra.ogg (y -tranquila.ogg);
//  con --juego, también assets/musica/horas-extra-<capa>.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr, hz, sube, pulso, paso, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'horas-extra';

// ── Instrumentos ────────────────────────────────
const INS = {
  riff:  { onda: 'pulso', duty: 0.25, vol: 0.16, ataque: 0.003, caida: 0.2, sosten: 0.55, gate: 0.85, suelta: 0.04, eco: 0.3, pan: 0.1, vibrato: true, glide: 0.04 },
  canto: { onda: 'pulso', duty: 0.5, pwm: 0.1, vol: 0.14, ataque: 0.01, caida: 0.5, sosten: 0.75, gate: 0.95, suelta: 0.08, eco: 0.35, pan: 0.1, vibrato: true, glide: 0.05 },
  arpe:  { onda: 'pulso', duty: 0.125, vol: 0.07, ataque: 0.002, caida: 0.06, sosten: 0.25, gate: 0.7, suelta: 0.02, eco: 0.3, pan: -0.35 },
  bajo:  { onda: 'triangulo', vol: 0.28, ataque: 0.002, caida: 0.12, sosten: 0.7, gate: 0.8, suelta: 0.02, eco: 0, pan: 0 },
  // los de la capa de ritmo
  voz2:  { onda: 'pulso', duty: 0.125, vol: 0.07, ataque: 0.003, caida: 0.25, sosten: 0.5, gate: 0.85, suelta: 0.04, eco: 0.25, pan: -0.45, cents: -6, capa: 'ritmo' },
  golpe: { onda: 'pulso', duty: 0.5, vol: 0.05, ataque: 0.002, caida: 0.08, sosten: 0.2, gate: 0.5, suelta: 0.03, eco: 0.2, pan: 0.35, capa: 'ritmo' },
};

// En 4/4, a 168 pulsos por minuto: 52 compases, 74 segundos
const { B, nota, melodia, acorde, sonido, bombo, tambor, platillo, platazo, subida, guardar } = crearMotor({
  bpm: 168, compas: 4, compases: 52, instrumentos: INS, capas: { percusion: 'ritmo', subida: 'ritmo' },
});

// El «ding» del ascensor: una campanita de dos ondas (la nota y su quinta arriba)
function ding(t, n = 'E5', vol = 1) {
  const f = hz(n), f2 = f * 1.5;
  let a = 0, b = 0;
  sonido(t, 1.5, (s) => {
    a = (a + f / SR) % 1; b = (b + f2 / SR) % 1;
    return (pulso(a, f / SR, 0.5) * 0.6 + pulso(b, f2 / SR, 0.25) * 0.3 * Math.exp(-s / 0.15)) * paso(Math.exp(-s / 0.45)) * 0.1 * vol;
  }, 0.25, 0.45);
}

// ── PARTITURA ───────────────────────────────────
const ACORDE = {
  Em: { raiz: 'E1', tres: ['E4', 'G4', 'B4'] },
  D:  { raiz: 'D2', tres: ['D4', 'F#4', 'A4'] },
  C:  { raiz: 'C2', tres: ['C4', 'E4', 'G4'] },
  B:  { raiz: 'B1', tres: ['D#4', 'F#4', 'B4'] },
  E:  { raiz: 'E1', tres: ['E4', 'G#4', 'B4'] },
};
const ACORDES_A = ['Em', 'D', 'C', 'D', 'Em', 'D', 'C', 'B'];
const ACORDES_B = ['C', 'D', 'Em', 'Em', 'C', 'D', 'E', 'E'];

// Arpegio en tresillos: doce notas por compás, sube y baja
const TRESILLOS = [0, 1, 2, 1, 2, 3, 2, 1, 0, 1, 2, 3];
function arpe(c, a, vol = 1) {
  const [x, y, z] = ACORDE[a].tres;
  const n = [x, y, z, sube(x, 1)];
  TRESILLOS.forEach((j, k) => nota('arpe', B(c, k / 3), 1 / 3, n[j], vol * (k % 3 === 0 ? 1 : 0.7)));
}
// El bajo: corcheas en la raíz, con la quinta y la octava empujando a contratiempo
function bajo(c, a, vol = 1) {
  const r = ACORDE[a].raiz;
  const fig = [r, r, tr(r, 12), r, r, tr(r, 7), tr(r, 12), r];
  fig.forEach((n, k) => nota('bajo', B(c, k / 2), 0.5, n, vol * (k % 2 ? 0.75 : 1)));
}

const RIFF = [   // sobre Em D C D Em D C B
  [['E5', 0.75], ['E5', 0.75], ['B4', 0.5], ['E5', 0.5], ['F#5', 0.5], ['G5', 1]],
  [['F#5', 0.75], ['E5', 0.75], ['D5', 0.5], ['A4', 2]],
  [['E5', 0.75], ['E5', 0.75], ['C5', 0.5], ['E5', 0.5], ['F#5', 0.5], ['G5', 1]],
  [['A5', 1.5], ['G5', 0.5], ['F#5', 1], ['D5', 1]],
  [['E5', 0.75], ['E5', 0.75], ['B4', 0.5], ['E5', 0.5], ['F#5', 0.5], ['G5', 1]],
  [['F#5', 0.75], ['E5', 0.75], ['D5', 0.5], ['A5', 2]],
  [['G5', 0.75], ['F#5', 0.75], ['E5', 0.5], ['C6', 1], ['B5', 1]],
  [['B5', 1], ['A5', 0.5], ['G5', 0.5], ['F#5', 1], ['D#5', 1]],
];
const RIFF2 = [   // una tercera abajo
  [['B4', 0.75], ['B4', 0.75], ['G4', 0.5], ['B4', 0.5], ['D5', 0.5], ['E5', 1]],
  [['D5', 0.75], ['C#5', 0.75], ['A4', 0.5], ['F#4', 2]],
  [['C5', 0.75], ['C5', 0.75], ['G4', 0.5], ['C5', 0.5], ['D5', 0.5], ['E5', 1]],
  [['F#5', 1.5], ['E5', 0.5], ['D5', 1], ['A4', 1]],
  [['B4', 0.75], ['B4', 0.75], ['G4', 0.5], ['B4', 0.5], ['D5', 0.5], ['E5', 1]],
  [['D5', 0.75], ['C#5', 0.75], ['A4', 0.5], ['F#5', 2]],
  [['E5', 0.75], ['D5', 0.75], ['C5', 0.5], ['G5', 1], ['G5', 1]],
  [['F#5', 1], ['F#5', 0.5], ['E5', 0.5], ['D#5', 1], ['B4', 1]],
];
const PUENTE = [   // sobre C D Em Em C D E E: sube y acaba en mayor
  [['G5', 1.5], ['E5', 0.5], ['G5', 1], ['C6', 1]],
  [['A5', 1.5], ['F#5', 0.5], ['A5', 1], ['D6', 1]],
  [['B5', 3], ['G5', 1]],
  [['E6', 2], ['D6', 1], ['B5', 1]],
  [['C6', 1.5], ['B5', 0.5], ['A5', 1], ['G5', 1]],
  [['A5', 1.5], ['G5', 0.5], ['F#5', 1], ['A5', 1]],
  [['G#5', 3], ['B5', 1]],
  [['E6', 2], ['D6', 1], ['B5', 1]],
];

// 1. Entrada (0-3): el ascensor, el arpegio y el bajo
ding(B(0), 'E5');
['Em', 'D', 'C', 'B'].forEach((a, k) => { arpe(k, a, 0.6 + k * 0.12); if (k >= 2) bajo(k, a, 0.8); });
nota('bajo', B(0), 8, 'E2', 0.7);

// 2. A (4-11), 3. A' (12-19) y 6. A'' (32-39): el riff
// 4. Puente (20-27) y 7. puente otra vez (40-47)
// 5. Respiro (28-31): el ascensor sube planta a planta
// 8. Final (48-51): medio riff; empalma con la entrada
for (const c0 of [4, 12, 32]) {
  ding(B(c0), 'E5', 0.8);
  melodia('riff', c0, RIFF);
  ACORDES_A.forEach((a, k) => { arpe(c0 + k, a, 0.8); bajo(c0 + k, a); });
}
for (const c0 of [20, 40]) {
  ding(B(c0), 'G5', 0.8);
  melodia('canto', c0, PUENTE, c0 === 40 ? 1.05 : 1);
  ACORDES_B.forEach((a, k) => { arpe(c0 + k, a, 0.8); bajo(c0 + k, a); });
}
['E5', 'F#5', 'G#5', 'A5'].forEach((n, k) => {
  ding(B(28 + k), n, 0.9);
  arpe(28 + k, ['Em', 'D', 'C', 'B'][k], 0.9);
  nota('bajo', B(28 + k), 4, sube(ACORDE[['Em', 'D', 'C', 'B'][k]].raiz, 1), 0.7);
});
ding(B(48), 'E5');
melodia('riff', 48, RIFF.slice(0, 4), 0.85);
['Em', 'D', 'C', 'D'].forEach((a, k) => { arpe(48 + k, a, 0.8 - k * 0.05); bajo(48 + k, a, 0.85); });

// ── La capa de ritmo (con zombis despiertos) ──
function bateria(c, vol = 1) {
  bombo(B(c), vol); bombo(B(c, 1.5), 0.7 * vol); bombo(B(c, 2.5), 0.8 * vol);
  tambor(B(c, 1), vol); tambor(B(c, 3), vol);
  for (let k = 0; k < 8; k++) platillo(B(c, k / 2), (k % 2 ? 0.45 : 0.8) * vol);
}
function bateriaPuente(c) {
  for (let k = 0; k < 4; k++) bombo(B(c, k), 0.9);
  tambor(B(c, 1)); tambor(B(c, 3)); tambor(B(c, 3.5), 0.5);
  for (let k = 0; k < 4; k++) platillo(B(c, k + 0.5), 0.8, true);
}
// Golpes de acorde a contratiempo (en los empujones del riff)
function golpes(c, a) {
  for (const p of [0.75, 2, 3.5]) acorde('golpe', B(c, p), 0.25, ACORDE[a].tres.map((n) => sube(n, 1)), 1);
}
const redoble = (c) => { for (let k = 0; k < 8; k++) tambor(B(c, 2 + k / 4), 0.3 + k * 0.09); };
for (let c = 0; c < 4; c++) { bombo(B(c), 0.7); bombo(B(c, 2), 0.6); platillo(B(c, 1), 0.5); platillo(B(c, 3), 0.5); }
for (let c = 4; c < 20; c++) bateria(c, c < 12 ? 0.85 : 1);
for (let c = 20; c < 28; c++) bateriaPuente(c);
for (let c = 28; c < 32; c++) for (let k = 0; k < 4; k++) bombo(B(c, k), 0.4 + (c - 28) * 0.15);
for (let c = 32; c < 40; c++) bateria(c);
for (let c = 40; c < 48; c++) bateriaPuente(c);
for (let c = 48; c < 52; c++) bateria(c, 0.8 - (c - 48) * 0.08);
for (const c of [11, 19, 27, 39, 47]) redoble(c);
for (const c of [4, 12, 20, 32, 40]) platazo(B(c), 0.6);
for (let k = 0; k < 16; k++) tambor(B(31, k / 4), 0.15 + 0.8 * k / 15);
subida(B(30), 8, 'E3', 'E5', 0.8);
melodia('voz2', 12, RIFF2);
melodia('voz2', 32, RIFF2);
melodia('voz2', 40, PUENTE, 0.8, -1);
for (const c0 of [4, 12, 32]) ACORDES_A.forEach((a, k) => golpes(c0 + k, a));

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['puente', 20, 28], ['respiro', 28, 32], ["A''", 32, 40], ["puente'", 40, 48], ['final', 48, 52]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
