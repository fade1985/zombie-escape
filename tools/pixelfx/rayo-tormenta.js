// El rayo del lanza rayos (llamarada.gd): el borrador A, "tormenta" (9 nov). No se exporta: el juego lo dibuja a código
// con lo mismo (Relampago y llamarada.trazar_rayo). Para verlo, copiar este archivo y _rayo.js a src/fx/lightning/ de
// pixelfx y: node tools/render.mjs lightning/rayo-tormenta
// Borrador A, "tormenta": tres rayos entrelazados que titilan cada uno a su ritmo, nudos de luz que corren por el
// tronco hasta el zombi y latigazos que salen a los lados.
import { D, L, T1, CEL, META, ramp, forma, salto, nudo, chispas, zigzag, crackle, stroke, frameRng, WHITE, TAU, cycle } from "./_rayo.js";

export const meta = { ...META, name: "Rayo A tormenta", desc: "borrador", tags: ["lightning", "beam", "loop"], options: { palette: CEL, seed: 3 } };

export function draw(p, t, o) {
  const C = ramp(o), S = o.seed, ph = t / D;
  // dos hebras finas que cambian a otro ritmo, por detrás
  for (const [n, sal, k] of [[12, 1, 0.6], [24, 2, 0.45]]) {
    const R = frameRng(S, forma(t, n), sal);
    crackle(p, zigzag(R, 0, 0, L, 0, 0.14, 0.15), k + 0.25 * R.next(), C, 0.3);
  }
  // el tronco
  const f = forma(t, 18), R = frameRng(S, f, 0);
  const b = zigzag(R, 0, 0, L, 0, 0.1, 0.45);
  stroke(p, b, 1, C, 1, { light: 0.45, hero: f % 7 === 0 });
  // nudos de luz que corren por el tronco
  const pts = b.paths[0].pts;
  for (let j = 0; j < 3; j++) {
    const u = (ph * 4 + j / 3) % 1, [x, y] = pts[Math.floor(u * (pts.length - 1))];
    p.circle(x, y, 2.4, C[7]);
    p.circle(x, y, 1.2, WHITE);
    p.glow(x, y, 12, C[5], 0.6);
  }
  // latigazos: una rama que sale del tronco, vive unos fotogramas y se va
  cycle(t, D, 5, S * 7 + 1, 0.1, (age, life, r) => {
    const i = Math.floor(r.range(0.15, 0.85) * pts.length), [x, y] = pts[i];
    const a = r.sign() * r.range(0.6, 1.3) + r.range(-0.2, 0.2), l = r.range(14, 30);
    const R2 = frameRng(S, i, 9);
    crackle(p, zigzag(R2, x, y, x + Math.cos(a) * l, y + Math.sin(a) * l, 0.3, 0.6), 1 - age / life, C, 0.4);
  });
  // la boca
  nudo(p, t, 0, 0, C, S + 5, 4, 3);
  p.glow(0, 0, 22, C[5], 0.5);
  // el zombi tocado, el salto y el siguiente
  nudo(p, t, T1[0], T1[1], C, S, 8, 6);
  chispas(p, t, T1[0], T1[1], C, S, 22);
  salto(p, t, C, S);
}
