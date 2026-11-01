// La mutación Tentacular (M29; mutaciones.gd, actuar "tentacular"): cuando empuja a los zombis de alrededor, a Johnny le
// salen de la cintura seis tentáculos morados que restallan hacia fuera hasta donde llega el empujón ("reach"), ondulando
// como un látigo, dan en el suelo (una onda y unas gotas de baba) y se recogen enroscándose. Vistos desde arriba: salen a
// la altura de la cintura ("height") y la punta baja al suelo (z). Cada tentáculo, con borde oscuro, cuerpo, brillo por
// un lado y ventosas. El origen es el suelo, a sus pies. Lo exporta exportar.mjs.
import { Particles, P, Rng, fit, clamp, ease, smooth, TAU, WHITE, hex } from "../../core/index.js";

export const meta = {
  name: "Tentáculos",
  desc: "Tentacles burst from the waist and whip outward all around, rippling like lashes, slap the floor with a ring and slime, then curl back in.",
  tags: ["tentacle", "mutation", "shadow", "aoe", "one-shot"],
  size: [128, 112],
  origin: [64, 70],
  duration: 0.7,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#14041a", "#3a0b44", "#6a1670", "#a0249a", "#d65ac8", "#ffb0ef"], reach: 45, height: 20, seed: 4 },
};

const VISTA = 0.6, N = 6;

export function create(o) {
  const C = fit(o.palette, 6).map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed), L = o.reach, H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999 });
  const tentaculos = Array.from({ length: N }, (_, i) => ({
    a: (i / N) * TAU + R.range(-0.25, 0.25),   // hacia dónde sale
    lado: R.sign(),                             // hacia dónde ondula y se enrosca
    t0: R.range(0, 0.05),
    largo: L * R.range(0.85, 1.05),
    grueso: R.range(2.5, 3.2),
  }));
  // las gotas de baba al dar en el suelo
  const gotas = [];
  for (const q of tentaculos)
    for (let j = 0; j < 3; j++) {
      const d = q.largo * R.range(0.8, 1), a = q.a + R.range(-0.25, 0.25), sp = R.range(20, 50);
      gotas.push({ x: Math.cos(a) * d, y: Math.sin(a) * d * VISTA, z: 0, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA, vz: R.range(30, 60), t0: q.t0 + 0.12, s: R.chance(0.4) ? 1.5 : 1, suelo: -1 });
    }
  let t = 0;

  // un tentáculo en el instante t: la lista de puntos [x, y (con su altura ya restada), grueso]
  function forma(q) {
    const u = t - q.t0;
    if (u <= 0) return null;
    const sale = ease.outCubic(clamp(u / 0.13)), vuelve = smooth(0.24, 0.5, u);
    const largo = q.largo * sale * (1 - vuelve);
    if (largo < 2) return null;
    const pts = [], pasos = Math.ceil(largo / 1.5);
    let x = 0, y = 0, a = q.a;
    for (let i = 0; i <= pasos; i++) {
      const s = i / pasos;
      // ondula como un látigo (una onda que corre hacia la punta) y, al recogerse, se enrosca hacia un lado
      a = q.a + q.lado * (0.7 * Math.sin(s * 6 - u * 26) * (1.1 - sale * 0.5) * s + vuelve * 3.2 * s * s);
      if (i > 0) { x += Math.cos(a) * (largo / pasos); y += Math.sin(a) * (largo / pasos) * VISTA; }
      // de la cintura (H) baja al suelo hacia la punta; al recogerse, la punta se levanta un poco
      const z = H * (1 - s) * (1 - s * 0.3) + vuelve * 4 * s;
      pts.push([x, y - z, q.grueso * (1 - s * 0.85)]);
    }
    return pts;
  }

  // los tentáculos de detrás (los que van hacia arriba) o los de delante: primero el borde oscuro de todos, luego los
  // cuerpos, luego los brillos y las ventosas, así se leen encima
  function pintar(p, detras) {
    const formas = tentaculos.filter((q) => (Math.sin(q.a) < -0.2) === detras).map(forma).filter(Boolean);
    for (const pts of formas) for (const [x, y, w] of pts) p.circle(x, y, w + 1, C[1]);
    for (const pts of formas) for (const [x, y, w] of pts) p.circle(x, y, w, C[3]);
    for (const pts of formas)
      pts.forEach(([x, y, w], i) => {
        if (w > 1.2) p.dot(x - w * 0.4, y - w * 0.5, C[4], 1);
        if (i % 4 === 2 && w > 1.5) p.dot(x + w * 0.3, y + w * 0.3, C[5], 1);
      });
  }

  return {
    update(dt) {
      t += dt;
      for (const g of gotas) {
        if (t < g.t0 || g.suelo >= 0) continue;
        g.vz -= 380 * dt;
        g.z += g.vz * dt;
        g.x += g.vx * dt; g.y += g.vy * dt;
        if (g.z <= 0) g.suelo = t;
      }
      ps.update(dt);
    },
    drawBack(p) {
      // la onda por el suelo cuando restallan
      const u = clamp((t - 0.1) / 0.35);
      if (t > 0.1 && u < 1) {
        const r = L * (0.5 + 0.6 * ease.outCubic(u)), k = 1 - u, pasos = Math.ceil(r * 3);
        for (let i = 0; i < pasos; i++) {
          const a = (i / pasos) * TAU, x = Math.cos(a) * r, y = Math.sin(a) * r * VISTA;
          p.dot(x, y + 1, C[0], k * 0.6);
          p.dot(x, y, k > 0.5 ? C[4] : C[3], k);
        }
      }
      // las gotas de baba que han caído
      for (const g of gotas) {
        if (g.suelo < 0) continue;
        const k = 1 - clamp((t - g.suelo) / 0.25);
        if (k > 0) p.ellipse(g.x, g.y, g.s * 1.3, g.s * 0.8, C[2], k);
      }
      // la sombra de los tentáculos en el suelo
      for (const q of tentaculos) {
        const pts = forma(q);
        if (!pts) continue;
        for (let i = 0; i < pts.length; i += 2) {
          const s = i / (pts.length - 1), z = H * (1 - s) * (1 - s * 0.3);
          p.dot(pts[i][0], pts[i][1] + z, C[0], 0.3);
        }
      }
      // los tentáculos que van hacia arriba de la pantalla quedan detrás de Johnny
      pintar(p, true);
      ps.draw(p, "back");
    },
    draw(p) {
      pintar(p, false);
      // las gotas por el aire
      for (const g of gotas) {
        if (t < g.t0 || g.suelo >= 0) continue;
        p.dot(g.x, g.y - g.z, C[4], 1);
        p.dot(g.x - 0.5, g.y - g.z - 0.5, WHITE, 0.6);
      }
      // un destello en la cintura al salir
      if (t < 0.12) p.glow(0, -H, 14, C[4], 0.5 * (1 - t / 0.12));
      ps.draw(p, "front");
    },
  };
}
