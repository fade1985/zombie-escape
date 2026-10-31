// Lo que hace el chorro del lanzallamas y del lanza ácido al dar en algo (llamarada.gd, quemar), visto desde arriba:
//  - M59, al dar a un zombi (este y chorro-golpe-acido.js), en cada pellizco de daño, como el chispazo del lanza rayos:
//    el fuego, una bocanada de llamas que lame el cuerpo y sube, con chispas y un poco de humo; el ácido, un chisporroteo:
//    gotas que salpican y caen cada una en su sitio (con su altura, z), burbujas que crecen y revientan y vapor verde.
//  - M60, contra la pared, donde se corta el chorro (chorro-pared.js y chorro-pared-acido.js): lo mismo, más ancho y
//    aplastado (el chorro se abre contra la pared) y, el ácido, con chorretones que caen hasta el suelo.
// "tipo": "fuego" o "acido" · "height": a qué altura da · "spread": lo que se abre (1 en un zombi) · "chorretones": el
// ácido en la pared. El origen es el suelo, debajo del golpe. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, clamp, ease, TAU, WHITE, hex, mix } from "../../core/index.js";

export const meta = {
  name: "Golpe del chorro",
  desc: "A flamethrower jet hitting a body, seen from above: a lick of flame that wraps it and rises, sparks and a wisp of smoke.",
  tags: ["fire", "acid", "hit", "impact", "one-shot"],
  size: [96, 96],
  origin: [48, 68],
  duration: 0.5,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { tipo: "fuego", palette: ["#1d0f0a", "#5a1a10", "#a8321a", "#e8641e", "#ffa53a", "#ffe08a", "#fff8d6"], height: 13, spread: 1, chorretones: 0, seed: 3 },
};

const VISTA = 0.6;

export function create(o) {
  const C = fit(o.palette, 7), CH = C.map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed), H = o.height, S = o.spread;
  const fuego = o.tipo === "fuego";
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [C[6], C[5], C[4], C[3]], haze: C[5] }), lights = new Lights();
  const gotas = [], burbujas = [], chorros = [];
  let t = 0;
  if (fuego) {
    // la bocanada: llamas que salen del golpe hacia los lados (más, contra la pared) y suben
    for (let i = 0; i < 10 + 8 * S; i++) {
      const a = R.range(0, TAU), sp = R.range(20, 60) * S;
      ps.spawn(P.FIRE, Math.cos(a) * 3, -H + Math.sin(a) * 2, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - R.range(20, 50), R.range(0.24, 0.42), 0, R.range(4, 7), R.range(0, 0.06));
    }
    for (let i = 0; i < 6 + 4 * S; i++) {
      const a = R.range(0, TAU), sp = R.range(80, 170);
      ps.spawn(P.SPARK, 0, -H, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 50, R.range(0.12, 0.3));
    }
    ps.spawn(P.SMOKE, R.range(-3, 3), -H - 6, R.range(-6, 6), -R.range(14, 22), R.range(0.3, 0.42), hex("#3a302c"), R.range(2.5, 3.5), 0.12);
    lights.add(0, -H, 30 + 14 * S, C[4], 0.6, 0.3);
  } else {
    // el ácido: gotas que salpican, burbujas y vapor
    for (let i = 0; i < 8 + 6 * S; i++) {
      const a = R.range(0, TAU), sp = R.range(40, 110) * S;
      gotas.push({ x: Math.cos(a) * 2, y: Math.sin(a) * 2, z: H, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA, vz: R.range(20, 80), s: R.range(0.8, 1.8), c: R.pick([CH[3], CH[4], CH[4], CH[5]]), suelo: -1 });
    }
    for (let i = 0; i < 5 + 3 * S; i++) {
      const a = R.range(0, TAU), d = R.range(1, 6) * S;
      burbujas.push({ x: Math.cos(a) * d, y: -H + Math.sin(a) * d * 0.8, t0: R.range(0, 0.25), vida: R.range(0.12, 0.22), r: R.range(1.2, 2.6) });
    }
    for (let i = 0; i < 4; i++)
      ps.spawn(P.VAPOUR, R.range(-4, 4) * S, -H + R.range(-2, 2), R.range(-8, 8), -R.range(12, 24), R.range(0.25, 0.38), R.pick([C[4], C[5]]), R.range(2.5, 4) * Math.max(1, S * 0.8), R.range(0, 0.1));
    for (let i = 0; i < o.chorretones; i++)
      chorros.push({ x: R.range(-8, 8) * S, t0: R.range(0, 0.1), v: R.range(50, 80), w: R.chance(0.5) ? 1 : 2 });
    lights.add(0, -H, 24 + 10 * S, C[4], 0.45, 0.25);
  }
  return {
    update(dt) {
      t += dt;
      for (const g of gotas) {
        if (g.suelo >= 0) continue;
        g.vz -= 500 * dt;
        g.z += g.vz * dt;
        g.vx -= g.vx * 1.5 * dt; g.vy -= g.vy * 1.5 * dt;
        g.x += g.vx * dt; g.y += g.vy * dt;
        if (g.z <= 0) g.suelo = t;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // las gotas de ácido que han caído: una manchita que chisporrotea y se va
      for (const g of gotas) {
        if (g.suelo < 0) continue;
        const k = (1 - clamp((t - g.suelo) / 0.2)) * (1 - clamp((t - 0.38) / 0.1));
        if (k <= 0) continue;
        p.ellipse(g.x, g.y, g.s * 1.3, g.s * 0.8, mix(g.c, C[0], 0.3), k);
        if ((Math.floor(t * 30) + Math.round(g.x)) % 3 === 0) p.dot(g.x, g.y - 1, C[6], k);
      }
      ps.draw(p, "back");
    },
    draw(p) {
      // el golpe: un destello
      if (t < 0.06) p.glow(0, -H, 10 + 6 * S, fuego ? C[5] : C[5], 0.55 * (1 - t / 0.06));
      // los chorretones de ácido: bajan por la pared hasta el suelo
      for (const c of chorros) {
        const u = t - c.t0;
        if (u <= 0) continue;
        const largo = Math.min(H, u * c.v), k = 1 - clamp((t - 0.3) / 0.15);
        if (k <= 0) continue;
        for (let y = 0; y < largo; y++) for (let x = 0; x < c.w; x++) p.dot(c.x + x, -H + y, y > largo - 2 ? C[5] : C[3], k);
      }
      // las gotas por el aire, con su sombra
      const fin = 1 - clamp((t - 0.4) / 0.08);
      for (const g of gotas) {
        if (g.suelo >= 0 || fin <= 0) continue;
        p.dot(g.x, g.y, CH[0], 0.35 * fin);
        if (g.s > 1.3) p.circle(g.x, g.y - g.z, g.s, g.c, fin);
        else p.dot(g.x, g.y - g.z, g.c, fin);
        p.dot(g.x - 0.5, g.y - g.z - 0.5, C[6], 0.8 * fin);
      }
      // las burbujas: crecen y revientan en un anillito
      for (const b of burbujas) {
        const u = (t - b.t0) / b.vida;
        if (u < 0 || u > 1.4) continue;
        if (u <= 1) {
          const r = b.r * ease.outCubic(u);
          p.circle(b.x, b.y, r, C[3], 0.9);
          p.dot(b.x - r * 0.4, b.y - r * 0.4, C[6], 1);
        } else {
          const r = b.r * (1 + (u - 1) * 2);
          for (let i = 0; i < 6; i++) p.dot(b.x + Math.cos((i / 6) * TAU) * r, b.y + Math.sin((i / 6) * TAU) * r, C[5], 1 - (u - 1) / 0.4);
        }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
