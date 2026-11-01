// El rugido de un jefe en su presentación (M57; ui/presentacion.gd, al gritar), visto desde arriba: de la cabeza salen
// ondas de sonido (arcos que se abren uno tras otro y se van), el aire tiembla en un destello rojizo, y en el suelo una
// onda de polvo se abre a sus pies levantando piedrecitas que saltan y caen (cada una con su altura, z). "height": la
// altura de la cabeza. El origen es el suelo, a sus pies. Lo exporta exportar.mjs.
import { Particles, P, Rng, fit, clamp, ease, TAU, WHITE, hex, mix } from "../../core/index.js";

export const meta = {
  name: "Rugido",
  desc: "A boss roar from above: sound-wave arcs burst from the head one after another, a reddish shimmer, and a dust ring opens on the floor kicking up pebbles.",
  tags: ["roar", "shout", "boss", "intro", "shockwave", "one-shot"],
  size: [208, 176],
  origin: [104, 112],
  duration: 1.2,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#2a0c0c", "#5a1414", "#9a2222", "#d8442c", "#ff8a4a", "#ffd0a0"],
    polvo: ["#2a2622", "#4a4540", "#77706a", "#a39c92", "#c9c2b6", "#e4ded2"],
    height: 40,
    seed: 9,
  },
};

const VISTA = 0.6;

export function create(o) {
  const C = fit(o.palette, 6).map((c) => (typeof c === "string" ? hex(c) : c)), D = fit(o.polvo, 6).map((c) => (typeof c === "string" ? hex(c) : c));
  const R = new Rng(o.seed), H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999, haze: D[3] });
  // las ondas de sonido: arcos que salen de la cabeza, uno tras otro
  const ondas = Array.from({ length: 4 }, (_, i) => ({ t0: i * 0.13, fase: R.range(0, TAU) }));
  // las piedrecitas que levanta la onda del suelo: salen cuando la onda pasa por su sitio
  const piedras = Array.from({ length: 22 }, () => {
    const a = R.range(0, TAU), d = R.range(14, 70);
    return { a, d, x: Math.cos(a) * d, y: Math.sin(a) * d * VISTA, z: 0, vz: R.range(40, 110), t0: 0.05 + d / 180, s: R.chance(0.3) ? 2 : 1, c: R.pick([D[2], D[3], D[4]]), sale: false };
  });
  // el polvo que levanta la onda
  for (let i = 0; i < 16; i++) {
    const a = R.range(0, TAU), d = R.range(16, 60);
    ps.spawn(P.SMOKE, Math.cos(a) * d, Math.sin(a) * d * VISTA, Math.cos(a) * R.range(15, 35), Math.sin(a) * R.range(8, 20) - R.range(4, 10), R.range(0.45, 0.7), R.pick([D[3], D[4]]), R.range(3, 5), 0.05 + d / 180);
  }
  let t = 0;
  return {
    update(dt) {
      t += dt;
      for (const q of piedras) {
        if (t < q.t0) continue;
        q.sale = true;
        q.vz -= 420 * dt;
        q.z += q.vz * dt;
        q.x += Math.cos(q.a) * 25 * dt;
        q.y += Math.sin(q.a) * 25 * VISTA * dt;
        if (q.z < 0) { q.z = 0; q.vz = Math.abs(q.vz) > 40 ? -q.vz * 0.35 : 0; }
      }
      ps.update(dt);
    },
    drawBack(p) {
      // la onda de polvo por el suelo: un anillo grueso que se abre y se deshace
      const u = clamp(t / 0.6);
      if (u < 1) {
        const r = 10 + 80 * ease.outCubic(u), k = 1 - u, pasos = Math.ceil(r * 3);
        for (let i = 0; i < pasos; i++) {
          const a = (i / pasos) * TAU, rr = r + Math.sin(a * 9 + t * 20) * 1.5;
          const x = Math.cos(a) * rr, y = Math.sin(a) * rr * VISTA;
          // borde oscuro por fuera (para que se lea en suelos claros), polvo claro en medio y más polvo por dentro
          p.dot(x * 1.03, y * 1.03 + 1, D[1], k * 0.9);
          p.dot(x, y, k > 0.5 ? D[5] : D[4], k);
          p.dot(x, y - 1, D[4], k);
          if (u < 0.6) (p.dot(x * 0.96, y * 0.96, D[3], k * 0.8), p.dot(x * 0.92, y * 0.92, D[2], k * 0.5));
        }
      }
      // las piedrecitas que ya están en el suelo y su sombra
      const fin = 1 - clamp((t - 0.95) / 0.2);
      for (const q of piedras) if (q.sale) p.dot(q.x, q.y, D[0], 0.4 * fin);
      ps.draw(p, "back");
    },
    draw(p) {
      // el destello rojizo del grito, alrededor de la cabeza
      const k = t < 0.06 ? t / 0.06 : 1 - clamp((t - 0.06) / 0.5);
      p.glow(0, -H, 30, C[3], 0.35 * k);
      // las ondas de sonido: arcos (más anchos a los lados que arriba, aplastados) que se abren desde la cabeza
      for (const w of ondas) {
        const u = (t - w.t0) / 0.55;
        if (u < 0 || u >= 1) continue;
        const r = 8 + 70 * ease.outQuad(u), a0 = 1 - u * u, pasos = Math.ceil(r * 4);
        for (let i = 0; i < pasos; i++) {
          const a = (i / pasos) * TAU;
          // se dibujan en trozos (como ondas de sonido de cómic): huecos que giran
          if (Math.sin(a * 6 + w.fase) < -0.3) continue;
          const x = Math.cos(a) * r, y = -H + Math.sin(a) * r * 0.7;
          // tres de gordo: el borde de fuera oscuro, el centro claro y el de dentro naranja
          const f = (q) => [Math.cos(a) * (r + q), -H + Math.sin(a) * (r + q) * 0.7];
          const [xa, ya] = f(1.5), [xb, yb] = f(-1.5);
          p.dot(xa, ya, C[1], a0 * 0.9);
          p.dot(x, y, a0 > 0.6 ? WHITE : C[5], a0);
          p.dot(xb, yb, a0 > 0.5 ? C[4] : C[3], a0);
        }
      }
      // las piedrecitas por el aire
      const fin = 1 - clamp((t - 0.95) / 0.2);
      for (const q of piedras) {
        if (!q.sale || fin <= 0) continue;
        if (q.s > 1) p.rect(q.x - 1, q.y - q.z - 1, 2, 2, q.c, fin);
        else p.dot(q.x, q.y - q.z, q.c, fin);
      }
      ps.draw(p, "front");
    },
  };
}
