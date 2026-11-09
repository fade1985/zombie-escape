// El chispazo de la electricidad al dar a un zombi (M50): el del lanza rayos en cada zombi que toca, el de la descarga
// que salta de uno a otro, el del estallido del arma Épica y el de Pararrayos (ArmasCreadas.rayo). Sale del "zap-hit" de
// pixelfx (que viene del rayo de Sprite Fusion, licencia MIT, Hugo Duprez), pasado a la vista desde arriba del juego y
// sin el arco que llega desde la izquierda (el rayo lo pone el juego, relampago.gd):
//  - el golpe es un nudo de rayitos que se cruzan, rehecho en cada fotograma, alrededor de un corazón blanco;
//  - chispas que saltan haciendo eses y caen al suelo;
//  - en el suelo, debajo, una quemadura en forma de helecho (como la de un rayo de verdad) que se enciende hacia fuera,
//    se enfría y se va. Va aplastada de arriba abajo (VISTA), como lo que hay en el suelo visto desde arriba.
// El origen es el suelo, debajo del golpe; el golpe va "height" píxeles más arriba (a la altura del cuerpo).
// Los colores, los celestes del lanza rayos (llamarada.gd). Lo exporta exportar.mjs (lo copia a src/fx/holy/).
import { Particles, Lights, P, Rng, fit, smooth, rng, TAU, WHITE, hex, mix } from "../../core/index.js";
import { zigzag, crackle } from "../lightning/_lib.js";

export const meta = {
  name: "Chispazo",
  desc: "An electric hit seen from above: a knot of crackling zigzags on a white heart, sparks that jink and fall, and a fern of burn marks that glows out on the floor and cools.",
  tags: ["lightning", "electric", "hit", "impact", "one-shot"],
  size: [128, 112],   // (con sitio para que la luz del golpe no se salga: antes, 96 x 80, y dejaba un recuadro)
  origin: [64, 72],
  duration: 0.5,
  loop: false,
  fps: 30,
  bg: "dark",
  options: { palette: ["#06262e", "#07505a", "#0aa0a2", "#16c8cc", "#2cf2f0", "#9fe8ff", "#ecffff", "#ffffff"], height: 20, seed: 3 },
};

const VISTA = 0.55, ASH = hex("#5a6a72");

// la quemadura en el suelo: ramas que salen del centro, y de ellas otras más cortas a un lado y a otro
function helecho(R) {
  const out = [];
  const crecer = (x, y, a, largo, w, d, nivel) => {
    const pts = [[x, y, d]];
    let lado = R.sign();
    for (let s = 0; s < largo; s += 1.4) {
      a += R.range(-0.3, 0.3);
      x += Math.cos(a) * 1.4;
      y += Math.sin(a) * 1.4 * VISTA;
      d += 1.4;
      pts.push([x, y, d]);
      if (nivel < 1 && s > 2 && R.chance(0.25)) {
        lado = -lado;
        crecer(x, y, a + lado * R.range(0.55, 1.05), (largo - s) * R.range(0.3, 0.55), w * 0.6, d, nivel + 1);
      }
    }
    out.push({ pts, w });
  };
  for (let i = 0; i < 5; i++) crecer(0, 0, (i / 5) * TAU + R.range(-0.35, 0.35), R.range(10, 17), 1, 0, 0);
  return out;
}

export function create(o) {
  const C = fit(o.palette, 8).map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed);
  const H = o.height, ps = new Particles({ rng: R, ground: () => 999 }), lights = new Lights();
  const rama = helecho(R);
  // las chispas: salen del golpe y cambian de rumbo de golpe cada poco; caen hacia el suelo
  const chispas = Array.from({ length: 12 }, () => {
    const a = R.range(0, TAU), sp = R.range(110, 210);
    return { x: 0, y: -H, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA - 50, life: R.range(0.18, 0.34), age: 0, next: R.range(0.02, 0.05), rastro: [] };
  });
  lights.add(0, -H, 50, C[4], 0.7, 0.25);
  lights.add(0, -H, 12, WHITE, 0.5, 0.06);
  for (let i = 0; i < 2; i++)
    ps.spawn(P.SMOKE, R.range(-3, 3), -H + R.range(-3, 2), R.range(-5, 5), -R.range(8, 14), R.range(0.25, 0.35), mix(ASH, C[4], 0.3), R.range(2, 3), R.range(0.08, 0.14));
  let t = 0;
  return {
    update(dt) {
      t += dt;
      for (const s of chispas) {
        if ((s.age += dt) >= s.life) continue;
        if ((s.next -= dt) <= 0) {
          s.next = R.range(0.025, 0.05);
          const sp = Math.hypot(s.vx, s.vy), a = Math.atan2(s.vy, s.vx) + R.sign() * R.range(0.6, 1.3);
          s.vx = Math.cos(a) * sp;
          s.vy = Math.sin(a) * sp;
          s.rastro.push([s.x, s.y]);
          if (s.rastro.length > 4) s.rastro.shift();
        }
        s.vx -= s.vx * 3 * dt;
        s.vy -= s.vy * 3 * dt - 220 * dt;
        s.x += s.vx * dt;
        s.y += s.vy * dt;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // el helecho se enciende desde el centro, blanco, se enfría bajando por los colores y se va
      const enfria = smooth(0.15, 0.4, t), va = 1 - smooth(0.36, 0.48, t);
      for (const br of rama)
        for (let i = 1; i < br.pts.length; i++) {
          const [x0, y0] = br.pts[i - 1], [x, y, d] = br.pts[i], edad = t - d / 200;
          if (edad < 0) break;
          const k = Math.exp(-edad / 0.12) - enfria * 0.3;
          const c = k > 0.75 ? WHITE : k > 0.45 ? C[6] : k > 0.25 ? C[5] : k > 0.1 ? C[4] : k > -0.05 ? C[2] : C[1];
          p.line(x0, y0, x, y, c, va);
          if ((i & 3) === 0 && k > 0) p.glow(x, y, 4, C[5], 0.3 * k * va);
        }
      ps.draw(p, "back");
    },
    draw(p) {
      const f = Math.floor(t * 20 + 1e-4);
      // el golpe: un nudo de rayitos que se rehace en cada fotograma, alrededor de un corazón blanco
      if (t < 0.3) {
        const a = t / 0.3, r = rng(o.seed, 5, f), R0 = 9 * (1 - a * 0.5), m = Math.round(10 * (1 - a * 0.5));
        for (let i = 0; i < m; i++) {
          const ang = r.range(0, TAU), d0 = r.range(0.5, R0 * 0.5), ang2 = ang + r.range(-1.2, 1.2), d1 = r.range(R0 * 0.55, R0);
          crackle(p, zigzag(r, Math.cos(ang) * d0, -H + Math.sin(ang) * d0, Math.cos(ang2) * d1, -H + Math.sin(ang2) * d1, 0.5, 0), 0.75 * (1 - a) + 0.25, C, 0.25);
        }
        p.circle(0, -H, 3 * (1 - a) + 1, C[5]);
        p.circle(0, -H, 2 * (1 - a) + 0.5, WHITE);
        p.glow(0, -H, 18, C[4], 0.55 * (1 - a));
        if (t < 0.06) p.glow(0, -H, 9, WHITE, 0.45);
      }
      // las chispas: la cabeza brillante y detrás las eses, que se enfrían
      for (const s of chispas) {
        if (s.age >= s.life) continue;
        const k = 1 - s.age / s.life, camino = [...s.rastro, [s.x, s.y]];
        for (let i = 0; i < camino.length - 1; i++)
          p.line(camino[i][0], camino[i][1], camino[i + 1][0], camino[i + 1][1], i === camino.length - 2 ? (k > 0.5 ? WHITE : C[6]) : k > 0.5 ? C[5] : C[4], 0.6 + 0.4 * (i / camino.length));
        p.px(s.x, s.y, k > 0.4 ? WHITE : C[5]);
        p.glow(s.x, s.y, 4, C[5], 0.4 * k);
      }
      // la luz, que parpadea al apagarse
      p.glow(0, -H, 34 * Math.max(0, 1 - t / 0.45), C[3], 0.45 * Math.exp(-t * 6) * (f % 2 ? 0.7 : 1));
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
