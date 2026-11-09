// Común a los borradores del rayo del lanza rayos (Johnny Rush): de dónde a dónde va, la paleta celeste del juego,
// el arco que salta a otro zombi, el nudo de chispazos donde toca y las chispas que saltan (vista desde arriba: sin
// gravedad, frenan y se apagan).
import { fit, cycle, TAU, WHITE } from "../../core/index.js";
import { zigzag, bowed, crackle, stroke, frameRng, flight, spark } from "./_lib.js";

export const D = 1.0, L = 128, FR = 18;            // un bucle de 1 s; el rayo mide 128 px (256 en el juego); 18 formas/s
export const T1 = [L, 0], T2 = [L + 34, 26];         // el zombi que toca y al que salta la descarga
export const CEL = ["#04121c", "#0a2a44", "#0d4f74", "#127fa6", "#1fb8d6", "#2cf2f0", "#9fe8ff", "#ecffff"];
export const META = {
  size: [200, 96],
  origin: [18, 40],
  duration: D,
  loop: true,
  fps: 30,
  bg: "dark",
};
export const ramp = (o) => fit(o.palette, 8);
export const SPK = (C) => [WHITE, C[7], C[6], C[4]];

/** Número de forma (0..n-1) en este instante, para n formas por bucle. */
export const forma = (t, n) => Math.floor((t / D) * n) % n;

/** El arco que salta de T1 a T2, combado y titilando. */
export function salto(p, t, C, S) {
  const f = forma(t, FR), R = frameRng(S, f, 77);
  const k = 0.65 + 0.35 * R.next();
  crackle(p, bowed(R, T1[0], T1[1], T2[0], T2[1], R.range(-10, 10), 0.25, 0.5), k, C, 0.5);
}

/** Donde toca: un nudo de zigzags cortitos que chisporrotea, con su luz. */
export function nudo(p, t, x, y, C, S, r = 7, n = 5) {
  const f = forma(t, FR * 2), R = frameRng(S, f, 31 + x);
  for (let i = 0; i < n; i++) {
    const a = R.range(0, TAU), l = R.range(r * 0.5, r * 1.4);
    crackle(p, zigzag(R, x, y, x + Math.cos(a) * l, y + Math.sin(a) * l, 0.4, 0), R.range(0.5, 1), C, 0.25);
  }
  const late = 0.75 + 0.25 * R.next();
  p.circle(x, y, (r * 0.45 + 1) * late, C[5]);
  p.circle(x, y, (r * 0.3 + 0.8) * late, C[7]);
  p.circle(x, y, r * 0.15 + 0.6, WHITE);
  p.glow(x, y, r * 3 + 6, C[5], 0.7 * late);
  p.glow(x, y, r + 3, WHITE, 0.6);
}

/** Chispas que saltan de (x, y) a todos lados y se apagan. */
export function chispas(p, t, x, y, C, S, rate = 40) {
  cycle(t, D, rate, S * 5 + x, (g) => g.range(0.12, 0.3), (age, life, r) => {
    const a = r.range(0, TAU), sp = r.range(60, 180);
    const [sx, sy, vx, vy] = flight(x, y, Math.cos(a) * sp, Math.sin(a) * sp, age, { g: 0, drag: 5 });
    spark(p, sx, sy, vx, vy, 1 - age / life, SPK(C));
  });
}

export { zigzag, bowed, crackle, stroke, frameRng, WHITE, TAU, cycle };
