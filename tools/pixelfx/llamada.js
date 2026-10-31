// La llamada de la atraedora (M52; granada.gd): cada vez que pita, un pulso de sonido que se abre por el suelo, visto desde
// arriba, para que se note que está llamando a los zombis. Como los pitidos van cada vez más deprisa, los pulsos también.
// Hecho para el juego con la banda de los anillos de pixelfx:
//  - dos ondas amarillas que se abren por el suelo en elipse (VISTA: lo de arriba abajo más corto), una detrás de otra, y
//    se apagan a lo lejos;
//  - en el despertador, unas rayitas que vibran a los lados (el ring-ring) y un destello.
// "reach": hasta dónde llega la onda, en píxeles del dibujo · "height": a qué altura está el despertador. El origen es el
// suelo, debajo de la granada. Lo exporta exportar.mjs.
import { Rng, fit, band, clamp, ease, WHITE } from "../../core/index.js";

export const meta = {
  name: "Llamada",
  desc: "An alarm calling, seen from above: two yellow sound rings open over the floor and fade far out, and little ring-ring lines buzz at the clock.",
  tags: ["sound", "pulse", "lure", "ring", "one-shot"],
  size: [168, 112],
  origin: [84, 60],
  duration: 0.6,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#3a2a08", "#7a5a10", "#b8901c", "#e0a820", "#ffd23f", "#ffe060", "#fff0a0"], reach: 76, height: 10, seed: 2 },
};

const VISTA = 0.6, ONDAS = [[0, 0.5], [0.1, 0.45]];

export function create(o) {
  const C = fit(o.palette, 7), R = new Rng(o.seed), REACH = o.reach, H = o.height;
  let t = 0;
  const onda = (p, delante) => {
    for (const [desde, dura] of ONDAS) {
      const u = clamp((t - desde) / dura);
      if (u <= 0 || u >= 1) continue;
      const r = 4 + (REACH - 4) * ease.outCubic(u), k = (1 - u) * (desde ? 0.6 : 1);
      band(p, 0, 0, r, VISTA, Math.max(1.5, 4 * (1 - u)), k, C, (g) => (Math.sin(g) >= 0) === delante);
    }
  };
  return {
    update(dt) {
      t += dt;
    },
    drawBack(p) {
      onda(p, false);
    },
    draw(p) {
      onda(p, true);
      // el ring-ring: rayitas que vibran a los dos lados del despertador
      if (t < 0.3) {
        const k = 1 - t / 0.3, f = Math.floor(t * 30) % 2;
        for (const s of [-1, 1])
          for (let i = 0; i < 3; i++) {
            const a = -0.6 + i * 0.6, d0 = 6 + f, d1 = 9 + f + i % 2;
            p.line(s * Math.cos(a) * d0, -H + Math.sin(a) * d0, s * Math.cos(a) * d1, -H + Math.sin(a) * d1, i === 1 ? WHITE : C[4], k);
          }
        p.glow(0, -H, 10, C[3], 0.5 * k);
        if (t < 0.05) p.glow(0, -H, 5, WHITE, 0.6);
      }
    },
  };
}
