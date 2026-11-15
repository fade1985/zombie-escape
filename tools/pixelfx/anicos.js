// Un zombi congelado que muere de un golpe revienta en añicos (zombi.reventar_hielo), visto desde arriba. Hecho para el
// juego con la idea del final del "ice/freeze" y del "spawn/shatter-death" de pixelfx:
//  - el bloque de hielo (el mismo de bloque-hielo.js) se pone blanco y se agrieta un instante;
//  - revienta: sus caras salen volando dando vueltas, cada una con su altura (z), caen en su sitio del suelo, rebotan,
//    resbalan frenando y se funden; con ellas, trozos del zombi helado (gris verdoso con escarcha);
//  - un destello, un anillo de polvo de hielo que se abre por el suelo, copos y chispas.
// El agua que queda es aparte (charco.gd, "deshielo"). El origen son los pies del zombi. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, flare, clamp, ease, rand, TAU, WHITE, hex } from "../../core/index.js";
import { splitPoly, centroid } from "../ice/_lib.js";

export const meta = {
  name: "Añicos",
  desc: "A frozen zombie is struck dead and bursts, seen from above: its ice block flashes white and cracks, then panes and frozen chunks fly out tumbling, land, bounce, skid and melt amid a ring of ice dust.",
  tags: ["ice", "shatter", "death", "one-shot"],
  size: [150, 116],
  origin: [75, 80],
  duration: 1.2,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#151a3d", "#212f6b", "#2c58aa", "#3a8bd8", "#62c8f4", "#a6ecff", "#dcfbff", "#ffffff"], carne: ["#33433f", "#56685f", "#7d9089"], seed: 7 },
};

const VISTA = 0.55, GRIETA = 0.07, CORE = [0, -22];
const V = {
  l0: [-15, 0], l1: [-17, -10], l2: [-17, -31], p1: [-12, -45], n1: [-6, -42], p2: [0, -52], n2: [6, -43], p3: [12, -47], r2: [17, -30], r1: [16, -9], r0: [14, 0],
  i0: [-6, -36], i1: [6, -35], i2: [-9, -21], i3: [3, -25], i4: [9, -13], i5: [-5, -8], i6: [2, 0], i7: [0, -40],
};
const FACETS = [
  ["l0 l1 i5 i6", 0.62], ["i5 i4 i6", 0.42], ["i4 r2 r1 r0 i6", 0.2], ["l1 l2 i2 i5", 0.74], ["i2 i3 i4 i5", 0.5],
  ["i1 r2 i4 i3", 0.28], ["l2 i0 i2", 0.7], ["i0 i1 i3 i2", 0.58], ["n1 i7 n2 i1 i0", 0.52], ["i1 n2 p3 r2", 0.4],
  ["l2 p1 n1 i0", 0.88], ["p2 n2 i7", 0.66], ["n1 p2 i7", 1],
].map(([k, lit]) => ({ pts: k.split(" ").map((v) => V[v]), lit }));
const OUTLINE = "l0 l1 l2 p1 n1 p2 n2 p3 r2 r1 r0".split(" ").map((v) => V[v]);

export function create(o) {
  const C = fit(o.palette, 8), CH = C.map((c) => (typeof c === "string" ? hex(c) : c)), K = o.carne.map(hex), R = new Rng(o.seed);
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [C[7], C[6], C[5], C[4]], haze: C[6] }), lights = new Lights();
  const trozos = [];
  let t = 0, roto = false;
  // las grietas del instante blanco: desde el medio del cuerpo, quebradas
  const grietas = Array.from({ length: 7 }, (_, i) => {
    let x = CORE[0], y = CORE[1], an = (i / 7) * TAU + R.range(-0.3, 0.3);
    const pts = [[x, y]];
    for (let s = 0; s < R.int(5, 9); s++) {
      an += R.range(-0.5, 0.5);
      x += Math.cos(an) * 2.2;
      y += Math.sin(an) * 2.6;
      pts.push([x, y]);
    }
    return pts;
  });
  const chop = (pts, depth) => {
    const c = centroid(pts);
    return c.area < 22 || depth > 1 ? [pts] : splitPoly(pts, c.x, c.y, R.range(0, Math.PI)).flatMap((q) => chop(q, depth + 1));
  };
  const lanzar = (tr, mx, my, fuerza) => {
    // sale del cuerpo hacia fuera: en el suelo, lejos por los lados y menos hacia delante y atrás (VISTA)
    const a = Math.atan2(R.range(-1, 1), mx - CORE[0] || R.range(-1, 1)), sp = R.range(40, 115) * fuerza;
    Object.assign(tr, { x: mx * 0.8, y: R.range(-2, 2), z: -my, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA + R.range(-25, 25) * VISTA, vz: R.range(30, 110),
      giro: 0, vgiro: R.range(-12, 12), f: 0, vf: R.sign() * R.range(4, 12) });
    trozos.push(tr);
  };

  return {
    update(dt) {
      t += dt;
      if (!roto && t >= GRIETA) {
        roto = true;
        lights.add(CORE[0], CORE[1], 60, WHITE, 0.9, 0.12);
        lights.add(CORE[0], CORE[1], 70, C[4], 0.5, 0.5);
        // las caras del bloque, partidas en trozos
        for (const F of FACETS)
          for (const part of chop(F.pts, 0)) {
            const m = centroid(part);
            lanzar({ pts: part.map(([x, y]) => [x - m.x, y - m.y]), lit: F.lit, c: CH[3 + Math.round(F.lit * 3)], vida: R.range(0.75, 1.05) }, m.x, m.y, 1.2 - Math.min(0.5, m.area / 120));
          }
        // trozos del zombi helado
        for (let i = 0; i < 9; i++) {
          const w = R.range(2, 4.5), h = R.range(2, 3.5);
          const pts = [[-w / 2, -h / 2], [w / 2, -h / 2 + R.range(-0.5, 0.5)], [w / 2, h / 2], [-w / 2 + R.range(-0.5, 0.5), h / 2]];
          lanzar({ pts, carne: true, c: R.pick(K), vida: R.range(0.8, 1.1) }, R.range(-8, 8), -R.range(8, 42), 0.9);
        }
        // astillas finas, polvo de hielo que se abre por el suelo, copos y chispas
        for (let i = 0; i < 14; i++) {
          const a = R.range(0, TAU), w = R.range(0.8, 1.6);
          lanzar({ pts: [[-w, -0.6], [w, 0], [-w * 0.6, 0.7]], c: R.pick([CH[6], CH[7], CH[5]]), vida: R.range(0.45, 0.8) }, Math.cos(a) * 8, -R.range(6, 46), 1.5);
        }
        for (let i = 0; i < 16; i++) {
          const a = (i / 16) * TAU + R.range(-0.2, 0.2), sp = R.range(40, 75);
          ps.spawn(P.VAPOUR, Math.cos(a) * 6, Math.sin(a) * 6 * VISTA, Math.cos(a) * sp, Math.sin(a) * sp * VISTA, R.range(0.45, 0.75), R.chance(0.6) ? C[6] : C[5], R.range(2.5, 4.5));
        }
        for (let i = 0; i < 8; i++) ps.spawn(P.VAPOUR, R.range(-10, 10), -R.range(10, 40), R.range(-25, 25), -R.range(10, 25), R.range(0.4, 0.7), C[6], R.range(3, 5));
        for (let i = 0; i < 14; i++) {
          const a = R.range(-Math.PI, 0), sp = R.range(40, 120);
          ps.spawn(P.FLAKE, R.range(-10, 10), CORE[1] + R.range(-14, 14), Math.cos(a) * sp, Math.sin(a) * sp, R.range(0.7, 1.1), R.chance(0.6) ? WHITE : C[6], R.range(0.5, 1.4));
        }
        for (let i = 0; i < 10; i++) {
          const a = R.range(0, TAU), sp = R.range(100, 190);
          ps.spawn(P.SPARK, CORE[0], CORE[1], Math.cos(a) * sp, Math.sin(a) * sp * 0.8 - 40, R.range(0.12, 0.25));
        }
        for (let i = 0; i < 6; i++) ps.spawn(P.STAR, R.range(-24, 24), -R.range(4, 48), R.range(-10, 10), -R.range(4, 14), R.range(0.3, 0.6), R.chance(0.5) ? WHITE : C[6], R.range(1, 2.2));
      }
      for (let i = trozos.length - 1; i >= 0; i--) {
        const g = trozos[i];
        if ((g.vida -= dt) <= 0) {
          trozos.splice(i, 1);
          continue;
        }
        g.vz -= 560 * dt;
        g.z += g.vz * dt;
        if (g.z <= 0) {
          if (g.vz < -80) {
            ps.spawn(P.VAPOUR, g.x, g.y, g.vx * 0.2, -3, R.range(0.2, 0.35), C[6], R.range(1.5, 2.5));
            if (!g.carne && R.chance(0.3)) ps.spawn(P.STAR, g.x, g.y - 1, 0, -3, R.range(0.2, 0.35), WHITE, R.range(0.6, 1.4));
          }
          g.z = 0;
          g.vz = g.vz < -60 ? -g.vz * 0.3 : 0;
          g.vx *= 0.7; g.vy *= 0.7; g.vgiro *= 0.4; g.vf *= 0.3;
          if (g.vz === 0) g.f = Math.round(g.f / Math.PI) * Math.PI;   // (tumbado: plano en el suelo)
        }
        const roce = g.z > 0 ? 0.4 : 4;
        g.vx -= g.vx * roce * dt; g.vy -= g.vy * roce * dt;
        g.x += g.vx * dt; g.y += g.vy * dt; g.giro += g.vgiro * dt; g.f += g.vf * dt;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // un anillo de polvo de hielo que se abre por el suelo y se apaga
      if (t >= GRIETA) {
        const k = clamp((t - GRIETA) / 0.5), r = 6 + 34 * ease.outCubic(k), a = 0.6 * (1 - k);
        if (a > 0.02)
          for (let i = 0; i < 90; i++) {
            const an = (i / 90) * TAU, rr = r + (rand(i, 5) - 0.5) * 6;
            if (rand(i, 11) < 0.25) continue;
            p.dot(Math.cos(an) * rr, Math.sin(an) * rr * VISTA, rand(i, 3) < 0.3 ? WHITE : C[5], a);
          }
      }
      // las sombras de los trozos que vuelan
      for (const g of trozos) if (g.z > 1) p.dot(g.x, g.y, C[0], 0.35 * Math.min(1, g.vida / 0.25));
      ps.draw(p, "back");
    },
    draw(p) {
      // el instante blanco: el bloque entero se pone blanco y se agrieta
      if (t < GRIETA + 0.04) {
        const k = clamp(t / GRIETA);
        p.poly(OUTLINE, t < GRIETA ? WHITE : C[6], 1);
        for (const gr of grietas) {
          const n = Math.max(2, Math.ceil(gr.length * ease.outCubic(k)));
          for (let i = 1; i < n; i++) p.line(gr[i - 1][0], gr[i - 1][1], gr[i][0], gr[i][1], C[4]);
        }
        p.glow(CORE[0], CORE[1], 30, WHITE, 0.5);
      }
      if (t >= GRIETA && t < GRIETA + 0.16) flare(p, CORE[0], CORE[1], 30 * Math.pow(1 - (t - GRIETA) / 0.16, 1.4), 1 - (t - GRIETA) / 0.16, C);
      // los trozos: cada uno girado, aplastado según da la vuelta (f), con su borde; se funden al final
      for (const g of trozos) {
        const funde = Math.min(1, g.vida / 0.3), s = 0.55 + 0.45 * funde, ca = Math.cos(g.giro), sa = Math.sin(g.giro), cf = Math.cos(g.f) || 0.15;
        const pts = g.pts.map(([x, y]) => {
          const u = x * s * (Math.abs(cf) < 0.15 ? 0.15 * Math.sign(cf || 1) : cf), v = y * s;
          return [g.x + ca * u - sa * v, g.y - g.z + sa * u + ca * v];
        });
        const al = funde > 0.6 ? 1 : funde / 0.6;
        p.poly(pts, g.c, al);
        if (g.carne) {
          p.dot(pts[0][0], pts[0][1], C[6], al);   // escarcha encima
        } else if (pts.length > 2 && g.lit !== undefined) {
          p.line(pts[0][0], pts[0][1], pts[1][0], pts[1][1], cf > 0 ? WHITE : C[6], al);
          for (let k = 1; k < pts.length; k++) p.line(pts[k][0], pts[k][1], pts[(k + 1) % pts.length][0], pts[(k + 1) % pts.length][1], C[5], al * 0.8);
        }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
