// ─────────────────────────────────────────────
//  El villancico de las campanas en 8 bits, en versión siniestra para Zombie Escape.
//
//  Es un arreglo NUESTRO de «Shchedryk» (Mykola Leontovych, 1916), que es de dominio público.
//  Del original solo se toma el motivo de cuatro notas (si♭-la-si♭-sol). Lo demás lo hemos
//  escrito aquí: el bajo que baja, la melodía de lamento, la percusión, la campana y el latido.
//  No copia ninguna versión moderna (ni la de Lindsey Stirling ni la letra inglesa).
//
//  node tools/villancico-8bit.mjs   → tools/efectos/villancico-8bit.wav
//  Sale en bucle perfecto. El sonido lo hace tools/motor-8bit.mjs; aquí solo van los instrumentos
//  y la PARTITURA (más abajo): para cambiar la canción, tocar eso.
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, sube } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SALIDA = path.join(ROOT, 'tools', 'efectos', 'villancico-8bit.wav');

// ── Instrumentos ────────────────────────────────
// vol, onda, envolvente (ataque → caída hasta «sosten»; al soltar, «suelta»), cuánto va al eco y a qué lado
const INS = {
  cajita:   { onda: 'pulso', duty: 0.125, vol: 0.16, ataque: 0.002, caida: 0.35, sosten: 0, suena: 0.5, suelta: 0.2, eco: 0.6, pan: 0.35 },
  osti:     { onda: 'pulso', duty: 0.25, vol: 0.17, ataque: 0.003, caida: 0.08, sosten: 0.55, gate: 0.85, suelta: 0.03, eco: 0.15, pan: -0.2 },
  octava:   { onda: 'pulso', duty: 0.125, vol: 0.08, ataque: 0.003, caida: 0.08, sosten: 0.5, gate: 0.8, suelta: 0.03, eco: 0.3, pan: 0.4 },
  terceras: { onda: 'pulso', duty: 0.125, vol: 0.11, ataque: 0.003, caida: 0.08, sosten: 0.55, gate: 0.85, suelta: 0.03, eco: 0.2, pan: 0.3 },
  canto:    { onda: 'pulso', duty: 0.5, vol: 0.17, ataque: 0.015, caida: 0.5, sosten: 0.65, gate: 0.97, suelta: 0.12, eco: 0.3, pan: 0.1, vibrato: true },
  canto2:   { onda: 'pulso', duty: 0.25, vol: 0.08, ataque: 0.015, caida: 0.5, sosten: 0.65, gate: 0.97, suelta: 0.12, eco: 0.3, pan: -0.35, vibrato: true, cents: 9 },
  bajo:     { onda: 'triangulo', vol: 0.36, ataque: 0.002, caida: 0.25, sosten: 0.85, gate: 0.9, suelta: 0.02, eco: 0, pan: 0 },
  fantasma: { onda: 'triangulo', vol: 0.32, ataque: 0.004, caida: 0.3, sosten: 0.6, gate: 0.9, suelta: 0.05, eco: 0.35, pan: 0 },
  zumbido:  { onda: 'pulso', duty: 0.5, vol: 0.035, ataque: 0.4, caida: 1, sosten: 1, gate: 1, suelta: 0.3, eco: 0, pan: 0 },
};

// Va en 3/4, como el original
const { B, nota, arpegio, subida, campana, viento, bombo, tambor, platillo, platazo, guardar } =
  crearMotor({ bpm: 160, compas: 3, compases: 68, instrumentos: INS });

// ── PARTITURA ───────────────────────────────────
// El motivo de Leontovych: [nota, pulso donde empieza, cuánto dura]
const MOTIVO = [['Bb4', 0, 1], ['A4', 1, 0.5], ['Bb4', 1.5, 0.5], ['G4', 2, 1]];
const TERCERAS = [['D5', 0, 1], ['C5', 1, 0.5], ['D5', 1.5, 0.5], ['Bb4', 2, 1]];
function motivo(ins, c, patron, vol = 1, oct = 0) {
  for (const [n, p, d] of patron) nota(ins, B(c, p), d, sube(n, oct), vol);
}

// Lo nuestro: el bajo que baja (sol, fa, mi♭, re) con sus acordes, y la melodía de lamento
const BAJOS = ['G2', 'F2', 'Eb2', 'D2'];
const ACORDES = [['G4', 'Bb4', 'D5'], ['F4', 'A4', 'C5'], ['Eb4', 'G4', 'Bb4'], ['D4', 'F#4', 'A4']];
const LAMENTO = [   // 16 compases: [nota, pulsos]
  [['D5', 3]], [['C5', 3]], [['Bb4', 2], ['C5', 1]], [['A4', 3]],
  [['G5', 3]], [['F5', 2], ['Eb5', 1]], [['Eb5', 2], ['D5', 1]], [['F#5', 3]],
  [['G5', 2], ['A5', 1]], [['Bb5', 2], ['A5', 1]], [['G5', 2], ['Bb5', 1]], [['A5', 3]],
  [['G5', 2], ['F5', 1]], [['F5', 2], ['Eb5', 1]], [['Eb5', 2], ['D5', 1]], [['D5', 3]],
];
function lamento(ins, c, i, vol = 1) {
  let p = 0;
  for (const [n, d] of LAMENTO[i]) { nota(ins, B(c, p), d, n, vol); p += d; }
}
const bajoCorchea = (c) => {   // bajo saltando de octava en corcheas
  for (let k = 0; k < 6; k++) nota('bajo', B(c, k / 2), 0.5, k % 2 ? sube(BAJOS[c % 4], 1) : BAJOS[c % 4]);
};
const platillos = (c, vol = 1) => {
  for (let k = 0; k < 6; k++) platillo(B(c, k / 2), (k % 2 ? 0.6 : 1) * vol);
};
const redoble = (c) => { for (let k = 0; k < 4; k++) tambor(B(c, 2 + k / 4), 0.5 + k * 0.15); };

// 1. Entrada (compases 0-7): la cajita de música sola, luego campana y bajo
for (let c = 0; c < 8; c++) motivo('cajita', c, MOTIVO, 1, 1);
for (let c = 4; c < 8; c++) nota('bajo', B(c), 3, 'G2', 0.5);
campana(B(4));
viento(B(0), B(8), 0.8);

// 2. A (8-15): el motivo sobre un sol que no se mueve
campana(B(8));
for (let c = 8; c < 16; c++) {
  motivo('osti', c, MOTIVO);
  nota('bajo', B(c), 3, 'G2');
  bombo(B(c), 0.6);
  if (c >= 12) motivo('cajita', c, MOTIVO, 0.5, 1);
}

// 3. A' (16-23): entran las terceras y el bajo empieza a bajar
for (let c = 16; c < 24; c++) {
  motivo('osti', c, MOTIVO);
  motivo('terceras', c, TERCERAS);
  for (let p = 0; p < 3; p++) nota('bajo', B(c, p), 1, BAJOS[c % 4]);
  bombo(B(c));
  platillos(c, 0.6);
  if (c % 4 === 3) { tambor(B(c, 2), 0.6); tambor(B(c, 2.5), 0.8); }
}

// 4. B (24-39): el lamento por encima, con toda la percusión
platazo(B(24));
campana(B(24)); campana(B(32));
for (let c = 24; c < 40; c++) {
  motivo('osti', c, MOTIVO, 0.7);
  lamento('canto', c, c - 24);
  bajoCorchea(c);
  bombo(B(c));
  tambor(B(c, 2));
  platillos(c);
  if (c % 8 === 7) redoble(c);
}

// 5. Ruptura (40-47): latido, campanas y el motivo muy grave; al final, redoble y subida
campana(B(40)); campana(B(44));
viento(B(40), B(8));
for (let c = 40; c < 48; c++) {
  motivo('fantasma', c, MOTIVO, 1, -2);
  nota('zumbido', B(c), 3, 'G1');
  bombo(B(c), 0.7, true); bombo(B(c, 0.5), 0.4, true);
  if (c >= 44) motivo('cajita', c, MOTIVO, 0.7, 1);
}
for (let k = 0; k < 24; k++) tambor(B(46, k / 4), 0.15 + 0.85 * k / 23);
subida(B(46), 6, 'G3', 'G5');

// 6. Clímax (48-63): todo a la vez, con el acorde arpegiado
platazo(B(48)); platazo(B(56), 0.7);
campana(B(48)); campana(B(56));
for (let c = 48; c < 64; c++) {
  motivo('osti', c, MOTIVO);
  motivo('octava', c, MOTIVO, 1, 1);
  lamento('canto', c, c - 48, 1.15);
  lamento('canto2', c, c - 48);
  arpegio(B(c), 3, ACORDES[c % 4]);
  bajoCorchea(c);
  bombo(B(c)); bombo(B(c, 1.5));
  tambor(B(c, 1)); tambor(B(c, 2));
  platillos(c);
  if (c % 8 === 7) redoble(c);
}

// 7. Final (64-67): vuelve la cajita y empalma con la entrada
campana(B(64));
for (let c = 64; c < 68; c++) {
  motivo('cajita', c, MOTIVO, 1, 1);
  nota('bajo', B(c), 3, BAJOS[c % 4], 0.6 - (c - 64) * 0.1);
}

guardar(SALIDA, [['entrada', 0, 8], ['A', 8, 16], ["A'", 16, 24], ['B', 24, 40], ['ruptura', 40, 48], ['clímax', 48, 64], ['final', 64, 68]]);
