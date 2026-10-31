// La chispa de una bala al dar a un zombi: el "hit-spark" de pixelfx 0.3.0 (que viene del impact de Sprite Fusion,
// licencia MIT, Hugo Duprez) con dos cosas más para el juego:
//  - "talla": la de una bala o la de un perdigón de la escopeta (más pequeña y con menos chispas, porque dan
//    varios a la vez).
//  - "aim" en cualquier dirección (el original casi siempre a la derecha): la cruz y el chorro de chispas miran hacia
//    donde iba la bala, pero las chispas siguen cayendo hacia abajo de la pantalla, al suelo, como en la vista desde
//    arriba del juego.
// El origen es el suelo, debajo del golpe; el golpe va "height" píxeles más arriba (a la altura de la bala).
// Se exporta con: node tools/pixelfx/exportar_chispa.mjs <carpeta de pixelfx> assets/sprites
import { Particles, Lights, P, Rng, fit, WHITE } from "../../core/index.js";

export const meta = {
  name: "Chispa",
  desc: "La chispa de una bala al dar: una cruz con un rayo largo hacia donde iba, un rombo blanco y chispas que caen y rebotan.",
  tags: ["impact", "hit", "spark", "one-shot"],
  size: [160, 120],
  origin: [80, 70],
  duration: 0.4,
  loop: false,
  fps: 30,
  options: { palette: ["#4a1712", "#c9281f", "#f2561d", "#ff8a2a", "#ffe26b", "#fff3a6", "#ffffff"], height: 11, aim: 0, talla: 1, seed: 4 },
};

// Los colores, de oscuro a blanco: los de siempre (los de la trazadora), la crítica (más roja) y los de cada calidad
// mejorada (los de Armas.traza, con uno más oscuro delante)
export const COLORES = {
  normal: ["#4a1712", "#c9281f", "#f2561d", "#ff8a2a", "#ffe26b", "#fff3a6", "#ffffff"],
  critica: ["#5a0915", "#b3122a", "#ff4d2e", "#ff9a3c", "#ffe9a8", "#fff6dc", "#ffffff"],
  poco_comun: ["#0f4a0f", "#217821", "#3fb33f", "#5fd35f", "#b9ffb9", "#f1fff1", "#ffffff"],
  rara: ["#042e59", "#105091", "#2980d9", "#4aa3ff", "#a4d1ff", "#edf6ff", "#ffffff"],
  epica: ["#3a0f59", "#622391", "#9a45d9", "#c06bff", "#e0b5ff", "#f9f0ff", "#ffffff"],
};

// un rayo de la cruz: gordo en la raíz, un pelo en la punta, blanco que se enfría hacia fuera
function ray(p, x, y, a, L, w, C, from = 0) {
  const c = Math.cos(a), s = Math.sin(a);
  for (let d = from * L; d <= L; d += 0.5) {
    const u = d / L, hw = w * Math.pow(1 - u, 1.6);
    const col = u < 0.3 ? WHITE : u < 0.62 ? C[5] : u < 0.88 ? C[4] : C[3];
    p.px(x + c * d, y + s * d, col);
    if (hw > 0.45) for (let o = 0.5; o <= hw; o += 0.5) for (const e of [-o, o]) p.px(x + c * d - s * e, y + s * d + c * e, u < 0.3 && o < 1 ? C[5] : C[4]);
  }
}

// el centro: un rombo blanco con el borde claro
function diamond(p, x, y, r, C) {
  for (let dy = -r - 1; dy <= r + 1; dy++)
    for (let dx = -r - 1; dx <= r + 1; dx++) {
      const m = Math.abs(dx) + Math.abs(dy);
      if (m <= r) p.px(x + dx, y + dy, WHITE);
      else if (m === r + 1) p.px(x + dx, y + dy, C[3]);
    }
}

export function create(o) {
  const C = fit(o.palette, 7), R = new Rng(o.seed), X = 0, Y = -o.height, A = o.aim, K = o.talla, floor = () => 0;
  const ps = new Particles({ rng: R, ground: floor, sparks: [C[6], C[5], C[4], C[2]] });
  const lights = new Lights();
  // la cruz: un rayo largo y fino hacia donde iba la bala, uno corto detrás, dos brazos desiguales y un destello entre medias
  const tilt = R.range(-0.08, 0.08);
  const rays = [
    { a: A + tilt, L: R.range(33, 37) * K, w: 2.2 * Math.sqrt(K) },
    { a: A + Math.PI + tilt, L: R.range(8, 10) * K, w: 2.2 * Math.sqrt(K) },
    { a: A - Math.PI / 2 + tilt, L: R.range(15, 18) * K, w: 2.6 * Math.sqrt(K) },
    { a: A + Math.PI / 2 + tilt, L: R.range(10, 12) * K, w: 2.3 * Math.sqrt(K) },
    { a: A - Math.PI / 4 + tilt, L: R.range(5, 7) * K, w: 1 },
  ];
  const rombo = Math.max(2, Math.round(4 * K));

  lights.add(X, Y, 38 * K, C[4], 0.35, 0.18);
  lights.add(X + Math.cos(A) * 10 * K, Y + Math.sin(A) * 10 * K, 22 * K, C[5], 0.45, 0.1);
  lights.add(X, -2, 26 * K, C[3], 0.22, 0.22);
  // un cono de chispas hacia donde iba la bala: caen, rebotan en el suelo y se apagan
  const n = Math.round(9 * K), V = 0.6 * K + 0.1;   // (más despacio que en pixelfx: aquí un personaje mide 48)
  for (let i = 0; i < n; i++) {
    const a = A + R.range(-0.6, 0.6) - 0.15 * Math.cos(A), v = R.range(170, 360) * V;
    ps.spawn(P.SPARK, X + Math.cos(A), Y, Math.cos(a) * v, Math.sin(a) * v - 40 * V, R.range(0.2, 0.36), WHITE, 1, i > n - 3 ? R.range(0.01, 0.03) : 0);
  }
  // trocitos al rojo que saltan y caen tintineando
  for (let i = 0; i < Math.round(6 * K); i++) {
    const a = A + R.range(-1.1, 0.5) - 0.3 * Math.cos(A), v = R.range(70, 170) * V;
    ps.spawn(P.GRIT, X + Math.cos(A), Y, Math.cos(a) * v, Math.sin(a) * v - R.range(30, 80) * V, R.range(0.28, 0.38), R.pick([C[5], C[4], C[4], C[3]]), 1);
  }

  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
      lights.update(dt);
    },
    draw(p) {
      ps.draw(p);
      if (t < 0.025) {
        // el destello: la cruz entera alrededor del rombo
        for (const r of rays) ray(p, X, Y, r.a, r.L, r.w, C);
        diamond(p, X, Y, rombo, C);
      } else if (t < 0.058) {
        // más larga y más fina, el rombo todavía nítido
        for (const r of rays) ray(p, X, Y, r.a, r.L * 1.2, r.w * 0.55, C, 0.12);
        diamond(p, X, Y, rombo - 1, C);
      } else if (t < 0.092) {
        // solo queda el rayo largo, que se quema desde la raíz
        const r = rays[0];
        ray(p, X, Y, r.a, r.L * 1.3, 0.6, [C[0], C[1], C[2], C[3], C[3], C[4]], 0.4);
      }
      const pop = Math.exp(-t / 0.045);
      if (pop > 0.02) {
        p.glow(X, Y, 22 * K, C[4], 0.3 * pop);
        p.glow(X, Y, 7 * K, WHITE, 0.15 * pop);
        p.glowLine(X, Y, X + Math.cos(A) * 26 * K, Y + Math.sin(A) * 26 * K, 4, C[5], 0.25 * pop);
      }
      lights.draw(p);
    },
  };
}
