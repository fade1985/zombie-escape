// La curación de la médica sobre Johnny (M56; aliado.gd, curar), vista desde arriba. Rehecha en la M66 para que se vea
// más: a sus pies se enciende un círculo de luz verde con un anillo que se abre; de ahí sube una columna de luz (dos
// hilos a los lados y rayitas que suben, sin taparle), un brillo le envuelve, y suben cruces verdes con su borde
// oscuro y chispitas. Va de hijo de Johnny, para que le siga. "height": lo alto del cuerpo; "feet": cuánto más abajo
// del origen (el sitio de Johnny) tiene los pies. Lo exporta exportar.mjs.
import { Particles, P, Rng, fit, band, clamp, ease, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Curación",
  desc: "A healing burst seen from above: a green disc lights up under the feet with an opening ring, a column of light rises round the body, outlined crosses float up and motes sparkle.",
  tags: ["heal", "buff", "holy", "one-shot"],
  size: [112, 128],   // (+16 por lado: que la luz no se salga del lienzo, 9 nov)
  origin: [56, 92],
  duration: 1.0,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#0c2a12", "#1a5a26", "#2f9a40", "#57d468", "#9cf2a4", "#e2ffe4"], height: 44, feet: 8, seed: 4 },
};

const VISTA = 0.5, ANCHO = 11;

// una cruz de botiquín: el centro blanco, los brazos verde claro y el borde verde oscuro (para que se lea encima de todo)
function cruz(p, x, y, n, C, a) {
  const X = Math.round(x), Y = Math.round(y), dentro = (i, j) => (Math.abs(i) <= n && j === 0) || (Math.abs(j) <= n && i === 0);
  for (let j = -n - 1; j <= n + 1; j++)
    for (let i = -n - 1; i <= n + 1; i++) {
      if (dentro(i, j)) p.dot(X + i, Y + j, i === 0 && j === 0 ? WHITE : Math.abs(i) + Math.abs(j) >= n ? C[3] : C[4], a);
      else if (dentro(i - 1, j) || dentro(i + 1, j) || dentro(i, j - 1) || dentro(i, j + 1)) p.dot(X + i, Y + j, C[1], a * 0.9);
    }
}

export function create(o) {
  const C = fit(o.palette, 6), R = new Rng(o.seed), H = o.height, F = o.feet;
  const ps = new Particles({ rng: R, ground: () => 999 });
  // las cruces: salen alrededor del cuerpo, una detrás de otra, y suben
  const cruces = Array.from({ length: 5 }, (_, i) => ({
    x: [-9, 8, -4, 10, -11][i] + R.range(-1, 1), y: F - R.range(14, H - 6), t0: 0.12 + i * 0.09, v: R.range(16, 24), n: i % 2 ? 1 : 2,
  }));
  // las rayitas de luz que suben por la columna
  const rayas = Array.from({ length: 9 }, (_, i) => ({ x: R.range(-ANCHO + 2, ANCHO - 2), t0: 0.05 + i * 0.05 + R.range(0, 0.03), v: R.range(70, 100), l: R.range(4, 8) }));
  for (let i = 0; i < 14; i++)
    ps.spawn(P.MOTE, R.range(-ANCHO, ANCHO), F - R.range(0, H), R.range(-5, 5), -R.range(18, 40), R.range(0.4, 0.8), R.pick([C[4], C[5], WHITE]), 1, R.range(0.05, 0.4));
  let t = 0;
  // lo encendida que está la columna: de golpe, se mantiene y se apaga
  const fuerza = () => (t < 0.12 ? t / 0.12 : 1 - clamp((t - 0.35) / 0.55));
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
    },
    drawBack(p) {
      const k = fuerza();
      // el círculo de luz a sus pies y su borde
      if (k > 0) {
        p.glow(0, F, 16, C[3], 0.35 * k);
        band(p, 0, F, 13, VISTA, 1, k * 0.9, C);
      }
      // el anillo que se abre
      const u = clamp(t / 0.5);
      if (u < 1) band(p, 0, F, 6 + 20 * ease.outCubic(u), VISTA, 2, 1 - u, C);
    },
    draw(p) {
      const k = fuerza();
      if (k > 0) {
        // los dos hilos de la columna a los lados, más tenues arriba
        for (let y = 0; y <= H + 6; y++) {
          const a = k * (1 - y / (H + 6)) * 0.9;
          for (const s of [-1, 1]) {
            const x = s * Math.round(ANCHO * (1 - 0.08 * Math.sin(y * 0.4 + t * 12)));
            p.dot(x, F - y, y % 5 === 0 ? C[5] : C[3], a);
            p.light(x, F - y, C[3], a * 0.6);
          }
        }
        // el brillo que le envuelve
        p.glow(0, F - H * 0.5, 20, C[3], 0.4 * k);
      }
      // las rayitas que suben por dentro
      for (const r of rayas) {
        const y0 = F - (t - r.t0) * r.v;
        if (t < r.t0 || y0 < F - H - 8) continue;
        for (let d = 0; d < r.l; d++) p.dot(r.x, Math.round(y0 + d), d === 0 ? WHITE : C[4], (1 - d / r.l) * 0.85);
      }
      // las cruces
      for (const c of cruces) {
        const u = (t - c.t0) / 0.6;
        if (u < 0 || u > 1) continue;
        cruz(p, c.x, c.y - u * c.v, c.n, C, u < 0.65 ? 1 : 1 - (u - 0.65) / 0.35);
      }
      ps.draw(p, "front");
    },
  };
}
