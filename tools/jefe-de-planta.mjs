// ─────────────────────────────────────────────
//  «Jefe de planta»: canción original para las salas de los jefes (también los de la azotea y la planta 40),
//  compuesta aquí desde cero. Épica de tráiler en do menor, rápida y oscura: cuerdas en semicorcheas sin parar
//  (acentos 3+3+2), coro, «braam» y, cuando sale el jefe, tambores, golpes de metal y el tema de Johnny
//  (orquesta.mjs) en trompas y trompetas.
//
//  Dos capas: la base (ostinato, chelos, contrabajos, coro, braam) suena desde que se entra en la sala, tensa; la
//  intensa (tambores, metales, el tema, golpes y platillos) entra cuando aparece el jefe.
//
//  node tools/jefe-de-planta.mjs [--juego]  → tools/efectos/elegir/jefe-de-planta.ogg (y -tranquila.ogg);
//  con --juego, también assets/musica/jefe-de-planta-<capa>.ogg (a -25 LUFS, como la música de peleas). Bucle perfecto.
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr } from './motor-8bit.mjs';
import { copiar, acordes, enTono, TEMA_A, TEMA_B, ACORDES_A, ACORDES_B } from './orquesta.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'jefe-de-planta';

const INS = copiar(['ostinato', 'chelos', 'contra', 'cuerdas', 'coro', 'trompas', 'trompetas', 'metal', 'braam'], {
  trompas: { capa: 'intensa' }, trompetas: { capa: 'intensa' }, metal: { capa: 'intensa' },
  coro: { ataque: 0.3 },
});

// En 4/4, a 132 pulsos por minuto: 44 compases, 80 segundos
const { B, nota, melodia, acorde, taiko, caja16, platillo16, golpe, ascenso, guardar } = crearMotor({
  bpm: 132, compas: 4, compases: 44, instrumentos: INS,
  capas: { percusion: 'intensa', golpe: 'intensa', subida: 'intensa' }, sala: { tamano: 0.88, apagar: 0.42 },
});

const AC = acordes('C');
const TA = enTono(TEMA_A, 'C'), TB = enTono(TEMA_B, 'C');
// El ostinato de semicorcheas, acentos 3+3+2
const FIGURA = [0, 0, 2, 0, 1, 0, 2, 0, 0, 2, 1, 0, 2, 0, 1, 2];
const ACENTO = new Set([0, 3, 6, 8, 11, 14]);
function ostinato(c, a, vol = 1) {
  const t = AC[a].tres;
  FIGURA.forEach((j, k) => nota('ostinato', B(c, k / 4), 0.25, t[j], vol * (ACENTO.has(k) ? 1 : 0.55)));
}
// Los chelos: corcheas en la raíz con la octava en los acentos
function chelos(c, a, vol = 1) {
  const r = tr(AC[a].raiz, 12);
  for (let k = 0; k < 8; k++) {
    const fuerte = k === 0 || k === 3 || k === 6;
    nota('chelos', B(c, k / 2), 0.5, fuerte ? r : tr(r, 12), vol * (fuerte ? 1 : 0.6));
  }
}
const contra = (c, a, vol = 1) => nota('contra', B(c), 4, AC[a].raiz, vol);
const coro = (c, a, vol = 1) => acorde('coro', B(c), 4, AC[a].coro, vol);
const braam = (t, raiz, vol = 1) => acorde('braam', t, 4, [tr(raiz, -12), raiz, tr(raiz, 7)], vol);
// Toda la base de un compás
function base(c, a, vol = 1, conCoro = true) {
  ostinato(c, a, vol); chelos(c, a, vol); contra(c, a, vol);
  if (conCoro) coro(c, a, 0.6 * vol);
}

// 1. Entrada (0-3): braam y el ostinato que crece sobre do
braam(B(0), 'C2');
['i', 'i', 'VI', 'V'].forEach((a, k) => { ostinato(k, a, 0.5 + k * 0.15); contra(k, a, 0.8); });
acorde('coro', B(2), 8, AC.V.coro, 0.5);

// 2. A (4-11) y 3. A' (12-19): el tema (en la capa intensa)
// 4. B (20-27): la segunda frase, con golpes de metal
// 5. Respiro (28-31): solo el ostinato y los chelos, y los tambores que crecen
// 6. A'' (32-39): el tema otra vez, a tope; 7. Final (40-43): el ostinato solo; empalma con la entrada
for (const c0 of [4, 12, 32]) {
  braam(B(c0), 'C2', c0 === 4 ? 0.7 : 1);
  ACORDES_A.forEach((a, k) => base(c0 + k, a, c0 === 4 ? 0.85 : 1, c0 !== 4));
}
braam(B(20), 'Ab1'); braam(B(24), 'Ab1', 0.8);
ACORDES_B.forEach((a, k) => base(20 + k, a));
['i', 'VI', 'iv', 'V'].forEach((a, k) => { ostinato(28 + k, a, 0.6 + k * 0.1); chelos(28 + k, a, 0.7); });
braam(B(40), 'C2', 0.8);
['i', 'VI', 'iv', 'V'].forEach((a, k) => { ostinato(40 + k, a, 0.9 - k * 0.1); contra(40 + k, a, 0.8); coro(40 + k, a, 0.35); });

// ── La capa intensa (cuando sale el jefe) ──
function tambores(c, vol = 1, relleno = false) {
  taiko(B(c), vol, true); taiko(B(c, 1.5), 0.75 * vol, false, -0.3); taiko(B(c, 3), 0.85 * vol, false, 0.3);
  taiko(B(c, 2), 0.5 * vol, true);
  caja16(B(c, 1), 0.8 * vol); caja16(B(c, 3), 0.8 * vol);
  if (relleno) for (let k = 0; k < 8; k++) taiko(B(c, 2 + k / 4), (0.35 + k * 0.08) * vol, false, k % 2 ? 0.4 : -0.4);
}
// Golpes de metal en los acentos 3+3+2
function golpesMetal(c, a, vol = 1) {
  for (const p of [0, 1.5, 3]) acorde('metal', B(c, p), 0.5, AC[a].tres, vol);
}
for (let c = 0; c < 4; c++) { taiko(B(c), 0.5 + c * 0.12, true); taiko(B(c, 2), 0.35 + c * 0.1, true); }
golpe(B(0), 0.7);
for (let c = 4; c < 28; c++) tambores(c, c < 12 ? 0.85 : 1, c % 8 === 7);
for (let c = 28; c < 32; c++) for (let k = 0; k < 4; k++) taiko(B(c, k), 0.35 + (c - 28) * 0.17, k % 2 === 0, k % 2 ? 0.3 : -0.3);
for (let k = 0; k < 16; k++) caja16(B(31, k / 4), 0.15 + 0.75 * k / 15);
for (let c = 32; c < 40; c++) tambores(c, 1, c === 39);
for (let c = 40; c < 44; c++) { taiko(B(c), 0.7 - (c - 40) * 0.1, true); taiko(B(c, 2), 0.4, true); }
for (const c of [12, 20, 32]) { golpe(B(c)); platillo16(B(c)); ascenso(B(c - 1), 4); }
platillo16(B(4), 0.6); platillo16(B(24), 0.7); platillo16(B(28), 0.5);
ACORDES_B.forEach((a, k) => golpesMetal(20 + k, a, 0.9));
melodia('trompas', 4, TA, 0.85, -1);
melodia('trompas', 12, TA, 1, -1);
melodia('trompetas', 12, TA, 0.85);
melodia('trompas', 20, TB, 0.9, -1);
melodia('trompetas', 20, TB, 0.9, -1);
melodia('trompas', 32, TA, 1, -1);
melodia('trompetas', 32, TA, 1);

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ['respiro', 28, 32], ["A''", 32, 40], ['final', 40, 44]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego'), lufs: -25 });
