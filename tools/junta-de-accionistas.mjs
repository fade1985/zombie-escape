// ─────────────────────────────────────────────
//  «Junta de accionistas»: canción original para explorar Torre Velaria, compuesta aquí desde cero.
//  Épica de tráiler «híbrida» en mi menor: un pulso de sintetizador que hace tic-tac en semicorcheas debajo de la
//  orquesta (cuerdas, coro, trompas), golpes, «braam» y tambores. El tema de las trompas empieza con la forma de la
//  sintonía de Velaria de «Música en espera» (sube por el acorde y salta a la novena: mi, sol, si, fa sostenido),
//  y la campana de la entrada la toca entera: la firma de la torre.
//
//  Dos capas: la base (pulso, cuerdas, coro, trompas, campana y braam) suena siempre; la de ritmo (tambores,
//  platillos, trompetas, golpes de metal y los impactos) entra con zombis despiertos.
//
//  node tools/junta-de-accionistas.mjs [--juego]  → tools/efectos/elegir/junta-de-accionistas.ogg (y
//  -tranquila.ogg); con --juego, también assets/musica/junta-de-accionistas-<capa>.ogg. Bucle perfecto.
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'junta-de-accionistas';

// ── Instrumentos ────────────────────────────────
const INS = {
  tictac:  { onda: 'sierra', voces: 2, abrir: 8, ancho: 0.3, vol: 0.2, ataque: 0.002, caida: 0.06, sosten: 0.1, gate: 0.5, suelta: 0.03, eco: 0.15, sala: 0.15, pan: 0, filtro: 300, filtroEnv: 4, reso: 1.6 },
  cuerdas: { onda: 'sierra', voces: 6, abrir: 20, ancho: 0.9, vol: 0.07, ataque: 0.35, caida: 2, sosten: 1, gate: 1, suelta: 0.6, eco: 0, sala: 0.6, pan: 0, filtro: 1900 },
  contra:  { onda: 'sierra', voces: 3, abrir: 8, ancho: 0.2, vol: 0.3, ataque: 0.15, caida: 1, sosten: 0.9, gate: 0.98, suelta: 0.3, eco: 0, sala: 0.2, pan: 0, filtro: 240 },
  coro:    { onda: 'coro', voces: 5, abrir: 18, ancho: 0.9, vol: 0.13, ataque: 0.6, caida: 2, sosten: 1, gate: 1, suelta: 0.8, eco: 0, sala: 0.7, pan: 0, vibrato: 0.08 },
  trompas: { onda: 'sierra', voces: 3, abrir: 10, ancho: 0.4, vol: 0.3, ataque: 0.07, caida: 0.5, sosten: 0.8, gate: 0.95, suelta: 0.2, eco: 0, sala: 0.55, pan: 0.2, filtro: 600, filtroEnv: 1.6, vibrato: 0.06, glide: 0.08 },
  braam:   { onda: 'sierra', voces: 6, abrir: 30, ancho: 0.8, vol: 0.13, ataque: 0.03, caida: 1.5, sosten: 0.35, suena: 2.8, suelta: 1, eco: 0, sala: 0.6, pan: 0, filtro: 150, filtroEnv: 7, reso: 1.2 },
  campana: { onda: 'fm', ratio: 1.4, indice: 2.4, indiceCae: 0.9, vol: 0.13, ataque: 0.002, caida: 2.4, sosten: 0, suena: 3, suelta: 1, eco: 0.2, sala: 0.7, pan: 0 },
  // los de la capa de ritmo
  trompetas: { onda: 'sierra', voces: 3, abrir: 9, ancho: 0.5, vol: 0.16, ataque: 0.05, caida: 0.4, sosten: 0.8, gate: 0.92, suelta: 0.15, eco: 0, sala: 0.5, pan: -0.1, filtro: 1300, filtroEnv: 2, vibrato: 0.07, glide: 0.06, capa: 'ritmo' },
  metal:   { onda: 'sierra', voces: 4, abrir: 14, ancho: 0.7, vol: 0.13, ataque: 0.01, caida: 0.2, sosten: 0.3, gate: 0.6, suelta: 0.12, eco: 0, sala: 0.6, pan: 0, filtro: 700, filtroEnv: 3, capa: 'ritmo' },
};

// En 4/4, a 90 pulsos por minuto: 36 compases, 96 segundos
const { B, nota, melodia, acorde, sonido, taiko, caja16, platillo16, golpe, ascenso, guardar } = crearMotor({
  bpm: 90, compas: 4, compases: 36, instrumentos: INS,
  capas: { percusion: 'ritmo', golpe: 'ritmo', subida: 'ritmo' }, sala: { tamano: 0.9, apagar: 0.42 },
});

// El tic del reloj de la sala de juntas
function tic(t, vol = 1) {
  let fase = 0;
  sonido(t, 0.05, (s) => {
    fase = (fase + 2100 / SR) % 1;
    return Math.sin(2 * Math.PI * fase) * Math.exp(-s / 0.006) * 0.12 * vol;
  }, 0.4, 0.2, 0.2);
}

// ── PARTITURA ───────────────────────────────────
const ACORDE = {
  Em: { raiz: 'E2', notas: ['E4', 'G4', 'B4', 'E5'] },
  C:  { raiz: 'C2', notas: ['E4', 'G4', 'C5', 'E5'] },
  G:  { raiz: 'G1', notas: ['D4', 'G4', 'B4', 'D5'] },
  D:  { raiz: 'D2', notas: ['D4', 'F#4', 'A4', 'D5'] },
  Am: { raiz: 'A1', notas: ['E4', 'A4', 'C5', 'E5'] },
  B:  { raiz: 'B1', notas: ['D#4', 'F#4', 'B4', 'D#5'] },
  Bm: { raiz: 'B1', notas: ['D4', 'F#4', 'B4', 'D5'] },
};
const ACORDES_A = ['Em', 'C', 'G', 'D', 'Em', 'C', 'Am', 'B'];
const ACORDES_B = ['C', 'D', 'Bm', 'Em', 'C', 'D', 'B', 'B'];

// El pulso de sintetizador: semicorcheas en la raíz, la octava cada tres (3+3+3+3+4)
const OCTAVA = new Set([2, 5, 8, 11, 14]);
function tictac(c, a, vol = 1) {
  const r = tr(ACORDE[a].raiz, 12);
  for (let k = 0; k < 16; k++) nota('tictac', B(c, k / 4), 0.25, OCTAVA.has(k) ? tr(r, 12) : r, vol * (k % 4 === 0 ? 1 : 0.65));
}
const contra = (c, a, vol = 1) => nota('contra', B(c), 4, ACORDE[a].raiz, vol);
const cuerdas = (c, a, vol = 1) => acorde('cuerdas', B(c), 4, ACORDE[a].notas, vol);
const coro = (c, a, vol = 1) => acorde('coro', B(c), 4, ACORDE[a].notas, vol);
const braam = (t, raiz, vol = 1) => acorde('braam', t, 4, [tr(raiz, -12), raiz, tr(raiz, 7)], vol);
// La sintonía de Velaria, en campana enorme
function campana(c, vol = 1) {
  ['E4', 'G4', 'B4', 'F#5'].forEach((n, k) => nota('campana', B(c, k * 0.75), k === 3 ? 3 : 0.75, n, vol));
}

const TEMA_A = [   // sobre Em C G D Em C Am B
  [['E4', 0.5], ['G4', 0.5], ['B4', 0.5], ['F#5', 2.5]],
  [['E5', 1], ['D5', 1], ['B4', 2]],
  [['D4', 0.5], ['G4', 0.5], ['B4', 0.5], ['E5', 2.5]],
  [['F#5', 1], ['E5', 1], ['D5', 1], ['A4', 1]],
  [['E4', 0.5], ['G4', 0.5], ['B4', 0.5], ['F#5', 2.5]],
  [['G5', 1], ['F#5', 1], ['E5', 1], ['C5', 1]],
  [['C5', 1.5], ['B4', 0.5], ['A4', 1], ['E5', 1]],
  [['D#5', 3], ['F#5', 1]],
];
const TEMA_B = [   // sobre C D Bm Em C D B B: el clímax
  [['G5', 2], ['E5', 1], ['G5', 1]],
  [['A5', 2], ['F#5', 1], ['D5', 1]],
  [['B5', 3], ['F#5', 1]],
  [['G5', 2], ['F#5', 1], ['E5', 1]],
  [['E5', 2], ['G5', 1], ['C6', 1]],
  [['D6', 2], ['C6', 1], ['A5', 1]],
  [['B5', 2], ['F#5', 2]],
  [['D#5', 2], ['F#5', 2]],
];

// 1. Entrada (0-3): braam, la sintonía en campana, el reloj; el pulso entra flojito
braam(B(0), 'E2');
campana(0);
nota('contra', B(0), 16, 'E2', 0.8);
acorde('coro', B(0), 8, ACORDE.Em.notas, 0.5);
acorde('coro', B(2), 8, ACORDE.B.notas, 0.5);
for (let c = 0; c < 4; c++) for (let k = 0; k < 4; k++) tic(B(c, k), k % 2 ? 0.6 : 1);
tictac(2, 'Em', 0.4); tictac(3, 'B', 0.6);

// 2. A (4-11): pulso, cuerdas y el tema en las trompas
// 3. A' (12-19): con el coro
// 4. B (20-27): el clímax
// 5. Respiro (28-29): solo el pulso y el reloj; 6. A'' (30-33): media frase a tope
// 7. Final (34-35): campana y pulso; empalma con la entrada
melodia('trompas', 4, TEMA_A, 0.85);
ACORDES_A.forEach((a, k) => { tictac(4 + k, a, 0.8); cuerdas(4 + k, a, 0.7); contra(4 + k, a, 0.8); });
braam(B(12), 'E2');
melodia('trompas', 12, TEMA_A);
ACORDES_A.forEach((a, k) => { tictac(12 + k, a); cuerdas(12 + k, a, 0.8); contra(12 + k, a); coro(12 + k, a, 0.7); });
braam(B(20), 'C2');
braam(B(24), 'C2', 0.8);
melodia('trompas', 20, TEMA_B, 0.9, -1);
melodia('coro', 20, TEMA_B, 0.55);
ACORDES_B.forEach((a, k) => { tictac(20 + k, a); cuerdas(20 + k, a); contra(20 + k, a); coro(20 + k, a, 0.6); });
['Em', 'B'].forEach((a, k) => {
  tictac(28 + k, a, 0.7 + k * 0.15);
  contra(28 + k, a, 0.7);
  for (let j = 0; j < 4; j++) tic(B(28 + k, j), j % 2 ? 0.6 : 1);
});
braam(B(30), 'E2');
melodia('trompas', 30, TEMA_A.slice(4));
['Em', 'C', 'Am', 'B'].forEach((a, k) => { tictac(30 + k, a); cuerdas(30 + k, a); contra(30 + k, a); coro(30 + k, a, 0.8); });
campana(34, 0.9);
['Em', 'B'].forEach((a, k) => {
  tictac(34 + k, a, 0.6 - k * 0.15);
  contra(34 + k, a, 0.7);
  coro(34 + k, a, 0.4);
  for (let j = 0; j < 4; j++) tic(B(34 + k, j), j % 2 ? 0.5 : 0.9);
});

// ── La capa de ritmo (con zombis despiertos) ──
// Tambores: cuatro graves a negras y un redoble de semicorcheas al final de cada frase
function tambores(c, vol = 1, relleno = false) {
  for (let k = 0; k < 4; k++) taiko(B(c, k), (k === 0 ? 1 : 0.6) * vol, k === 0, k % 2 ? 0.3 : -0.3);
  taiko(B(c, 2.5), 0.5 * vol, false, 0.2); taiko(B(c, 3.5), 0.5 * vol, false, -0.2);
  if (relleno) for (let k = 0; k < 8; k++) taiko(B(c, 2 + k / 4), (0.3 + k * 0.1) * vol, false, k % 2 ? 0.4 : -0.4);
}
// Golpes de metal en los acentos 3+3+2 (corcheas 0, 3 y 6)
function golpesMetal(c, a, vol = 1) {
  for (const p of [0, 1.5, 3]) acorde('metal', B(c, p), 0.5, ACORDE[a].notas.slice(0, 3).map((n) => tr(n, -12)), vol);
}
for (let c = 0; c < 4; c++) taiko(B(c), 0.5 + c * 0.12, true);
golpe(B(0), 0.8);
for (let c = 4; c < 12; c++) tambores(c, 0.8, c === 11);
for (let c = 12; c < 28; c++) { tambores(c, 1, c % 4 === 3); caja16(B(c, 2), 0.9); }
ACORDES_B.forEach((a, k) => golpesMetal(20 + k, a, 0.9));
for (let c = 28; c < 30; c++) for (let k = 0; k < 4; k++) taiko(B(c, k), 0.4 + (c - 28) * 0.3, true);
for (let k = 0; k < 16; k++) caja16(B(29, k / 4), 0.15 + 0.7 * k / 15);
for (let c = 30; c < 34; c++) { tambores(c, 1, c === 33); caja16(B(c, 2), 0.9); }
for (const c of [12, 20, 30]) { golpe(B(c)); platillo16(B(c)); ascenso(B(c - 1), 4); }
platillo16(B(24), 0.7);
for (let c = 34; c < 36; c++) taiko(B(c), 0.7 - (c - 34) * 0.15, true);
melodia('trompetas', 12, TEMA_A, 0.8, 1);
melodia('trompetas', 20, TEMA_B, 1);
melodia('trompetas', 30, TEMA_A.slice(4), 1, 1);

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ['respiro', 28, 30], ["A''", 30, 34], ['final', 34, 36]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
