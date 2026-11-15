// El golpe del chorro (chorro-golpe.js) del lanza hielo contra la pared, donde se corta: más ancho, con más esquirlas y
// más niebla.
import * as base from "./chorro-golpe-hielo.js";

export const meta = {
  ...base.meta,
  name: "Chorro de hielo contra la pared",
  desc: "A freezing jet blasting a wall, seen from above: a wide cloud of icy mist, a spray of shards and frost on the floor.",
  size: [144, 124],
  origin: [72, 82],
  options: { ...base.meta.options, spread: 2, seed: 8 },
};
export const create = base.create;
