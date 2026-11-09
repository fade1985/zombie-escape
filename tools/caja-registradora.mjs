// ─────────────────────────────────────────────
//  «Caja registradora»: canción original para explorar el Centro comercial, compuesta aquí desde cero.
//  Montaje en 8 bits (solo ondas de la NES): rápida, en la menor, con un riff que se repite en escalón (la misma
//  figura sobre la menor y sobre do) y un puente en mayor que levanta. El gancho es el «cha-ching» de la caja
//  registradora, que abre cada parte.
//
//  Dos capas: la base (bajo, arpegio, riff y caja registradora) suena siempre; la de ritmo (batería, segunda voz y
//  la subida) entra con zombis despiertos.
//
//  node tools/caja-registradora.mjs [--juego]  → tools/efectos/elegir/caja-registradora.ogg (y -tranquila.ogg);
//  con --juego, también assets/musica/caja-registradora-<capa>.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr, sube, pulso, ruido, paso, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'caja-registradora';

// ── Instrumentos ────────────────────────────────
const INS = {
  riff:  { onda: 'pulso', duty: 0.25, vol: 0.17, ataque: 0.003, caida: 0.25, sosten: 0.55, gate: 0.85, suelta: 0.04, eco: 0.3, pan: 0.1, vibrato: true, glide: 0.04 },
  canto: { onda: 'pulso', duty: 0.5, pwm: 0.1, vol: 0.15, ataque: 0.01, caida: 0.5, sosten: 0.7, gate: 0.95, suelta: 0.08, eco: 0.35, pan: 0.1, vibrato: true, glide: 0.05 },
  bajo:  { onda: 'triangulo', vol: 0.28, ataque: 0.002, caida: 0.12, sosten: 0.7, gate: 0.8, suelta: 0.02, eco: 0, pan: 0 },
  // los de la capa de ritmo
  voz2:  { onda: 'pulso', duty: 0.125, vol: 0.07, ataque: 0.003, caida: 0.25, sosten: 0.5, gate: 0.85, suelta: 0.04, eco: 0.25, pan: -0.45, cents: -6, capa: 'ritmo' },
  contra: { onda: 'pulso', duty: 0.25, vol: 0.06, ataque: 0.003, caida: 0.08, sosten: 0.2, gate: 0.6, suelta: 0.02, eco: 0.2, pan: -0.4, capa: 'ritmo' },
};

// En 4/4, a 152 pulsos por minuto: 44 compases, 69 segundos
const { B, nota, melodia, arpegio, sonido, bombo, tambor, platillo, platazo, subida, guardar } = crearMotor({
  bpm: 152, compas: 4, compases: 44, instrumentos: INS, capas: { percusion: 'ritmo', subida: 'ritmo' },
});

// El «cha-ching»: el cajón que se abre (ruido metálico) y la campanita de dos notas
function chaChing(t, vol = 1) {
  const r = ruido(true);
  let ru = 0;
  sonido(t, 0.14, (s, i) => {
    if (i % 3 === 0) ru = r();
    return ru * paso(Math.exp(-s / 0.04)) * 0.1 * vol;
  }, -0.2, 0.1);
  for (const [k, n] of [[0.5, 'E6'], [0.75, 'A6']]) {
    let fase = 0;
    const f = 440 * 2 ** ((n === 'E6' ? 7 : 12) / 12) * 2;   // mi6 y la6
    sonido(t + k, 1, (s) => {
      fase = (fase + f / SR) % 1;
      return pulso(fase, f / SR, 0.5) * paso(Math.exp(-s / 0.25)) * 0.07 * vol;
    }, 0.3, 0.45);
  }
}

// ── PARTITURA ───────────────────────────────────
const ACORDE = {
  Am: { raiz: 'A1', arpe: ['A4', 'C5', 'E5'] },
  F:  { raiz: 'F1', arpe: ['F4', 'A4', 'C5'] },
  C:  { raiz: 'C2', arpe: ['G4', 'C5', 'E5'] },
  G:  { raiz: 'G1', arpe: ['G4', 'B4', 'D5'] },
  E:  { raiz: 'E1', arpe: ['G#4', 'B4', 'E5'] },
  Em: { raiz: 'E1', arpe: ['G4', 'B4', 'E5'] },
};
const ACORDES_A = ['Am', 'F', 'C', 'G', 'Am', 'F', 'G', 'E'];
const ACORDES_B = ['F', 'G', 'Em', 'Am', 'F', 'G', 'Am', 'E'];

// El bajo saltando de octava en corcheas
function bajo(c, a, vol = 1) {
  const r = ACORDE[a].raiz;
  for (let k = 0; k < 8; k++) nota('bajo', B(c, k / 2), 0.5, k % 2 ? tr(r, 12) : r, vol * (k % 2 ? 0.8 : 1));
}
const arpe = (c, a, vol = 1) => arpegio(B(c), 4, ACORDE[a].arpe, vol);

const RIFF = [   // sobre Am F C G Am F G E: la misma figura en el compás 1, 3 y 5
  [['A4', 0.5], ['C5', 0.5], ['E5', 0.5], ['A5', 1], ['G5', 0.5], ['E5', 0.5], ['C5', 0.5]],
  [['F5', 1.5], ['E5', 0.5], ['C5', 1], ['A4', 1]],
  [['G4', 0.5], ['C5', 0.5], ['E5', 0.5], ['G5', 1], ['F5', 0.5], ['E5', 0.5], ['C5', 0.5]],
  [['D5', 1.5], ['B4', 0.5], ['G4', 2]],
  [['A4', 0.5], ['C5', 0.5], ['E5', 0.5], ['A5', 1], ['G5', 0.5], ['E5', 0.5], ['C5', 0.5]],
  [['F5', 0.5], ['A5', 0.5], ['C6', 1], ['B5', 0.5], ['A5', 0.5], ['F5', 1]],
  [['G5', 1], ['F5', 0.5], ['E5', 0.5], ['D5', 1], ['B4', 1]],
  [['G#4', 1], ['B4', 1], ['E5', 2]],
];
// La segunda voz: el riff una tercera abajo (en la escala)
const RIFF2 = [
  [['E4', 0.5], ['A4', 0.5], ['C5', 0.5], ['E5', 1], ['E5', 0.5], ['C5', 0.5], ['A4', 0.5]],
  [['C5', 1.5], ['C5', 0.5], ['A4', 1], ['F4', 1]],
  [['E4', 0.5], ['G4', 0.5], ['C5', 0.5], ['E5', 1], ['D5', 0.5], ['C5', 0.5], ['G4', 0.5]],
  [['B4', 1.5], ['G4', 0.5], ['D4', 2]],
  [['E4', 0.5], ['A4', 0.5], ['C5', 0.5], ['E5', 1], ['E5', 0.5], ['C5', 0.5], ['A4', 0.5]],
  [['C5', 0.5], ['F5', 0.5], ['A5', 1], ['G5', 0.5], ['F5', 0.5], ['C5', 1]],
  [['D5', 1], ['D5', 0.5], ['C5', 0.5], ['B4', 1], ['G4', 1]],
  [['E4', 1], ['G#4', 1], ['B4', 2]],
];
const PUENTE = [   // sobre F G Em Am F G Am E: en mayor, más largo y más arriba
  [['C5', 1], ['F5', 1], ['A5', 2]],
  [['B5', 1], ['A5', 0.5], ['G5', 0.5], ['D5', 2]],
  [['E5', 1], ['G5', 1], ['B5', 2]],
  [['C6', 1.5], ['B5', 0.5], ['A5', 2]],
  [['A5', 1], ['C6', 1], ['D6', 2]],
  [['D6', 1.5], ['C6', 0.5], ['B5', 2]],
  [['C6', 1], ['B5', 1], ['A5', 1], ['E5', 1]],
  [['G#5', 2], ['B5', 2]],
];

// 1. Entrada (0-3): caja registradora, bajo y arpegio
chaChing(B(0));
['Am', 'F', 'C', 'G'].forEach((a, k) => { bajo(k, a, 0.8); arpe(k, a, 0.8 + k * 0.1); });

// 2. A (4-11) y 3. A' (12-19): el riff
// 4. Puente (20-27): en mayor
// 5. Respiro (28-31): solo el arpegio y el bajo largo; al final, la subida
// 6. A'' (32-39): el riff otra vez, con todo
// 7. Final (40-43): el riff a medias con la caja registradora; empalma con la entrada
for (const c0 of [4, 12, 32]) {
  chaChing(B(c0), 0.8);
  melodia('riff', c0, RIFF);
  ACORDES_A.forEach((a, k) => { bajo(c0 + k, a); arpe(c0 + k, a, 0.6); });
}
chaChing(B(20), 0.8);
melodia('canto', 20, PUENTE);
ACORDES_B.forEach((a, k) => { bajo(20 + k, a); arpe(20 + k, a, 0.6); });
['Am', 'F', 'G', 'E'].forEach((a, k) => {
  arpe(28 + k, a, 0.9);
  nota('bajo', B(28 + k), 4, sube(ACORDE[a].raiz, 1), 0.7);
});
chaChing(B(40));
melodia('riff', 40, RIFF.slice(0, 4), 0.85);
['Am', 'F', 'C', 'G'].forEach((a, k) => { bajo(40 + k, a, 0.85); arpe(40 + k, a, 0.7); });

// ── La capa de ritmo (con zombis despiertos) ──
function bateriaA(c, vol = 1) {
  bombo(B(c), vol); bombo(B(c, 1.5), 0.7 * vol); bombo(B(c, 2), 0.9 * vol);
  tambor(B(c, 1), vol); tambor(B(c, 3), vol);
  for (let k = 0; k < 8; k++) platillo(B(c, k / 2), (k % 2 ? 0.5 : 0.85) * vol);
}
function bateriaPuente(c) {
  for (let k = 0; k < 4; k++) bombo(B(c, k), 0.9);
  tambor(B(c, 1)); tambor(B(c, 3));
  for (let k = 0; k < 4; k++) platillo(B(c, k + 0.5), 0.8, true);
}
const redoble = (c) => { for (let k = 0; k < 8; k++) tambor(B(c, 2 + k / 4), 0.3 + k * 0.09); };
for (let c = 0; c < 4; c++) { bombo(B(c), 0.7); bombo(B(c, 2), 0.6); platillo(B(c, 1), 0.5); platillo(B(c, 3), 0.5); }
for (let c = 4; c < 20; c++) bateriaA(c, c < 12 ? 0.85 : 1);
for (let c = 20; c < 28; c++) bateriaPuente(c);
for (let c = 28; c < 32; c++) for (let k = 0; k < 4; k++) bombo(B(c, k), 0.4 + (c - 28) * 0.15);
for (let c = 32; c < 40; c++) bateriaA(c);
for (let c = 40; c < 44; c++) bateriaA(c, 0.8 - (c - 40) * 0.08);
for (const c of [11, 19, 27, 39]) redoble(c);
for (const c of [4, 12, 20, 32]) platazo(B(c), 0.6);
for (let k = 0; k < 16; k++) tambor(B(31, k / 4), 0.15 + 0.8 * k / 15);
subida(B(30), 8, 'A3', 'A5', 0.8);
melodia('voz2', 12, RIFF2);
melodia('voz2', 32, RIFF2);
// el contrarriff del puente: corcheas sueltas en lo alto del acorde
ACORDES_B.forEach((a, k) => {
  const [x, y, z] = ACORDE[a].arpe;
  [z, y, x, y, z, y, x, y].forEach((n, j) => nota('contra', B(20 + k, j / 2), 0.5, sube(n, 1), j % 2 ? 0.6 : 1));
});

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['puente', 20, 28], ['respiro', 28, 32], ["A''", 32, 40], ['final', 40, 44]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
