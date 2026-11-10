// ─────────────────────────────────────────────
//  «Planta por planta»: canción original para explorar los Apartamentos, compuesta aquí desde cero.
//  Épica de tráiler en sol menor con el tema de Johnny (orquesta.mjs) en las trompas y los violines. De la canción
//  vieja de los Apartamentos («El último inquilino») se queda lo que los hacía suyos: la cajita de música en
//  tresillos y el reloj de la portería.
//
//  Dos capas: la base (cajita, reloj, cuerdas, coro, trompas, campana) suena siempre; la de ritmo (tambores,
//  ostinato de semicorcheas, trompetas y golpes) entra con zombis despiertos.
//
//  node tools/planta-por-planta.mjs [--juego]  → tools/efectos/elegir/planta-por-planta.ogg (y -tranquila.ogg);
//  con --juego, también assets/musica/planta-por-planta-<capa>.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr, SR } from './motor-8bit.mjs';
import { copiar, acordes, enTono, TEMA_A, TEMA_B, ACORDES_A, ACORDES_B } from './orquesta.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'planta-por-planta';

const INS = copiar(['ostinato', 'chelos', 'contra', 'cuerdas', 'violines', 'coro', 'trompas', 'trompetas', 'braam', 'celesta', 'campana'], {
  ostinato: { capa: 'ritmo' }, trompetas: { capa: 'ritmo' }, celesta: { vol: 0.1, pan: -0.3 },
});

// En 4/4, a 92 pulsos por minuto: 36 compases, 94 segundos
const { B, nota, melodia, acorde, sonido, taiko, caja16, platillo16, golpe, ascenso, guardar } = crearMotor({
  bpm: 92, compas: 4, compases: 36, instrumentos: INS,
  capas: { percusion: 'ritmo', golpe: 'ritmo', subida: 'ritmo' }, sala: { tamano: 0.9, apagar: 0.4 },
});

// El reloj de la portería: «tic» y «tac», uno a cada lado
function tic(t, alto, vol = 1) {
  let fase = 0;
  const f = alto ? 2300 : 1700;
  sonido(t, 0.05, (s) => {
    fase = (fase + f / SR) % 1;
    return Math.sin(2 * Math.PI * fase) * Math.exp(-s / 0.007) * 0.11 * vol;
  }, alto ? 0.35 : -0.35, 0.15, 0.2);
}
const reloj = (c, vol = 1) => { for (let k = 0; k < 4; k++) tic(B(c, k), k % 2 === 0, vol); };

const AC = acordes('G');
const TA = enTono(TEMA_A, 'G'), TB = enTono(TEMA_B, 'G');
// La cajita: doce notas por compás (tresillos), sube y baja por el acorde
const CAJITA = [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1];
function cajita(c, a, vol = 1) {
  const n = AC[a].coro.map((x) => tr(x, 12));
  CAJITA.forEach((j, k) => nota('celesta', B(c, k / 3), 1 / 3, n[j], vol * (k % 3 === 0 ? 1 : 0.7)));
}
// El ostinato de semicorcheas, acentos 3+3+2 (capa de ritmo)
const FIGURA = [0, 0, 2, 0, 1, 0, 2, 0, 0, 2, 1, 0, 2, 0, 1, 2];
const ACENTO = new Set([0, 3, 6, 8, 11, 14]);
function ostinato(c, a, vol = 1) {
  const t = AC[a].tres;
  FIGURA.forEach((j, k) => nota('ostinato', B(c, k / 4), 0.25, t[j], vol * (ACENTO.has(k) ? 1 : 0.55)));
}
function chelos(c, a, vol = 1) {
  const r = tr(AC[a].raiz, 12);
  for (let k = 0; k < 8; k++) {
    const fuerte = k === 0 || k === 3 || k === 6;
    nota('chelos', B(c, k / 2), 0.5, fuerte ? r : tr(r, 12), vol * (fuerte ? 1 : 0.6));
  }
}
const contra = (c, a, vol = 1) => nota('contra', B(c), 4, AC[a].raiz, vol);
const cuerdas = (c, a, vol = 1) => acorde('cuerdas', B(c), 4, AC[a].coro, vol);
const coro = (c, a, vol = 1) => acorde('coro', B(c), 4, AC[a].coro, vol);
const braam = (t, raiz, vol = 1) => acorde('braam', t, 4, [tr(raiz, -12), raiz, tr(raiz, 7)], vol);

// 1. Entrada (0-3): campana, reloj y cajita sobre un sol grave
nota('campana', B(0), 4, 'G3', 0.9);
nota('contra', B(0), 16, 'G1', 0.7);
['i', 'VI', 'iv', 'V'].forEach((a, k) => { cajita(k, a, 0.6 + k * 0.12); reloj(k); coro(k, a, 0.35); });

// 2. A (4-11): el tema en las trompas, con cajita y cuerdas; el reloj sigue
// 3. A' (12-19): los violines con el tema, coro y chelos
// 4. B (20-27): la segunda frase; 5. A'' (28-31): media frase a tope
// 6. Final (32-35): cajita y reloj; empalma con la entrada
braam(B(4), 'G1', 0.6);
melodia('trompas', 4, TA, 0.85, -1);
ACORDES_A.forEach((a, k) => { cajita(4 + k, a, 0.7); cuerdas(4 + k, a, 0.6); contra(4 + k, a, 0.75); reloj(4 + k, 0.6); });
braam(B(12), 'G1');
melodia('violines', 12, TA);
melodia('trompas', 12, TA, 0.7, -1);
ACORDES_A.forEach((a, k) => { cajita(12 + k, a, 0.5); cuerdas(12 + k, a, 0.7); contra(12 + k, a); coro(12 + k, a, 0.6); chelos(12 + k, a, 0.8); });
braam(B(20), 'Eb1');
braam(B(24), 'Eb1', 0.8);
melodia('trompas', 20, TB, 0.9, -1);
melodia('coro', 20, TB, 0.5, -1);
ACORDES_B.forEach((a, k) => { cuerdas(20 + k, a, 0.8); contra(20 + k, a); coro(20 + k, a, 0.6); chelos(20 + k, a); });
braam(B(28), 'G1');
melodia('violines', 28, TA.slice(4));
melodia('trompas', 28, TA.slice(4), 0.9, -1);
['i', 'VI', 'iv', 'V'].forEach((a, k) => { cuerdas(28 + k, a, 0.8); contra(28 + k, a); coro(28 + k, a, 0.7); chelos(28 + k, a); });
nota('campana', B(32), 4, 'G3', 0.8);
['i', 'VI', 'iv', 'V'].forEach((a, k) => { cajita(32 + k, a, 0.85 - k * 0.07); reloj(32 + k); contra(32 + k, a, 0.6); coro(32 + k, a, 0.3); });

// ── La capa de ritmo (con zombis despiertos) ──
function tambores(c, vol = 1, relleno = false) {
  taiko(B(c), vol, true); taiko(B(c, 1.5), 0.7 * vol, false, -0.3); taiko(B(c, 3), 0.8 * vol, false, 0.3);
  if (relleno) for (let k = 0; k < 4; k++) taiko(B(c, 3 + k / 4), (0.4 + k * 0.15) * vol, false, k % 2 ? 0.4 : -0.4);
}
for (let c = 0; c < 4; c++) taiko(B(c), 0.45 + c * 0.1, true);
for (let c = 4; c < 12; c++) tambores(c, 0.8, c === 11);
for (let c = 12; c < 32; c++) { tambores(c, 1, c % 4 === 3); caja16(B(c, 1), 0.75); caja16(B(c, 3), 0.75); }
for (let c = 32; c < 36; c++) taiko(B(c), 0.7 - (c - 32) * 0.1, true);
for (const c of [12, 20, 28]) { golpe(B(c)); platillo16(B(c)); ascenso(B(c - 1), 4); }
ACORDES_A.forEach((a, k) => { ostinato(4 + k, a, 0.6); ostinato(12 + k, a, 0.8); });
ACORDES_B.forEach((a, k) => ostinato(20 + k, a, 0.9));
['i', 'VI', 'iv', 'V'].forEach((a, k) => ostinato(28 + k, a, 0.9));
melodia('trompetas', 12, TA, 0.8);
melodia('trompetas', 20, TB, 1);
melodia('trompetas', 28, TA.slice(4), 1);

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ["A''", 28, 32], ['final', 32, 36]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
