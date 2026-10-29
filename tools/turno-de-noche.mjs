// ─────────────────────────────────────────────
//  «Turno de noche»: canción original en 8 bits para Zombie Escape, compuesta aquí desde cero
//  (no es arreglo de nada). Johnny limpiando el edificio de madrugada: un arpegio que no para,
//  un bajo que empuja y una melodía en modo frigio (el fa natural sobre mi le da el aire de miedo).
//
//  En el juego es la música de las hordas y los jefes, partida en dos capas que suenan a la vez (scripts/sonido.gd):
//  la base (arpegio, bajo, batería, sirena y gruñidos), que suena siempre, y la melodía, que entra cuando aprieta.
//
//  node tools/turno-de-noche.mjs   → tools/efectos/turno-de-noche.wav (entera, para oírla), un .wav por capa y
//  assets/musica/turno-de-noche-<capa>.ogg (base y melodia; necesita ffmpeg)
//  Sale en bucle perfecto. El sonido lo hace tools/motor-8bit.mjs; aquí solo van los instrumentos
//  y la PARTITURA (más abajo): para cambiar la canción, tocar eso.
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, pasarAOgg, sube, pulso, ruido, paso, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SALIDA = path.join(ROOT, 'tools', 'efectos', 'turno-de-noche.wav');
const OGG = (capa) => path.join(ROOT, 'assets', 'musica', `turno-de-noche-${capa}.ogg`);
const VOLUMEN = -9.3;   // decibelios: así, con las dos capas, queda a -25 LUFS, como la música de peleas que se grabó del juego JS

// ── Instrumentos ────────────────────────────────
const INS = {
  arpe:    { onda: 'pulso', duty: 0.125, vol: 0.11, ataque: 0.002, caida: 0.09, sosten: 0.3, gate: 0.7, suelta: 0.03, eco: 0.35, pan: -0.3 },
  voz:     { onda: 'pulso', duty: 0.35, pwm: 0.12, vol: 0.16, ataque: 0.01, caida: 0.6, sosten: 0.7, gate: 0.95, suelta: 0.1, eco: 0.3, pan: 0.15, vibrato: true, glide: 0.05, capa: 'melodia' },
  voz2:    { onda: 'pulso', duty: 0.25, vol: 0.08, ataque: 0.01, caida: 0.6, sosten: 0.7, gate: 0.95, suelta: 0.1, eco: 0.2, pan: -0.4, vibrato: true, cents: -10, glide: 0.05, capa: 'melodia' },
  bajo:    { onda: 'triangulo', vol: 0.38, ataque: 0.002, caida: 0.15, sosten: 0.8, gate: 0.85, suelta: 0.02, eco: 0, pan: 0 },
  mordida: { onda: 'pulso', duty: 0.25, vol: 0.07, ataque: 0.002, caida: 0.05, sosten: 0.15, gate: 0.8, suelta: 0.02, eco: 0, pan: 0.1 },
  sirena:  { onda: 'pulso', duty: 0.25, vol: 0.09, ataque: 0.05, caida: 1, sosten: 1, gate: 1, suelta: 0.15, eco: 0.5, pan: 0.4, glide: 0.35 },
  pedal:   { onda: 'triangulo', vol: 0.3, ataque: 0.3, caida: 1, sosten: 1, gate: 1, suelta: 0.3, eco: 0, pan: 0 },
};

// En 4/4, a 136 pulsos por minuto
const { B, nota, subida, sonido, bombo, tambor, platillo, platazo, guardar } =
  crearMotor({ bpm: 136, compas: 4, compases: 52, instrumentos: INS, capas: { subida: 'melodia' } });

// Gruñido de zombi a lo lejos: tono grave que cae y tiembla, con algo de ruido
function grunido(t, pan, vol = 1) {
  const r = ruido();
  let fase = 0, ru = 0;
  sonido(t, 1.4, (s, i) => {
    const f = (55 + 35 * Math.exp(-s / 0.5)) * (1 + 0.08 * Math.sin(2 * Math.PI * 7 * s));
    fase = (fase + f / SR) % 1;
    if (i % 6 === 0) ru = r();
    const env = Math.min(1, s / 0.15) * Math.exp(-Math.max(0, s - 0.3) / 0.4);
    return (pulso(fase, f / SR, 0.5) * 0.7 + ru * 0.3) * paso(env) * 0.12 * vol;
  }, pan, 0.4);
}

// ── PARTITURA ───────────────────────────────────
// El arpegio de semicorcheas: una línea arriba que se alterna con una nota fija (el «pedal»)
const figura = (arriba, pedal) => arriba.flatMap((n) => [n, pedal]);
const ACORDE = {
  Em: { raiz: 'E2', fig: figura(['E4', 'E5', 'G5', 'F5', 'E5', 'D5', 'E5', 'F5'], 'B4') },
  F:  { raiz: 'F2', fig: figura(['F4', 'F5', 'A5', 'G5', 'F5', 'E5', 'F5', 'G5'], 'C5') },
  Am: { raiz: 'A1', fig: figura(['A3', 'A4', 'C5', 'B4', 'A4', 'G4', 'A4', 'B4'], 'E4') },
  Bb: { raiz: 'Bb1', fig: figura(['Bb3', 'Bb4', 'D5', 'C5', 'Bb4', 'A4', 'Bb4', 'C5'], 'F4') },
  B:  { raiz: 'B1', fig: figura(['B3', 'B4', 'D#5', 'C5', 'B4', 'A4', 'B4', 'C5'], 'F#4') },
};
const arpegio = (c, acorde, vol = 1) => ACORDE[acorde].fig.forEach((n, k) => nota('arpe', B(c, k / 4), 0.25, n, vol));

// Bajo galopando en semicorcheas: [semicorchea, octava arriba]
const RITMO_BAJO = [[0, 0], [2, 0], [3, 1], [6, 0], [8, 0], [10, 0], [11, 1], [14, 0]];
function bajo(c, acorde, mordida = false) {
  for (const [k, oct] of RITMO_BAJO) {
    const n = sube(ACORDE[acorde].raiz, oct);
    nota('bajo', B(c, k / 4), k % 8 === 0 ? 0.5 : 0.25, n);
    if (mordida) nota('mordida', B(c, k / 4), 0.25, sube(n, 1));
  }
}

// Melodías: [nota, pulsos] por compás; «~» delante = llega deslizándose desde la nota anterior
const MELODIA_A = [   // sobre Em Em F Em Em Em F B
  [['B4', 1.5], ['~E5', 0.5], ['F5', 1], ['E5', 1]],
  [['D5', 0.5], ['E5', 0.5], ['~B4', 3]],
  [['C5', 1.5], ['A4', 0.5], ['F5', 1], ['E5', 1]],
  [['E5', 0.75], ['D5', 0.75], ['B4', 0.5], ['G4', 2]],
  [['B4', 1.5], ['~E5', 0.5], ['F5', 1], ['G5', 1]],
  [['A5', 0.5], ['G5', 0.5], ['F5', 0.5], ['E5', 0.5], ['~B5', 2]],
  [['A5', 1.5], ['G5', 0.5], ['F5', 1], ['C5', 1]],
  [['C5', 1], ['B4', 1], ['D#5', 2]],
];
const MELODIA_B = [   // sobre Am F Bb B Am F Bb B
  [['C6', 2], ['B5', 1], ['A5', 1]],
  [['A5', 1.5], ['G5', 0.5], ['~F5', 2]],
  [['F5', 1.5], ['D5', 0.5], ['Bb4', 2]],
  [['B4', 1], ['D#5', 1], ['F#5', 1], ['A5', 1]],
  [['C6', 1], ['B5', 0.5], ['A5', 0.5], ['~E5', 2]],
  [['F5', 1], ['A5', 1], ['~C6', 2]],
  [['D6', 1.5], ['C6', 0.5], ['Bb5', 1], ['F5', 1]],
  [['F#5', 2], ['D#5', 2]],
];
function melodia(ins, c0, frase, vol = 1, oct = 0) {
  let antes = null;
  frase.forEach((compas, k) => {
    let p = 0;
    for (const [marca, d] of compas) {
      const n = sube(marca.replace('~', ''), oct);
      nota(ins, B(c0 + k, p), d, n, vol, marca.startsWith('~') ? antes : null);
      antes = n; p += d;
    }
  });
}
const ACORDES_A = ['Em', 'Em', 'F', 'Em', 'Em', 'Em', 'F', 'B'];
const ACORDES_B = ['Am', 'F', 'Bb', 'B', 'Am', 'F', 'Bb', 'B'];

// Baterías: A, recta; B, con el bombo a contratiempo y platillos en semicorcheas
const redoble = (c) => { for (let k = 0; k < 4; k++) tambor(B(c, 3 + k / 4), 0.5 + k * 0.15); };
function bateriaA(c) {
  bombo(B(c)); bombo(B(c, 2)); bombo(B(c, 2.5), 0.7);
  tambor(B(c, 1)); tambor(B(c, 3));
  for (let k = 0; k < 8; k++) platillo(B(c, k / 2), k % 2 ? 0.6 : 1);
}
function bateriaB(c) {
  bombo(B(c)); bombo(B(c, 0.75), 0.7); bombo(B(c, 2)); bombo(B(c, 2.75), 0.7);
  tambor(B(c, 1)); tambor(B(c, 3));
  for (let k = 0; k < 16; k++) if (k !== 14) platillo(B(c, k / 4), k % 4 === 0 ? 1 : k % 2 ? 0.35 : 0.6);
  platillo(B(c, 3.5), 0.8, true);
}

// 1. Entrada (0-3): el arpegio solo sobre un mi grave, y un gruñido a lo lejos
['Em', 'Em', 'F', 'Em'].forEach((a, k) => arpegio(k, a, 1.5));
nota('pedal', B(0), 8, 'E2', 0.5); nota('pedal', B(2), 8, 'E2', 0.5);
grunido(B(2), 0.5, 0.7);

// 2. Arranque (4-7): entra el bajo con bombo y platillos
['Em', 'Em', 'F', 'B'].forEach((a, k) => {
  const c = 4 + k;
  arpegio(c, a);
  bajo(c, a);
  bombo(B(c)); bombo(B(c, 2));
  for (let j = 0; j < 8; j++) platillo(B(c, j / 2), j % 2 ? 0.5 : 0.8);
});
redoble(7);

// 3. A (8-15): la melodía
melodia('voz', 8, MELODIA_A);
ACORDES_A.forEach((a, k) => { arpegio(8 + k, a, 0.8); bajo(8 + k, a); bateriaA(8 + k); });
redoble(15);

// 4. A otra vez (16-23), más llena: segunda voz una octava abajo y el bajo con mordida
platazo(B(16));
melodia('voz', 16, MELODIA_A);
melodia('voz2', 16, MELODIA_A, 1, -1);
ACORDES_A.forEach((a, k) => { arpegio(16 + k, a, 0.8); bajo(16 + k, a, true); bateriaB(16 + k); });
redoble(23);

// 5. B (24-31): sube y se tuerce (si♭ contra mi, lo más lejos que se puede ir)
platazo(B(24));
melodia('voz', 24, MELODIA_B, 1.15);
melodia('voz2', 24, MELODIA_B, 1, -1);
ACORDES_B.forEach((a, k) => { arpegio(24 + k, a, 0.8); bajo(24 + k, a, true); bateriaB(24 + k); });
redoble(27); redoble(31);

// 6. Ruptura (32-39): una alarma que va y viene, latidos, gruñidos; al final, redoble y subida
for (let c = 32; c < 40; c += 2) nota('pedal', B(c), 8, 'E2');
for (let c = 32; c < 40; c++) {
  nota('sirena', B(c), 2, 'E5', 1, 'Bb4');
  nota('sirena', B(c, 2), 2, 'Bb4', 1, 'E5');
  bombo(B(c), 0.6, true); bombo(B(c, 0.5), 0.35, true);
  bombo(B(c, 2), 0.6, true); bombo(B(c, 2.5), 0.35, true);
}
grunido(B(33), -0.6); grunido(B(35), 0.6); grunido(B(37, 2), -0.3);
['Em', 'Em', 'F', 'B'].forEach((a, k) => arpegio(36 + k, a, 0.5 + k * 0.1));
for (let k = 0; k < 16; k++) tambor(B(39, k / 4), 0.15 + 0.85 * k / 15);
subida(B(39), 4, 'E3', 'E5');

// 7. A final (40-47): todo a la vez
platazo(B(40)); platazo(B(44), 0.7);
melodia('voz', 40, MELODIA_A, 1.2);
melodia('voz2', 40, MELODIA_A, 1, -1);
ACORDES_A.forEach((a, k) => { arpegio(40 + k, a); bajo(40 + k, a, true); bateriaB(40 + k); });

// 8. Final (48-51): queda el arpegio con el bajo apagándose y empalma con la entrada
bombo(B(48));
['Em', 'Em', 'F', 'Em'].forEach((a, k) => {
  arpegio(48 + k, a, 1.2 - k * 0.1);
  nota('bajo', B(48 + k), 4, ACORDE[a].raiz, 0.6 - k * 0.12);
});

const capas = guardar(SALIDA, [['entrada', 0, 4], ['arranque', 4, 8], ['A', 8, 16], ['A+', 16, 24], ['B', 24, 32], ['ruptura', 32, 40], ['A final', 40, 48], ['final', 48, 52]]);
for (const [capa, wav] of Object.entries(capas)) pasarAOgg(wav, OGG(capa), VOLUMEN);
