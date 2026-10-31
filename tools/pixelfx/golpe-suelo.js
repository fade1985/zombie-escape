// El golpe al final de los ataques de los jefes (M58), visto desde arriba. Hecho para el juego con la idea del
// "dirt-explosion" de pixelfx (polvo, onda y cascotes):
//  - "pisoton" (este): un jefe aterriza de un salto o pega un puñetazo al suelo (gymbro.gd, mascota.gd: aterrizar;
//    cientifico_jefe.gd: punetazo). Una bocanada de polvo en el centro, grietas en el suelo, una onda que se abre por el
//    suelo en elipse (VISTA: lo de arriba abajo más corto) levantando polvo a su paso, y cascotes que saltan, cada uno con
//    su altura (z), caen en su sitio, rebotan y se quedan un momento.
//  - "golpe-pared" (golpe-pared.js): una carga que se estrella (minijefe.gd, estrellarse): sin onda ni grietas, a la
//    altura del cuerpo, una nube de yeso y cascotes que caen al suelo.
// "reach": hasta dónde llega la onda, en píxeles del dibujo · "height": a qué altura es el golpe · "ring": con la onda y las
// grietas · "chunks": cuántos cascotes. El origen es el suelo, en el centro. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, band, clamp, smooth, ease, TAU, WHITE, hex, mix } from "../../core/index.js";

export const meta = {
  name: "Pisotón",
  desc: "A heavy landing seen from above: a puff of dust, cracks in the floor, a shockwave ring that opens over the floor kicking up dust, and rubble that hops, lands and settles.",
  tags: ["impact", "dust", "slam", "shockwave", "one-shot"],
  size: [240, 150],
  origin: [120, 80],
  duration: 1.1,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#1a1410", "#3a2e24", "#7a6a58", "#a8987e", "#cfc2a6", "#ebe2cc", "#fffaf0"], reach: 100, height: 0, ring: true, chunks: 22, seed: 6 },
};

const VISTA = 0.6, ABRE = 0.4;

export function create(o) {
  const C = fit(o.palette, 7), CH = C.map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed);
  const REACH = o.reach, H = o.height, K = REACH / 100;
  const ps = new Particles({ rng: R, ground: () => 999 }), lights = new Lights();
  const frente = (t) => REACH * ease.outCubic(clamp(t / ABRE));
  // las grietas: rayas quebradas que salen del centro por el suelo
  const grietas = o.ring ? Array.from({ length: 7 }, (_, i) => {
    const pts = [[0, 0]];
    let x = 0, y = 0, a = (i / 7) * TAU + R.range(-0.3, 0.3);
    const largo = R.range(0.22, 0.4) * REACH;
    for (let d = 0; d < largo; d += 2) {
      a += R.range(-0.45, 0.45);
      x += Math.cos(a) * 2;
      y += Math.sin(a) * 2 * VISTA;
      pts.push([x, y]);
    }
    return pts;
  }) : [];
  // los cascotes: saltan desde el golpe, cada uno con su altura
  const cascotes = Array.from({ length: o.chunks }, () => {
    const a = R.range(0, TAU), sp = R.range(50, 170) * (o.ring ? K : 0.7);
    return { x: R.range(-3, 3), y: R.range(-2, 2), z: H + R.range(0, 6), vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA,
      vz: R.range(50, 150) * (o.ring ? 1 : 0.5), giro: R.range(0, TAU), vgiro: R.range(-12, 12), w: R.range(1.5, 3.5) * (o.ring ? 1.8 : 1.3), h: R.range(1.2, 2.5) * (o.ring ? 1.8 : 1.3),
      c: R.pick([CH[3], CH[4], CH[4], CH[5]]), vida: R.range(0.7, 1.0) };
  });
  // la bocanada de polvo del golpe
  for (let i = 0; i < (o.ring ? 16 : 12); i++) {
    const a = R.range(0, TAU), sp = R.range(20, 70) * (o.ring ? K : 0.8);
    ps.spawn(P.DUST, Math.cos(a) * 4, -H + Math.sin(a) * 3, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - R.range(5, 20),
      R.range(0.5, 0.85), R.pick([C[4], C[5], C[5], C[6]]), R.range(4, 7) * (o.ring ? Math.max(0.7, K) : 1));
  }
  lights.add(0, -H, 40 + 30 * K, C[5], 0.4, 0.15);
  let t = 0;
  return {
    update(dt) {
      t += dt;
      // la onda levanta polvo a su paso
      if (o.ring && t < ABRE) {
        const fr = frente(t);
        for (let i = 0; i < Math.round(2 * K + 1); i++) {
          const a = R.range(0, TAU);
          ps.spawn(P.DUST, Math.cos(a) * fr, Math.sin(a) * fr * VISTA, Math.cos(a) * R.range(10, 30), Math.sin(a) * R.range(5, 15) - R.range(4, 12),
            R.range(0.35, 0.6), R.pick([C[4], C[5], C[6]]), R.range(2.5, 4.5) * Math.max(0.7, K));
        }
      }
      for (let i = cascotes.length - 1; i >= 0; i--) {
        const g = cascotes[i];
        if ((g.vida -= dt) <= 0) {
          cascotes.splice(i, 1);
          continue;
        }
        g.vz -= 560 * dt;
        g.z += g.vz * dt;
        if (g.z <= 0) {
          if (g.vz < -90) ps.spawn(P.DUST, g.x, g.y, 0, -4, R.range(0.25, 0.4), C[4], R.range(1.5, 2.5));
          g.z = 0;
          g.vz = g.vz < -70 ? -g.vz * 0.3 : 0;
          g.vx *= 0.6; g.vy *= 0.6; g.vgiro *= 0.4;
        }
        const roce = g.z > 0 ? 0.4 : 5;
        g.vx -= g.vx * roce * dt; g.vy -= g.vy * roce * dt;
        g.x += g.vx * dt; g.y += g.vy * dt; g.giro += g.vgiro * dt;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // las grietas: aparecen de golpe y se borran
      const va = 1 - smooth(0.6, 1.0, t);
      if (va > 0)
        for (const g of grietas) {
          const n = Math.max(2, Math.ceil(g.length * ease.outCubic(clamp(t / 0.08))));
          for (let i = 1; i < n; i++) {
            const k = va * (1 - (i / g.length) * 0.5);
            p.line(g[i - 1][0], g[i - 1][1], g[i][0], g[i][1], CH[0], k);
            if (i < g.length * 0.7) p.line(g[i - 1][0] + 1, g[i - 1][1], g[i][0] + 1, g[i][1], CH[1], k);
          }
        }
      // la onda: la mitad de detrás
      if (o.ring && t < ABRE + 0.1) {
        const u = clamp(t / (ABRE + 0.1));
        band(p, 0, 0, frente(t) + 1, VISTA, Math.max(2, 7 * Math.pow(1 - u, 0.7) * Math.max(0.6, K)), u < 0.6 ? 1 : (1 - u) / 0.4, C, (g) => Math.sin(g) < 0);
      }
      ps.draw(p, "back");
    },
    draw(p) {
      // la onda: la mitad de delante
      if (o.ring && t < ABRE + 0.1) {
        const u = clamp(t / (ABRE + 0.1));
        band(p, 0, 0, frente(t) + 1, VISTA, Math.max(2, 7 * Math.pow(1 - u, 0.7) * Math.max(0.6, K)), u < 0.6 ? 1 : (1 - u) / 0.4, C, (g) => Math.sin(g) >= 0);
      }
      // el golpe: un destello claro, un instante
      if (t < 0.07) p.glow(0, -H, 14 + 10 * K, C[6], 0.5 * (1 - t / 0.07));
      // los cascotes, con su sombra mientras van por el aire
      for (const g of cascotes) {
        const al = Math.min(1, g.vida / 0.25), ca = Math.cos(g.giro), sa = Math.sin(g.giro), y0 = g.y - g.z;
        if (g.z > 1) p.dot(g.x, g.y, CH[0], 0.35 * al);
        for (let u = -g.w / 2; u <= g.w / 2; u += 0.5)
          for (let v = -g.h / 2; v <= g.h / 2; v += 0.5) {
            const borde = g.w > 2.4 && (Math.abs(u) > g.w / 2 - 0.6 || Math.abs(v) > g.h / 2 - 0.6), luz = u + v < -g.w * 0.25;
            p.dot(g.x + ca * u - sa * v, y0 + sa * u + ca * v, borde ? CH[1] : luz ? mix(g.c, WHITE, 0.3) : g.c, al);
          }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
