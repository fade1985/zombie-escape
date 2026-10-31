// El golpe del chorro (chorro-golpe.js) del lanza ácido en un zombi (M59): el chisporroteo, con los verdes del chorro
// (llamarada.gd, VERDES).
import * as base from "./chorro-golpe.js";

export const meta = {
  ...base.meta,
  name: "Golpe del chorro de ácido",
  desc: "An acid jet hitting a body, seen from above: drops splash and sizzle on the floor, bubbles swell and pop, green vapour rises.",
  options: { ...base.meta.options, tipo: "acido", palette: ["#0f1a06", "#2f4a10", "#5f8a1c", "#96b430", "#c7e04a", "#ecf896", "#fbffe0"], seed: 4 },
};
export const create = base.create;
