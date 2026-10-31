// El golpe del chorro (chorro-golpe.js) del lanza ácido contra la pared, donde se corta (M60): salpica más ancho y chorrea
// por la pared hasta el suelo.
import * as base from "./chorro-golpe-acido.js";

export const meta = {
  ...base.meta,
  name: "Chorro de ácido contra la pared",
  desc: "An acid jet splashing on a wall, seen from above: a wide splash, drips running down to the floor, bubbles and green vapour.",
  size: [144, 124],
  origin: [72, 82],
  options: { ...base.meta.options, spread: 2, chorretones: 5, seed: 6 },
};
export const create = base.create;
