// La nube de gases del Flatulento (M37): cada vez que Johnny suelta los gases, una bocanada sale de él y se extiende
// por el suelo hasta donde llegan (los 140 del radio = 70 píxeles del dibujo), con el borde roto en lenguas que se
// enroscan, columnitas de humo retorcido y motas que brillan, y se deshace. Es el "poison-cloud" de pixelfx (licencia
// MIT, © Patch, https://github.com/patch-gg/pixelfx) pasado a vista desde arriba: el suelo es una elipse, como los
// charcos de charco.gd (lo alto es 0,6 de lo ancho), con sus mismos colores, del amarillo verdoso al violeta.
// Lo exporta tools/pixelfx/exportar.mjs a assets/sprites/nube-gases-*.png.
import { fit, rng, smooth, clamp, ease, TAU, tileNoise } from "../../core/index.js";

export const meta = {
  name: "Nube de gases",
  desc: "A fart of toxic gas seen from above: a puff bursts out and rolls across the floor to its full reach, its edge torn into tongues that curl over, ribbons of fume twisting up, specks twinkling, then it thins away.",
  tags: ["nature", "poison", "gas", "cloud", "miasma", "toxic", "area", "ground", "one-shot"],
  size: [184, 128],
  origin: [92, 66],
  duration: 1.6,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#0e0816", "#24123a", "#3e2056", "#5a3a62", "#6a6a3a", "#96aa30", "#cce040", "#f4ffa0"], seed: 3 },
};

const D = meta.duration;
const F = 0.6;        // el suelo, visto un poco desde arriba
const RAD = 70;       // hasta dónde llega el gas (el radio de mutaciones.gd, en píxeles del dibujo)
const LENGUAS = 9;    // en cuántas lenguas se rompe el borde
const RIZOS = 10;     // los rizos del borde

// lo que se ha extendido ya (sale deprisa y frena) y lo que se ha deshecho
const frente = (t) => 8 + (RAD - 8) * ease.outCubic(clamp(t / 0.55));
const queda = (t) => 1 - smooth(0.85, D - 0.05, t);
// el borde no es redondo: se rompe en lenguas que avanzan un poco más que el resto, y se mueven
const borde = (a, t, seed) => 1 + 0.1 * tileNoise((a / TAU) * LENGUAS, t * 1.6, LENGUAS, 0, seed) + 0.04 * tileNoise((a / TAU) * 23, t * 3, 23, 0, seed + 5);

// la sábana de gas pegada al suelo: fina en el medio (el gas ya ha salido) y espesa en el frente que avanza, con
// vetas que corren hacia fuera; clara por dentro, donde está iluminada, y del verde al violeta hacia el borde
function sabana(p, C, t, seed) {
  const R = frente(t), k = queda(t), X = Math.ceil(R * 1.16), Y = Math.ceil(R * F * 1.16);
  const dentro = 0.35 * (1 - smooth(0.25, 1.1, t));   // lo que queda en el medio
  for (let y = -Y; y <= Y; y++)
    for (let x = -X; x <= X; x++) {
      const dx = (x + 0.5) / R, dy = (y + 0.5) / (R * F), d = Math.hypot(dx, dy), a = Math.atan2(dy, dx), e = borde(a, t, seed);
      if (d > e) continue;
      const u = d / e, veta = 0.65 + 0.35 * tileNoise(d * 7 - t * 5, (a / TAU) * 16, 0, 16, seed + 9);
      const espeso = Math.max(dentro, smooth(0.45, 0.9, u) * (1 - smooth(0.97, 1, u) * 0.5));
      const lv = u - (veta - 0.65) * 0.5;
      const c = u > 0.96 ? C[3] : lv > 0.86 ? C[4] : lv > 0.68 ? C[5] : t < 0.4 && lv < 0.3 ? C[7] : C[6];
      p.blend(x, y, c, 0.55 * espeso * veta * k);
    }
}

// los rizos del borde: el gas que llega al frente sube y se enrosca hacia fuera, como en el original
function rizos(p, C, t, seed, detras) {
  const R = frente(t), k0 = queda(t);
  for (let i = 0; i < RIZOS; i++) {
    const g = rng(seed, i, 41), a = (i / RIZOS) * TAU + g.range(-0.2, 0.2), sn = Math.sin(a);
    if (sn < 0 !== detras) continue;
    const vida = Math.sin(Math.PI * clamp((t - 0.08 - g.range(0, 0.15)) / g.range(0.9, 1.25)));
    if (vida < 0.15) continue;
    const e = borde(a, t, seed), ex = Math.cos(a) * R * e, ey = sn * R * F * e, s = Math.cos(a) < 0 ? -1 : 1;
    const r = 2.5 + 4.5 * vida * g.range(0.75, 1.1), cx = ex - Math.cos(a) * r * 0.9, cy = ey - sn * r * 0.5 - r * 0.7, giro = -s * t * TAU * 1.4 + g.range(0, TAU);
    for (let b = 0; b < 4.6; b += 0.1) {
      const rr = r * (1 - b * 0.12), px = cx + s * Math.cos(giro + b) * rr, py = cy + Math.sin(giro + b) * rr, w = 2.2 * (1 - b / 6);
      for (let o = -w; o <= w; o += 0.8) {
        const qx = px + s * Math.cos(giro + b) * o, qy = py + Math.sin(giro + b) * o;
        p.blend(qx, qy, o > w * 0.4 ? C[6 - (detras ? 1 : 0)] : C[5 - (detras ? 1 : 0)], 0.4 * vida * k0 * (1 - b / 5.5));
      }
    }
  }
}

// la bocanada: sale de Johnny, gorda y clara, y se abre enseguida
function bocanada(p, C, t) {
  if (t > 0.38) return;
  const u = t / 0.38, r = 5 + 16 * ease.outQuad(u), k = 1 - smooth(0.2, 1, u);
  for (let y = -Math.ceil(r); y <= Math.ceil(r * F); y++)
    for (let x = -Math.ceil(r); x <= Math.ceil(r); x++) {
      const d = Math.hypot(x / r, (y + r * 0.3) / (r * 0.8));
      if (d > 1) continue;
      p.blend(x, y - 6, d < 0.45 ? C[7] : d < 0.75 ? C[6] : C[5], 0.7 * k * (1 - d * 0.5));
    }
  p.glow(0, -6, 10 + r, C[6], 0.5 * k);
}

// columnitas de humo: salen de la nube y suben retorciéndose como cintas, cada vez más finas
function columnas(p, C, t, seed) {
  for (let i = 0; i < 8; i++) {
    const R = rng(seed, i, 77), t0 = 0.06 + i * 0.08 + R.range(0, 0.05), L = R.range(0.95, 1.3), age = t - t0;
    if (age < 0 || age > L || t > D - 0.04) continue;
    const u = age / L, an = R.range(0, TAU), dist = Math.sqrt(R.range(0.05, 1)) * RAD * 0.62;
    const x0 = Math.cos(an) * dist * Math.min(1, frente(t0 + 0.2) / RAD), y0 = Math.sin(an) * dist * F;
    const rise = R.range(24, 34), len = R.range(18, 28), ph = R.range(0, TAU), amp = R.range(2, 4);
    const head = 3 + rise * age, tail = Math.max(1, head - len), fade = smooth(0, 0.15, u) * (1 - smooth(0.45, 1, u)) * queda(t);
    for (let h = tail; h <= head; h += 0.7) {
      const s = (h - tail) / Math.max(1, head - tail), tw = Math.cos(h * 0.3 + age * 3 + ph), w = 1 + 2.2 * Math.abs(tw) * (1 - s * 0.5);
      const x = x0 + amp * Math.sin(h * 0.16 + age * 2 + ph) * (0.4 + s), a = fade * Math.sin(Math.PI * Math.min(1, s * 1.2)) * 0.55;
      for (let o = -w; o <= w; o += 1) p.blend(x + o, y0 - h, tw > 0 ? (Math.abs(o) < w * 0.5 ? C[6] : C[5]) : Math.abs(o) < w * 0.5 ? C[4] : C[3], a);
    }
  }
}

// motas que salen con el gas, brillando, y se van apagando
function motas(p, C, t, seed) {
  for (let i = 0; i < 24; i++) {
    const R = rng(seed, i, 13), t0 = R.range(0, 0.5), L = R.range(0.6, 1.0), age = t - t0;
    if (age < 0 || age > L) continue;
    const u = age / L, an = R.range(0, TAU), dist = Math.min(frente(t) * 0.95, R.range(4, 14) + age * R.range(40, 75));
    const x = Math.cos(an) * dist, y = Math.sin(an) * dist * F - R.range(2, 12) - Math.sin(age * R.range(3, 6)) * 2;
    const a = Math.min(1, u * 5) * Math.min(1, (1 - u) * 3) * (0.6 + 0.4 * Math.sin(age * R.range(8, 12) + R.range(0, TAU)));
    if (a < 0.1) continue;
    p.dot(x, y, a > 0.7 ? C[7] : C[6], a * 1.2);
    p.glow(x, y, 4, C[6], 0.3 * a);
  }
}

export function drawBack(p, t, o) {
  const C = fit(o.palette, 8), R = frente(t), k = queda(t);
  // la luz de dentro, baja, a lo largo del frente
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * TAU + t;
    p.glow(Math.cos(a) * R * 0.75, Math.sin(a) * R * F * 0.75, 20, C[5], 0.12 * k);
  }
  sabana(p, C, t, o.seed);
  rizos(p, C, t, o.seed, true);
}

export function draw(p, t, o) {
  const C = fit(o.palette, 8);
  bocanada(p, C, t);
  columnas(p, C, t, o.seed * 7 + 2);
  rizos(p, C, t, o.seed, false);
  motas(p, C, t, o.seed * 11 + 5);
}
