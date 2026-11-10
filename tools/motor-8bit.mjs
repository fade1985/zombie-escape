// ─────────────────────────────────────────────
//  Motor de música de 8 bits: ondas y ruido como los de la NES, percusión, eco y el .wav en bucle.
//  Lo usan las canciones de tools/ (villancico-8bit.mjs, turno-de-noche.mjs, el-ultimo-inquilino.mjs). Cada una crea su motor,
//  escribe su partitura en pulsos y al final llama a guardar():
//
//    const m = crearMotor({ bpm: 160, compas: 3, compases: 68, instrumentos: INS });
//    m.nota('canto', m.B(4), 3, 'G5');          // compás 4, dura 3 pulsos
//    m.guardar(SALIDA, [['entrada', 0, 8], ...]);
//
//  Sale en bucle perfecto: lo que suena después del final (ecos, campanas) se suma al principio.
//  Sin azar: cada vez sale igual.
//
//  Por capas: si los instrumentos dicen su «capa» (base, ritmo, melodía...), guardar() saca además un .wav por
//  capa, todos igual de largos y al mismo volumen, que sumados suenan como la canción entera. El juego los toca a
//  la vez y sube o baja cada uno según lo que pasa (scripts/sonido.gd).
// ─────────────────────────────────────────────
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';

export const SR = 44100;

// ── Notas y ondas de consola ────────────────────
const SEMITONO = { C: 0, 'C#': 1, Db: 1, D: 2, 'D#': 3, Eb: 3, E: 4, F: 5, 'F#': 6, Gb: 6, G: 7, 'G#': 8, Ab: 8, A: 9, 'A#': 10, Bb: 10, B: 11 };
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

// Ruido de 16 bits: siempre el mismo para la misma semilla (la canción sale igual cada vez)
export function azar(semilla) {
  let x = (semilla * 2654435761) >>> 0 || 1;
  return () => {
    x ^= x << 13; x >>>= 0; x ^= x >> 17; x ^= x << 5; x >>>= 0;
    return x / 2147483648 - 1;
  };
}
// Filtro de dos polos (paso bajo en «low», de banda en «band»): g = tan(π·hz/SR), k = 1/resonancia
export function crearSvf() {
  let ic1 = 0, ic2 = 0;
  const o = {
    low: 0, band: 0,
    paso(x, g, k) {
      const a1 = 1 / (1 + g * (g + k)), a2 = g * a1, a3 = g * a2;
      const v3 = x - ic2, v1 = a1 * ic1 + a2 * v3, v2 = ic2 + a2 * ic1 + a3 * v3;
      ic1 = 2 * v1 - ic1; ic2 = 2 * v2 - ic2;
      o.low = v2; o.band = v1;
    },
  };
  return o;
}
// Las formantes de una «a» cantada: [hz, estrechez, volumen]
const FORMANTES = [[730, 6, 1], [1090, 8, 0.55], [2440, 10, 0.25]];
// Reverberación de sala (la de Freeverb: ocho peines y cuatro pasatodo por lado)
function reverberar(x, N, { tamano = 0.86, apagar = 0.35, nivel = 1 }) {
  const PEINES = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617], PASA = [556, 441, 341, 225];
  return [0, 23].map((sep) => {
    const peines = PEINES.map((l) => ({ b: new Float32Array(l + sep), i: 0, guarda: 0 }));
    const pasa = PASA.map((l) => ({ b: new Float32Array(l + sep), i: 0 }));
    const y = new Float32Array(N);
    for (let k = 0; k < N; k++) {
      const e = x[k] * 0.015;
      let s = 0;
      for (const p of peines) {
        const v = p.b[p.i];
        p.guarda = v * (1 - apagar) + p.guarda * apagar;
        p.b[p.i] = e + p.guarda * tamano;
        if (++p.i === p.b.length) p.i = 0;
        s += v;
      }
      for (const p of pasa) {
        const v = p.b[p.i];
        p.b[p.i] = s + v * 0.5;
        if (++p.i === p.b.length) p.i = 0;
        s = v - s;
      }
      y[k] = s * 3 * nivel;
    }
    return y;
  });
}

// «instrumentos»: { nombre: { onda: 'pulso' | 'triangulo', duty, vol, ataque, caida, sosten, gate o suena,
//   suelta, eco, pan, y si quiere vibrato, cents (desafinar), pwm (el duty se mueve), glide (segundos al deslizar) } }
// La envolvente: ataque → cae hasta «sosten» (en «caida» segundos); al soltar la nota se apaga en «suelta».
// Cada instrumento puede decir su «capa»; la de lo demás va en «capas»: { percusion, campana, arpegio, subida, viento,
// sonido }. Lo que no diga ninguna, a la capa «base».
//
// Instrumentos «de 16 bits» (los de las canciones de los edificios, noviembre): más ricos que los de la NES.
//   onda: 'sierra' (cuerdas y metales), 'seno' (flauta, órgano suave), 'fm' (piano eléctrico y campanitas: «ratio» y
//         «indice», que se apaga en «indiceCae» segundos) o 'coro' (una sierra pasada por las formantes de una «a»)
//   voces y abrir: varias copias de la nota desafinadas «abrir» cents entre la más grave y la más aguda (suena ancho),
//         repartidas a los lados según «ancho» (0 en el centro, 1 una a cada lado)
//   filtro: quita los agudos por encima de esos Hz (más oscuro y menos estridente); «filtroEnv» lo abre al atacar la
//         nota (2 = el triple al principio) y «reso» le da un pico (0,7 nada, 3 mucho)
//   sala: cuánto va a la reverberación de sala (la que pide «sala» en crearMotor); cinta: la nota tiembla como una
//         cinta vieja (lo que diga la función «cinta» de crearMotor); tremolo: { hz, prof } sube y baja el volumen
//   Con cualquiera de esto, el volumen ya no va a escalones de NES (y las canciones de antes suenan igual que siempre).
// «sala»: { tamano (0,7 cuarto pequeño, 0,92 catedral), apagar (0,2 brillante, 0,6 oscura), nivel }
// «cinta»: función (segundos desde el principio) → cents, para los instrumentos con «cinta»
// «eco»: { pulsos, fb } el eco de ida y vuelta (por defecto, a pulso y medio y 0,45)
export function crearMotor({ bpm, compas, compases, instrumentos: INS, capas = {}, sala = null, cinta = null, eco = {} }) {
  const NEGRA = 60 / bpm;            // segundos de un pulso
  const LARGO = Math.round(compases * compas * NEGRA * SR);
  const COLA = 6 * SR;               // lo que sigue sonando tras el final; se suma al principio
  const N = LARGO + COLA;
  const CAPAS = new Map();           // nombre → lo que suena en esa capa (izquierda, derecha y lo que va al eco)
  function capa(nombre = 'base') {
    if (!CAPAS.has(nombre)) CAPAS.set(nombre, { L: new Float32Array(N), R: new Float32Array(N), ECO: new Float32Array(N), SALA: null });
    return CAPAS.get(nombre);
  }

  const B = (c, p = 0) => c * compas + p;               // compás y pulso → pulsos desde el principio
  const muestra = (t) => Math.round(t * NEGRA * SR);    // de pulsos a muestras
  function suma(c, k, v, gL, gR, eco, aSala = 0) {
    if (k >= N) return;
    c.L[k] += v * gL; c.R[k] += v * gR; c.ECO[k] += v * eco;
    if (aSala) (c.SALA ??= new Float32Array(N))[k] += v * aSala;
  }
  // Lo mismo con izquierda y derecha ya separadas
  function suma2(c, k, vL, vR, eco, aSala) {
    if (k >= N) return;
    c.L[k] += vL; c.R[k] += vR; c.ECO[k] += (vL + vR) * 0.5 * eco;
    if (aSala) (c.SALA ??= new Float32Array(N))[k] += (vL + vR) * 0.5 * aSala;
  }

  // Una nota: t y d en pulsos; con «de», empieza en esa nota y se desliza hasta la suya
  function nota(ins, t, d, nombre, vol = 1, de = null) {
    const I = INS[ins];
    const c = capa(I.capa);
    if (I.onda !== 'pulso' && I.onda !== 'triangulo' || I.filtro || I.sala || I.cinta || I.tremolo || I.voces)
      return notaRica(I, c, t, d, nombre, vol, de);
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
      suma(c, ini + i, onda * paso(env) * I.vol * vol, gL, gR, I.eco);
    }
  }

  // La nota de los instrumentos de 16 bits (ver arriba): varias voces, filtro, sala, cinta...
  function notaRica(I, c, t, d, nombre, vol, de) {
    const f0 = hz(nombre) * 2 ** ((I.cents ?? 0) / 1200);
    const fDe = de && hz(de) * 2 ** ((I.cents ?? 0) / 1200);
    const abierta = I.suena ?? d * NEGRA * I.gate;
    const n = Math.round((abierta + I.suelta * 5) * SR);
    const ini = muestra(t);
    const t0 = t * NEGRA;
    const voces = I.voces ?? 1;
    const reparto = (v) => (voces === 1 ? 0 : (v / (voces - 1)) * 2 - 1);   // de -1 a 1
    const desafina = Array.from({ length: voces }, (_, v) => 2 ** (reparto(v) * (I.abrir ?? 0) / 2 / 1200));
    const lados = Array.from({ length: voces }, (_, v) => lado(Math.max(-1, Math.min(1, (I.pan ?? 0) + reparto(v) * (I.ancho ?? 0.6)))));
    const fases = Array.from({ length: voces }, (_, v) => (v * 0.618) % 1);
    const fasesMod = new Array(voces).fill(0);
    const norma = 1 / Math.sqrt(voces);
    const filtros = [crearSvf(), crearSvf()];
    const formantes = I.onda === 'coro' ? [0, 1].map(() => FORMANTES.map(() => crearSvf())) : null;
    const k = 1 / (I.reso ?? 0.707);
    const vib = I.vibrato === true ? 0.15 : (I.vibrato ?? 0);
    let gFijo = I.filtro && !I.filtroEnv ? Math.tan(Math.PI * Math.min(I.filtro, 18000) / SR) : 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      let env = s < I.ataque ? s / I.ataque : I.sosten + (1 - I.sosten) * Math.exp(-(s - I.ataque) / I.caida);
      if (s > abierta) env *= Math.exp(-(s - abierta) / I.suelta);
      let f = f0;
      if (de) f = fDe * (f0 / fDe) ** Math.min(1, s / (I.glide ?? 0.06));
      if (vib && s > 0.3) f *= 2 ** (Math.min(1, (s - 0.3) / 0.4) * vib * Math.sin(2 * Math.PI * 5.2 * s) / 12);
      if (I.cinta && cinta) f *= 2 ** (cinta(t0 + s) / 1200);
      let vL = 0, vR = 0;
      for (let v = 0; v < voces; v++) {
        const fv = f * desafina[v];
        const dt = fv / SR;
        fases[v] = (fases[v] + dt) % 1;
        const p = fases[v];
        let w;
        if (I.onda === 'sierra' || I.onda === 'coro') w = 2 * p - 1 - blep(p, dt);
        else if (I.onda === 'seno') w = Math.sin(2 * Math.PI * p);
        else if (I.onda === 'fm') {
          fasesMod[v] = (fasesMod[v] + dt * (I.ratio ?? 2)) % 1;
          const ind = (I.indice ?? 1) * (I.indiceCae ? 0.25 + 0.75 * Math.exp(-s / I.indiceCae) : 1);
          w = Math.sin(2 * Math.PI * p + ind * Math.sin(2 * Math.PI * fasesMod[v]));
        } else if (I.onda === 'triangulo') w = triangulo(p);
        else w = pulso(p, dt, I.pwm ? I.duty + I.pwm * Math.sin(2 * Math.PI * 0.7 * (t0 + s)) : I.duty);
        vL += w * lados[v][0]; vR += w * lados[v][1];
      }
      vL *= norma; vR *= norma;
      if (formantes) {
        let oL = 0, oR = 0;
        FORMANTES.forEach(([fc, q, g], j) => {
          const gg = Math.tan(Math.PI * fc / SR);
          formantes[0][j].paso(vL, gg, 1 / q); oL += formantes[0][j].band * g;
          formantes[1][j].paso(vR, gg, 1 / q); oR += formantes[1][j].band * g;
        });
        vL = oL; vR = oR;
      }
      if (I.filtro) {
        const g = gFijo || Math.tan(Math.PI * Math.min(18000, I.filtro * (1 + (I.filtroEnv ?? 0) * env)) / SR);
        filtros[0].paso(vL, g, k); filtros[1].paso(vR, g, k);
        vL = filtros[0].low; vR = filtros[1].low;
      }
      let a = env * I.vol * vol;
      if (I.tremolo) a *= 1 - I.tremolo.prof * (0.5 + 0.5 * Math.sin(2 * Math.PI * I.tremolo.hz * (t0 + s)));
      suma2(c, ini + i, vL * a, vR * a, I.eco ?? 0, I.sala ?? 0);
    }
  }

  // Una melodía: [nota, pulsos] por compás desde el compás c0; «~» delante = llega deslizándose desde la anterior,
  // «-» = silencio
  function melodia(ins, c0, frase, vol = 1, oct = 0) {
    let antes = null;
    frase.forEach((compasMel, k) => {
      let p = 0;
      for (const [marca, d] of compasMel) {
        if (marca !== '-') {
          const n = sube(marca.replace('~', ''), oct);
          nota(ins, B(c0 + k, p), d, n, vol, marca.startsWith('~') ? antes : null);
          antes = n;
        }
        p += d;
      }
    });
  }

  // Un acorde: varias notas a la vez
  const acorde = (ins, t, d, notas, vol = 1) => notas.forEach((n) => nota(ins, t, d, n, vol));

  // Acorde arpegiado a lo consola: cambia de nota 30 veces por segundo
  function arpegio(t, d, acorde, vol = 1) {
    const fs_ = acorde.map(hz);
    const n = Math.round(d * NEGRA * SR);
    const [gL, gR] = lado(-0.4);
    const ini = muestra(t);
    const c = capa(capas.arpegio);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      const f = fs_[Math.floor(s * 30) % fs_.length];
      const enPulso = (s / NEGRA) % 1;   // golpecito al principio de cada pulso
      const env = (0.55 + 0.45 * Math.exp(-enPulso * NEGRA / 0.12)) * Math.min(1, (n - i) / (0.02 * SR));
      const dt = f / SR;
      fase = (fase + dt) % 1;
      suma(c, ini + i, pulso(fase, dt, 0.125) * paso(env) * 0.08 * vol, gL, gR, 0.2);
    }
  }

  // Sube de una nota a otra (para entrar en el clímax)
  function subida(t, d, de, a, vol = 1) {
    const f1 = hz(de), f2 = hz(a);
    const n = Math.round(d * NEGRA * SR);
    const [gL, gR] = lado(0.2);
    const ini = muestra(t);
    const c = capa(capas.subida);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const x = i / n;
      const dt = f1 * (f2 / f1) ** x / SR;
      fase = (fase + dt) % 1;
      suma(c, ini + i, pulso(fase, dt, 0.125) * paso(0.15 + 0.85 * x) * 0.13 * vol, gL, gR, 0.3);
    }
  }

  // Campana de iglesia, grave y rajada
  function campana(t, nombre = 'G3', vol = 1) {
    const f = hz(nombre);
    const n = 6 * SR;
    const ini = muestra(t);
    const c = capa(capas.campana);
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
      suma(c, ini + i, v * env * 0.3 * vol, 1, 1, 0.35);
    }
  }

  // Viento: ruido grave que sube y baja y va de un lado a otro
  function viento(t, d, vol = 1) {
    const r = ruido();
    const n = Math.round(d * NEGRA * SR);
    const ini = muestra(t);
    const c = capa(capas.viento);
    let v = 0, y = 0;
    for (let i = 0; i < n; i++) {
      if (i % 20 === 0) v = r();
      const x = i / n;
      y += (v - y) * (0.02 + 0.04 * Math.sin(x * Math.PI * 3) ** 2);
      const [gL, gR] = lado(Math.sin(x * Math.PI * 2) * 0.6);
      suma(c, ini + i, y * Math.sin(Math.PI * x) ** 2 * 0.3 * vol, gL, gR, 0);
    }
  }

  // Un sonido a medida de la canción: fn(segundos desde que empieza, muestra) da cada valor
  // (con «aSala», también a la reverberación; con «enCapa», en esa capa y no en la de «sonido»)
  function sonido(t, segundos, fn, pan = 0, eco = 0, aSala = 0, enCapa = capas.sonido) {
    const n = Math.round(segundos * SR);
    const [gL, gR] = lado(pan);
    const ini = muestra(t);
    const c = capa(enCapa);
    for (let i = 0; i < n; i++) suma(c, ini + i, fn(i / SR, i), gL, gR, eco, aSala);
  }

  // ── Percusión de 16 bits (la de las canciones épicas) ──
  // Tambor japonés grande (taiko): un golpe grave que cae de tono, con el parche al principio
  function taiko(t, vol = 1, grave = false, pan = 0) {
    const r = azar(muestra(t) + 7);
    let fase = 0, lp = 0;
    const [f1, f2, cae] = grave ? [95, 46, 0.65] : [150, 72, 0.4];
    sonido(t, cae * 4, (s) => {
      const f = f2 + (f1 - f2) * Math.exp(-s / 0.05);
      fase = (fase + f / SR) % 1;
      lp += (r() - lp) * 0.12;
      return (Math.sin(2 * Math.PI * fase) * Math.exp(-s / cae) + lp * 2.2 * Math.exp(-s / 0.035)) * 0.55 * vol;
    }, pan, 0, 0.45, capas.percusion);
  }
  // Caja de orquesta moderna: ruido medio con cuerpo
  function caja16(t, vol = 1, pan = 0.1) {
    const r = azar(muestra(t) + 11);
    const bp = crearSvf();
    const g = Math.tan(Math.PI * 1900 / SR);
    let fase = 0;
    sonido(t, 0.7, (s) => {
      fase = (fase + (180 + 60 * Math.exp(-s / 0.01)) / SR) % 1;
      bp.paso(r(), g, 1.2);
      return (bp.band * 1.6 * Math.exp(-s / 0.14) + Math.sin(2 * Math.PI * fase) * 0.6 * Math.exp(-s / 0.05)) * 0.32 * vol;
    }, pan, 0, 0.35, capas.percusion);
  }
  // Charles (hi-hat) suave: ruido sin graves, cerrado o abierto
  function charles(t, vol = 1, abierto = false, pan = 0.35) {
    const r = azar(muestra(t) + 13);
    let lp = 0, lp2 = 0;
    sonido(t, abierto ? 0.6 : 0.12, (s) => {
      const x = r();
      lp += (x - lp) * 0.35;           // quita lo más agudo (no chirría)
      lp2 += (lp - lp2) * 0.08;        // y lo grave
      return (lp - lp2) * Math.exp(-s / (abierto ? 0.16 : 0.025)) * 0.16 * vol;
    }, pan, 0, 0.1, capas.percusion);
  }
  // Platillo grande que se queda sonando
  function platillo16(t, vol = 1, pan = -0.2) {
    const r = azar(muestra(t) + 17);
    let lp = 0, lp2 = 0;
    sonido(t, 4, (s) => {
      lp += (r() - lp) * 0.45;
      lp2 += (lp - lp2) * 0.05;
      return (lp - lp2) * Math.exp(-s / 1.1) * Math.min(1, s / 0.004) * 0.12 * vol;
    }, pan, 0, 0.3, capas.percusion);
  }
  // Impacto de tráiler: un «bum» que se siente más que se oye, con un soplo de ruido grave y mucha sala
  function golpe(t, vol = 1) {
    const r = azar(muestra(t) + 19);
    let fase = 0, lp = 0;
    sonido(t, 4.5, (s) => {
      const f = 30 + 45 * Math.exp(-s / 0.12);
      fase = (fase + f / SR) % 1;
      lp += (r() - lp) * (0.02 + 0.1 * Math.exp(-s / 0.1));
      return (Math.sin(2 * Math.PI * fase) * Math.exp(-s / 1.1) * 0.9 + lp * 3 * Math.exp(-s / 0.5)) * Math.min(1, s / 0.002) * 0.6 * vol;
    }, 0, 0, 0.6, capas.golpe ?? capas.percusion);
  }
  // Subida de ruido (antes de un golpe): un soplo que se va abriendo hacia los agudos durante «d» pulsos
  function ascenso(t, d, vol = 1) {
    const r = azar(muestra(t) + 23);
    const bp = crearSvf();
    const segundos = d * NEGRA;
    sonido(t, segundos, (s) => {
      const x = s / segundos;
      bp.paso(r(), Math.tan(Math.PI * 250 * 20 ** x / SR), 1.4);
      return bp.band * x * x * Math.min(1, (segundos - s) / 0.01) * 0.5 * vol;
    }, 0, 0, 0.5, capas.subida);
  }

  // ── Percusión ─────────────────────────────────
  function bombo(t, vol = 1, grave = false) {   // «grave» = latido de corazón
    const n = Math.round(0.4 * SR);
    const ini = muestra(t);
    const c = capa(capas.percusion);
    let fase = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      const f = grave ? 38 + 60 * Math.exp(-s / 0.06) : 48 + 130 * Math.exp(-s / 0.035);
      fase = (fase + f / SR) % 1;
      suma(c, ini + i, (1 - 4 * Math.abs(fase - 0.5)) * Math.exp(-s / (grave ? 0.2 : 0.14)) * 0.75 * vol, 1, 1, 0);
    }
  }
  function tambor(t, vol = 1) {
    const r = ruido();
    const n = Math.round(0.3 * SR);
    const ini = muestra(t);
    const c = capa(capas.percusion);
    let fase = 0, ru = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      if (i % 2 === 0) ru = r();
      fase = (fase + 200 * (1 + 0.5 * Math.exp(-s / 0.01)) / SR) % 1;
      const v = ru * paso(Math.exp(-s / 0.075)) * 0.5 + (1 - 4 * Math.abs(fase - 0.5)) * Math.exp(-s / 0.035) * 0.45;
      suma(c, ini + i, v * 0.45 * vol, 1, 1, 0.1);
    }
  }
  function platillo(t, vol = 1, abierto = false) {
    const r = ruido();
    const n = Math.round((abierto ? 0.4 : 0.08) * SR);
    const ini = muestra(t);
    const c = capa(capas.percusion);
    const [gL, gR] = lado(0.25);
    for (let i = 0; i < n; i++) suma(c, ini + i, r() * paso(Math.exp(-i / SR / (abierto ? 0.1 : 0.022))) * 0.1 * vol, gL, gR, 0);
  }
  function platazo(t, vol = 1) {
    const r = ruido(), m = ruido(true);
    const n = 3 * SR;
    const ini = muestra(t);
    const c = capa(capas.percusion);
    let me = 0;
    for (let i = 0; i < n; i++) {
      const s = i / SR;
      if (i % 3 === 0) me = m();
      suma(c, ini + i, (r() * paso(Math.exp(-s / 0.8)) * 0.2 + me * Math.exp(-s / 0.3) * 0.08) * vol, 1, 1, 0.2);
    }
  }

  // ── Mezcla y .wav ─────────────────────────────
  // «partes»: [nombre, compás de inicio, compás de fin] para decir el volumen de cada una.
  // Devuelve { capa: su .wav } si la canción va por capas (si no, nada)
  function guardar(salida, partes) {
    // Cada capa se mezcla por separado (eco, bucle y filtro hacen lo mismo con la suma que con cada parte): así,
    // las capas sumadas suenan igual que la canción entera
    const mezcladas = new Map([...CAPAS].map(([nombre, c]) => [nombre, mezclar(c)]));
    const sL = new Float32Array(LARGO), sR = new Float32Array(LARGO);
    for (const [cL, cR] of mezcladas.values()) {
      for (let i = 0; i < LARGO; i++) { sL[i] += cL[i]; sR[i] += cR[i]; }
    }

    // Todas a la misma ganancia: la que deja la canción entera con el pico a -1 dB
    let pico = 0;
    for (let i = 0; i < LARGO; i++) pico = Math.max(pico, Math.abs(sL[i]), Math.abs(sR[i]));
    const ganancia = 0.89 / pico;

    const wav = escribir(salida, sL, sR, ganancia);

    // Volumen de cada parte, para ver que crece y baja donde toca
    const db = (x) => (20 * Math.log10(x)).toFixed(1);
    const volumen = (xL, xR, c0, c1) => {
      let e = 0;
      const i0 = muestra(B(c0)), i1 = muestra(B(c1));
      for (let i = i0; i < i1; i++) e += (xL[i] * ganancia) ** 2 + (xR[i] * ganancia) ** 2;
      return db(Math.sqrt(e / (2 * (i1 - i0))));
    };
    console.log(`${salida}\n${(LARGO / SR).toFixed(1)} s, pico normalizado a -1 dB`);
    for (const [nombre, c0, c1] of partes) {
      console.log(`  ${nombre.padEnd(8)} compases ${String(c0).padStart(2)}-${c1 - 1}  ${volumen(sL, sR, c0, c1)} dB`);
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

    // Las capas, cada una en su .wav (…-base.wav, …-ritmo.wav...), con el volumen de cada parte
    const archivos = {};
    if (mezcladas.size < 2) return archivos;
    console.log(`capas (dB en cada parte: ${partes.map((p) => p[0]).join(', ')})`);
    for (const [nombre, [cL, cR]] of mezcladas) {
      archivos[nombre] = salida.replace(/\.wav$/, `-${nombre}.wav`);
      escribir(archivos[nombre], cL, cR, ganancia);
      const vols = partes.map(([, c0, c1]) => volumen(cL, cR, c0, c1).padStart(6));
      console.log(`  ${nombre.padEnd(8)} ${vols.join(' ')}`);
    }
    return archivos;
  }

  // Lo que suena en una capa, ya con su eco, en bucle y filtrado: [izquierda, derecha]
  function mezclar({ L, R, ECO, SALA }) {
    // Eco de ida y vuelta (izquierda, derecha...) a pulso y medio, más oscuro que el sonido
    const D = muestra(eco.pulsos ?? 1.5);
    const FB = eco.fb ?? 0.45;
    const ecoL = new Float32Array(N), ecoR = new Float32Array(N);
    let oscuro = 0;
    const ecoIn = new Float32Array(N);
    for (let i = 0; i < N; i++) { oscuro += (ECO[i] - oscuro) * 0.25; ecoIn[i] = oscuro; }
    for (let i = D; i < N; i++) {
      ecoL[i] = ecoIn[i - D] + FB * ecoR[i - D];
      ecoR[i] = FB * ecoL[i - D];
    }
    for (let i = 0; i < N; i++) { L[i] += ecoL[i] * 0.6; R[i] += ecoR[i] * 0.6; }

    // Reverberación de sala (solo si algún instrumento la usa)
    if (SALA) {
      const [rL, rR] = reverberar(SALA, N, sala ?? {});
      for (let i = 0; i < N; i++) { L[i] += rL[i]; R[i] += rR[i]; }
    }

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
    return [filtrar(L), filtrar(R)];
  }

  // Guarda un .wav de 16 bits en estéreo
  function escribir(salida, sL, sR, ganancia) {
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
    return wav;
  }

  return { B, NEGRA, nota, notaRica, melodia, acorde, arpegio, subida, campana, viento, sonido, bombo, tambor, platillo, platazo,
    taiko, caja16, charles, platillo16, golpe, ascenso, guardar };
}

// Pasa el .wav a .ogg para el juego, como el resto de assets/musica/ (32 000 muestras por segundo, la misma
// calidad que la música que se grababa del juego JS). «decibelios» lo baja hasta su volumen en el juego (el menú
// y explorar están a -29,7 LUFS y las peleas a -25; se mide con `ffmpeg -i x.ogg -af ebur128 -f null -`).
// Necesita ffmpeg.
export function medirLufs(archivo) {
  const r = spawnSync('ffmpeg', ['-hide_banner', '-nostats', '-i', archivo, '-af', 'ebur128', '-f', 'null', '-'], { encoding: 'utf8' });
  return +/I:\s+(-?[\d.]+) LUFS/.exec(r.stderr.split('Summary:')[1])[1];
}
export function pasarAOgg(wav, ogg, decibelios) {
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', wav, '-af', `volume=${decibelios}dB`,
    '-ar', '32000', '-c:a', 'libvorbis', '-q:a', '1', ogg]);
  console.log(`${ogg}  (${decibelios} dB)`);
}

// La misma nota, «semis» semitonos arriba (o abajo, en negativo): transponer('C4', 7) → 'G4'
const NOMBRES = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
export function transponer(n, semis) {
  const [, nombre, oct] = /^([A-G][#b]?)(\d)$/.exec(n);
  const m = SEMITONO[nombre] + 12 * +oct + semis;
  return NOMBRES[((m % 12) + 12) % 12] + Math.floor(m / 12);
}

// Saca una canción de las de los edificios para elegir y para el juego:
//   tools/efectos/elegir/<nombre>.ogg            la canción entera, con todas sus capas (como suena con zombis)
//   tools/efectos/elegir/<nombre>-tranquila.ogg  solo la base (como suena sin zombis despiertos), con la misma ganancia
//   con «juego»: assets/musica/<nombre>-<capa>.ogg, cada capa a su volumen del juego (las dos juntas a «lufs»: -29,7,
//   como la música de explorar; -25, la de las peleas)
// Para escuchar van más altas (a -18 LUFS la entera), todas igual, para compararlas.
export function sacarCancion(raiz, nombre, wav, capas, { juego = false, lufs = -29.7 } = {}) {
  const medida = medirLufs(wav);
  const elegir = path.join(raiz, 'tools', 'efectos', 'elegir');
  fs.mkdirSync(elegir, { recursive: true });
  const oir = (de, a, db) => execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', de, '-af', `volume=${db}dB`,
    '-c:a', 'libvorbis', '-q:a', '5', path.join(elegir, a)]);
  oir(wav, `${nombre}.ogg`, -18 - medida);
  if (capas.base) oir(capas.base, `${nombre}-tranquila.ogg`, -18 - medida);
  console.log(`para elegir: tools/efectos/elegir/${nombre}.ogg${capas.base ? " y -tranquila.ogg" : ""} (entera a ${medida} LUFS antes de ajustar)`);
  if (juego) {
    // (una canción de una sola capa, como la del menú, va entera como su «base»)
    for (const [capa, archivo] of Object.entries(Object.keys(capas).length ? capas : { base: wav })) {
      pasarAOgg(archivo, path.join(raiz, 'assets', 'musica', `${nombre}-${capa}.ogg`), +(lufs - medida).toFixed(1));
    }
  }
}
