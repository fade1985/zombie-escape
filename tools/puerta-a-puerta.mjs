// ─────────────────────────────────────────────
//  «Puerta a puerta»: canción original en 8 bits para cuando Johnny explora el edificio, compuesta
//  aquí desde cero (no es arreglo de nada). Tiene que sonar mucho rato sin cansar, así que va con
//  aire: un bajo que camina de puntillas, una marimba que gotea y una melodía con huecos.
//
//  Está en do menor. El miedo lo pone una nota que baja de medio tono en medio tono por dentro del
//  acorde (do, si, si bemol, la) mientras el bajo se queda quieto en do. En medio hay un sótano:
//  sin batería, con goteras, una puerta que cruje y algo que gruñe lejos.
//
//  En el juego es el sexto tramo de la música de explorar (assets/musica/explorar-6.ogg, ver scripts/sonido.gd).
//
//  node tools/puerta-a-puerta.mjs   → tools/efectos/puerta-a-puerta.wav y assets/musica/explorar-6.ogg (necesita ffmpeg)
//  Sale en bucle perfecto. El sonido lo hace tools/motor-8bit.mjs; aquí solo van los instrumentos
//  y la PARTITURA (más abajo): para cambiar la canción, tocar eso.
// ─────────────────────────────────────────────
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crearMotor, pasarAOgg, sube, pulso, triangulo, ruido, paso, SR } from './motor-8bit.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SALIDA = path.join(ROOT, 'tools', 'efectos', 'puerta-a-puerta.wav');
const OGG = path.join(ROOT, 'assets', 'musica', 'explorar-6.ogg');
const VOLUMEN = -11.6;   // decibelios: así queda a -28,1 LUFS, la media de explorar-1 a explorar-5

// ── Instrumentos ────────────────────────────────
const INS = {
  mari:     { onda: 'triangulo', vol: 0.28, ataque: 0.002, caida: 0.12, sosten: 0, suena: 0.18, suelta: 0.06, eco: 0.4, pan: -0.3 },
  voz:      { onda: 'pulso', duty: 0.25, pwm: 0.08, vol: 0.12, ataque: 0.02, caida: 0.6, sosten: 0.7, gate: 0.9, suelta: 0.12, eco: 0.45, pan: 0.2, vibrato: true, glide: 0.1 },
  voz2:     { onda: 'pulso', duty: 0.5, vol: 0.06, ataque: 0.02, caida: 0.6, sosten: 0.7, gate: 0.9, suelta: 0.12, eco: 0.3, pan: -0.35, vibrato: true, cents: 7, glide: 0.1 },
  fantasma: { onda: 'triangulo', vol: 0.12, ataque: 0.08, caida: 1.2, sosten: 0.6, gate: 0.95, suelta: 0.3, eco: 0.5, pan: 0.1, vibrato: true, glide: 0.15 },
  bajo:     { onda: 'triangulo', vol: 0.32, ataque: 0.003, caida: 0.18, sosten: 0.6, gate: 0.8, suelta: 0.03, eco: 0, pan: 0 },
  zumbido:  { onda: 'pulso', duty: 0.5, vol: 0.03, ataque: 0.8, caida: 1, sosten: 1, gate: 1, suelta: 0.5, eco: 0, pan: 0 },
};

// En 4/4, a 104 pulsos por minuto: 40 compases, 92 segundos
const { B, nota, sonido, bombo, tambor, platillo, guardar } =
  crearMotor({ bpm: 104, compas: 4, compases: 40, instrumentos: INS });

// Gotera: una gota que cae en un charco (sube de tono muy deprisa) y rebota en el eco
function gota(t, pan, vol = 1) {
  let fase = 0;
  sonido(t, 0.12, (s) => {
    const f = 700 + 1100 * (1 - Math.exp(-s / 0.012));
    fase = (fase + f / SR) % 1;
    return triangulo(fase) * paso(Math.exp(-s / 0.035)) * 0.16 * vol;
  }, pan, 0.7);
}
// Puerta que cruje: una onda muy fina y muy grave que suena a chasquidos, y cambia de velocidad
function crujido(t, segundos, pan, vol = 1) {
  let fase = 0;
  sonido(t, segundos, (s) => {
    const x = s / segundos;
    const f = 38 + 30 * Math.sin(Math.PI * x) + 9 * Math.sin(2 * Math.PI * 3.3 * s);
    fase = (fase + f / SR) % 1;
    return pulso(fase, f / SR, 0.04) * paso(Math.sin(Math.PI * x) ** 0.6) * 0.09 * vol;
  }, pan, 0.25);
}
// Algo que gruñe al fondo del pasillo: grave, tembloroso y con aliento
function grunido(t, pan, vol = 1) {
  const r = ruido();
  let fase = 0, ru = 0;
  sonido(t, 2, (s, i) => {
    const f = (70 - 20 * Math.min(1, s / 1.5)) * (1 + 0.06 * Math.sin(2 * Math.PI * 6 * s));
    fase = (fase + f / SR) % 1;
    if (i % 8 === 0) ru = r();
    const env = Math.min(1, s / 0.4) * Math.exp(-Math.max(0, s - 0.6) / 0.5);
    return (pulso(fase, f / SR, 0.3) * 0.6 + ru * 0.4) * paso(env) * 0.08 * vol;
  }, pan, 0.5);
}

// ── PARTITURA ───────────────────────────────────
// Cada acorde: su nota grave, su quinta y las cuatro notas de la marimba (abajo, dentro, arriba, dentro).
// En los cuatro primeros, la nota «de dentro» es la que baja: do, si, si bemol, la
const ACORDE = {
  Cm:    { raiz: 'C2', quinta: 'G2', mari: ['G4', 'C5', 'Eb5', 'C5'] },
  CmM7:  { raiz: 'C2', quinta: 'G2', mari: ['G4', 'B4', 'Eb5', 'B4'] },
  Cm7:   { raiz: 'C2', quinta: 'G2', mari: ['G4', 'Bb4', 'Eb5', 'Bb4'] },
  Cm6:   { raiz: 'C2', quinta: 'G2', mari: ['G4', 'A4', 'Eb5', 'A4'] },
  Ab:    { raiz: 'Ab1', quinta: 'Eb2', mari: ['G4', 'C5', 'Eb5', 'C5'] },
  Fm:    { raiz: 'F2', quinta: 'C2', mari: ['F4', 'Ab4', 'C5', 'Ab4'] },
  Dm7b5: { raiz: 'D2', quinta: 'Ab2', mari: ['F4', 'Ab4', 'D5', 'Ab4'] },
  G:     { raiz: 'G1', quinta: 'D2', mari: ['F4', 'B4', 'D5', 'B4'] },
};
// La marimba en corcheas con huecos: [pulso, cuál de sus cuatro notas]. «Ligera», solo media figura
const MARI_LLENA = [[0, 0], [0.5, 2], [1.5, 1], [2, 0], [2.5, 2], [3.5, 1]];
const MARI_LIGERA = [[0, 0], [0.5, 2], [1.5, 1]];
function marimba(c, acorde, figura = MARI_LLENA, vol = 1) {
  for (const [p, k] of figura) nota('mari', B(c, p), 0.5, ACORDE[acorde].mari[k], vol * (p % 1 ? 0.8 : 1));
}
// El bajo de puntillas: larga, corta, la octava y la quinta para seguir andando
function bajo(c, acorde, vol = 1) {
  const { raiz, quinta } = ACORDE[acorde];
  nota('bajo', B(c), 1, raiz, vol);
  nota('bajo', B(c, 1.5), 0.5, raiz, vol * 0.8);
  nota('bajo', B(c, 2), 0.5, sube(raiz, 1), vol * 0.75);
  nota('bajo', B(c, 3), 0.75, quinta, vol * 0.85);
}

// Melodía: [nota, pulsos] por compás; «r» = silencio; «~» delante = llega deslizándose desde la anterior.
// Los compases impares preguntan (silencio, dos notas y una larga) y los pares contestan bajando
const MELODIA = [   // sobre Cm CmM7 Cm7 Cm6 Ab Fm Dm7b5 G
  [['r', 1], ['Eb5', 0.5], ['G5', 0.5], ['~D5', 2]],
  [['C5', 1], ['B4', 1], ['G4', 2]],
  [['r', 1], ['Eb5', 0.5], ['G5', 0.5], ['F5', 2]],
  [['Eb5', 1], ['C5', 1], ['A4', 2]],
  [['r', 1], ['C5', 0.5], ['Eb5', 0.5], ['G5', 2]],
  [['Ab5', 1], ['G5', 0.5], ['F5', 0.5], ['C5', 2]],
  [['r', 1], ['D5', 0.5], ['F5', 0.5], ['~Ab5', 2]],
  [['G5', 1], ['D5', 1], ['B4', 2]],
];
const ACORDES = ['Cm', 'CmM7', 'Cm7', 'Cm6', 'Ab', 'Fm', 'Dm7b5', 'G'];
function melodia(ins, c0, frase, vol = 1, oct = 0) {
  let antes = null;
  frase.forEach((compas, k) => {
    let p = 0;
    for (const [marca, d] of compas) {
      if (marca !== 'r') {
        const n = sube(marca.replace('~', ''), oct);
        nota(ins, B(c0 + k, p), d, n, vol, marca.startsWith('~') ? antes : null);
        antes = n;
      }
      p += d;
    }
  });
}

// Platillos en los contratiempos y un bombo que tropieza; «tambor» añade un golpe suave en el tercer pulso
function bateria(c, vol = 1, conTambor = false) {
  bombo(B(c), 0.4 * vol); bombo(B(c, 2.5), 0.25 * vol);
  for (let k = 0; k < 4; k++) platillo(B(c, k + 0.5), (k % 2 ? 0.45 : 0.6) * vol);
  if (conTambor) tambor(B(c, 2), 0.2 * vol);
}

// 1. Entrada (0-3): el bajo solo, de puntillas; luego los platillos y una gota
['Cm', 'Cm', 'Ab', 'G'].forEach((a, k) => bajo(k, a, 0.9));
for (let c = 2; c < 4; c++) for (let k = 0; k < 4; k++) platillo(B(c, k + 0.5), 0.3 + 0.1 * k);
gota(B(1, 1.5), 0.5);
marimba(3, 'G', MARI_LIGERA, 0.6);

// 2. Paseo (4-11): la marimba y el bajo dan la vuelta a los acordes; la melodía solo pregunta
ACORDES.forEach((a, k) => {
  const c = 4 + k;
  marimba(c, a, MARI_LLENA, 0.8);
  bajo(c, a);
  bateria(c, 0.8);
});
MELODIA.forEach((compas, k) => { if (k % 2 === 0) melodia('voz', 4 + k, [compas], 0.75); });
gota(B(7, 3), -0.5, 0.7);

// 3. Tema (12-19): la melodía entera
melodia('voz', 12, MELODIA);
ACORDES.forEach((a, k) => {
  const c = 12 + k;
  marimba(c, a, MARI_LLENA, 0.75);
  bajo(c, a);
  bateria(c);
});

// 4. Sótano (20-27): sin batería; un zumbido grave, la melodía muy despacio y muy abajo,
//    goteras, una puerta que cruje y algo que gruñe lejos
const SOTANO = ['Ab', 'Ab', 'G', 'G', 'Ab', 'Ab', 'G', 'G'];
const FANTASMA = [
  [['r', 2], ['C4', 1], ['Eb4', 1]],
  [['D4', 4]],
  [['r', 2], ['B3', 1], ['D4', 1]],
  [['Ab4', 2], ['~G4', 2]],
  [['r', 2], ['C4', 1], ['Eb4', 1]],
  [['G4', 3], ['F4', 1]],
  [['Eb4', 2], ['D4', 2]],
  [['B3', 4]],
];
melodia('fantasma', 20, FANTASMA);
SOTANO.forEach((a, k) => {
  const c = 20 + k;
  if (k % 2 === 0) nota('zumbido', B(c), 8, sube(ACORDE[a].raiz, 1));
  nota('bajo', B(c), 2, ACORDE[a].raiz, 0.7);
  bombo(B(c), 0.3);
});
marimba(26, 'G', MARI_LIGERA, 0.5); marimba(27, 'G', MARI_LLENA, 0.65);
gota(B(20, 2.5), 0.6); gota(B(21, 3.5), -0.4, 0.8); gota(B(23, 1), 0.3, 0.6);
gota(B(24, 2.5), -0.6); gota(B(25, 1.5), 0.5, 0.7);
crujido(B(22), 1.6, -0.5);
grunido(B(24, 2), 0.6, 0.8);

// 5. Tema otra vez (28-35): la melodía con una segunda voz debajo y un golpe suave de tambor
melodia('voz', 28, MELODIA, 1.05);
melodia('voz2', 28, MELODIA, 1, -1);
ACORDES.forEach((a, k) => {
  const c = 28 + k;
  marimba(c, a, MARI_LLENA, 0.8);
  bajo(c, a);
  bateria(c, 1, true);
});

// 6. Final (36-39): vuelve a quedarse el bajo con los platillos, y empalma con la entrada
['Cm', 'Cm', 'Ab', 'G'].forEach((a, k) => {
  const c = 36 + k;
  bajo(c, a, 0.95 - k * 0.05);
  for (let j = 0; j < 4; j++) platillo(B(c, j + 0.5), 0.55 - 0.08 * k);
});
marimba(36, 'Cm', MARI_LLENA, 0.6); marimba(37, 'Cm', MARI_LIGERA, 0.45);
bombo(B(36), 0.35);
gota(B(38, 2.5), -0.3, 0.8);

guardar(SALIDA, [['entrada', 0, 4], ['paseo', 4, 12], ['tema', 12, 20], ['sótano', 20, 28], ['tema+', 28, 36], ['final', 36, 40]]);
pasarAOgg(SALIDA, OGG, VOLUMEN);
