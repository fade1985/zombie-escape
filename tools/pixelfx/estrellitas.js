// Las estrellitas de quien se ha quedado atontado (un jefe al estrellarse o con un bidón, minijefe.gd; Johnny en el
// suelo, johnny.gd): el "stunned" de pixelfx (licencia MIT, © Patch, https://github.com/patch-gg/pixelfx) sin el
// muñeco: tres estrellas que giran y dos pajaritos dan vueltas sobre la cabeza en un anillo inclinado, pasando por
// detrás (la capa de detrás, más apagada) y por delante, dejando purpurina. El origen es el centro del anillo; el
// juego lo pone sobre la cabeza y lo agranda o lo achica con el tamaño de cada uno. Se repite sin costura (2 s).
// Lo exporta tools/pixelfx/exportar.mjs a assets/sprites/estrellitas-*.png.
import { cycle, fit, hex, mix, sparkle, flare, rand, TAU } from "../../core/index.js";
import { icon, bitmap, shaped, starShape } from "../status/_lib.js";

export const meta = {
  name: "Estrellitas",
  desc: "Seeing stars, without the body: three spinning stars and two little birds circle a head on a tilted ring, ducking behind it and sweeping round in front, trailing glitter.",
  tags: ["status", "stun", "dizzy", "stars", "birds", "loop"],
  size: [64, 44],
  origin: [32, 26],
  duration: 2,
  loop: true,
  fps: 30,
  options: {
    palette: ["#3a1e0c", "#8a4a12", "#d88a1c", "#f5c030", "#ffe36e", "#fff6c8", "#ffffff"],
    birds: ["#1a1422", "#6a7fae", "#b8c8e8", "#f4f8ff"],
    beak: "#ffae35",
    seed: 2,
  },
};

// la cabeza que haría de muñeco (la del "stunned": su anillo va 2 píxeles por debajo de lo alto de la cabeza)
const A = { y: -2, w: 24 };
const D = meta.duration, TURNS = 2, N = 5;
const STAR7 = ["...#...", "..###..", "#######", ".#####.", "..###..", ".##.##.", ".#...#."];
// un pajarito mirando a la derecha: cuerpo, cabeza, ojo, pico, cola y un ala que bate
const BIRD = [true, false].map((up) => (dx, dy) => {
  const x = dx + 0.5, y = dy + 0.5;
  if (dx === 3 && dy === -2) return "e";
  if ((dx === 5 || dx === 4) && dy === -1) return dx === 5 ? "b" : "#";
  const wing = up ? [[-1, -1], [-1, -2], [-2, -2], [-2, -3], [-3, -3], [-3, -4]] : [[-1, 1], [-1, 2], [-2, 2], [-2, 3], [0, 1]];
  if (wing.some(([a, b]) => a === dx && b === dy)) return "w";
  if ((x / 3.3) ** 2 + ((y - 0.6) / 1.9) ** 2 <= 1 || (x - 2.8) ** 2 + (y + 1.2) ** 2 <= 1.7 ** 2) return "#";
  if ((dx === -4 && (dy === -1 || dy === 0)) || (dx === -5 && dy === -1)) return "#";
  return "";
});
const STAR = shaped.bind(null, starShape(0.44));

// el anillo: estrellas en 0, 2 y 4, pajaritos entre medias
function ring(t) {
  const cy = A.y + 2, rx = A.w * 0.62, ry = 4.5;
  return Array.from({ length: N }, (_, i) => {
    const th = TAU * ((TURNS * t) / D + i / N), s = Math.sin(th);
    return { i, th, x: Math.cos(th) * rx, y: cy + s * ry, near: s >= 0, depth: 0.5 + 0.5 * s, bird: i % 2 === 1, rx, ry, cy };
  });
}

function draw1(p, t, o, layer) {
  const C = fit(o.palette, 7), Bd = fit(o.birds, 4), far = layer === "back";
  const dim = (c) => (far ? mix(c, Bd[0], 0.3) : c);
  for (const it of ring(t)) {
    if (it.near === far) continue;
    if (!it.bird)
      for (let k = 1; k <= 12; k++) {
        const th = it.th - k * 0.085, x = Math.cos(th) * it.rx, y = it.cy - 1 + Math.sin(th) * it.ry;
        if (Math.sin(th) >= 0 === far || rand(it.i, k, Math.floor(((t / D) * TURNS + k * 0.37) * 9)) < 0.25) continue;
        p.dot(x, y, dim(k < 4 ? C[6] : k < 8 ? C[5] : C[4]), 1.1 - k / 13);
        if (k < 6) p.light(x, y, C[4], 0.3 * (1 - k / 6));
      }
    if (it.bird) {
      const up = Math.floor(t * 8 + it.i * 0.5) % 2 === 0, bob = Math.sin((t / D) * TAU * 4 + it.i) * 0.7, flip = it.near;
      const f = BIRD[up ? 0 : 1], ins = flip ? (dx, dy) => f(-dx, dy) : f;
      icon(p, it.x, it.y - 3 + bob, 7, ins, [Bd[0], dim(Bd[1]), dim(Bd[2]), dim(Bd[3])], 1, { e: Bd[0], b: dim(hex(o.beak)), w: dim(Bd[1]) });
    } else {
      const spin = (t / D) * TAU * 3 + it.i, R = [C[0], dim(C[3]), dim(C[4]), dim(C[5])];
      if (it.depth > 0.55) icon(p, it.x, it.y - 1, 7, STAR(4 + 0.8 * it.depth, spin), R);
      else icon(p, it.x, it.y - 1, 5, bitmap(STAR7), R);
      p.px(it.x, it.y - 1, far ? C[5] : C[6]);
      p.glow(it.x, it.y - 1, 11, C[4], 0.24 + 0.3 * it.depth);
      p.glow(it.x, it.y - 1, 4, C[6], 0.3 * it.depth);
      const fr = Math.exp(-((Math.atan2(Math.sin(it.th - Math.PI / 2), Math.cos(it.th - Math.PI / 2)) / 0.32) ** 2));
      if (!far && fr > 0.08) flare(p, it.x, it.y - 1, 9 * fr, fr, [C[3], C[4], C[5], C[6]]);
    }
  }
}

export function drawBack(p, t, o) {
  draw1(p, t, o, "back");
}

export function draw(p, t, o) {
  const C = fit(o.palette, 7);
  draw1(p, t, o, "front");
  // chispitas que saltan alrededor del anillo
  cycle(t, D, 14, o.seed + 3, (r) => r.range(0.25, 0.5), (age, life, r) => {
    const th = r.range(0, TAU), u = age / life, x = Math.cos(th) * A.w * r.range(0.45, 0.95), y = A.y + 1 + Math.sin(th) * 7 - r.range(0, 9);
    const arm = Math.round(r.range(1, 2.6) * Math.sin(Math.PI * u));
    if (arm < 1) p.dot(x, y, C[6], Math.sin(Math.PI * u) * 1.4);
    sparkle(p, x, y, arm, C[5], C[4], 0.35 * Math.sin(Math.PI * u));
  });
  p.glow(0, A.y + 1, 26, C[4], 0.13);
}
