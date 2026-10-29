// ─────────────────────────────────────────────
//  «El último inquilino»: canción original en 8 bits para el menú de Zombie Escape, compuesta aquí
//  desde cero (no es arreglo de nada). La pantalla de título de madrugada: un reloj que no para,
//  una cajita de música que da vueltas en tresillos y una melodía en re menor armónico (el do
//  sostenido le da el aire antiguo y de miedo). Tranquila y sin batería fuerte: invita a entrar.
//
//  El tema es un motivo de cuatro notas (sube una cuarta, baja medio tono y salta a una nota larga)
//  que se repite en escalón: sobre re menor, sobre sol menor y sobre si bemol. Antes de volver,
//  siempre pasa por mi bemol mayor, el acorde «raro» que da el escalofrío.
//
//  En el juego es la música de los menús y de explorar las plantas, partida en dos capas que suenan a la vez
//  (scripts/sonido.gd): la base (cajita, bajo, reloj, campana y melodía), que suena siempre, y la batería, que solo se
//  sube con zombis despiertos (y por eso lleva, solo en su capa, un latido y un pulso donde la canción no tenía batería).
//
//  node tools/el-ultimo-inquilino.mjs   → tools/efectos/el-ultimo-inquilino.wav (entera, para oírla), un .wav por
//  capa y assets/musica/el-ultimo-inquilino-<capa>.ogg (base y bateria; necesita ffmpeg)
//  Sale en bucle perfecto. El sonido lo hace tools/motor-8bit.mjs; aquí solo van los instrumentos
//  y la PARTITURA (más abajo): para cambiar la canción, tocar eso.
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, pasarAOgg, sube, pulso, ruido, paso, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SALIDA = path.join(ROOT, 'tools', 'efectos', 'el-ultimo-inquilino.wav');
const OGG = (capa) => path.join(ROOT, 'assets', 'musica', `el-ultimo-inquilino-${capa}.ogg`);
const VOLUMEN = -13.9;   // decibelios: así, con las dos capas, queda a -29,7 LUFS, como la música del menú que se grabó del juego JS

// ── Instrumentos ────────────────────────────────
const INS = {
  caja:   { onda: 'pulso', duty: 0.125, vol: 0.16, ataque: 0.002, caida: 0.2, sosten: 0, suena: 0.25, suelta: 0.1, eco: 0.45, pan: -0.35 },
  brillo: { onda: 'pulso', duty: 0.125, vol: 0.07, ataque: 0.002, caida: 0.4, sosten: 0, suena: 0.5, suelta: 0.25, eco: 0.6, pan: 0.45 },
  voz:    { onda: 'pulso', duty: 0.5, vol: 0.13, ataque: 0.03, caida: 0.8, sosten: 0.75, gate: 0.95, suelta: 0.15, eco: 0.4, pan: 0.1, vibrato: true, glide: 0.08 },
  voz2:   { onda: 'pulso', duty: 0.25, vol: 0.07, ataque: 0.03, caida: 0.8, sosten: 0.75, gate: 0.95, suelta: 0.15, eco: 0.3, pan: -0.4, vibrato: true, cents: -8, glide: 0.08 },
  bajo:   { onda: 'triangulo', vol: 0.36, ataque: 0.005, caida: 0.5, sosten: 0.75, gate: 0.92, suelta: 0.06, eco: 0, pan: 0 },
  pedal:  { onda: 'triangulo', vol: 0.2, ataque: 0.6, caida: 1, sosten: 1, gate: 1, suelta: 0.6, eco: 0, pan: 0 },
};

// En 4/4, a 80 pulsos por minuto: 32 compases, 96 segundos
const { B, nota, sonido, campana, bombo, tambor, platillo, platazo, guardar } =
  crearMotor({ bpm: 80, compas: 4, compases: 32, instrumentos: INS, capas: { percusion: 'bateria' } });

// El reloj de la portería: «tic» agudo y «tac» un poco más grave, uno a cada lado
function tic(t, alto, vol = 1) {
  const r = ruido(true);
  const f = alto ? 2600 : 1900;
  let fase = 0;
  sonido(t, 0.05, (s) => {
    fase = (fase + f / SR) % 1;
    return (pulso(fase, f / SR, 0.5) * 0.6 + r() * 0.4) * paso(Math.exp(-s / 0.009)) * 0.12 * vol;
  }, alto ? 0.3 : -0.3, 0.15);
}
const reloj = (c, vol = 1) => { for (let k = 0; k < 4; k++) tic(B(c, k), k % 2 === 0, vol); };

// ── PARTITURA ───────────────────────────────────
// Cada acorde: su nota grave, su quinta y las seis notas que da la cajita (sube y baja)
const ACORDE = {
  Dm: { raiz: 'D2', quinta: 'A2', caja: ['D4', 'A4', 'D5', 'F5', 'D5', 'A4'] },
  Bb: { raiz: 'Bb1', quinta: 'F2', caja: ['D4', 'F4', 'Bb4', 'D5', 'Bb4', 'F4'] },
  Gm: { raiz: 'G1', quinta: 'D2', caja: ['D4', 'G4', 'Bb4', 'D5', 'Bb4', 'G4'] },
  A:  { raiz: 'A1', quinta: 'E2', caja: ['C#4', 'E4', 'A4', 'C#5', 'A4', 'E4'] },
  A7: { raiz: 'A1', quinta: 'E2', caja: ['C#4', 'E4', 'G4', 'C#5', 'G4', 'E4'] },
  Eb: { raiz: 'Eb2', quinta: 'Bb2', caja: ['Eb4', 'G4', 'Bb4', 'Eb5', 'Bb4', 'G4'] },
  F:  { raiz: 'F2', quinta: 'C3', caja: ['C4', 'F4', 'A4', 'C5', 'A4', 'F4'] },
};
// La cajita: doce notas por compás (tresillos), con el primer golpe de cada pulso un poco más fuerte
function caja(c, acorde, vol = 1) {
  const fig = ACORDE[acorde].caja;
  for (let k = 0; k < 12; k++) nota('caja', B(c, k / 3), 1 / 3, fig[k % 6], vol * (k % 3 === 0 ? 1 : 0.7));
}
// El bajo meciéndose en tresillos: nota larga, la octava y la quinta
function bajoMecido(c, acorde, vol = 1) {
  const { raiz, quinta } = ACORDE[acorde];
  nota('bajo', B(c), 2, raiz, vol);
  nota('bajo', B(c, 2), 4 / 3, sube(raiz, 1), vol * 0.8);
  nota('bajo', B(c, 10 / 3), 2 / 3, quinta, vol * 0.8);
}

// Melodías: [nota, pulsos] por compás; «~» delante = llega deslizándose desde la nota anterior
const MELODIA_A = [   // sobre Dm Bb Gm A Dm Bb Eb A7
  [['A4', 0.5], ['D5', 0.5], ['C#5', 0.5], ['F5', 2.5]],
  [['G5', 1.5], ['F5', 0.5], ['D5', 2]],
  [['D5', 0.5], ['G5', 0.5], ['F#5', 0.5], ['Bb5', 2.5]],
  [['A5', 1], ['E5', 1], ['C#5', 2]],
  [['A4', 0.5], ['D5', 0.5], ['C#5', 0.5], ['F5', 2.5]],
  [['F5', 0.5], ['Bb5', 0.5], ['A5', 0.5], ['D6', 2.5]],
  [['C6', 1], ['Bb5', 1], ['G5', 2]],
  [['E5', 0.5], ['F5', 0.5], ['E5', 0.5], ['C#5', 2.5]],
];
const MELODIA_B = [   // sobre Bb F Gm Dm Bb F Eb A: más arriba y más cantada
  [['D6', 1.5], ['C6', 0.5], ['Bb5', 1], ['F5', 1]],
  [['A5', 1.5], ['G5', 0.5], ['F5', 2]],
  [['Bb5', 1], ['A5', 0.5], ['G5', 0.5], ['D5', 2]],
  [['F5', 2 / 3], ['E5', 2 / 3], ['D5', 2 / 3], ['A4', 2]],
  [['D6', 1.5], ['C6', 0.5], ['Bb5', 1], ['D6', 1]],
  [['C6', 1.5], ['Bb5', 0.5], ['A5', 2]],
  [['G5', 1], ['Bb5', 1], ['~Eb6', 2]],
  [['D6', 1], ['C#6', 1], ['A5', 2]],
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
const ACORDES_A = ['Dm', 'Bb', 'Gm', 'A', 'Dm', 'Bb', 'Eb', 'A7'];
const ACORDES_B = ['Bb', 'F', 'Gm', 'Dm', 'Bb', 'F', 'Eb', 'A'];

// 1. Entrada (0-3): el reloj y la cajita sola sobre un re grave; suena una campana
['Dm', 'Bb', 'Gm', 'A'].forEach((a, k) => { caja(k, a, 0.6 + k * 0.13); reloj(k); });
nota('pedal', B(0), 16, 'D2', 0.6);
campana(B(0), 'D3', 0.6);

// 2. A (4-11): entra la melodía, con el bajo en notas largas
melodia('voz', 4, MELODIA_A);
ACORDES_A.forEach((a, k) => {
  const c = 4 + k;
  caja(c, a, 0.8);
  nota('bajo', B(c), 4, ACORDE[a].raiz, 0.8);
  reloj(c, 0.8);
});

// 3. B (12-19): la melodía sube, con segunda voz; el reloj se calla y entra un bombo suave
melodia('voz', 12, MELODIA_B, 1.05);
melodia('voz2', 12, MELODIA_B, 1, -1);
ACORDES_B.forEach((a, k) => {
  const c = 12 + k;
  caja(c, a, 0.8);
  nota('bajo', B(c), 2, ACORDE[a].raiz, 0.85);
  nota('bajo', B(c, 2), 2, ACORDE[a].quinta, 0.75);
  bombo(B(c), 0.45); bombo(B(c, 2), 0.3);
  for (let j = 0; j < 12; j++) platillo(B(c, j / 3), j % 3 === 0 ? 0.45 : 0.18);
});
for (let k = 0; k < 6; k++) tambor(B(19, 2 + k / 3), 0.15 + k * 0.08);

// 4. A' (20-27): el tema otra vez, más lleno: segunda voz abajo, el bajo meciéndose y algo de batería
platazo(B(20), 0.5);
campana(B(20), 'D3', 0.5);
melodia('voz', 20, MELODIA_A, 1.1);
melodia('voz2', 20, MELODIA_A, 1, -1);
ACORDES_A.forEach((a, k) => {
  const c = 20 + k;
  caja(c, a, 0.8);
  bajoMecido(c, a, 0.9);
  bombo(B(c), 0.45); bombo(B(c, 8 / 3), 0.3);
  tambor(B(c, 2), 0.3);
  for (let j = 0; j < 4; j++) platillo(B(c, j), 0.35);
  reloj(c, 0.5);
});

// 5. Final (28-31): se queda el reloj con la cajita; el motivo suena arriba, muy lejos, y empalma con la entrada
campana(B(28), 'D3', 0.5);
['Dm', 'Bb', 'Eb', 'A'].forEach((a, k) => {
  const c = 28 + k;
  caja(c, a, 0.85 - k * 0.07);
  nota('bajo', B(c), 4, ACORDE[a].raiz, 0.55 - k * 0.1);
  reloj(c);
});
melodia('brillo', 28, [MELODIA_A[0]], 1, 1);
melodia('brillo', 30, [MELODIA_A[6]], 0.8);

// 6. La batería de pelea, solo en su capa (el juego la sube con zombis despiertos): donde la canción no lleva
//    batería se le pone una para que la capa no se quede callada. Un latido en la entrada y el final, y un pulso suave en A
const latido = (c, vol) => {
  for (const p of [0, 2]) { bombo(B(c, p), vol, true); bombo(B(c, p + 1 / 3), vol * 0.6, true); }
  platillo(B(c, 1), vol * 0.4); platillo(B(c, 3), vol * 0.4);
};
for (let k = 0; k < 4; k++) latido(k, 0.4 + k * 0.05);
for (let c = 4; c < 12; c++) {
  bombo(B(c), 0.4); bombo(B(c, 8 / 3), 0.25);
  tambor(B(c, 2), 0.2);
  for (let j = 0; j < 12; j++) platillo(B(c, j / 3), j % 3 === 0 ? 0.35 : 0.12);
}
for (let k = 0; k < 3; k++) tambor(B(11, 3 + k / 3), 0.15 + k * 0.1);
for (let k = 0; k < 4; k++) latido(28 + k, 0.55 - k * 0.05);

const capas = guardar(SALIDA, [['entrada', 0, 4], ['A', 4, 12], ['B', 12, 20], ["A'", 20, 28], ['final', 28, 32]]);
for (const [capa, wav] of Object.entries(capas)) pasarAOgg(wav, OGG(capa), VOLUMEN);
