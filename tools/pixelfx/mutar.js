// Elegir una mutación (M54; partida.gd, elegir_mutacion), visto desde arriba: el cuerpo de Johnny se enciende de morado,
// dos hebras de ADN se enroscan alrededor de él y suben hasta deshacerse, en el suelo se abren dos ondas blandas (que
// tiemblan, como si fueran de carne) y burbujitas que salen a sus pies y revientan. Va de hijo de Johnny, para que le
// siga. "height": lo alto del cuerpo. El origen es el suelo, a sus pies. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, clamp, ease, smooth, TAU, WHITE, hex } from "../../core/index.js";

export const meta = {
  name: "Mutar",
  desc: "A mutation taking hold, from above: the body glows magenta, two DNA strands coil up around it and fray, wobbly flesh-like rings open on the floor and bubbles pop.",
  tags: ["buff", "mutation", "arcane", "poison", "one-shot"],
  size: [112, 112],
  origin: [56, 84],
  duration: 1.1,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#1a0620", "#4a0f4f", "#7d1a7a", "#b5179e", "#e04fc8", "#ffb0ef"], height: 24, seed: 6 },
};

const VISTA = 0.6;

export function create(o) {
  const C = fit(o.palette, 6).map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed), H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999 }), lights = new Lights();
  // las burbujas a sus pies: salen una tras otra, crecen y revientan
  const burbujas = Array.from({ length: 9 }, () => {
    const a = R.range(0, TAU), d = R.range(6, 16);
    return { x: Math.cos(a) * d, y: Math.sin(a) * d * VISTA, t0: R.range(0.05, 0.55), vida: R.range(0.14, 0.24), r: R.range(1.2, 2.4) };
  });
  // las ondas del suelo: cada una con su temblor
  const ondas = [0, 0.18].map((t0) => ({ t0, fase: R.range(0, TAU), n: R.int(5, 7) }));
  for (let i = 0; i < 10; i++)
    ps.spawn(P.MOTE, R.range(-10, 10), -R.range(0, H * 1.4), R.range(-6, 6), -R.range(18, 36), R.range(0.3, 0.5), R.pick([C[4], C[5], WHITE]), 1, R.range(0.1, 0.4));
  lights.add(0, -H, 40, C[4], 0.6, 0.35);
  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // las ondas blandas por el suelo
      for (const w of ondas) {
        const u = clamp((t - w.t0) / 0.55);
        if (t < w.t0 || u >= 1) continue;
        const r = 6 + 30 * ease.outCubic(u), k = 1 - u;
        const pasos = Math.ceil(r * 4);
        for (let i = 0; i < pasos; i++) {
          const a = (i / pasos) * TAU, rr = r * (1 + 0.08 * Math.sin(a * w.n + w.fase + t * 9));
          const x = Math.cos(a) * rr, y = Math.sin(a) * rr * VISTA;
          p.dot(x, y, k > 0.6 ? C[5] : k > 0.3 ? C[4] : C[3], k);
          if (u < 0.5) p.dot(x, y + 1, C[2], k * 0.7);
        }
      }
      // las burbujas
      for (const b of burbujas) {
        const u = (t - b.t0) / b.vida;
        if (u < 0 || u > 1.4) continue;
        if (u <= 1) {
          const r = b.r * ease.outCubic(u);
          p.circle(b.x, b.y - r, r, C[3], 0.9);
          p.dot(b.x - r * 0.4, b.y - r * 1.4, C[5], 1);
        } else {
          const r = b.r * (1 + (u - 1) * 2);
          for (let i = 0; i < 6; i++) p.dot(b.x + Math.cos((i / 6) * TAU) * r, b.y - b.r + Math.sin((i / 6) * TAU) * r * 0.8, C[4], 1 - (u - 1) / 0.4);
        }
      }
      ps.draw(p, "back");
    },
    draw(p) {
      // el cuerpo se enciende de morado, de golpe, y se va apagando
      const k = t < 0.08 ? t / 0.08 : 1 - clamp((t - 0.08) / 0.7);
      p.glow(0, -H * 0.9, 22, C[3], 0.5 * k);
      if (t < 0.1) p.glow(0, -H, 12, C[5], 0.4 * (1 - t / 0.1));
      // las dos hebras de ADN: se enroscan alrededor del cuerpo y suben; la parte de delante (seno > 0) más clara
      const sube = ease.outCubic(clamp(t / 0.7)), va = 1 - smooth(0.6, 0.95, t);
      if (va > 0) {
        const alto = H * 2.2, base = -4 - sube * 14, giro = t * 7;
        for (let s = 0; s < 2; s++) {
          const fase = s * Math.PI;
          for (let h = 0; h < alto * Math.min(1, t / 0.25); h += 1) {
            const y = base - h, a = fase + giro + h * 0.22, rad = 10 * (1 - h / alto * 0.35);
            const x = Math.cos(a) * rad, delante = Math.sin(a) > 0;
            // se deshace por arriba: los puntos de lo alto se van saltando
            const corte = (h / alto) - (1 - va) * 1.2;
            if (corte > 0.85 - (h % 3) * 0.05) continue;
            p.dot(x, y, delante ? (h % 6 < 1 ? WHITE : C[5]) : C[2], va * (delante ? 1 : 0.7));
            // los peldaños entre una hebra y la otra
            if (s === 0 && h % 6 === 0 && delante) for (let j = -2; j <= 2; j++) p.dot((x * j) / 3, y, C[4], va * 0.6);
          }
        }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
