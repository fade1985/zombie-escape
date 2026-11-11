// ─────────────────────────────────────────────
//  «Sin luz»: canción original para el menú principal (11 nov), compuesta aquí desde cero, en lugar de «El conserje»
//  (el-conserje.mjs, épica: el dueño quería que el menú diera miedo, que el juego es de terror).
//  Terror en re menor, lenta (60 pulsos por minuto): un zumbido grave que respira, viento, una campana lejana y una caja
//  de música que toca una nana rota, desafinada como una cinta vieja (la «cinta» del motor), con notas que no tocan
//  (sol sostenido, do sostenido, mi bemol). Debajo, cuerdas y un coro con notas que chocan, un latido de corazón,
//  golpes graves de piano y, a la mitad, un golpe de orquesta. Al final se queda el zumbido solo y empalma con la entrada.
//
//  Una sola capa (en el menú no hay zombis que la hagan subir; así, en la web, ocupa la mitad).
//
//  node tools/sin-luz.mjs [--juego]  → tools/efectos/elegir/sin-luz.ogg; con --juego, también
//  assets/musica/sin-luz-base.ogg. Sale en bucle perfecto (motor-8bit.mjs).
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sacarCancion } from './motor-8bit.mjs';
import { ORQUESTA, copiar } from './orquesta.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const NOMBRE = 'sin-luz';
const COMPASES = 24;
const SEGUNDOS = COMPASES * 4;   // (a 60 pulsos por minuto, un pulso es un segundo)

const INS = {
  ...copiar(['campana', 'braam']),
  // El zumbido: sierras muy graves y tapadas que suben y bajan despacio, como algo que respira en el sótano
  dron:   { onda: 'sierra', voces: 4, abrir: 14, ancho: 0.6, vol: 0.2, ataque: 3, caida: 4, sosten: 1, gate: 1, suelta: 3, eco: 0, sala: 0.4, pan: 0, filtro: 170, tremolo: { hz: 9 / SEGUNDOS, prof: 0.35 } },
  // La caja de música: campanitas metálicas (FM), con la cinta que tiembla
  caja:   { onda: 'fm', ratio: 5.4, indice: 1.3, indiceCae: 0.2, vol: 0.12, ataque: 0.002, caida: 0.9, sosten: 0, suena: 1.4, suelta: 0.6, eco: 0.35, sala: 0.6, pan: -0.2, cinta: true },
  // Piano grave y apagado, para los golpes
  piano:  { ...ORQUESTA.piano, vol: 0.2, sala: 0.75, filtro: 1200, pan: 0 },
  // Cuerdas que entran muy despacio y también tiemblan
  cuerdas: { ...ORQUESTA.cuerdas, vol: 0.06, ataque: 2.5, suelta: 2, filtro: 1100, sala: 0.75, cinta: true },
  coro:   { ...ORQUESTA.coro, vol: 0.1, ataque: 2.5, suelta: 2, sala: 0.85 },
  // Un violín muy agudo y muy flojo que se queda colgado: la nota que pone los pelos de punta
  aguja:  { onda: 'sierra', voces: 3, abrir: 30, ancho: 0.8, vol: 0.03, ataque: 3, caida: 3, sosten: 1, gate: 1, suelta: 2, eco: 0, sala: 0.8, pan: 0.3, filtro: 3000, vibrato: 0.3 },
};

// La cinta: siempre tiembla un poco y, a ratos, se le cae el tono. Vueltas enteras en los 96 segundos, para que el bucle empalme
const cinta = (s) => 16 * Math.sin(2 * Math.PI * 30 / SEGUNDOS * s) + 7 * Math.sin(2 * Math.PI * 163 / SEGUNDOS * s)
  - 22 * Math.max(0, Math.sin(2 * Math.PI * 5 / SEGUNDOS * s)) ** 6;

const { B, nota, melodia, acorde, campana, viento, bombo, taiko, golpe, guardar } = crearMotor({
  bpm: 60, compas: 4, compases: COMPASES, instrumentos: INS, sala: { tamano: 0.93, apagar: 0.5 }, cinta,
});

// El latido: dos golpes graves (pum-pum) al principio del compás
const latido = (c, vol = 1) => { bombo(B(c), 0.8 * vol, true); bombo(B(c, 0.4), 0.55 * vol, true); };

// Toda la canción: el zumbido en re y la (quinta), que no se va nunca
acorde('dron', B(0), SEGUNDOS, ['D1', 'A1', 'D2']);

// 1. Entrada (0-3): viento, la campana lejana y las cuerdas que asoman
viento(B(0), 16, 0.8);
nota('campana', B(0), 4, 'D3', 0.7);
acorde('cuerdas', B(1), 11, ['D3', 'A3'], 0.7);
nota('aguja', B(2), 6, 'A5', 0.6);

// 2. La nana (4-11): la caja de música sobre acordes que no acaban de sonar bien
melodia('caja', 4, [
  [['D5', 1], ['F5', 1], ['A5', 1.5], ['G#5', 0.5]],
  [['A5', 3], ['-', 1]],
  [['Bb5', 1], ['A5', 1], ['F5', 1], ['E5', 1]],
  [['C#5', 3], ['-', 1]],
  [['D5', 1], ['F5', 1], ['A5', 1], ['D6', 1]],
  [['C#6', 2], ['Bb5', 2]],
  [['A5', 1], ['G#5', 1], ['F5', 1], ['E5', 1]],
  [['Eb5', 4]],
]);
acorde('cuerdas', B(4), 8, ['D3', 'F3', 'A3'], 0.8);
acorde('cuerdas', B(6), 8, ['Bb2', 'D3', 'F3', 'E4'], 0.8);       // si bemol con mi: choca
acorde('cuerdas', B(8), 8, ['D3', 'F3', 'A3', 'C#4'], 0.85);      // re menor con do sostenido
acorde('cuerdas', B(10), 8, ['Eb3', 'G3', 'Bb3', 'D4'], 0.85);    // mi bemol: medio tono por encima de casa
for (let c = 8; c < 12; c++) latido(c, 0.6 + (c - 8) * 0.1);
nota('piano', B(8), 4, 'D2', 0.8); nota('piano', B(8), 4, 'Eb2', 0.6);

// 3. Lo que se acerca (12-19): la nana se rompe, el coro con notas pegadas, el violín agudo y el latido más deprisa
nota('campana', B(12), 4, 'D3', 0.8);
melodia('caja', 12, [
  [['D5', 1], ['F5', 1], ['A5', 2]],
  [['G#5', 4]],
  [['F5', 1], ['E5', 1], ['Eb5', 2]],
  [['D5', 4]],
  [['-', 4]],
  [['-', 2], ['A5', 0.5], ['Bb5', 1.5]],
  [['-', 4]],
  [['-', 3], ['C#5', 1]],
], 0.9);
acorde('coro', B(12), 16, ['D3', 'Eb3', 'A3'], 0.9);
nota('aguja', B(13), 14, 'Eb6', 0.8);
viento(B(12), 32, 0.9);
for (let c = 12; c < 20; c++) {
  latido(c, 0.8);
  if (c >= 14) latido(c + 0.5, 0.6);   // (a partir del 14, dos veces por compás: el corazón se acelera)
}
[12, 14, 16, 18].forEach((c) => { nota('piano', B(c), 4, 'D2', 0.9); nota('piano', B(c), 4, 'Eb2', 0.7); });
// El golpe de orquesta (16): un «braam» grave y un tambor enorme
golpe(B(16), 0.7);
acorde('braam', B(16), 4, ['D1', 'D2', 'A2']);
for (let c = 16; c < 20; c++) taiko(B(c, 2), 0.35, true);
acorde('cuerdas', B(16), 8, ['D3', 'G#3', 'D4'], 0.9);            // re con sol sostenido (el tritono)

// 4. Final (20-23): se queda el zumbido con la campana y un trozo de la nana, cada vez más lejos; empalma con la entrada
nota('campana', B(20), 4, 'D3', 0.6);
melodia('caja', 20, [
  [['D5', 1], ['F5', 1], ['A5', 2]],
  [['G#5', 4]],
], 0.6);
acorde('cuerdas', B(20), 10, ['D3', 'A3'], 0.6);
nota('aguja', B(21), 8, 'A5', 0.5);

const WAV = path.join(ROOT, 'tools', 'efectos', `${NOMBRE}.wav`);
const capas = guardar(WAV, [['entrada', 0, 4], ['nana', 4, 12], ['se acerca', 12, 20], ['final', 20, 24]]);
sacarCancion(ROOT, NOMBRE, WAV, capas, { juego: process.argv.includes('--juego') });
