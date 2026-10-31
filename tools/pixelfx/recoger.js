// El destello al recoger algo del suelo (M53; billete.gd: los billetes, los lanzables, los objetos, las armas y la
// munición), visto desde arriba: una estrellita de cuatro puntas que se abre y se cierra, un anillito en el suelo y unas
// chispitas que suben. Pequeño y rápido, porque se cogen muchos. Dorado y blanco, que vale para todo.
// "height": a qué altura está la cosa. El origen es el suelo. Lo exporta exportar.mjs.
import { Particles, P, Rng, fit, band, clamp, ease, sparkle, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Recoger",
  desc: "A pickup glint seen from above: a four-point star opens and shuts, a tiny ring on the floor and a few motes float up.",
  tags: ["pickup", "collect", "sparkle", "one-shot"],
  size: [48, 48],
  origin: [24, 32],
  duration: 0.4,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#3a2a08", "#8a5a10", "#d89a20", "#ffd23f", "#ffec8a", "#fff8d6"], height: 6, seed: 3 },
};

const VISTA = 0.6;

export function create(o) {
  const C = fit(o.palette, 6), R = new Rng(o.seed), H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999 });
  for (let i = 0; i < 5; i++) {
    const a = R.range(0, TAU);
    ps.spawn(P.MOTE, Math.cos(a) * 3, -H + Math.sin(a) * 2, Math.cos(a) * R.range(5, 15), -R.range(25, 45), R.range(0.25, 0.38), R.pick([C[4], C[5], WHITE]), 1);
  }
  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
    },
    drawBack(p) {
      // el anillito en el suelo
      const u = clamp(t / 0.25);
      if (u < 1) band(p, 0, 0, 2 + 8 * ease.outCubic(u), VISTA, 1.5, 1 - u, C);
    },
    draw(p) {
      // la estrellita: se abre de golpe y se cierra
      const u = clamp(t / 0.22);
      if (u < 1) {
        const L = 7 * Math.sin(u * Math.PI);
        sparkle(p, 0, -H, L, WHITE, C[3]);
        p.glow(0, -H, 6 + L, C[4], 0.5 * (1 - u));
      }
      ps.draw(p, "front");
    },
  };
}
