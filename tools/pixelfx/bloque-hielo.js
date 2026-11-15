// El bloque de hielo que envuelve a un zombi congelado (zombi.congelar, lanza hielo y demás), visto desde arriba. Hecho
// para el juego con el bloque facetado del "ice/freeze" de pixelfx (las mismas caras y aristas, del tamaño de un
// zombi de 48 px):
//  - la escarcha corre por el suelo hasta los pies y forma una costra alrededor, con helechos de hielo;
//  - el bloque cristaliza cara a cara, de abajo arriba: cada cara se perfila en blanco, destella y queda de cristal
//    (medio transparente, para que se vea el zombi dentro), con su esquirla y su brillo; al cerrarse, una estrella en
//    la punta;
//  - y luego se queda (de FORMA en adelante es un bucle de CICLO segundos que el juego repite mientras le dura el
//    congelado): una luz que barre las caras y destellos en las esquinas, siempre en el mismo sitio y momento para que
//    el bucle empalme sin saltos.
// Al acabarse, el juego lo quita y suelta el "deshielo" (o, si muere congelado, los "anicos").
// El origen son los pies del zombi. Lo exporta exportar.mjs (con 'bucle' en EfectoSuelo.TIPOS).
import { Particles, Lights, P, Rng, fit, sparkle, clamp, smooth, rand, TAU, WHITE } from "../../core/index.js";

const FORMA = 0.5, CICLO = 1.2;

export const meta = {
  name: "Bloque de hielo",
  desc: "Frost races to a frozen zombie's feet and a faceted ice block crystallizes round it pane by pane, then holds, with light sweeping its faces and glints on its corners (loops after the forming part).",
  tags: ["ice", "freeze", "frozen", "status", "loop"],
  size: [64, 76],
  origin: [32, 66],
  duration: FORMA + CICLO,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#151a3d", "#212f6b", "#2c58aa", "#3a8bd8", "#62c8f4", "#a6ecff", "#dcfbff", "#ffffff"], seed: 5 },
};

const VISTA = 0.5;   // el suelo, aplastado (se ve un poco desde arriba)
const SNAP = 0.12;   // lo que tarda la escarcha en llegar a los pies
const SEAL = 0.12;   // cuando empieza a cristalizar el bloque (y cada cara, un poco después: FACETS)

// el bloque (el de "ice/freeze"): una corona de tres puntas sobre lados rectos, en trece caras. Cada cara: sus
// esquinas, cuánta luz coge (0 sombra .. 1 iluminada) y cuándo cristaliza
const V = {
  l0: [-15, 0], l1: [-17, -10], l2: [-17, -31], p1: [-12, -45], n1: [-6, -42], p2: [0, -52], n2: [6, -43], p3: [12, -47], r2: [17, -30], r1: [16, -9], r0: [14, 0],
  i0: [-6, -36], i1: [6, -35], i2: [-9, -21], i3: [3, -25], i4: [9, -13], i5: [-5, -8], i6: [2, 0], i7: [0, -40],
};
const FACETS = [
  ["l0 l1 i5 i6", 0.62, 0], ["i5 i4 i6", 0.42, 0.02], ["i4 r2 r1 r0 i6", 0.2, 0.04], ["l1 l2 i2 i5", 0.74, 0.06], ["i2 i3 i4 i5", 0.5, 0.08],
  ["i1 r2 i4 i3", 0.28, 0.1], ["l2 i0 i2", 0.7, 0.12], ["i0 i1 i3 i2", 0.58, 0.14], ["n1 i7 n2 i1 i0", 0.52, 0.16], ["i1 n2 p3 r2", 0.4, 0.18],
  ["l2 p1 n1 i0", 0.88, 0.2], ["p2 n2 i7", 0.66, 0.22], ["n1 p2 i7", 1, 0.24],
].map(([k, lit, at], i) => ({ pts: k.split(" ").map((v) => V[v]), lit, at: SEAL + at, i }));
const OUTLINE = "l0 l1 l2 p1 n1 p2 n2 p3 r2 r1 r0".split(" ").map((v) => V[v]);
const X0 = -18, X1 = 18, Y0 = -53, Y1 = 0, BW = X1 - X0;
const VERTS = [V.p1, V.p2, V.p3, V.l2, V.r2, V.n1, V.n2, V.l1, V.r1];

const inPoly = (pts, x, y) => {
  let c = false;
  for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    const [xi, yi] = pts[i], [xj, yj] = pts[j];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
  }
  return c;
};
const centroid = (pts) => ({ x: pts.reduce((s, q) => s + q[0], 0) / pts.length, y: pts.reduce((s, q) => s + q[1], 0) / pts.length });

// la costra de escarcha del suelo: una elipse alrededor de los pies que llega desde fuera, con helechos que salen
function floorFrost(p, C, t) {
  const RX = 24, RY = RX * VISTA;
  for (let y = -RY - 2; y <= RY + 2; y++)
    for (let x = -RX - 2; x <= RX + 2; x++) {
      const d = Math.hypot(x / RX, y / RY);
      if (d > 1.05) continue;
      const llega = SNAP * (1 - d) * 0.6 + SNAP * d * 0.4, age = t - (SNAP - llega);
      if (age < 0) continue;
      const h = rand(x * 7 + 3, y * 13 + 1), borde = d > 0.8;
      if (borde && h > 0.45) continue;   // el borde, deshilachado
      if (!borde && h > 0.75 && d > 0.5) continue;
      const fresh = age < 0.05;
      p.dot(x, y, fresh ? WHITE : d < 0.45 ? C[5] : h < 0.2 ? C[6] : C[4], (borde ? 0.55 : 0.7) * (1.1 - d * 0.5));
    }
  // los helechos: rayitas de escarcha que salen hacia fuera
  for (let k = 0; k < 14; k++) {
    const a = (k / 14) * TAU + rand(k, 3) * 0.4, L = 3 + rand(k, 9) * 5, g = smooth(SNAP * 0.5, SNAP + 0.15, t);
    const x0 = Math.cos(a) * 20, y0 = Math.sin(a) * 20 * VISTA;
    const n = Math.round(L * g);
    for (let j = 0; j < n; j++) p.dot(x0 + Math.cos(a) * j, y0 + Math.sin(a) * j * VISTA, j === n - 1 ? WHITE : C[5], 0.8);
  }
}

export function create(o) {
  const C = fit(o.palette, 8), R = new Rng(o.seed);
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [C[7], C[6], C[5], C[4]], haze: C[5] }), lights = new Lights();

  // qué cara es cada píxel del bloque
  const fid = new Int8Array(BW * (Y1 - Y0)).fill(-1);
  for (let y = Y0; y < Y1; y++)
    for (let x = X0; x < X1; x++) {
      if (!inPoly(OUTLINE, x + 0.5, y + 0.5)) continue;
      let f = FACETS.findIndex((F) => inPoly(F.pts, x + 0.5, y + 0.5));
      if (f < 0) {
        let best = 1e9;
        FACETS.forEach((F, k) => {
          const c = centroid(F.pts), d = Math.hypot(c.x - x, c.y - y);
          if (d < best) (best = d), (f = k);
        });
      }
      fid[(y - Y0) * BW + (x - X0)] = f;
    }
  const at = (x, y) => (x < X0 || x >= X1 || y < Y0 || y >= Y1 ? -1 : fid[(y - Y0) * BW + (x - X0)]);
  for (const F of FACETS) {
    F.c = centroid(F.pts);
    F.tint = C[3 + Math.round(F.lit * 3)];
    F.alpha = 0.06 + 0.12 * F.lit;
    F.d = clamp((F.c.x + 0.55 * F.c.y + 36) / 46);   // por dónde le pasa la luz (de arriba a la izquierda abajo a la derecha)
    F.len = F.pts.reduce((s, q, k) => s + Math.hypot(F.pts[(k + 1) % F.pts.length][0] - q[0], F.pts[(k + 1) % F.pts.length][1] - q[1]), 0);
  }
  // cada arista una vez: sus puntas, las caras que separa, si es del contorno y hacia dónde mira
  const EDGES = [];
  for (const F of FACETS)
    F.pts.forEach((a, k) => {
      const b = F.pts[(k + 1) % F.pts.length];
      let e = EDGES.find((e) => (e.a === a && e.b === b) || (e.a === b && e.b === a));
      if (!e) EDGES.push((e = { a, b, fs: [] }));
      e.fs.push(F);
    });
  for (const e of EDGES) {
    const [x0, y0] = e.a, [x1, y1] = e.b, c = e.fs[0].c;
    let nx = y1 - y0, ny = x0 - x1;
    if (nx * ((x0 + x1) / 2 - c.x) + ny * ((y0 + y1) / 2 - c.y) < 0) (nx = -nx), (ny = -ny);
    e.outer = e.fs.length === 1;
    e.lit = (-nx * 0.55 - ny * 0.84) / Math.hypot(nx, ny);
    e.floor = y0 === 0 && y1 === 0;
    e.at = Math.min(...e.fs.map((F) => F.at));
  }

  let t = 0, formed = 0, sealed = false;
  // en el bucle (de FORMA en adelante), el tiempo del ciclo: la luz que barre y los destellos van con él
  const ciclo = () => (t < FORMA ? -1 : (t - FORMA) % CICLO);
  const vida = (l) => Math.max(0.05, Math.min(l, FORMA - 0.02 - t));   // (nada de la formación pasa al bucle)

  return {
    update(dt) {
      t += dt;
      if (t < SNAP)
        for (const s of [-1, 1])
          if (R.chance(0.35)) ps.spawn(P.STREAK, s * 24 * (1 - t / SNAP), R.range(-3, 3), -s * R.range(50, 90), 0, vida(R.range(0.08, 0.12)), R.chance(0.5) ? C[6] : C[5]);
      // cada cara encaja con un destello, su estrellita y un poco de vaho
      while (formed < FACETS.length && t >= FACETS[formed].at) {
        const F = FACETS[formed++];
        ps.spawn(P.STAR, F.c.x + R.range(-2, 2), F.c.y + R.range(-2, 2), 0, -4, vida(R.range(0.15, 0.3)), WHITE, R.range(1, 2));
        if (F.c.y > -14) ps.spawn(P.VAPOUR, F.c.x, -1, Math.sign(F.c.x || 1) * R.range(10, 25), -R.range(2, 6), vida(R.range(0.25, 0.35)), C[6], R.range(2, 3));
        lights.add(F.c.x, F.c.y, 14, C[6], 0.4, 0.1);
      }
      if (!sealed && formed === FACETS.length) {
        sealed = true;
        lights.add(0, -26, 50, C[5], 0.5, Math.min(0.3, FORMA - t - 0.02));
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      floorFrost(p, C, t);
      ps.draw(p, "back");
    },
    draw(p) {
      if (t >= SEAL - 0.06) {
        const c = ciclo();
        // la luz que barre las caras (una vez por ciclo; en la formación, ninguna)
        for (const F of FACETS) F.g = c < 0 ? 0 : Math.sin(Math.PI * clamp((c - 0.25 - F.d * 0.3) / 0.14)) * (0.35 + 0.65 * F.lit);
        for (let y = Y0; y < Y1; y++)
          for (let x = X0; x < X1; x++) {
            const f = at(x, y);
            if (f < 0) continue;
            const F = FACETS[f], age = t - F.at;
            if (age < 0) continue;
            if (age < 0.03) {
              p.blend(x, y, C[7], 0.55);
              continue;
            }
            const fresh = 1 - clamp((age - 0.03) / 0.1), g = F.g;
            p.blend(x, y, fresh > 0.5 || g > 0.5 ? C[6] : F.tint, F.alpha + 0.3 * fresh + 0.2 * g);
            if (g > 0.05) p.light(x, y, C[5], 0.4 * g);
          }
        // las aristas: el contorno claro donde mira a la luz y oscuro en la sombra; las de dentro, pálidas
        for (const e of EDGES) {
          if (e.floor || t < e.at) continue;
          const [x0, y0] = e.a, [x1, y1] = e.b, fresh = e.fs.some((F) => t - F.at < 0.1 || F.g > 0.6);
          if (e.outer && e.lit < 0) p.line(x0 + 1, y0, x1 + 1, y1, C[1]);
          if (e.outer) p.glowLine(x0, y0, x1, y1, 4, C[4], 0.08);
          p.line(x0, y0, x1, y1, fresh ? WHITE : e.outer ? (e.lit > 0.3 ? WHITE : e.lit > -0.2 ? C[6] : C[4]) : (y0 + y1) / 2 < -30 ? C[6] : C[5]);
        }
        // una cara a punto de cristalizar: sus aristas se perfilan en blanco, con una bolita de luz delante
        for (const F of FACETS) {
          const age = t - F.at;
          if (age < -0.06 || age >= 0) continue;
          let left = ((age + 0.06) / 0.06) * F.len;
          for (let k = 0; k < F.pts.length && left > 0; k++) {
            const [x0, y0] = F.pts[k], [x1, y1] = F.pts[(k + 1) % F.pts.length], L = Math.hypot(x1 - x0, y1 - y0), v = Math.min(1, left / L);
            left -= L;
            p.line(x0, y0, x0 + (x1 - x0) * v, y0 + (y1 - y0) * v, WHITE);
            if (v < 1) p.glow(x0 + (x1 - x0) * v, y0 + (y1 - y0) * v, 5, C[6], 0.6);
          }
        }
        // los destellos de las esquinas: siempre los mismos, a su hora del ciclo
        if (c >= 0)
          for (const [k, t0] of [[0, 0.62], [4, 0.85], [2, 1.02]]) {
            const g = (c - t0) / 0.16;
            if (g > 0 && g < 1) sparkle(p, VERTS[k][0], VERTS[k][1], 5 * Math.sin(Math.PI * g), WHITE, C[5], 0.5);
          }
        // la estrella de la punta al cerrarse
        const top = FACETS[FACETS.length - 1].at, g = t - top;
        if (g > 0 && g < 0.2) sparkle(p, V.p2[0], V.p2[1], 7 * Math.sin(Math.PI * (g / 0.2)), WHITE, C[4], 0.6);
        // un frío suave dentro del bloque
        p.glow(0, -24, 22, C[4], 0.12 * smooth(SEAL, FORMA, t));
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
