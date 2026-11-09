// ─────────────────────────────────────────────
//  «Últimas rebajas»: canción original para explorar el Centro comercial, compuesta aquí desde cero.
//  Épica de tráiler en re menor: cuerdas en ostinato de semicorcheas (acentos 3+3+2), coro, trompas con el tema
//  (sube una quinta y se queda), golpes de tráiler y tambores japoneses. La campana del principio es el
//  «ding-dong» de megafonía de «Hilo musical» (la, fa, re), lento y enorme: la firma del centro comercial.
//
//  Dos capas: la base (cuerdas, coro, trompas, campana y los «braam» graves) suena siempre; la de ritmo (tambores,
//  platillos, trompetas una octava arriba y los golpes) entra con zombis despiertos.
//
//  node tools/ultimas-rebajas.mjs [--juego]  → tools/efectos/elegir/ultimas-rebajas.ogg (y -tranquila.ogg);
//  con --juego, también assets/musica/ultimas-rebajas-<capa>.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion, transponer as tr } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'ultimas-rebajas';

// ── Instrumentos ────────────────────────────────
const INS = {
  ostinato: { onda: 'sierra', voces: 3, abrir: 12, ancho: 0.5, vol: 0.22, ataque: 0.004, caida: 0.1, sosten: 0.25, gate: 0.7, suelta: 0.05, eco: 0, sala: 0.35, pan: -0.25, filtro: 2200, filtroEnv: 1.2 },
  chelos:   { onda: 'sierra', voces: 3, abrir: 10, ancho: 0.4, vol: 0.3, ataque: 0.004, caida: 0.15, sosten: 0.35, gate: 0.75, suelta: 0.06, eco: 0, sala: 0.25, pan: 0.15, filtro: 650, filtroEnv: 1.2 },
  contra:   { onda: 'sierra', voces: 3, abrir: 8, ancho: 0.2, vol: 0.32, ataque: 0.15, caida: 1, sosten: 0.9, gate: 0.98, suelta: 0.3, eco: 0, sala: 0.2, pan: 0, filtro: 260 },
  manto:    { onda: 'sierra', voces: 6, abrir: 20, ancho: 0.9, vol: 0.045, ataque: 0.7, caida: 2, sosten: 1, gate: 1, suelta: 0.8, eco: 0, sala: 0.6, pan: 0, filtro: 1800 },
  coro:     { onda: 'coro', voces: 5, abrir: 18, ancho: 0.9, vol: 0.13, ataque: 0.5, caida: 2, sosten: 1, gate: 1, suelta: 0.7, eco: 0, sala: 0.7, pan: 0, vibrato: 0.08 },
  trompas:  { onda: 'sierra', voces: 3, abrir: 10, ancho: 0.4, vol: 0.3, ataque: 0.07, caida: 0.5, sosten: 0.8, gate: 0.95, suelta: 0.2, eco: 0, sala: 0.55, pan: 0.2, filtro: 600, filtroEnv: 1.6, vibrato: 0.06, glide: 0.08 },
  braam:    { onda: 'sierra', voces: 6, abrir: 28, ancho: 0.8, vol: 0.13, ataque: 0.03, caida: 1.4, sosten: 0.35, suena: 2.6, suelta: 0.9, eco: 0, sala: 0.6, pan: 0, filtro: 160, filtroEnv: 7, reso: 1.2 },
  campana:  { onda: 'fm', ratio: 3.5, indice: 2.2, indiceCae: 0.8, vol: 0.14, ataque: 0.002, caida: 2.2, sosten: 0, suena: 3, suelta: 1, eco: 0, sala: 0.7, pan: 0 },
  // los de la capa de ritmo
  trompetas: { onda: 'sierra', voces: 3, abrir: 9, ancho: 0.5, vol: 0.16, ataque: 0.05, caida: 0.4, sosten: 0.8, gate: 0.92, suelta: 0.15, eco: 0, sala: 0.5, pan: -0.1, filtro: 1300, filtroEnv: 2, vibrato: 0.07, glide: 0.06, capa: 'ritmo' },
};

// En 4/4, a 100 pulsos por minuto: 36 compases, 86 segundos
const { B, nota, melodia, acorde, taiko, caja16, platillo16, golpe, ascenso, guardar } = crearMotor({
  bpm: 100, compas: 4, compases: 36, instrumentos: INS,
  capas: { percusion: 'ritmo', golpe: 'ritmo', subida: 'ritmo' }, sala: { tamano: 0.9, apagar: 0.4 },
});

// ── PARTITURA ───────────────────────────────────
// Cada acorde: su nota grave, las tres notas del ostinato y las del coro
const ACORDE = {
  Dm:  { raiz: 'D2', tres: ['D4', 'F4', 'A4'], coro: ['D4', 'F4', 'A4', 'D5'] },
  Bb:  { raiz: 'Bb1', tres: ['D4', 'F4', 'Bb4'], coro: ['D4', 'F4', 'Bb4', 'D5'] },
  F:   { raiz: 'F2', tres: ['C4', 'F4', 'A4'], coro: ['C4', 'F4', 'A4', 'C5'] },
  C:   { raiz: 'C2', tres: ['C4', 'E4', 'G4'], coro: ['C4', 'E4', 'G4', 'C5'] },
  Gm:  { raiz: 'G1', tres: ['D4', 'G4', 'Bb4'], coro: ['D4', 'G4', 'Bb4', 'D5'] },
  A:   { raiz: 'A1', tres: ['C#4', 'E4', 'A4'], coro: ['C#4', 'E4', 'A4', 'C#5'] },
  Asus: { raiz: 'A1', tres: ['D4', 'E4', 'A4'], coro: ['D4', 'E4', 'A4', 'D5'] },
  DmC: { raiz: 'C2', tres: ['D4', 'F4', 'A4'], coro: ['C4', 'F4', 'A4', 'D5'] },
};
const ACORDES_A = ['Dm', 'Bb', 'F', 'C', 'Dm', 'Bb', 'Gm', 'A'];
const ACORDES_B = ['Bb', 'C', 'Dm', 'DmC', 'Bb', 'C', 'Asus', 'A'];

// El ostinato: 16 semicorcheas por compás, acentos 3+3+2 (posiciones 0, 3, 6, 8, 11 y 14)
const FIGURA = [0, 0, 2, 0, 1, 0, 2, 0, 0, 2, 1, 0, 2, 0, 1, 2];
const ACENTO = new Set([0, 3, 6, 8, 11, 14]);
function ostinato(c, a, vol = 1) {
  const tres = ACORDE[a].tres;
  FIGURA.forEach((j, k) => nota('ostinato', B(c, k / 4), 0.25, tres[j], vol * (ACENTO.has(k) ? 1 : 0.55)));
}
// Los chelos: corcheas en la raíz con la octava en los acentos (3+3+2)
function chelos(c, a, vol = 1) {
  const r = tr(ACORDE[a].raiz, 12);
  for (let k = 0; k < 8; k++) {
    const fuerte = k === 0 || k === 3 || k === 6;
    nota('chelos', B(c, k / 2), 0.5, fuerte ? r : tr(r, 12), vol * (fuerte ? 1 : 0.6));
  }
}
const contra = (c, a, vol = 1) => nota('contra', B(c), 4, ACORDE[a].raiz, vol);
const coro = (c, a, vol = 1) => acorde('coro', B(c), 4, ACORDE[a].coro, vol);
const manto = (c, a, vol = 1) => acorde('manto', B(c), 4, ACORDE[a].coro.map((n) => tr(n, 12)), vol);
// El «braam»: un acorde gravísimo que se abre de golpe
const braam = (t, raiz, vol = 1) => acorde('braam', t, 4, [tr(raiz, -12), raiz, tr(raiz, 7)], vol);
// La megafonía de «Hilo musical», de campana enorme: la, fa, re
function campanas(c, vol = 1) {
  nota('campana', B(c), 2, 'A4', vol);
  nota('campana', B(c, 1.5), 2, 'F4', vol * 0.9);
  nota('campana', B(c, 3), 2, 'D4', vol);
}

// El tema: sube una quinta y se queda; acaba en la sensible para volver a empezar
const TEMA_A = [
  [['D4', 1], ['A4', 1.5], ['G4', 0.5], ['A4', 1]],
  [['Bb4', 2], ['A4', 1], ['F4', 1]],
  [['C5', 1.5], ['A4', 0.5], ['F4', 2]],
  [['E4', 1.5], ['F4', 0.5], ['G4', 2]],
  [['D4', 1], ['A4', 1.5], ['G4', 0.5], ['A4', 1]],
  [['D5', 2], ['C5', 1], ['Bb4', 1]],
  [['Bb4', 1], ['A4', 1], ['G4', 1], ['Bb4', 1]],
  [['A4', 3], ['C#5', 1]],
];
const TEMA_B = [   // más arriba, el clímax
  [['F5', 2], ['D5', 1], ['F5', 1]],
  [['G5', 2], ['E5', 1], ['C5', 1]],
  [['A5', 3], ['F5', 1]],
  [['E5', 2], ['D5', 1], ['C5', 1]],
  [['D5', 2], ['F5', 1], ['Bb5', 1]],
  [['C6', 2], ['Bb5', 1], ['G5', 1]],
  [['A5', 2], ['D5', 2]],
  [['C#5', 2], ['E5', 2]],
];

// 1. Entrada (0-3): braam y la campana; el ostinato entra flojito
braam(B(0), 'D2');
campanas(0);
acorde('coro', B(0), 8, ACORDE.Dm.coro, 0.6);
acorde('coro', B(2), 8, ['C#4', 'E4', 'A4', 'C#5'], 0.6);
nota('contra', B(0), 16, 'D2', 0.8);
for (let c = 2; c < 4; c++) ostinato(c, c === 2 ? 'Dm' : 'A', 0.45 + (c - 2) * 0.25);

// 2. A (4-11): el tema en las trompas, el ostinato y los chelos
// 3. A' (12-19): con coro y manto de cuerdas
// 4. B (20-27): el clímax, el tema arriba
// 5. A'' (28-31): media frase, a tope
// 6. Final (32-35): se queda el ostinato con la campana y empalma con la entrada
braam(B(4), 'D2', 0.7);
melodia('trompas', 4, TEMA_A, 0.85);
ACORDES_A.forEach((a, k) => { ostinato(4 + k, a, 0.75); chelos(4 + k, a, 0.8); contra(4 + k, a, 0.8); });

braam(B(12), 'D2');
melodia('trompas', 12, TEMA_A);
ACORDES_A.forEach((a, k) => { ostinato(12 + k, a, 0.85); chelos(12 + k, a); contra(12 + k, a); coro(12 + k, a, 0.7); });

braam(B(20), 'Bb1');
braam(B(24), 'Bb1', 0.8);
melodia('trompas', 20, TEMA_B, 0.9, -1);
melodia('coro', 20, TEMA_B, 0.55);
ACORDES_B.forEach((a, k) => { ostinato(20 + k, a); chelos(20 + k, a); contra(20 + k, a); manto(20 + k, a, 0.8); coro(20 + k, a, 0.6); });

braam(B(28), 'D2');
melodia('trompas', 28, TEMA_A.slice(4));
['Dm', 'Bb', 'Gm', 'A'].forEach((a, k) => { ostinato(28 + k, a); chelos(28 + k, a); contra(28 + k, a); coro(28 + k, a, 0.8); manto(28 + k, a, 0.7); });

campanas(32, 0.9);
['Dm', 'Bb', 'Gm', 'A'].forEach((a, k) => {
  ostinato(32 + k, a, 0.7 - k * 0.08);
  contra(32 + k, a, 0.7);
  coro(32 + k, a, 0.4);
});

// ── La capa de ritmo (con zombis despiertos) ──
// Tambores 3+3+2: el grave en la parte fuerte y otros dos en los acentos
function tambores(c, vol = 1, relleno = false) {
  taiko(B(c), vol, true); taiko(B(c, 1.5), 0.7 * vol, false, -0.3); taiko(B(c, 3), 0.8 * vol, false, 0.3);
  if (relleno) for (let k = 0; k < 4; k++) taiko(B(c, 3 + k / 4), (0.4 + k * 0.15) * vol, false, k % 2 ? 0.4 : -0.4);
}
for (let c = 0; c < 4; c++) taiko(B(c), 0.5 + c * 0.12, true);
golpe(B(0), 0.8);
for (let c = 4; c < 12; c++) tambores(c, 0.8, c === 11);
for (let c = 12; c < 32; c++) {
  tambores(c, 1, c % 4 === 3);
  caja16(B(c, 1), 0.8); caja16(B(c, 3), 0.8);
}
for (const c of [12, 20, 28]) { golpe(B(c)); platillo16(B(c)); ascenso(B(c - 1), 4); }
platillo16(B(24), 0.7);
for (let c = 32; c < 36; c++) taiko(B(c), 0.8 - (c - 32) * 0.12, true);
melodia('trompetas', 12, TEMA_A, 0.8, 1);
melodia('trompetas', 20, TEMA_B, 1);
melodia('trompetas', 28, TEMA_A.slice(4), 1, 1);

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['A', 4, 12], ["A'", 12, 20], ['B', 20, 28], ["A''", 28, 32], ['final', 32, 36]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
