// El hielo que revienta al descongelarse un zombi (zombi.gd: cuando se le acaba el congelado, o si muere congelado),
// visto desde arriba. Hecho para el juego con la idea del "ice-shatter" de pixelfx (un bloque de hielo que se agrieta,
// destella y revienta en trozos que ruedan y resbalan entre polvo de hielo):
//  - unas grietas blancas que corren un instante por donde está el cuerpo y un destello;
//  - trozos de hielo de varios tamaños que saltan hacia todos lados, cada uno con su altura (z): caen en su sitio del
//    suelo, rebotan, resbalan frenando y se funden;
//  - polvo de hielo y unas astillas finas.
// El origen es el suelo, debajo del zombi; el cuerpo va "height" píxeles más arriba. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, clamp, ease, rng, TAU, WHITE, hex } from "../../core/index.js";

export const meta = {
  name: "Deshielo",
  desc: "A frozen body bursts free, seen from above: cracks race over it and flash, then ice chunks fly out, land, bounce, skid and melt in a puff of ice dust.",
  tags: ["ice", "shatter", "break", "one-shot"],
  size: [112, 100],
  origin: [56, 62],
  duration: 0.9,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#151a3d", "#212f6b", "#2c58aa", "#3a8bd8", "#62c8f4", "#a6ecff", "#dcfbff", "#ffffff"], height: 16, seed: 5 },
};

const VISTA = 0.6, GRIETA = 0.08;

export function create(o) {
  const C = fit(o.palette, 8), CH = C.map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed), H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [C[7], C[6], C[5], C[4]], haze: C[6] }), lights = new Lights();
  const trozos = [];
  let t = 0, roto = false;
  // las grietas: rayas que salen del centro del cuerpo
  const grietas = Array.from({ length: 6 }, (_, i) => {
    const a = (i / 6) * TAU + R.range(-0.4, 0.4), pts = [[0, -H]];
    let x = 0, y = -H, an = a;
    for (let s = 0; s < R.range(6, 11); s++) {
      an += R.range(-0.5, 0.5);
      x += Math.cos(an) * 1.5;
      y += Math.sin(an) * 1.5 * 1.3;
      pts.push([x, y]);
    }
    return pts;
  });
  return {
    update(dt) {
      t += dt;
      if (!roto && t >= GRIETA) {
        roto = true;
        lights.add(0, -H, 40, C[5], 0.7, 0.3);
        // los trozos: salen del cuerpo (a varias alturas) hacia todos lados
        for (let i = 0; i < 16; i++) {
          const a = R.range(0, TAU), sp = R.range(40, 130), z = R.range(H * 0.3, H * 1.4);
          trozos.push({ x: R.range(-4, 4), y: R.range(-2, 2), z, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA, vz: R.range(20, 90),
            giro: R.range(0, TAU), vgiro: R.range(-14, 14), w: R.range(1.5, 4), h: R.range(1.2, 2.6), c: R.pick([CH[5], CH[6], CH[6], CH[5]]), vida: R.range(0.55, 0.8) });
        }
        for (let i = 0; i < 8; i++) {
          const a = R.range(0, TAU), sp = R.range(20, 60);
          ps.spawn(P.VAPOUR, Math.cos(a) * 3, -H * R.range(0.3, 1), Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 6, R.range(0.3, 0.5), R.chance(0.6) ? C[6] : C[5], R.range(2.5, 4.5));
        }
        for (let i = 0; i < 10; i++) {
          const a = R.range(0, TAU), sp = R.range(90, 180);
          ps.spawn(P.SPARK, 0, -H, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 40, R.range(0.12, 0.25));
        }
      }
      for (let i = trozos.length - 1; i >= 0; i--) {
        const g = trozos[i];
        if ((g.vida -= dt) <= 0) {
          trozos.splice(i, 1);
          continue;
        }
        g.vz -= 520 * dt;
        g.z += g.vz * dt;
        if (g.z <= 0) {
          if (g.vz < -70) ps.spawn(P.VAPOUR, g.x, g.y, g.vx * 0.2, -4, R.range(0.2, 0.35), C[6], R.range(1.5, 2.5));
          g.z = 0;
          g.vz = g.vz < -60 ? -g.vz * 0.3 : 0;
          g.vx *= 0.7; g.vy *= 0.7; g.vgiro *= 0.5;
        }
        const roce = g.z > 0 ? 0.5 : 4;
        g.vx -= g.vx * roce * dt; g.vy -= g.vy * roce * dt;
        g.x += g.vx * dt; g.y += g.vy * dt; g.giro += g.vgiro * dt;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      ps.draw(p, "back");
    },
    draw(p) {
      // las grietas corren por el cuerpo y destellan
      if (t < GRIETA + 0.06) {
        const k = clamp(t / GRIETA);
        for (const g of grietas) {
          const n = Math.max(2, Math.ceil(g.length * ease.outCubic(k)));
          for (let i = 1; i < n; i++) p.line(g[i - 1][0], g[i - 1][1], g[i][0], g[i][1], t < GRIETA ? WHITE : C[6], 1);
        }
        if (t >= GRIETA - 0.03) p.glow(0, -H, 16, WHITE, 0.6);
      }
      if (t >= GRIETA && t < GRIETA + 0.15) p.glow(0, -H, 26, C[5], 0.5 * (1 - (t - GRIETA) / 0.15));
      // los trozos: un pedazo girado, con su borde oscuro y su lado claro; su sombra mientras vuelan
      for (const g of trozos) {
        const al = Math.min(1, g.vida / 0.25), ca = Math.cos(g.giro), sa = Math.sin(g.giro), y0 = g.y - g.z;
        if (g.z > 1) p.dot(g.x, g.y, CH[1], 0.35 * al);
        for (let u = -g.w / 2; u <= g.w / 2; u += 0.5)
          for (let v = -g.h / 2; v <= g.h / 2; v += 0.5) {
            const borde = g.w > 2.5 && (Math.abs(u) > g.w / 2 - 0.6 || Math.abs(v) > g.h / 2 - 0.6), luz = u + v < -g.w * 0.2;
            p.dot(g.x + ca * u - sa * v, y0 + sa * u + ca * v, borde ? CH[4] : luz ? WHITE : g.c, al);
          }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
