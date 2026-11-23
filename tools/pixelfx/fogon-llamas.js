// Un cuadro de los fogones en damero del cocinero (fogones_damero.gd) cuando quema, visto desde arriba: la plancha se
// pone al rojo de golpe, brotan lenguas de fuego por todo el cuadro (de 64×64 píxeles del dibujo, 4×4 casillas), suben
// llamaradas, chispas y brasas, y al final se apagan dejando la plancha oscureciéndose. Todo va en el suelo (la hoja de
// detrás): Johnny se ve encima si no ha salido a tiempo.
// Origen: el centro del cuadro. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, clamp, smooth, ease, noise, rand, mix, WHITE, rgb } from "../../core/index.js";
import { hotFirst, flameTongue, simDraw, BIG_LAYERS, BACK_LAYERS } from "../fire/_lib.js";

export const meta = {
  name: "Fogón en llamas",
  desc: "A square of floor seen from above turns red-hot and bursts into flame tongues all over, sparks and embers rise, then it dies down to a cooling plate.",
  tags: ["fire", "ground", "hazard", "one-shot"],
  size: [96, 124],
  origin: [48, 80],
  duration: 0.95,
  loop: false,
  fps: 20,
  bg: "ground",
  options: {
    palette: ["#1f0b10", "#4a1118", "#8c1d1c", "#cc3a1a", "#f2701f", "#ffae35", "#ffe27a", "#fff8d6"],
    seed: 4,
  },
};

const MEDIO = 32;                     // medio lado del cuadro
const SUBE = 0.06, BAJA = 0.62;       // cuándo están las llamas arriba del todo y cuándo empiezan a apagarse
const WARM = rgb(255, 150, 70);
const BRASA = [[1, 1, 7], [0.7, 0.8, 6], [0.4, 0.55, 5]];

export function create(o) {
  const F = fit(o.palette, 8), H = hotFirst(F), R = new Rng(o.seed), S = o.seed * 13;
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [H[0], H[1], H[3], H[4]] }), lights = new Lights();
  // las lenguas: una por cada hueco de una rejilla de 4×4, movida al azar dentro de él; unas grandes y otras pequeñas,
  // cada una con su retraso (para que no parezcan velas en fila)
  const sitios = [];
  for (let j = 0; j < 4; j++)
    for (let i = 0; i < 4; i++) {
      const x = -MEDIO + 8 + i * 16 + R.range(-5, 5), y = -MEDIO + 10 + j * 15 + R.range(-4, 4), g = R.next();
      sitios.push({ x, y, h: 14 + g * 16, w: 4.6 + g * 3.4, t0: R.range(0, 0.1), fin: BAJA + R.range(-0.12, 0.15), n: R.int(0, 1e5) });
    }
  // y unas pocas pequeñitas entre medias
  for (let i = 0; i < 7; i++)
    sitios.push({ x: R.range(-MEDIO + 4, MEDIO - 4), y: R.range(-MEDIO + 6, MEDIO - 3), h: R.range(7, 11), w: R.range(2.8, 3.8),
      t0: R.range(0.02, 0.15), fin: BAJA + R.range(-0.2, 0.05), n: R.int(0, 1e5) });
  sitios.sort((a, b) => a.y - b.y);
  let t = 0, golpe = false;

  // lo caliente que está la plancha (0 fría, 1 al rojo)
  const calor = () => ease.outCubic(clamp(t / 0.08)) * (1 - smooth(BAJA, meta.duration, t) * 0.85);

  const plancha = (p) => {
    const k = calor(), fin = 1 - smooth(meta.duration - 0.2, meta.duration, t);
    if (k <= 0 || fin <= 0) return;
    for (let y = -MEDIO; y < MEDIO; y++)
      for (let x = -MEDIO; x < MEDIO; x++) {
        // del borde (más oscuro) al centro (más claro), con vetas de ruido que se mueven
        const borde = Math.min(x + MEDIO, MEDIO - 1 - x, y + MEDIO, MEDIO - 1 - y);
        const v = 0.55 * noise(x * 0.13 + t * 2.2, S + Math.floor(y / 3)) + 0.45 * rand(Math.floor(x / 2), Math.floor(y / 2), S);
        const q = k * (0.45 + 0.4 * Math.min(1, borde / 10) + 0.25 * v);
        if (borde < 1) { p.blend(x, y, H[7], 0.9 * fin); continue; }   // el canto de la plancha
        const c = q > 1.0 ? H[4] : q > 0.82 ? H[5] : q > 0.6 ? H[6] : H[7];
        p.blend(x, y, c, Math.min(0.85, 0.2 + q * 0.6) * fin);
      }
    p.glow(0, 0, 44, mix(H[4], WHITE, 0.1), 0.35 * k);
  };

  const llamas = (p) => {
    const NZ = (rate, seed = 0, off = 0) => noise(t * rate + off, seed);
    for (const s of sitios) {
      const age = t - s.t0;
      if (age < 0) continue;
      const sube = ease.outBack(clamp(age / SUBE), 1.8), baja = 1 - ease.inQuad(clamp((t - s.fin) / (meta.duration - 0.05 - s.fin)));
      const h = s.h * sube * baja * (0.8 + 0.2 * noise(t * 5, s.n)) * (1 + 0.45 * Math.max(0, noise(t * 3.1, s.n + 70) - 0.5));
      if (h < 1) continue;
      const L = baja > 0.75 ? BIG_LAYERS : baja > 0.4 ? BACK_LAYERS : BRASA;
      flameTongue(p, s.x, s.y, h, s.w * (0.55 + 0.45 * baja), NZ(2.4, s.n + 40) * 1.6, NZ, s.n, H, L);
    }
  };

  return {
    update(dt) {
      t += dt;
      if (!golpe) {
        golpe = true;
        lights.add(0, -8, 60, WARM, 0.9, 0.7);
        lights.add(0, -4, 34, WHITE, 0.6, 0.08);
        // el primer bufido: chispas que saltan desde todo el cuadro
        for (let i = 0; i < 22; i++)
          ps.spawn(P.SPARK, R.range(-MEDIO, MEDIO), R.range(-MEDIO, MEDIO), R.range(-50, 50), -R.range(90, 200), R.range(0.25, 0.5));
      }
      // mientras arde: bocanadas que suben de las lenguas y algunas brasas
      if (t < BAJA - 0.05)
        for (let i = 0; i < 3; i++) {
          if (!R.chance(0.7 * dt * 60)) continue;
          const s = R.pick(sitios);
          ps.spawn(P.FIRE, s.x + R.range(-1.5, 1.5), s.y - s.h * 0.7, R.range(-6, 6), -R.range(25, 45), R.range(0.18, 0.32), 0,
            R.range(1.8, 3.2), 0);
          if (R.chance(0.2)) ps.spawn(P.EMBER, s.x, s.y - s.h * 0.4, R.range(-18, 18), -R.range(30, 80), R.range(0.3, 0.55), H[3], 1);
        }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      plancha(p);
      llamas(p);
      simDraw(p, ps, H, "back");
      simDraw(p, ps, H, "front");
      lights.draw(p);
    },
    draw() {},
  };
}
