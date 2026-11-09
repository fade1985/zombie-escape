// El golpe del chorro (chorro-golpe.js) del lanzallamas contra la pared, donde se corta (M60): más ancho, el fuego se
// aplasta y se abre contra ella.
import * as base from "./chorro-golpe.js";

export const meta = {
  ...base.meta,
  name: "Chorro contra la pared",
  desc: "A flamethrower jet splashing on a wall, seen from above: the flame flattens and spreads out wide, with sparks and a wisp of smoke.",
  size: [160, 136],   // (+16 por lado: que la luz no se salga del lienzo, 9 nov)
  origin: [80, 92],
  options: { ...base.meta.options, spread: 2, seed: 5 },
};
export const create = base.create;
