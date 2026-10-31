// La curación de la médica sobre Johnny (M56; aliado.gd, curar), vista desde arriba: un brillo verde que le envuelve,
// crucecitas que suben y se apagan, chispitas y un anillo que se abre por el suelo a sus pies. Va de hijo de Johnny, para
// que le siga. "height": lo alto del cuerpo. El origen es el suelo, a sus pies. Lo exporta exportar.mjs.
import { Particles, P, Rng, fit, band, clamp, ease, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Curación",
  desc: "A healing glow seen from above: green light wraps the body, little crosses float up and fade, motes sparkle and a ring opens on the floor.",
  tags: ["heal", "buff", "holy", "one-shot"],
  size: [80, 96],
  origin: [40, 76],
  duration: 0.9,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#0c2a12", "#1a5a26", "#2f9a40", "#57d468", "#9cf2a4", "#e2ffe4"], height: 24, seed: 4 },
};

const VISTA = 0.6;

export function create(o) {
  const C = fit(o.palette, 6), R = new Rng(o.seed), H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999 });
  // las crucecitas: salen alrededor del cuerpo, una detrás de otra, y suben
  const cruces = Array.from({ length: 6 }, (_, i) => ({ x: R.range(-10, 10), y: -R.range(4, H), t0: i * 0.08 + R.range(0, 0.04), v: R.range(18, 30), s: R.chance(0.5) ? 2 : 1 }));
  for (let i = 0; i < 10; i++)
    ps.spawn(P.MOTE, R.range(-10, 10), -R.range(0, H), R.range(-6, 6), -R.range(15, 35), R.range(0.4, 0.7), R.pick([C[4], C[5], WHITE]), 1, R.range(0, 0.3));
  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
    },
    drawBack(p) {
      // el anillo a sus pies
      const u = clamp(t / 0.45);
      if (u < 1) band(p, 0, 0, 4 + 18 * ease.outCubic(u), VISTA, 2, 1 - u, C);
    },
    draw(p) {
      // el brillo verde que le envuelve, de golpe y luego se apaga
      const k = t < 0.1 ? t / 0.1 : 1 - clamp((t - 0.1) / 0.6);
      p.glow(0, -H * 0.55, 18, C[3], 0.45 * k);
      // las crucecitas
      for (const c of cruces) {
        const u = (t - c.t0) / 0.55;
        if (u < 0 || u > 1) continue;
        const x = Math.round(c.x), y = Math.round(c.y - u * c.v), a = u < 0.7 ? 1 : 1 - (u - 0.7) / 0.3, n = c.s;
        for (let d = -n; d <= n; d++) {
          p.dot(x + d, y, d === 0 ? WHITE : C[4], a);
          p.dot(x, y + d, d === 0 ? WHITE : C[4], a);
        }
        for (const [dx, dy] of [[-n - 1, 0], [n + 1, 0], [0, -n - 1], [0, n + 1]]) p.dot(x + dx, y + dy, C[2], a * 0.8);
      }
      ps.draw(p, "front");
    },
  };
}
