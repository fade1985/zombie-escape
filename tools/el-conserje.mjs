// ─────────────────────────────────────────────
//  «El conserje»: canción original para el menú principal, compuesta aquí desde cero.
//  Épica de pantalla de título en la menor, lenta y majestuosa: piano arpegiado, coro, una campana y el tema de Johnny
//  (orquesta.mjs) entero, primero en una trompa sola y luego con toda la orquesta; al final se queda el piano solo
//  con el principio del tema y empalma con la entrada.
//
//  Una sola capa (en el menú no hay zombis que la hagan subir; así, en la web, ocupa la mitad).
//
//  node tools/el-conserje.mjs [--juego]  → tools/efectos/elegir/el-conserje.ogg; con --juego, también
//  assets/musica/el-conserje-base.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr } from './motor-8bit.mjs';
import { copiar, acordes, TEMA_A, TEMA_B, ACORDES_A, ACORDES_B } from './orquesta.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'el-conserje';

const INS = copiar(['ostinato', 'chelos', 'contra', 'cuerdas', 'violines', 'coro', 'trompas', 'trompetas', 'braam', 'piano', 'celesta', 'campana'], {
  ostinato: { vol: 0.15 }, trompas: { vol: 0.26 }, braam: { vol: 0.1 },
});

// En 4/4, a 76 pulsos por minuto: 32 compases, 101 segundos
const { B, nota, melodia, acorde, taiko, golpe, ascenso, platillo16, guardar } = crearMotor({
  bpm: 76, compas: 4, compases: 32, instrumentos: INS, sala: { tamano: 0.9, apagar: 0.4 },
});

const AC = acordes('A');
// El piano: corcheas que suben y bajan por el acorde
const SUBE_BAJA = [0, 1, 2, 3, 2, 1, 2, 1];
function piano(c, a, vol = 1) {
  const n = AC[a].coro.map((x) => tr(x, 12));
  SUBE_BAJA.forEach((j, k) => nota('piano', B(c, k / 2), 0.5, n[j], vol * (k === 0 ? 1 : 0.65)));
}
// El ostinato suave: corcheas (no semicorcheas: aquí todo respira)
function ostinato(c, a, vol = 1) {
  const t = AC[a].tres;
  [0, 2, 1, 2, 0, 2, 1, 2].forEach((j, k) => nota('ostinato', B(c, k / 2), 0.5, t[j], vol * (k % 4 === 0 ? 1 : 0.6)));
}
const contra = (c, a, vol = 1) => nota('contra', B(c), 4, AC[a].raiz, vol);
const cuerdas = (c, a, vol = 1) => acorde('cuerdas', B(c), 4, AC[a].coro, vol);
const coro = (c, a, vol = 1) => acorde('coro', B(c), 4, AC[a].coro, vol);
function chelos(c, a, vol = 1) {
  const r = tr(AC[a].raiz, 12);
  [0, 1.5, 2, 3.5].forEach((p, k) => nota('chelos', B(c, p), k % 2 ? 0.5 : 1.5, k === 2 ? tr(r, 7) : r, vol * (k % 2 ? 0.6 : 1)));
}

// 1. Entrada (0-3): campana, piano y coro sobre un la grave
nota('campana', B(0), 4, 'A3', 0.9);
nota('contra', B(0), 16, 'A1', 0.7);
['i', 'VI', 'iv', 'V'].forEach((a, k) => { piano(k, a, 0.7 + k * 0.08); coro(k, a, 0.45); });
melodia('celesta', 2, [[['E5', 1], ['A5', 1], ['B5', 1], ['C6', 1]], [['B5', 2], ['G#5', 2]]], 0.7);

// 2. A (4-11): el tema en la trompa sola, con piano y cuerdas
melodia('trompas', 4, TEMA_A, 0.85, -1);
ACORDES_A.forEach((a, k) => { piano(4 + k, a, 0.75); cuerdas(4 + k, a, 0.6); contra(4 + k, a, 0.7); });

// 3. A' (12-19): los violines con el tema y la trompa una octava abajo; entra el coro y, al final, los tambores
melodia('violines', 12, TEMA_A);
melodia('trompas', 12, TEMA_A, 0.7, -1);
ACORDES_A.forEach((a, k) => {
  piano(12 + k, a, 0.6); cuerdas(12 + k, a, 0.7); contra(12 + k, a, 0.8); coro(12 + k, a, 0.55);
  ostinato(12 + k, a, 0.5 + k * 0.06);
});
for (let c = 16; c < 20; c++) { taiko(B(c), 0.45 + (c - 16) * 0.1, true); taiko(B(c, 2), 0.3 + (c - 16) * 0.08, true); }
ascenso(B(19), 4, 0.7);

// 4. B (20-27): la segunda frase con toda la orquesta
golpe(B(20), 0.8); platillo16(B(20), 0.8);
acorde('braam', B(20), 4, ['F1', 'F2', 'C3']);
melodia('trompetas', 20, TEMA_B, 0.9);
melodia('trompas', 20, TEMA_B, 0.9, -1);
melodia('coro', 20, TEMA_B, 0.45, -1);
ACORDES_B.forEach((a, k) => {
  cuerdas(20 + k, a, 0.8); contra(20 + k, a); coro(20 + k, a, 0.6); ostinato(20 + k, a, 0.9); chelos(20 + k, a, 0.8);
  taiko(B(20 + k), 0.8, true); taiko(B(20 + k, 1.5), 0.5); taiko(B(20 + k, 3), 0.6);
});
platillo16(B(24), 0.6);

// 5. Final (28-31): el piano solo con el principio del tema, la campana; empalma con la entrada
nota('campana', B(28), 4, 'A3', 0.8);
melodia('piano', 28, TEMA_A.slice(0, 2), 0.9);
melodia('piano', 30, [[['D5', 1.5], ['C5', 0.5], ['B4', 2]], [['G#4', 4]]], 0.8);
['i', 'VI', 'iv', 'V'].forEach((a, k) => { cuerdas(28 + k, a, 0.55 - k * 0.05); contra(28 + k, a, 0.6); coro(28 + k, a, 0.35); });

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ['final', 28, 32]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
