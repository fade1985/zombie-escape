// El reventón de sangre de un zombi que muere de un golpe fuerte (M49: un crítico, una explosión o un golpe que le sobra
// mucho; partida.sangre), visto desde arriba. Un golpe de luz oscura, una nube de sangre que se abre y se deshace, y gotas
// gordas que salen en corona: cada una vuela con su altura (z), cae en su sitio del suelo (no en una raya, como el suelo de
// pixelfx, y = 0), salpica y se queda un momento antes de secarse (la mancha que queda la pone el juego: mancha.gd).
// "palette": la sangre, de oscura a clara (roja; reventon-sangre-verde.js y -morada.js cambian solo eso). Lo exporta
// exportar.mjs, una vez por color.
import { Particles, P, Rng, fit, sparkle, ease, TAU, hex, mix, WHITE } from "../../core/index.js";

export const meta = {
  name: "Reventón de sangre",
  desc: "A zombie bursts on a heavy hit, seen from above: a dark pop, a cloud of blood that opens and thins, and fat drops thrown out in a crown that land, splat and dry.",
  tags: ["blood", "impact", "death", "one-shot"],
  size: [200, 150],
  origin: [100, 100],
  duration: 1.2,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#2a0a0c", "#4e1014", "#7a1f1a", "#a8302a", "#d4554a"], size: 1, seed: 5 },
};

const VISTA = 0.6;   // lo de arriba abajo, más corto: el suelo visto desde arriba

export function create(o) {
  const C = fit(o.palette, 5).map(hex), S = o.size, R = new Rng(o.seed);
  const ps = new Particles({ rng: R, ground: () => 999 });
  const gotas = [], charcos = [];
  let t = 0;
  // la nube de sangre: bocanadas que se abren desde el cuerpo y se deshacen
  for (let i = 0; i < 14; i++) {
    const a = R.range(0, TAU), sp = R.range(30, 80) * S;
    ps.spawn(P.DUST, Math.cos(a) * 3, -16 + Math.sin(a) * 3, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 10,
      R.range(0.3, 0.55), R.pick([C[1], C[2], C[2], C[3]]), R.range(3, 6) * S);
  }
  // el estallido: chorros que salen del cuerpo en corona, un instante
  const chorros = Array.from({ length: 9 }, (_, i) => ({ a: (i / 9) * TAU + R.range(-0.25, 0.25), largo: R.range(10, 18) * S }));
  // las gotas: salen en corona desde el cuerpo, cada una con su saltito
  for (let i = 0; i < 26; i++) {
    const a = R.range(0, TAU), sp = R.range(40, 150) * S;
    gotas.push({ x: Math.cos(a) * 3, y: Math.sin(a) * 2, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA,
      z: R.range(10, 22), vz: R.range(40, 140), s: R.range(1, 2.6) * S, c: R.pick([C[2], C[3], C[3], C[4]]) });
  }
  // unas pocas, finas y rápidas, que salen más lejos
  for (let i = 0; i < 14; i++) {
    const a = R.range(0, TAU), sp = R.range(150, 240) * S;
    gotas.push({ x: 0, y: 0, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA, z: R.range(12, 20), vz: R.range(20, 80),
      s: 0.8, c: C[3] });
  }

  return {
    update(dt) {
      t += dt;
      for (let i = gotas.length - 1; i >= 0; i--) {
        const g = gotas[i];
        g.vz -= 600 * dt;
        g.z += g.vz * dt;
        g.x += g.vx * dt; g.y += g.vy * dt;
        g.vx -= g.vx * 1.2 * dt; g.vy -= g.vy * 1.2 * dt;
        if (g.z <= 0) {
          // cae al suelo: salpica y se queda como una manchita, que se seca
          charcos.push({ x: g.x, y: g.y, r: g.s * R.range(1.1, 1.6), c: g.c, t0: t, dx: g.vx * 0.03, dy: g.vy * 0.03 });
          gotas.splice(i, 1);
        }
      }
      ps.update(dt);
    },
    drawBack(p) {
      // las manchitas del suelo, que se secan antes de acabar (la mancha grande la pone el juego)
      for (const m of charcos) {
        const k = Math.min(1, (t - m.t0) / 0.06), seca = 1 - ease.inQuad(Math.min(1, Math.max(0, (t - 0.65) / 0.5)));
        if (seca <= 0) continue;
        const r = m.r * (0.6 + 0.4 * k);
        p.ellipse(m.x, m.y, r * 1.2, r * 0.75, mix(m.c, C[0], 0.35), seca);
        p.ellipse(m.x + m.dx, m.y + m.dy, r * 0.7, r * 0.45, m.c, seca);
        p.dot(m.x - r * 0.3, m.y - r * 0.25, mix(m.c, WHITE, 0.35), seca * 0.8);
      }
    },
    draw(p) {
      // el golpe: un destello oscuro, rojo, un instante
      if (t < 0.08) sparkle(p, 0, -16, 12 * S * (1 - ease.outCubic(t / 0.08)), C[4], C[2]);
      if (t < 0.18) {
        const k = ease.outCubic(t / 0.18), fin = 1 - t / 0.18;
        for (const ch of chorros)
          for (let d = 0; d <= ch.largo * k; d += 1.5) {
            const r = (1 - d / ch.largo) * 2.6 * S * fin + 0.6;
            p.circle(Math.cos(ch.a) * d, -16 + Math.sin(ch.a) * d * VISTA, r, d < ch.largo * k - 3 ? C[2] : C[3], 1);
          }
        p.circle(0, -16, 5 * S * fin + 1, C[1], 1);
      }
      ps.draw(p, "front");
      // las gotas en el aire, con su sombrita en el suelo
      for (const g of gotas) {
        if (g.z > 2) p.dot(g.x, g.y, C[0], 0.35);
        const y = g.y - g.z;
        if (g.s >= 1.6) p.circle(g.x, y, g.s, g.c, 1);
        else p.dot(g.x, y, g.c, 1);
        p.dot(g.x - g.s * 0.3, y - g.s * 0.3, mix(g.c, WHITE, 0.3), 0.9);
      }
    },
  };
}
