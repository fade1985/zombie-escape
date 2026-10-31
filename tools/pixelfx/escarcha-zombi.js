// El estallido de escarcha (escarcha.js), pequeño: el de cada zombi que se congela (zombi.gd, congelar; la congeladora y
// la cámara frigorífica). Unos cristalitos alrededor de los pies, el copo a la altura del cuerpo y unos trozos de hielo.
import * as base from "./escarcha.js";

export const meta = {
  ...base.meta,
  name: "Escarcha (zombi)",
  size: [72, 72],
  origin: [36, 48],
  duration: 1.2,
  options: { ...base.meta.options, reach: 14, height: 18, crystals: 9, tall: 0.9, seed: 7 },
};
export const create = base.create;
