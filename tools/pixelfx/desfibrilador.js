// El desfibrilador (M55; johnny.gd, cuando el talento Desfibrilador le hace volver con toda la vida), visto desde arriba:
// dos descargas seguidas, como las de verdad (¡pum!... ¡pum!): en cada una, un fogonazo blanco en el pecho, rayitos que
// le recorren el cuerpo, chispas y un anillo eléctrico que se abre por el suelo. Tras la segunda, el corazón vuelve: una
// línea verde de electrocardiograma que se traza sobre su cabeza con su latido y un brillo verde que le envuelve.
// Va de hijo de Johnny, para que le siga. "height": la altura del pecho. El origen es el suelo, a sus pies. Los rayitos,
// con zigzag y crackle del rayo de pixelfx. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, band, clamp, ease, rng, TAU, WHITE, hex } from "../../core/index.js";
import { zigzag, crackle } from "../lightning/_lib.js";

export const meta = {
  name: "Desfibrilador",
  desc: "A defibrillator revive from above: two jolts with crackles over the body, sparks and an electric ring, then a green heartbeat line over the head.",
  tags: ["lightning", "revive", "heal", "buff", "one-shot"],
  size: [96, 112],
  origin: [48, 84],
  duration: 1.2,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#06262e", "#07505a", "#0aa0a2", "#16c8cc", "#2cf2f0", "#9fe8ff", "#ecffff", "#ffffff"],
    verdes: ["#0c2a12", "#1a5a26", "#2f9a40", "#57d468", "#9cf2a4", "#e2ffe4"],
    height: 24,
    seed: 5,
  },
};

const VISTA = 0.6, GOLPES = [0, 0.32], ECG0 = 0.6;

// la forma del latido: plano, un piquito, el pico grande hacia arriba, el bajón y otra vez plano (u de 0 a 1)
function latido(u) {
  if (u < 0.3 || u > 0.72) return 0;
  if (u < 0.38) return -2 * Math.sin(((u - 0.3) / 0.08) * Math.PI);
  if (u < 0.46) return 0;
  if (u < 0.52) return -((u - 0.46) / 0.06) * 12;
  if (u < 0.6) return -12 + ((u - 0.52) / 0.08) * 17;
  if (u < 0.66) return 5 - ((u - 0.6) / 0.06) * 5;
  return 0;
}

export function create(o) {
  const C = fit(o.palette, 8).map((c) => (typeof c === "string" ? hex(c) : c)), V = fit(o.verdes, 6);
  const R = new Rng(o.seed), H = o.height;
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [C[7], C[6], C[5], C[4]] }), lights = new Lights();
  const lanzados = new Set();
  let t = 0;
  return {
    update(dt) {
      t += dt;
      GOLPES.forEach((g, i) => {
        if (t < g || lanzados.has(i)) return;
        lanzados.add(i);
        for (let j = 0; j < 10; j++) {
          const a = R.range(0, TAU), sp = R.range(80, 170);
          ps.spawn(P.SPARK, Math.cos(a) * 4, -H + Math.sin(a) * 3, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 40, R.range(0.15, 0.32));
        }
        lights.add(0, -H, 46, C[4], 0.8, 0.22);
        lights.add(0, -H, 14, WHITE, 0.6, 0.06);
      });
      if (t >= ECG0 && !lanzados.has("ecg")) {
        lanzados.add("ecg");
        for (let j = 0; j < 8; j++)
          ps.spawn(P.MOTE, R.range(-10, 10), -R.range(4, H * 1.6), R.range(-6, 6), -R.range(15, 35), R.range(0.3, 0.42), R.pick([V[4], V[5], WHITE]), 1, R.range(0, 0.2));
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // el anillo eléctrico que se abre por el suelo en cada descarga
      for (const g of GOLPES) {
        const u = clamp((t - g) / 0.3);
        if (t >= g && u < 1) band(p, 0, 0, 5 + 22 * ease.outCubic(u), VISTA, 2, 1 - u, C);
      }
      // y el verde, más suave, cuando vuelve el corazón
      const v = clamp((t - ECG0) / 0.45);
      if (t >= ECG0 && v < 1) band(p, 0, 0, 4 + 16 * ease.outCubic(v), VISTA, 1.5, 0.7 * (1 - v), V);
      ps.draw(p, "back");
    },
    draw(p) {
      const f = Math.floor(t * 20 + 1e-4);
      // las descargas: el fogonazo en el pecho y rayitos que le recorren el cuerpo, rehechos en cada fotograma
      GOLPES.forEach((g, i) => {
        const u = (t - g) / 0.2;
        if (u < 0 || u >= 1) return;
        const r = rng(o.seed, 7 + i, f);
        for (let j = 0; j < 6; j++) {
          const x0 = r.range(-3, 3), y0 = -H + r.range(-3, 3), a = r.range(0, TAU), l = r.range(8, 16);
          crackle(p, zigzag(r, x0, y0, x0 + Math.cos(a) * l * 0.7, y0 + Math.sin(a) * l, 0.45, 0.3), 0.85 * (1 - u) + 0.15, C, 0.3);
        }
        p.circle(0, -H, 4 * (1 - u) + 1, C[5]);
        p.circle(0, -H, 3 * (1 - u) + 0.5, WHITE);
        p.glow(0, -H, 22, C[4], 0.6 * (1 - u));
        if (u < 0.3) p.glow(0, -H, 12, WHITE, 0.5);
      });
      // el corazón vuelve: el brillo verde que le envuelve
      const k = t < ECG0 ? 0 : t < ECG0 + 0.1 ? (t - ECG0) / 0.1 : 1 - clamp((t - ECG0 - 0.1) / 0.5);
      if (k > 0) p.glow(0, -H * 0.9, 20, V[3], 0.4 * k);
      // la línea del electrocardiograma: se traza de izquierda a derecha sobre la cabeza, con su latido, y se apaga
      const e = (t - ECG0) / 0.35;
      if (e > 0) {
        const fin = 1 - clamp((t - ECG0 - 0.4) / 0.2), Y = -H * 2 - 10, W = 30;
        if (fin > 0) {
          const hasta = Math.min(1, e) * W;
          let px = -W / 2, py = Y;
          for (let x = 1; x <= hasta; x++) {
            const nx = -W / 2 + x, ny = Y + latido(x / W);
            p.line(px, py, nx, ny, x > hasta - 2 && e < 1 ? WHITE : V[4], fin);
            px = nx; py = ny;
          }
          // la punta que la va trazando
          if (e < 1) p.glow(px, py, 5, V[4], 0.6);
          p.glow(0, Y - 3, 16, V[3], 0.25 * fin);
        }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
