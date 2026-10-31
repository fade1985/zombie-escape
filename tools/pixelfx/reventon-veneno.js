// El reventón del gordo (M38): al morir, revienta y suelta su veneno. Es el "acid-splash" de pixelfx (licencia MIT,
// © Patch, https://github.com/patch-gg/pixelfx; sus gotas vienen de la sangre de Sprite Fusion, MIT, © 2026 Hugo
// Duprez) pasado a vista desde arriba, como el juego: la corona y las gotas salen hacia todos lados por el suelo (una
// elipse, como los charcos de charco.gd: lo alto es 0,6 de lo ancho), en los verdes del charco de veneno.
// No hay foso: debajo se extiende el charco grande de verdad (charco.gd, "reventon").
// Lo exporta tools/pixelfx/exportar.mjs a assets/sprites/reventon-veneno-*.png.
import { Rng, fit, smooth, clamp, ease, TAU, WHITE, mix, hex } from "../../core/index.js";

export const meta = {
  name: "Reventón de veneno",
  desc: "A fat body bursts into a crown of green venom seen from above; gobs fly out all round, splat on the floor and hiss, steam curling off.",
  tags: ["nature", "poison", "splash", "liquid", "ground", "one-shot"],
  size: [160, 112],
  origin: [80, 72],
  duration: 1.4,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#0c1a0a", "#1d4a1a", "#2f7a22", "#4fae2c", "#7ad63a", "#a6e84e", "#c8f77a", "#e6ffb0"], seed: 6 },
};

const F = 0.6;            // el suelo, visto un poco desde arriba
const BODY = 20;          // a qué altura revienta (la tripa del gordo, en píxeles del dibujo)
const G = 520;            // gravedad de las gotas
const CROWN = 30;         // lo que se abre la corona
const CROWN_T = 0.28;     // lo que dura

// una voluta de vapor: fina, clara, que sube culebreando y se va
function wisp(p, q, t, col) {
  const age = t - q.t0, u = age / q.life;
  if (u < 0 || u >= 1) return;
  const head = q.rise * age, tail = Math.max(0, head - q.len), fade = smooth(0, 0.15, u) * (1 - smooth(0.4, 1, u));
  for (let h = tail; h <= head; h += 0.5) {
    const s = (h - tail) / Math.max(1, head - tail), x = q.x + q.amp * Math.sin(h * q.k + q.ph) * (0.2 + s) + q.drift * age;
    p.blend(x, q.y - h, col, fade * Math.sin(Math.PI * s) * 0.45);
  }
}

export function create(o) {
  const C = fit(o.palette, 8), R = new Rng(o.seed), STEAM = mix(C[7], hex("#e8ece6"), 0.7), SCORCH = mix(C[0], hex("#0a0f08"), 0.5);
  // las gotas: en el suelo (x, y) y su altura (z); al caer dejan una manchita que chisporrotea
  const drops = [], stains = [], wisps = [];
  // la corona: púas alrededor del borde, con una perla en la punta que se suelta
  const spikes = Array.from({ length: 18 }, (_, i) => ({ a: (i / 18) * TAU + R.range(-0.15, 0.15), h: R.range(5, 11), r: R.range(0.85, 1.12), shed: false }));
  let t = 0, burst = false;
  const crownR = () => 6 + CROWN * ease.outCubic(clamp(t / 0.2));
  const crownH = () => 8 * Math.sin(Math.PI * clamp(t / CROWN_T));
  const spikeK = () => Math.sin(Math.PI * Math.pow(clamp((t - 0.015) / CROWN_T), 0.6));
  const tipOf = (s) => {
    const r = crownR() * s.r, h = crownH(), sn = Math.sin(s.a), sh = s.h * spikeK();
    const bx = Math.cos(s.a) * r, by = sn * r * F - h * (0.75 + 0.25 * Math.abs(sn));
    return [bx, by, bx + Math.cos(s.a) * sh * 0.5, by + sn * sh * 0.3 - sh];
  };
  const steam = (x, y, big) => wisps.push({ x, y, t0: t, life: Math.min(R.range(0.45, 0.8) * (big ? 1.3 : 1), meta.duration - 0.05 - t), rise: R.range(22, 34), len: R.range(5, 10) * (big ? 1.4 : 1), amp: R.range(1, 2.5), k: R.range(0.35, 0.6), ph: R.range(0, TAU), drift: R.range(-4, 4) });
  const throwDrop = (x, y, z, a, sp, up, s) => drops.push({ x, y, z, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * F, vz: up, s });

  // la pared de la corona: un vaso fino que sube alrededor del golpe, con el borde brillante; "back", la mitad de atrás
  const crown = (p, back) => {
    if (t > CROWN_T) return;
    const r = crownR(), h = crownH(), ry = r * F;
    for (let x = Math.floor(-r); x <= Math.ceil(r); x++) {
      const c = (x + 0.5) / r;
      if (Math.abs(c) > 1) continue;
      const e = Math.sqrt(1 - c * c), yb = (back ? -ry : ry) * e, hh = h * (0.75 + 0.25 * e);
      for (let y = Math.floor(yb - hh); y <= Math.round(yb); y++) {
        const rim = y === Math.floor(yb - hh);
        if (rim) p.px(x, y, back ? C[5] : c < 0.1 ? C[7] : C[6]);
        else p.blend(x, y, C[(c < -0.25 ? 5 : c > 0.45 ? 3 : 4) - (back ? 1 : 0)], back ? 0.55 : 0.75);
      }
    }
    for (const s of spikes) {
      if (Math.sin(s.a) < 0 !== back) continue;
      const [bx, by, tx, ty] = tipOf(s);
      p.line(bx, by, tx, ty, back ? C[4] : C[6]);
      p.line(bx + 1, by, (bx + tx) / 2 + 0.5, (by + ty) / 2, back ? C[3] : C[5]);
      if (!s.shed) p.px(tx, ty - 1, back ? C[5] : C[7]), p.px(tx + 1, ty - 1, C[5]);
    }
  };

  // una gota en el aire: su sombra en el suelo, una estela corta y la cabeza brillante
  const drawDrop = (p, d) => {
    const sx = d.x, sy = d.y - d.z, sp = Math.hypot(d.vx, d.vy - d.vz) || 1, ux = d.vx / sp, uy = (d.vy - d.vz) / sp, len = Math.min(5, 0.5 + sp * 0.012);
    p.dot(d.x, d.y, C[0], 0.35);
    p.line(sx - ux * len, sy - uy * len, sx - ux, sy - uy, C[4]);
    p.px(sx, sy, C[7]);
    if (d.s > 1) p.px(sx - ux, sy - uy, C[6]), p.px(sx + 1, sy, C[5]);
    p.glow(sx, sy, 3 + d.s * 1.5, C[6], 0.3);
  };

  return {
    update(dt) {
      t += dt;
      if (!burst) {
        burst = true;
        // el reventón: gotas gordas a todos lados, salen de la tripa
        for (let i = 0; i < 34; i++) throwDrop(R.range(-4, 4), R.range(-2, 2), BODY, R.range(0, TAU), R.range(40, 150), R.range(60, 200), R.chance(0.35) ? 2 : 1);
        for (let i = 0; i < 6; i++) steam(R.range(-12, 12), -R.range(2, 6), true);
      }
      // las perlas se sueltan de las púas cuando llegan arriba
      for (const s of spikes)
        if (!s.shed && t > 0.1) {
          s.shed = true;
          const [, , tx, ty] = tipOf(s), gy = Math.sin(s.a) * crownR() * s.r * F;
          throwDrop(tx, gy, gy - ty, s.a, R.range(30, 80), R.range(40, 110), R.chance(0.4) ? 2 : 1);
        }
      for (let i = drops.length - 1; i >= 0; i--) {
        const d = drops[i], drag = 0.6 / d.s;
        d.vz -= G * dt;
        d.vx -= d.vx * drag * dt;
        d.vy -= d.vy * drag * dt;
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.z += d.vz * dt;
        if (d.z <= 0) {
          // al caer: una manchita redonda que quema y chisporrotea, con su hilo de vapor
          stains.push({ x: d.x, y: d.y, t0: t, w: d.s * 1.1 + R.range(0.4, 1.4) });
          if (R.chance(0.5)) steam(d.x, d.y - 1, false);
          drops.splice(i, 1);
        }
      }
      if (t > 0.2 && t < 1.0 && R.chance(dt * 9)) {
        const a = R.range(0, TAU), r = Math.sqrt(R.range(0, 1)) * CROWN * 1.1;
        steam(Math.cos(a) * r, Math.sin(a) * r * F, R.chance(0.3));
      }
      for (let i = wisps.length - 1; i >= 0; i--) if (t - wisps[i].t0 > wisps[i].life) wisps.splice(i, 1);
    },
    drawBack(p) {
      const fade = 1 - smooth(meta.duration - 0.5, meta.duration - 0.05, t);
      // las manchitas donde han caído gotas: brillan al caer y se oscurecen
      for (const s of stains) {
        const age = t - s.t0, c = age < 0.12 ? C[7] : age < 0.4 ? C[6] : age < 0.8 ? C[4] : C[3];
        const w = Math.ceil(s.w);
        for (let y = -w; y <= w; y++)
          for (let x = -w - 1; x <= w + 1; x++) {
            const d = Math.hypot(x / (s.w + 0.6), y / Math.max(0.6, s.w * F));
            if (d > 1) continue;
            p.dot(s.x + x, s.y + y, d > 0.6 ? SCORCH : c, fade * (d > 0.6 ? 0.7 : 1));
          }
        if (age < 0.4) p.glow(s.x, s.y, 5, C[5], 0.3 * (1 - age / 0.4));
      }
      crown(p, true);
      // las gotas que van por detrás de la corona (las de arriba en la pantalla)
      for (const d of drops) if (d.y < 0) drawDrop(p, d);
    },
    draw(p) {
      // el fogonazo del reventón, en la tripa
      if (t < 0.12) {
        const k = 1 - t / 0.12;
        p.glow(0, -BODY, 26 * k + 6, C[6], 0.7 * k);
        p.light(0, -BODY, WHITE, k);
      }
      crown(p, false);
      for (const d of drops) if (d.y >= 0) drawDrop(p, d);
      for (const q of wisps) wisp(p, q, t, STEAM);
    },
  };
}
