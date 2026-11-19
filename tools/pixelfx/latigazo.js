// El chasquido de un latigazo contra el suelo (lenguas del Glotón y de la criatura; tentáculos), visto desde arriba. Hecho
// para el juego con la idea del "dirt-explosion" de pixelfx, en pequeño (golpe-suelo.js), más babas:
//  - un destello blanco en forma de estrella de cuatro puntas, un instante (el restallido);
//  - una onda pequeña que se abre por el suelo en elipse, levantando un poco de polvo;
//  - gotas de baba que saltan, cada una con su altura (z), caen y dejan una manchita que se borra;
//  - un par de grietas cortas.
// "drops": la paleta de las babas (oscuro a claro) · "reach": hasta dónde llega la onda · "count": cuántas gotas. El
// origen es el suelo, donde pega la punta. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, band, clamp, smooth, ease, TAU, WHITE, hex } from "../../core/index.js";

export const meta = {
  name: "Latigazo",
  desc: "A whip or tongue cracking on the floor seen from above: a white four-point snap, a small dust ring, spit drops that hop and splat, short cracks.",
  tags: ["impact", "whip", "slime", "dust", "one-shot"],
  size: [110, 70],
  origin: [55, 38],
  duration: 0.65,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#1a1410", "#3a2e24", "#7a6a58", "#a8987e", "#cfc2a6", "#ebe2cc", "#fffaf0"],
    drops: ["#25100e", "#7f2b26", "#b7463a", "#e98a78", "#ffd6cc"], reach: 26, count: 12, seed: 3 },
};

const VISTA = 0.6, ABRE = 0.22;

export function create(o) {
  const C = fit(o.palette, 7), D = o.drops.map(hex), R = new Rng(o.seed);
  const ps = new Particles({ rng: R, ground: () => 999 }), lights = new Lights();
  const frente = (t) => o.reach * ease.outCubic(clamp(t / ABRE));
  const grietas = Array.from({ length: 3 }, (_, i) => {
    const pts = [[0, 0]];
    let x = 0, y = 0, a = (i / 3) * TAU + R.range(-0.5, 0.5);
    for (let d = 0; d < R.range(8, 14); d += 2) {
      a += R.range(-0.5, 0.5);
      x += Math.cos(a) * 2; y += Math.sin(a) * 2 * VISTA;
      pts.push([x, y]);
    }
    return pts;
  });
  const gotas = Array.from({ length: o.count }, () => {
    const a = R.range(0, TAU), sp = R.range(70, 150);
    return { x: R.range(-2, 2), y: R.range(-1, 1), z: R.range(1, 4), vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA,
      vz: R.range(35, 75), r: R.pick([1, 1, 1.5, 2]), mancha: 0, vida: R.range(0.5, 0.64) };
  });
  for (let i = 0; i < 9; i++) {
    const a = R.range(0, TAU), sp = R.range(15, 45);
    ps.spawn(P.DUST, Math.cos(a) * 3, Math.sin(a) * 2, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - R.range(3, 10),
      R.range(0.35, 0.55), R.pick([C[4], C[5], C[5], C[6]]), R.range(3, 5));
  }
  lights.add(0, 0, 22, C[6], 0.3, 0.1);
  let t = 0;
  return {
    update(dt) {
      t += dt;
      for (const g of gotas) {
        if (g.z > 0) {
          g.vz -= 760 * dt;
          g.z += g.vz * dt;
          g.x += g.vx * dt; g.y += g.vy * dt;
          if (g.z <= 0) { g.z = 0; g.mancha = t; }
        }
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      const va = 1 - smooth(0.35, 0.65, t);
      if (va > 0)
        for (const g of grietas) {
          const n = Math.max(2, Math.ceil(g.length * ease.outCubic(clamp(t / 0.06))));
          for (let i = 1; i < n; i++) p.line(g[i - 1][0], g[i - 1][1], g[i][0], g[i][1], hex(C[0]), va * 0.8);
        }
      // las manchas de las gotas que han caído
      for (const g of gotas) {
        if (g.z > 0 || t > g.vida) continue;
        const k = 1 - smooth(g.vida - 0.15, g.vida, t);
        p.disc(g.x, g.y, g.r + 0.5, D[1], 0.85 * k);
        if (g.r > 1) p.dot(g.x - 0.5, g.y - 0.5, D[3], k);
      }
      if (t < ABRE + 0.08) {
        const u = clamp(t / (ABRE + 0.08));
        band(p, 0, 0, frente(t) + 1, VISTA, Math.max(1.5, 4 * (1 - u)), (u < 0.6 ? 1 : (1 - u) / 0.4) * 0.7, C.slice(0, 5), (g) => Math.sin(g) < 0);
      }
      ps.draw(p, "back");
    },
    draw(p) {
      if (t < ABRE + 0.08) {
        const u = clamp(t / (ABRE + 0.08));
        band(p, 0, 0, frente(t) + 1, VISTA, Math.max(1.5, 4 * (1 - u)), (u < 0.6 ? 1 : (1 - u) / 0.4) * 0.7, C.slice(0, 5), (g) => Math.sin(g) >= 0);
      }
      // las gotas en el aire: con contorno, su sombra en el suelo
      for (const g of gotas) {
        if (g.z <= 0) continue;
        p.dot(g.x, g.y, D[0], 0.35);
        p.disc(g.x, g.y - g.z, g.r + 0.6, D[0], 1);
        p.disc(g.x, g.y - g.z, g.r, D[2], 1);
        p.dot(g.x - 0.4, g.y - g.z - 0.4, D[4], 1);
      }
      ps.draw(p, "front");
      // el restallido: una estrella blanca de cuatro puntas, dos o tres fotogramas
      if (t < 0.1) {
        const k = 1 - t / 0.1, L = Math.round(4 + 10 * k);
        for (let i = -L; i <= L; i++) {
          const w = Math.abs(i) < L * 0.35 ? 1 : 0;
          for (let j = -w; j <= w; j++) {
            p.dot(i, j, WHITE, 1);
            p.dot(j, Math.round(i * VISTA), WHITE, 1);
          }
        }
        p.disc(0, 0, 2 + 2 * k, WHITE, 1);
        p.glow(0, 0, 12, WHITE, 0.35 * k);
      }
      lights.draw(p);
    },
  };
}
