// Los fogonazos de las armas de Johnny, sacados de "muzzle-pistol", "muzzle-smg" y "muzzle-shotgun" de pixelfx 0.3.0
// (que a su vez vienen del muzzle-flash de Sprite Fusion, licencia MIT, Hugo Duprez), partidos en dos para la vista
// desde arriba del juego:
//  - parte "llama": la llama, las chispas y su brillo, con el origen en la boca del arma y mirando a la derecha.
//    El exportador (exportar_fogonazo.mjs) la dibuja girada con la opción "angle" de pixelfx, sin perder píxeles.
//  - parte "humo": el humo y los granos de pólvora. No se gira (el humo siempre sube por la pantalla): el empujón
//    inicial sale hacia "rumbo" (radianes) y luego sube solo.
// Sin casquillo: el juego ya suelta el suyo (johnny.gd, soltar_casquillo).
// arma: "pistola", "mp5" o "escopeta". seed: la forma de la llama (la MP5 tiene varias para que no se repita).
// Se exporta con: node tools/pixelfx/exportar_fogonazo.mjs <carpeta de pixelfx> assets/sprites
import { Particles, P, Rng, rng, fit, mix, WHITE } from "../../core/index.js";
import { flashShape, flash, cloud, Smoke } from "./_lib.js";

export const meta = {
  name: "Fogonazo",
  desc: "Fogonazo de pistola, MP5 o escopeta en dos partes: la llama (para girarla) y el humo (que siempre sube).",
  tags: ["projectile", "muzzle", "gun", "flash", "smoke"],
  size: [160, 160],
  origin: [80, 80],
  duration: 4,
  loop: false,
  fps: 30,
  options: {
    palette: ["#4a1712", "#8a1f17", "#c9281f", "#f2561d", "#ff8a2a", "#ffc23d", "#ffe26b", "#fff3a6", "#ffffff"],
    smoke: ["#26222e", "#3b3644", "#544e5e", "#6f6979", "#8c8596", "#aca5b5", "#cbc4d2"],
    arma: "pistola",
    parte: "llama",
    rumbo: 0,
    seed: 3,
  },
};

// Lo que dura cada parte, en segundos (el exportador saca solo eso)
export const DURA = {
  pistola: { llama: 0.2, humo: 1.5 },
  mp5: { llama: 0.17, humo: 1.4 },
  escopeta: { llama: 0.3, humo: 2.8 },
};

const F1 = 1 / 30;

// El abanico de la escopeta (el "fan" de muzzle-shotgun): una bola gorda en la boca y lenguas desiguales en cono
function abanico(R, f) {
  const k = f === 1 ? 1 : f === 2 ? 0.82 : 0.55, w = f === 1 ? 1 : 1.25;
  const L = [{ off: 0.5, a: 0, len: 11 * k, wid: 3.6 * w, core: 0.5 }];
  for (let i = 0; i < 9; i++) {
    const u = i / 8 - 0.5, a = u * 1.15 + R[i * 3] * 0.12, len = (17 + 11 * (1 - Math.abs(u) * 1.4) + R[i * 3 + 1] * 7) * k;
    L.push({ off: 2, a, len, wid: (1.7 + R[i * 3 + 2]) * w, core: f === 1 ? 0.32 : 0 });
  }
  if (f === 1) for (const s of [-1, 1]) L.push({ off: 1, a: s * (1.6 + R[27 + (s > 0)] * 0.4), len: 5 + R[29] * 3, wid: 1.2, core: 0 });
  return L;
}

export function create(o) {
  const F = fit(o.palette, 9), SM = fit(o.smoke, 7), R = new Rng(o.seed), arma = o.arma, escopeta = arma === "escopeta";
  const cr = Math.cos(o.rumbo), sr = Math.sin(o.rumbo);
  // el humo sale hacia "rumbo": giramos su empujón (y su sitio de salida), pero la subida va siempre hacia arriba
  const girar = (x, y) => [x * cr - y * sr, x * sr + y * cr];
  // los granos de pólvora caen al suelo, que está unos 25 píxeles por debajo de la boca (más si dispara hacia abajo)
  const suelo = 25 + Math.max(0, sr) * 18;
  const ps = new Particles({ rng: R, ground: () => (o.parte === "llama" ? 1e9 : suelo), sparks: [F[7], F[6], F[4], F[3]] });
  const smoke = new Smoke(R);
  const humo = (q) => {
    const [x, y] = girar(q.x, q.y), [vx, vy] = girar(q.vx, q.vy);
    smoke.add({ ...q, x, y, vx, vy, curl: (q.curl ?? 0) * (cr < -0.1 ? -1 : 1) });
  };
  const forma = R.int(0, 1e6), tilt = R.range(-0.05, 0.05), jit = Array.from({ length: 32 }, () => R.next());
  const perdigones = Array.from({ length: 10 }, () => ({ a: R.range(-0.13, 0.13), v: R.range(900, 1150), d0: R.range(0, 4) }));

  if (o.parte === "llama") {
    // chispas escupidas hacia delante
    const n = escopeta ? 14 : arma === "mp5" ? 4 : 6, ab = escopeta ? 0.55 : 0.3;
    for (let i = 0; i < n; i++) {
      const a = R.range(-ab, ab), sp = R.range(180, escopeta ? 420 : 380);
      ps.spawn(P.SPARK, 3, 0, Math.cos(a) * sp, Math.sin(a) * sp, R.range(0.06, escopeta ? 0.24 : 0.15));
    }
  } else {
    // granos de pólvora sin quemar que caen
    for (let i = 0; i < (escopeta ? 7 : arma === "mp5" ? 2 : 5); i++) {
      const a = R.range(-0.35, 0.25), sp = R.range(60, escopeta ? 200 : 160), [x, y] = girar(3, 0);
      ps.spawn(P.EMBER, x, y, Math.cos(a + o.rumbo) * sp, Math.sin(a + o.rumbo) * sp, R.range(0.25, escopeta ? 0.8 : 0.5), F[5]);
    }
    if (escopeta) {
      // un empujón de gas grande que se frena, rueda, se hincha y sube
      for (let i = 0; i < 26; i++) {
        const a = R.range(-0.45, 0.35), sp = R.range(60, 230) * (i < 8 ? 1.15 : 0.8);
        humo({ x: 4 + R.range(0, 4), y: R.range(-1.5, 1.5), vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, r0: R.range(2.5, 3.5), r1: R.range(7, 12.5), life: R.range(2.0, 2.7), a: R.range(0.55, 0.72), b: R.range(0.9, 1), drag: R.range(2.6, 3.6), rise: R.range(9, 15), grow: R.range(1.8, 2.8), warm: 1, delay: R.range(0, 0.04) });
      }
      for (let i = 0; i < 6; i++) humo({ x: 2, y: 0, vx: R.range(15, 50), vy: -R.range(10, 25), r0: 1.5, r1: R.range(4, 6), life: R.range(1.8, 2.4), a: 0.5, b: 1, drag: 2, rise: 10, curl: -R.range(1.5, 3), warm: 0.6, delay: 0.08 + i * 0.05 });
    } else if (arma === "mp5") {
      // la MP5 dispara muy seguido: poco humo por tiro, que se va juntando en una neblina
      for (let j = 0; j < 3; j++) humo({ x: 3, y: 0, vx: R.range(45, 100) * (1 - j * 0.3), vy: -R.range(4, 16), r0: 1.2, r1: R.range(3.5, 5.5), life: R.range(1.1, 1.4), a: 0.4, b: R.range(0.8, 0.92), drag: 3.2, rise: 9, grow: 1.4, warm: 0.7, delay: j * 0.03 });
    } else {
      // pistola: una bocanada hacia delante y una ristra de volutas que se frenan y se enroscan hacia arriba y atrás
      for (let i = 0; i < 3; i++) humo({ x: 3, y: 0, vx: R.range(70, 120), vy: R.range(-12, 6), r0: 1.6, r1: R.range(4.5, 6), life: R.range(0.8, 1.05), a: 0.55, drag: 3.5, rise: 10, warm: 0.9, delay: i * 0.012 });
      for (let i = 0; i < 14; i++) {
        const k = i / 13;
        humo({ x: 2, y: 0, vx: 115 - 75 * k + R.range(-12, 12), vy: -6 - 10 * k + R.range(-5, 5), r0: 1.4, r1: (3.6 + k * 2.6) * R.range(0.75, 1.25), life: 1.0 + k * 0.3, a: 0.62, b: R.range(0.85, 1), drag: 2.2, rise: 6, curl: -4.4 + k * 1.8 + R.range(-0.5, 0.5), grow: 1.6, warm: 0.7, delay: 0.02 + i * 0.022 });
      }
    }
  }

  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
      smoke.update(dt);
    },
    draw(p) {
      const pop = Math.exp(-(t + 0.008) / (escopeta ? 0.05 : 0.035));
      if (o.parte === "humo") {
        const list = smoke.puffs();
        for (const q of list) q.w *= escopeta ? 0.25 + pop * 1.2 : 0.4 + pop;
        cloud(p, list, SM, [SM[0], mix(F[1], SM[1], 0.5), mix(F[2], SM[2], 0.4), F[3], F[4], F[5], F[7]], { dens: escopeta ? 1.4 : 1.5, max: escopeta ? 0.86 : arma === "mp5" ? 0.7 : 0.8, lit: 1.4 });
        ps.draw(p);
        return;
      }
      // la llama: el primer fotograma con el centro blanco, luego uno más frío y pequeño (la escopeta, tres)
      if (escopeta) {
        if (t < 3 * F1) {
          const f = t < F1 ? 1 : t < 2 * F1 ? 2 : 3;
          flash(p, 0, 0, 0, abanico(jit, f), f === 1 ? [WHITE, F[7], F[6], F[3]] : f === 2 ? [F[7], F[6], F[4], F[2]] : [F[5], F[4], F[3], F[1]], f + 9);
        }
        // los perdigones: cabezas al rojo con colas que se enfrían, cortados enseguida (las balas de verdad las pinta el juego)
        if (t < 0.1)
          for (const q of perdigones) {
            const head = Math.min(44, 6 + q.d0 + q.v * t), tail = Math.max(4, head - 22), ca = Math.cos(q.a), sa = Math.sin(q.a);
            for (let d = tail; d <= head; d += 0.5) {
              const u = (d - tail) / Math.max(1, head - tail);
              p.dot(ca * d, sa * d, u > 0.85 ? WHITE : u > 0.5 ? F[6] : F[4], (u > 0.3 ? 1 : u / 0.3) * (1 - t / 0.1));
            }
          }
      } else if (t < 2 * F1) {
        const f = t < F1 ? 1 : 2, r = rng(forma);
        const L = arma === "mp5"
          ? flashShape(r, f, { size: r.range(0.95, 1.2), spike: [12, 21], diag: [6, 11], cross: [4, 7.5], back: [2.5, 5] })
          : flashShape(r, f, { size: 1.15, spike: [15, 22], diag: [7, 12], cross: [4.5, 8], back: [3, 5.5] });
        flash(p, 0, 0, tilt, L, f === 1 ? [WHITE, F[7], F[6], F[3]] : [F[7], F[6], F[4], F[2]], f + o.seed);
      }
      ps.draw(p);
      // la luz: solo el golpe en la boca (la luz de alrededor ya la pone el juego, Luz.destello)
      p.glow(escopeta ? 6 : 4, 0, escopeta ? 20 : 14, F[4], 0.8 * pop);
      p.glow(2, 0, escopeta ? 10 : 7, WHITE, 0.5 * pop);
    },
  };
}
