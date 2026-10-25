// ─────────────────────────────────────────────
//  Motor de música de 8 bits: ondas y ruido como los de la NES, percusión, eco y el .wav en bucle.
//  Lo usan las canciones de tools/ (villancico-8bit.mjs, turno-de-noche.mjs). Cada una crea su motor,
//  escribe su partitura en pulsos y al final llama a guardar():
//
//    const m = crearMotor({ bpm: 160, compas: 3, compases: 68, instrumentos: INS });
//    m.nota('canto', m.B(4), 3, 'G5');          // compás 4, dura 3 pulsos
//    m.guardar(SALIDA, [['entrada', 0, 8], ...]);
//
//  Sale en bucle perfecto: lo que suena después del final (ecos, campanas) se suma al principio.
//  Sin azar: cada vez sale igual.
// ─────────────────────────────────────────────
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

export const SR = 44100;

// ── Notas y ondas de consola ────────────────────
const SEMITONO = { C: 0, 'C#': 1, D: 2, 'D#': 3, Eb: 3, E: 4, F: 5, 'F#': 6, G: 7, 'G#': 8, Ab: 8, A: 9, Bb: 10, B: 11 };
export const hz = (n) => {
  const [, nombre, oct] = /^([A-G][#b]?)(\d)$/.exec(n);
  return 440 * 2 ** ((SEMITONO[nombre] + 12 * (+oct + 1) - 69) / 12);
};
export const sube = (n, oct) => n.replace(/\d$/, (o) => +o + oct);   // la misma nota, octavas arriba o abajo

// Suaviza el salto de la onda cuadrada para que no chirríe de más (PolyBLEP)
const blep = (t, dt) => {
  if (t < dt) { t /= dt; return t + t - t * t - 1; }
  if (t > 1 - dt) { t = (t - 1) / dt; return t * t + t + t + 1; }
  return 0;
};
// Onda cuadrada de la NES; «duty» es lo ancha que es (0,125 fina y nasal, 0,5 redonda)
export function pulso(fase, dt, duty) {
  const v = (fase < duty ? 1 : -1) + blep(fase, dt) - blep((fase - duty + 1) % 1, dt);
  return v - (2 * duty - 1);
}
// Triángulo a escalones, como el de la NES (el del bajo)
export const triangulo = (fase) => Math.round((2 - 4 * Math.abs(fase - 0.5)) * 7.5) / 7.5 - 1;
// Ruido de la NES: «corto» suena metálico
export function ruido(corto = false) {
  let r = 1;
  return () => {
    const b = (r ^ (r >> (corto ? 6 : 1))) & 1;
    r = (r >> 1) | (b << 14);
    return r & 1 ? 1 : -1;
  };
}
export const paso = (v) => Math.round(v * 15) / 15;   // el volumen de la NES va en 16 escalones
function lado(p) {                                    // -1 izquierda, 0 centro, 1 derecha
  const a = (p + 1) * Math.PI / 4;
  return [Math.cos(a) * Math.SQRT2, Math.sin(a) * Math.SQRT2];
}

// «instrumentos»: { nombre: { onda: 'pulso' | 'triangulo', duty, vol, ataque, caida, sosten, gate o suena,
//   suelta, eco, pan, y si quiere vibrato, cents (desafinar), pwm (el duty se mueve), glide (segundos al deslizar) } }
// La envolvente: ataque → cae hasta «sosten» (en «caida» segundos); al soltar la nota se apaga en «suelta».
export function crearMotor({ bpm, compas, compases, instrumentos: INS }) {
  const NEGRA = 60 / bpm;            // segundos de un pulso
  const LARGO = Math.round(compases * compas * NEGRA * SR);
  const COLA = 6 * SR;               // lo que sigue sonando tras el final; se suma al principio
  const N = LARGO + COLA;
  const L = new Float32Array(N), R = new Float32Array(N), ECO = new Float32Array(N);

  const B = (c, p = 0) => c * compas + p;               // compás y pulso → pulsos desde el principio
  const muestra = (t) => Math.round(t * NEGRA * SR);    // de pulsos a muestras
  function suma(k, v, gL, gR, eco) {
    if (k >= N) return;
    L[k] += v * gL; R[k] += v * gR; ECO[k] += v * eco;
  }

  // Una nota: t y d en pulsos; con «de», empieza en esa nota y se desliza hasta la suya
  function nota(ins, t, d, nombre, vol = 1, de = null) {
    const I = INS[ins];
    const f0 = hz(nombre) * 2 ** ((I.cents ?? 0) / 1200);
    const fDe = de && hz(de) * 2 ** ((I.cents ?? 0) / 1200);
    const abierta = I.suena ?? d * NEGRA * I.gate;   // segundos con la nota pulsada
    const n = Math.round((abierta + I.suelta * 5) * SR);
    const [gL, gR] = lado(I.pan);
    const ini = muestra(t);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      let env = s < I.ataque ? s / I.ataque : I.sosten + (1 - I.sosten) * Math.exp(-(s - I.ataque) / I.caida);
      if (s > abierta) env *= Math.exp(-(s - abierta) / I.suelta);
      let f = f0;
      if (de) f = fDe * (f0 / fDe) ** Math.min(1, s / (I.glide ?? 0.06));
      if (I.vibrato && s > 0.3) f *= 2 ** (Math.min(1, (s - 0.3) / 0.4) * 0.15 * Math.sin(2 * Math.PI * 5.5 * s) / 12);
      const dt = f / SR;
      fase = (fase + dt) % 1;
      const duty = I.pwm ? I.duty + I.pwm * Math.sin(2 * Math.PI * 0.7 * (t * NEGRA + s)) : I.duty;
      const onda = I.onda === 'triangulo' ? triangulo(fase) : pulso(fase, dt, duty);
      suma(ini + i, onda * paso(env) * I.vol * vol, gL, gR, I.eco);
    }
  }

  // Acorde arpegiado a lo consola: cambia de nota 30 veces por segundo
  function arpegio(t, d, acorde, vol = 1) {
    const fs_ = acorde.map(hz);
    const n = Math.round(d * NEGRA * SR);
    const [gL, gR] = lado(-0.4);
    const ini = muestra(t);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      const f = fs_[Math.floor(s * 30) % fs_.length];
      const enPulso = (s / NEGRA) % 1;   // golpecito al principio de cada pulso
      const env = (0.55 + 0.45 * Math.exp(-enPulso * NEGRA / 0.12)) * Math.min(1, (n - i) / (0.02 * SR));
      const dt = f / SR;
      fase = (fase + dt) % 1;
      suma(ini + i, pulso(fase, dt, 0.125) * paso(env) * 0.08 * vol, gL, gR, 0.2);
    }
  }

  // Sube de una nota a otra (para entrar en el clímax)
  function subida(t, d, de, a, vol = 1) {
    const f1 = hz(de), f2 = hz(a);
    const n = Math.round(d * NEGRA * SR);
    const [gL, gR] = lado(0.2);
    const ini = muestra(t);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const x = i / n;
      const dt = f1 * (f2 / f1) ** x / SR;
      fase = (fase + dt) % 1;
      suma(ini + i, pulso(fase, dt, 0.125) * paso(0.15 + 0.85 * x) * 0.13 * vol, gL, gR, 0.3);
    }
  }

  // Campana de iglesia, grave y rajada
  function campana(t, nombre = 'G3', vol = 1) {
    const f = hz(nombre);
    const n = 6 * SR;
    const ini = muestra(t);
    const fases = [0, 0, 0, 0];
    const pasos = [f, f * 2 * 1.003, f * 0.5, f * 2.76].map((x) => x / SR);
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      for (let k = 0; k < 4; k++) fases[k] = (fases[k] + pasos[k]) % 1;
      const v = pulso(fases[0], pasos[0], 0.5) * 0.35
        + pulso(fases[1], pasos[1], 0.25) * 0.25 * Math.exp(-s / 0.8)
        + triangulo(fases[2]) * 0.5
        + pulso(fases[3], pasos[3], 0.5) * 0.18 * Math.exp(-s / 0.15);
      const env = paso(Math.exp(-s / 1.8)) * Math.min(1, s / 0.003);
      suma(ini + i, v * env * 0.3 * vol, 1, 1, 0.35);
    }
  }

  // Viento: ruido grave que sube y baja y va de un lado a otro
  function viento(t, d, vol = 1) {
    const r = ruido();
    const n = Math.round(d * NEGRA * SR);
    const ini = muestra(t);
    let v = 0, y = 0;
    for (let i = 0; i < n; i++) {
      if (i % 20 === 0) v = r();
      const x = i / n;
      y += (v - y) * (0.02 + 0.04 * Math.sin(x * Math.PI * 3) ** 2);
      const [gL, gR] = lado(Math.sin(x * Math.PI * 2) * 0.6);
      suma(ini + i, y * Math.sin(Math.PI * x) ** 2 * 0.3 * vol, gL, gR, 0);
    }
  }

  // Un sonido a medida de la canción: fn(segundos desde que empieza, muestra) da cada valor
  function sonido(t, segundos, fn, pan = 0, eco = 0) {
    const n = Math.round(segundos * SR);
    const [gL, gR] = lado(pan);
    const ini = muestra(t);
    for (let i = 0; i < n; i++) suma(ini + i, fn(i / SR, i), gL, gR, eco);
  }

  // ── Percusión ─────────────────────────────────
  function bombo(t, vol = 1, grave = false) {   // «grave» = latido de corazón
    const n = Math.round(0.4 * SR);
    const ini = muestra(t);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      const f = grave ? 38 + 60 * Math.exp(-s / 0.06) : 48 + 130 * Math.exp(-s / 0.035);
      fase = (fase + f / SR) % 1;
      suma(ini + i, (1 - 4 * Math.abs(fase - 0.5)) * Math.exp(-s / (grave ? 0.2 : 0.14)) * 0.75 * vol, 1, 1, 0);
    }
  }
  function tambor(t, vol = 1) {
    const r = ruido();
    const n = Math.round(0.3 * SR);
    const ini = muestra(t);
    let fase = 0, ru = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      if (i % 2 === 0) ru = r();
      fase = (fase + 200 * (1 + 0.5 * Math.exp(-s / 0.01)) / SR) % 1;
      const v = ru * paso(Math.exp(-s / 0.075)) * 0.5 + (1 - 4 * Math.abs(fase - 0.5)) * Math.exp(-s / 0.035) * 0.45;
      suma(ini + i, v * 0.45 * vol, 1, 1, 0.1);
    }
  }
  function platillo(t, vol = 1, abierto = false) {
    const r = ruido();
    const n = Math.round((abierto ? 0.4 : 0.08) * SR);
    const ini = muestra(t);
    const [gL, gR] = lado(0.25);
    for (let i = 0; i < n; i++) suma(ini + i, r() * paso(Math.exp(-i / SR / (abierto ? 0.1 : 0.022))) * 0.1 * vol, gL, gR, 0);
  }
  function platazo(t, vol = 1) {
    const r = ruido(), m = ruido(true);
    const n = 3 * SR;
    const ini = muestra(t);
    let me = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      if (i % 3 === 0) me = m();
      suma(ini + i, (r() * paso(Math.exp(-s / 0.8)) * 0.2 + me * Math.exp(-s / 0.3) * 0.08) * vol, 1, 1, 0.2);
    }
  }

  // ── Mezcla y .wav ─────────────────────────────
  // «partes»: [nombre, compás de inicio, compás de fin] para decir el volumen de cada una
  function guardar(salida, partes) {
    // Eco de ida y vuelta (izquierda, derecha...) a pulso y medio, más oscuro que el sonido
    const D = muestra(1.5);
    const FB = 0.45;
    const ecoL = new Float32Array(N), ecoR = new Float32Array(N);
    let oscuro = 0;
    const ecoIn = new Float32Array(N);
    for (let i = 0; i < N; i++) { oscuro += (ECO[i] - oscuro) * 0.25; ecoIn[i] = oscuro; }
    for (let i = D; i < N; i++) {
      ecoL[i] = ecoIn[i - D] + FB * ecoR[i - D];
      ecoR[i] = FB * ecoL[i - D];
    }
    for (let i = 0; i < N; i++) { L[i] += ecoL[i] * 0.6; R[i] += ecoR[i] * 0.6; }

    // Bucle: lo que suena después del final se suma al principio
    for (let i = 0; i < COLA; i++) { L[i] += L[LARGO + i]; R[i] += R[LARGO + i]; }

    // Filtro suave (quita el chirrido más agudo y el desvío del centro); arranca con el final ya pasado
    function filtrar(x) {
      const a = 1 - Math.exp(-2 * Math.PI * 10000 / SR);
      let lp = 0, hpIn = 0, hp = 0;
      const y = new Float32Array(LARGO);
      for (let vuelta = 0; vuelta < 2; vuelta++) {
        const desde = vuelta === 0 ? LARGO - SR : 0;
        for (let i = desde; i < LARGO; i++) {
          lp += (x[i] - lp) * a;
          hp = lp - hpIn + 0.9964 * hp;
          hpIn = lp;
          if (vuelta === 1) y[i] = hp;
        }
      }
      return y;
    }
    const sL = filtrar(L), sR = filtrar(R);

    let pico = 0;
    for (let i = 0; i < LARGO; i++) pico = Math.max(pico, Math.abs(sL[i]), Math.abs(sR[i]));
    const ganancia = 0.89 / pico;

    const wav = Buffer.alloc(44 + LARGO * 4);
    wav.write('RIFF', 0); wav.writeUInt32LE(36 + LARGO * 4, 4); wav.write('WAVE', 8);
    wav.write('fmt ', 12); wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(2, 22);
    wav.writeUInt32LE(SR, 24); wav.writeUInt32LE(SR * 4, 28); wav.writeUInt16LE(4, 32); wav.writeUInt16LE(16, 34);
    wav.write('data', 36); wav.writeUInt32LE(LARGO * 4, 40);
    const a16 = (v) => Math.max(-32768, Math.min(32767, Math.round(v * ganancia * 32767)));
    for (let i = 0; i < LARGO; i++) {
      wav.writeInt16LE(a16(sL[i]), 44 + i * 4);
      wav.writeInt16LE(a16(sR[i]), 46 + i * 4);
    }
    fs.mkdirSync(path.dirname(salida), { recursive: true });
    // Que Godot no importe los .wav de prueba (son grandes y no van en el juego)
    const ignorar = path.join(path.dirname(salida), '.gdignore');
    if (!fs.existsSync(ignorar)) fs.writeFileSync(ignorar, '');
    fs.writeFileSync(salida, wav);

    // Volumen de cada parte, para ver que crece y baja donde toca
    const db = (x) => (20 * Math.log10(x)).toFixed(1);
    console.log(`${salida}\n${(LARGO / SR).toFixed(1)} s, pico normalizado a -1 dB`);
    for (const [nombre, c0, c1] of partes) {
      let e = 0;
      const i0 = muestra(B(c0)), i1 = muestra(B(c1));
      for (let i = i0; i < i1; i++) e += (sL[i] * ganancia) ** 2 + (sR[i] * ganancia) ** 2;
      console.log(`  ${nombre.padEnd(8)} compases ${String(c0).padStart(2)}-${c1 - 1}  ${db(Math.sqrt(e / (2 * (i1 - i0))))} dB`);
    }
    // El empalme no da chasquido si el salto del final al principio es como los de una muestra a la siguiente
    const salto = Math.abs(sL[LARGO - 1] - sL[0]) * ganancia;
    let normal = 0;
    for (let i = LARGO - SR; i < LARGO - 1; i++) normal = Math.max(normal, Math.abs(sL[i + 1] - sL[i]) * ganancia);
    console.log(`  empalme del bucle: salto de ${salto.toFixed(3)} (en el último segundo llega a ${normal.toFixed(3)})`);

    // Con «--veces 4» guarda además la canción repetida, para oír si aguanta en bucle (…-x4.wav)
    const veces = +(process.argv[process.argv.indexOf('--veces') + 1] ?? 0);
    if (process.argv.includes('--veces') && veces > 1) {
      const datos = wav.subarray(44);
      const largo = Buffer.concat([wav.subarray(0, 44), ...Array(veces).fill(datos)]);
      largo.writeUInt32LE(36 + datos.length * veces, 4);
      largo.writeUInt32LE(datos.length * veces, 40);
      const otra = salida.replace(/\.wav$/, `-x${veces}.wav`);
      fs.writeFileSync(otra, largo);
      console.log(`${otra}  (${veces} veces, ${(veces * LARGO / SR / 60).toFixed(1)} min)`);
    }
  }

  return { B, NEGRA, nota, arpegio, subida, campana, viento, sonido, bombo, tambor, platillo, platazo, guardar };
}

// Pasa el .wav a .ogg para el juego, como el resto de assets/musica/ (32 000 muestras por segundo, la misma
// calidad que la música que se grababa del juego JS). «decibelios» lo baja hasta su volumen en el juego (el menú
// y explorar están a -29,7 LUFS y las peleas a -25; se mide con `ffmpeg -i x.ogg -af ebur128 -f null -`).
// Necesita ffmpeg.
export function pasarAOgg(wav, ogg, decibelios) {
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', wav, '-af', `volume=${decibelios}dB`,
    '-ar', '32000', '-c:a', 'libvorbis', '-q:a', '1', ogg]);
  console.log(`${ogg}  (${decibelios} dB)`);
}
