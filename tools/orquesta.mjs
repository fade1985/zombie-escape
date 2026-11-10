// ─────────────────────────────────────────────
//  Lo que comparten las canciones épicas del menú, los Apartamentos y los jefes (el-conserje.mjs,
//  planta-por-planta.mjs y jefe-de-planta.mjs): los instrumentos de orquesta y el tema principal del juego.
//
//  El tema de Johnny (en la menor, sobre La menor, Fa, Do, Sol, La menor, Fa, Re menor y Mi): una nota larga que sube
//  paso a paso y salta a la quinta (la, si, do... mi), y la segunda frase, más arriba, que acaba en la sensible para
//  volver a empezar. Cada canción lo toca en su tono con «enTono».
// ─────────────────────────────────────────────
import { transponer } from './motor-8bit.mjs';

// Los instrumentos (cada canción los copia y cambia lo que quiera: volumen, capa...)
export const ORQUESTA = {
  ostinato: { onda: 'sierra', voces: 3, abrir: 12, ancho: 0.5, vol: 0.22, ataque: 0.004, caida: 0.1, sosten: 0.25, gate: 0.7, suelta: 0.05, eco: 0, sala: 0.35, pan: -0.25, filtro: 2200, filtroEnv: 1.2 },
  chelos:   { onda: 'sierra', voces: 3, abrir: 10, ancho: 0.4, vol: 0.3, ataque: 0.004, caida: 0.15, sosten: 0.35, gate: 0.75, suelta: 0.06, eco: 0, sala: 0.25, pan: 0.15, filtro: 650, filtroEnv: 1.2 },
  contra:   { onda: 'sierra', voces: 3, abrir: 8, ancho: 0.2, vol: 0.32, ataque: 0.15, caida: 1, sosten: 0.9, gate: 0.98, suelta: 0.3, eco: 0, sala: 0.2, pan: 0, filtro: 260 },
  cuerdas:  { onda: 'sierra', voces: 6, abrir: 20, ancho: 0.9, vol: 0.07, ataque: 0.35, caida: 2, sosten: 1, gate: 1, suelta: 0.6, eco: 0, sala: 0.6, pan: 0, filtro: 1900 },
  violines: { onda: 'sierra', voces: 5, abrir: 16, ancho: 0.7, vol: 0.12, ataque: 0.12, caida: 1, sosten: 0.9, gate: 0.97, suelta: 0.35, eco: 0, sala: 0.6, pan: -0.15, filtro: 2400, vibrato: 0.1, glide: 0.08 },
  coro:     { onda: 'coro', voces: 5, abrir: 18, ancho: 0.9, vol: 0.13, ataque: 0.5, caida: 2, sosten: 1, gate: 1, suelta: 0.7, eco: 0, sala: 0.7, pan: 0, vibrato: 0.08 },
  trompas:  { onda: 'sierra', voces: 3, abrir: 10, ancho: 0.4, vol: 0.3, ataque: 0.07, caida: 0.5, sosten: 0.8, gate: 0.95, suelta: 0.2, eco: 0, sala: 0.55, pan: 0.2, filtro: 600, filtroEnv: 1.6, vibrato: 0.06, glide: 0.08 },
  trompetas: { onda: 'sierra', voces: 3, abrir: 9, ancho: 0.5, vol: 0.16, ataque: 0.05, caida: 0.4, sosten: 0.8, gate: 0.92, suelta: 0.15, eco: 0, sala: 0.5, pan: -0.1, filtro: 1300, filtroEnv: 2, vibrato: 0.07, glide: 0.06 },
  metal:    { onda: 'sierra', voces: 4, abrir: 14, ancho: 0.7, vol: 0.13, ataque: 0.01, caida: 0.2, sosten: 0.3, gate: 0.6, suelta: 0.12, eco: 0, sala: 0.6, pan: 0, filtro: 700, filtroEnv: 3 },
  braam:    { onda: 'sierra', voces: 6, abrir: 28, ancho: 0.8, vol: 0.13, ataque: 0.03, caida: 1.4, sosten: 0.35, suena: 2.6, suelta: 0.9, eco: 0, sala: 0.6, pan: 0, filtro: 160, filtroEnv: 7, reso: 1.2 },
  piano:    { onda: 'fm', ratio: 1, indice: 1.2, indiceCae: 0.6, vol: 0.16, ataque: 0.003, caida: 1.6, sosten: 0.05, gate: 0.95, suelta: 0.8, eco: 0.2, sala: 0.55, pan: 0.15 },
  celesta:  { onda: 'fm', ratio: 4, indice: 1.2, indiceCae: 0.3, vol: 0.11, ataque: 0.002, caida: 0.7, sosten: 0, suena: 0.6, suelta: 0.3, eco: 0.35, sala: 0.5, pan: -0.35 },
  campana:  { onda: 'fm', ratio: 3.5, indice: 2.2, indiceCae: 0.8, vol: 0.13, ataque: 0.002, caida: 2.2, sosten: 0, suena: 3, suelta: 1, eco: 0, sala: 0.7, pan: 0 },
};
// Una copia de los instrumentos que se piden, con lo que cambie cada canción: copiar(['coro', 'piano'], { piano: { vol: 0.2 } })
export function copiar(nombres, cambios = {}) {
  return Object.fromEntries(nombres.map((n) => [n, { ...ORQUESTA[n], ...(cambios[n] ?? {}) }]));
}

// El tema, en la menor: [nota, pulsos] por compás
export const TEMA_A = [   // sobre Am F C G Am F Dm E
  [['A4', 1.5], ['B4', 0.5], ['C5', 1], ['E5', 1]],
  [['F5', 2], ['E5', 1], ['C5', 1]],
  [['D5', 1.5], ['C5', 0.5], ['B4', 1], ['G4', 1]],
  [['B4', 2], ['A4', 1], ['G4', 1]],
  [['A4', 1.5], ['B4', 0.5], ['C5', 1], ['E5', 1]],
  [['A5', 2], ['G5', 1], ['F5', 1]],
  [['F5', 1], ['E5', 1], ['D5', 1], ['C5', 1]],
  [['B4', 3], ['G#4', 1]],
];
export const TEMA_B = [   // sobre F G Em Am F G E E: más arriba
  [['C6', 2], ['A5', 1], ['F5', 1]],
  [['D6', 2], ['B5', 1], ['G5', 1]],
  [['B5', 1.5], ['A5', 0.5], ['G5', 1], ['E5', 1]],
  [['A5', 3], ['E5', 1]],
  [['C6', 2], ['A5', 1], ['C6', 1]],
  [['D6', 1.5], ['C6', 0.5], ['B5', 1], ['G5', 1]],
  [['G#5', 2], ['B5', 2]],
  [['E5', 2], ['G#5', 1], ['B5', 1]],
];
export const ACORDES_A = ['i', 'VI', 'III', 'VII', 'i', 'VI', 'iv', 'V'];
export const ACORDES_B = ['VI', 'VII', 'v', 'i', 'VI', 'VII', 'V', 'V'];

// Los acordes de una tonalidad menor (raíz de la tónica, p. ej. 'A'): su nota grave, tres notas para el ostinato y
// cuatro para el coro y las cuerdas
export function acordes(tonica) {
  const t = (n, s) => transponer(n, s);
  const de = (raizGrave, notas) => ({ raiz: raizGrave, tres: notas.slice(0, 3), coro: notas });
  const base = {   // en la menor; luego se mueve
    i:   de('A1', ['A3', 'C4', 'E4', 'A4']),
    VI:  de('F1', ['A3', 'C4', 'F4', 'A4']),
    III: de('C2', ['G3', 'C4', 'E4', 'G4']),
    VII: de('G1', ['G3', 'B3', 'D4', 'G4']),
    iv:  de('D2', ['A3', 'D4', 'F4', 'A4']),
    v:   de('E2', ['G3', 'B3', 'E4', 'G4']),
    V:   de('E2', ['G#3', 'B3', 'E4', 'G#4']),
  };
  const semis = ({ C: 3, D: 5, E: 7, F: 8, G: 10, A: 0, B: 2 })[tonica[0]] - (tonica.includes('b') ? 1 : 0) + (tonica.includes('#') ? 1 : 0);
  const mover = (s) => (s > 6 ? s - 12 : s);   // lo más cerca posible
  const m = mover(semis);
  return Object.fromEntries(Object.entries(base).map(([k, a]) => [k, { raiz: t(a.raiz, m), tres: a.tres.map((n) => t(n, m)), coro: a.coro.map((n) => t(n, m)) }]));
}
// El tema en otro tono: enTono(TEMA_A, 'G') lo baja de la menor a sol menor (lo más cerca posible)
export function enTono(frase, tonica) {
  const semis = ({ C: 3, D: 5, E: 7, F: 8, G: 10, A: 0, B: 2 })[tonica[0]] - (tonica.includes('b') ? 1 : 0) + (tonica.includes('#') ? 1 : 0);
  const m = semis > 6 ? semis - 12 : semis;
  return frase.map((c) => c.map(([n, d]) => [n === '-' ? n : (n.startsWith('~') ? '~' : '') + transponer(n.replace('~', ''), m), d]));
}
